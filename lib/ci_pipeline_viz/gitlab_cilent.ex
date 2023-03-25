defmodule CiPipelineViz.GitlabCilent do
  alias CiPipelineViz.Project

  @type creds :: %{
          access_token: String.t(),
          refresh_token: String.t()
        }

  @spec search_projects(creds(), String.t()) :: list(Project.t())
  def search_projects(creds, search_term) do
    Req.get!("https://gitlab.com/api/v4/projects",
      auth: {:bearer, creds.access_token},
      params: %{search: search_term}
    ).body
    |> Enum.map(fn project_response ->
      %Project{
        id: project_response["id"],
        full_path: project_response["namespace"]["full_path"],
        name: project_response["namespace"]["path"]
      }
    end)
  end
end
