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

    {:ok, started_at, _} = DateTime.from_iso8601(pipeline_response["startedAt"])

    pipeline = %Pipeline{
      iid: pipeline_response["iid"],
      duration: pipeline_response["duration"],
      queued_duration: pipeline_response["queued_duration"],
      jobs: jobs,
      started_at: started_at
    }

    {:ok, pipeline}
  end
end
