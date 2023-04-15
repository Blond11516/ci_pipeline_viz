defmodule CiPipelineViz.GitlabClient do
  alias CiPipelineViz.Job
  alias CiPipelineViz.Project
  alias CiPipelineViz.Pipeline
  alias CiPipelineViz.Stage

  @type creds :: %{
          access_token: String.t(),
          refresh_token: String.t()
        }

  @spec fetch_pipeline(creds(), Project.path(), Pipeline.iid()) :: {:ok, Pipeline.t()}
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

    jobs =
      Enum.map(pipeline_response["jobs"]["nodes"], fn job_response ->
        "gid://gitlab/Ci::Build/" <> raw_job_id = job_response["id"]
        "gid://gitlab/Ci::Stage/" <> raw_stage_id = job_response["stage"]["id"]

        %Job{
          id: String.to_integer(raw_job_id),
          duration: job_response["duration"],
          queued_duration: job_response["queuedDuration"],
          name: job_response["name"],
          stage: %Stage{
            id: String.to_integer(raw_stage_id),
            name: job_response["stage"]["name"]
          }
        }
      end)

    pipeline = %Pipeline{
      iid: pipeline_response["iid"],
      duration: pipeline_response["duration"],
      queued_duration: pipeline_response["queued_duration"],
      jobs: jobs
    }

    {:ok, pipeline}
  end
end
