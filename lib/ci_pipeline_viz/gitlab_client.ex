defmodule CiPipelineViz.GitlabClient do
  alias CiPipelineViz.Job
  alias CiPipelineViz.Project
  alias CiPipelineViz.Pipeline
  alias CiPipelineViz.Stage

  @type gitlab_config :: %{
          base_url: String.t(),
          access_token: String.t(),
          refresh_token: String.t()
        }

  @spec fetch_pipeline(gitlab_config(), Project.path(), Pipeline.iid()) ::
          {:ok, Pipeline.t(), Graph.t()}
  def fetch_pipeline(gitlab_config, project_path, pipeline_iid) do
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
                startedAt
                jobs {
                  nodes {
                    id
                    duration
                    queuedDuration
                    name
                    startedAt
                    finishedAt
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
        url: Path.join(gitlab_config.base_url, "/api/graphql"),
        headers: [authorization: "Bearer #{gitlab_config.access_token}"]
      )

    pipeline_response = response.body["data"]["project"]["pipeline"]

    jobs_response = pipeline_response["jobs"]["nodes"]

    jobs =
      jobs_response
      |> Enum.filter(fn job -> job["startedAt"] != nil and job["finishedAt"] != nil end)
      |> Enum.map(fn job_response ->
        job_id = Job.Id.from_gid(job_response["id"])
        stage_id = Stage.Id.from_gid(job_response["stage"]["id"])
        {:ok, started_at, _} = DateTime.from_iso8601(job_response["startedAt"])
        {:ok, finished_at, _} = DateTime.from_iso8601(job_response["finishedAt"])

        %Job{
          id: job_id,
          duration: job_response["duration"],
          queued_duration: job_response["queuedDuration"],
          name: job_response["name"],
          started_at: started_at,
          finished_at: finished_at,
          stage: %Stage{
            id: stage_id,
            name: job_response["stage"]["name"]
          }
        }
      end)

    job_graph = parse_jobs_graph(jobs, jobs_response)

    {:ok, started_at, _} = DateTime.from_iso8601(pipeline_response["startedAt"])

    pipeline = %Pipeline{
      iid: pipeline_response["iid"],
      duration: pipeline_response["duration"],
      queued_duration: pipeline_response["queued_duration"],
      jobs: jobs,
      started_at: started_at
    }

    {:ok, pipeline, job_graph}
  end

  @spec parse_jobs_graph([Job.t()], map()) :: Graph.t()
  defp parse_jobs_graph(jobs, jobs_response) do
    edges = Enum.flat_map(jobs_response, &build_dependency_edge_list(&1, jobs))

    Graph.new(
      type: :directed,
      vertex_identifier: fn job -> job.id end
    )
    |> Graph.add_vertices(jobs)
    |> Graph.add_edges(edges)
  end

  @spec build_dependency_edge_list(map(), [Job.t()]) :: [Graph.Edge.t()]
  defp build_dependency_edge_list(job_response, jobs) do
    job_id = Job.Id.from_gid(job_response["id"])
    job = Enum.find(jobs, fn job -> job.id == job_id end)

    Enum.map(
      job_response["previousStageJobsOrNeeds"]["nodes"],
      &build_dependency_edge(&1, jobs, job)
    )
  end

  @spec build_dependency_edge(map(), [Job.t()], Job.t()) :: Graph.Edge.t()
  defp build_dependency_edge(dependency, jobs, dependent_job) do
    label =
      case dependency do
        %{"needId" => _} -> :needs
        %{"stageId" => _} -> :stage
      end

    jobs
    |> Enum.find(fn job -> job.name == dependency["name"] end)
    |> Graph.Edge.new(dependent_job, label: label)
  end
end
