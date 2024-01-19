defmodule CiPipelineVizWeb.Plugs.AuthPlug do
  import Plug.Conn

  use Phoenix.VerifiedRoutes,
    endpoint: CiPipelineVizWeb.Endpoint,
    router: CiPipelineVizWeb.Router,
    statics: CiPipelineVizWeb.static_paths()

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with base_url when not is_nil(base_url) <- get_session(conn, :base_url, nil),
         access_token when not is_nil(access_token) <- get_session(conn, :access_token, nil) do
      conn
      |> assign(:base_url, base_url)
      |> assign(:access_token, access_token)
    else
      _ -> Phoenix.Controller.redirect(conn, to: ~p"/settings")
    end
  end
end
