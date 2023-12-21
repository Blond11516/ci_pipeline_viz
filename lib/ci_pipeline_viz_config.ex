defmodule CiPipelineVizConfig do
  @spec gitlab_redirect_uri() :: String.t()
  def gitlab_redirect_uri do
    Application.fetch_env!(:ci_pipeline_viz, :gitlab_redirect_uri)
  end
end
