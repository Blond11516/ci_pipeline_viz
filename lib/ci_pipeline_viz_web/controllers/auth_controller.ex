defmodule CiPipelineVizWeb.Controllers.AuthController do
  use CiPipelineVizWeb, :controller

  import Plug.Conn

  alias Assent.{Config, Strategy.Gitlab}

  def request(conn, _params) do
    config()
    |> Gitlab.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        # Session params (used for OAuth 2.0 and OIDC strategies) will be
        # retrieved when user returns for the callback phase
        conn = put_session(conn, :session_params, session_params)

        # Redirect end-user to Github to authorize access to their account
        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, error} ->
        put_flash(conn, :error, "Failed to generate request authorization URL: #{inspect(error)}")
    end
  end

  def callback(conn, _params) do
    # End-user will return to the callback URL with params attached to the
    # request. These must be passed on to the strategy. In this example we only
    # expect GET query params, but the provider could also return the user with
    # a POST request where the params is in the POST body.
    %{params: params} = fetch_query_params(conn)

    # The session params (used for OAuth 2.0 and OIDC strategies) stored in the
    # request phase will be used in the callback phase
    session_params = get_session(conn, :session_params)

    config()
    # Session params should be added to the config so the strategy can use them
    |> Config.put(:session_params, session_params)
    |> Gitlab.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        conn
        |> put_session(:current_user, %{
          name: user["preferred_username"],
          creds: %{
            access_token: token["access_token"],
            refresh_token: token["refresh_token"]
          }
        })
        |> configure_session(renew: true)
        |> redirect(to: ~p"/")

      {:error, error} ->
        put_flash(conn, :error, "Authorization failed: #{inspect(error)}")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: ~p"/")
  end

  defp config,
    do: [
      client_id: Application.get_env(:ci_pipeline_viz, :gitlab_client_id),
      client_secret: Application.get_env(:ci_pipeline_viz, :gitlab_client_secret),
      redirect_uri: Application.get_env(:ci_pipeline_viz, :gitlab_redirect_uri)
    ]
end
