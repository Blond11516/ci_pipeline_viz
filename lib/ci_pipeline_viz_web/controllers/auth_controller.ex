defmodule CiPipelineVizWeb.Controllers.AuthController do
  defmodule GitlabAppCredentials do
    @enforce_keys [:base_url, :application_id, :application_secret]
    defstruct [:base_url, :application_id, :application_secret]

    @type t :: %__MODULE__{
            base_url: String.t(),
            application_id: String.t(),
            application_secret: String.t()
          }
  end

  use CiPipelineVizWeb, :controller

  import Plug.Conn

  alias Assent.{Config, Strategy.Gitlab}

  def request(conn, params) do
    config = request_config(params)

    config
    |> Gitlab.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        app_credentials = %GitlabAppCredentials{
          base_url: Keyword.fetch!(config, :base_url),
          application_id: Keyword.fetch!(config, :client_id),
          application_secret: Keyword.fetch!(config, :client_secret)
        }

        conn
        # Session params (used for OAuth 2.0 and OIDC strategies) will be
        # retrieved when user returns for the callback phase
        |> put_session(:session_params, session_params)
        |> put_session(:app_credentials, app_credentials)
        # Redirect end-user to Github to authorize access to their account
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
    app_credentials = get_session(conn, :app_credentials)

    app_credentials
    |> callback_config()
    # Session params should be added to the config so the strategy can use them
    |> Config.put(:session_params, session_params)
    |> Gitlab.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        conn
        |> put_session(:current_user, %{
          base_url: app_credentials.base_url,
          name: Map.fetch!(user, "preferred_username"),
          creds: %{
            access_token: Map.fetch!(token, "access_token"),
            refresh_token: Map.fetch!(token, "refresh_token")
          }
        })
        |> configure_session(renew: true)

      {:error, error} ->
        conn
        |> put_flash(:error, "Authorization failed: #{inspect(error)}")
        |> clear_session()
    end
    |> redirect(to: ~p"/")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: ~p"/")
  end

  def base_url_param_name, do: "gitlab-base-url"
  def application_id_param_name, do: "gitlab-application-id"
  def application_secret_param_name, do: "gitlab-application_id"

  defp request_config(params),
    do:
      Config.merge(base_config(),
        base_url: Map.fetch!(params, base_url_param_name()),
        client_id: Map.fetch!(params, application_id_param_name()),
        client_secret: Map.fetch!(params, application_secret_param_name())
      )

  defp callback_config(%GitlabAppCredentials{} = app_credentials),
    do:
      Config.merge(base_config(),
        base_url: app_credentials.base_url,
        client_id: app_credentials.application_id,
        client_secret: app_credentials.application_secret
      )

  defp base_config,
    do: [
      redirect_uri: CiPipelineVizConfig.gitlab_redirect_uri(),
      authorization_params: [scope: "read_api"]
    ]
end
