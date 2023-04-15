defmodule CiPipelineViz.GitlabClient do
  alias CiPipelineViz.Project
  alias CiPipelineViz.Pipeline

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
              }
            }

          }
        """,
        %{project_path: project_path, pipeline_iid: pipeline_iid},
        url: "https://gitlab.com/api/graphql",
        headers: [authorization: "Bearer #{creds.access_token}"]
      )

    pipeline_response = response.body["data"]["project"]["pipeline"]

    pipeline = %Pipeline{
      iid: pipeline_response["iid"],
      duration: pipeline_response["duration"],
      queued_duration: pipeline_response["queued_duration"]
    }

    {:ok, pipeline}
  end
end
