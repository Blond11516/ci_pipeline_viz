defmodule CiPipelineViz.GitlabClient do
  alias CiPipelineViz.Job
  alias CiPipelineViz.Project
  alias CiPipelineViz.Pipeline
  alias CiPipelineViz.Stage

  @type creds :: %{
          access_token: String.t(),
          refresh_token: String.t()
        }

  @spec fetch_pipeline(creds(), Project.path(), Pipeline.iid()) :: {:ok, Pipeline.t(), Graph.t()}
  def fetch_pipeline(creds, project_path, pipeline_iid) do
    {:ok, response} =
      Neuron.query(
        """
          query fetchPipeline($project_path: ID!, $pipeline_iid: ID!) {
            project(fullPath: $project_path) {
              id
              pipeline(iid: $pipeline_iid) {
                iid
                duration
                queuedDuration
                jobs {
                  nodes {
                    id
                    duration
                    queuedDuration
                    name
                    stage {
                      id
                      name
                    }
                    previousStageJobsOrNeeds {
                      nodes {
                        ... on CiBuildNeed {
                          needId: id
                          name
                        }
                        ... on CiJob {
                          stageId: id
                          name
                        }
                      }
                    }
                  }
                }
              }
            }

          }
        """,
        %{project_path: project_path, pipeline_iid: pipeline_iid},
        url: "https://gitlab.com/api/graphql",
        headers: [authorization: "Bearer #{creds.access_token}"]
      )

    pipeline_response = response.body["data"]["project"]["pipeline"]

    jobs_response = pipeline_response["jobs"]["nodes"]

    jobs =
      Enum.map(jobs_response, fn job_response ->
        job_id = Job.Id.from_gid(job_response["id"])
        stage_id = Stage.Id.from_gid(job_response["stage"]["id"])

        %Job{
          id: job_id,
          duration: job_response["duration"],
          queued_duration: job_response["queuedDuration"],
          name: job_response["name"],
          stage: %Stage{
            id: stage_id,
            name: job_response["stage"]["name"]
          }
        }
      end)

    edges =
      jobs_response
      |> Enum.flat_map(fn job_response ->
        job_id = Job.Id.from_gid(job_response["id"])
        job = Enum.find(jobs, fn job -> job.id == job_id end)

        job_response["previousStageJobsOrNeeds"]["nodes"]
        |> Enum.map(fn dependency ->
          label =
            case dependency do
              %{"needId" => _} -> :needs
              %{"stageId" => _} -> :stage
            end

          dependency_job = Enum.find(jobs, fn job -> job.name == dependency["name"] end)
          Graph.Edge.new(dependency_job, job, label: label)
        end)
      end)

    job_graph =
      Graph.new(
        type: :directed,
        vertex_identifier: fn job -> job.id end
      )
      |> Graph.add_vertices(jobs)
      |> Graph.add_edges(edges)

    pipeline = %Pipeline{
      iid: pipeline_response["iid"],
      duration: pipeline_response["duration"],
      queued_duration: pipeline_response["queued_duration"],
      jobs: jobs
    }

    {:ok, pipeline, job_graph}
  end
end
