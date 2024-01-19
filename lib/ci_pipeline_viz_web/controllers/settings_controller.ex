defmodule CiPipelineVizWeb.SettingsController do
  use CiPipelineVizWeb, :controller

  import Phoenix.Controller, except: [render: 2, render: 3]

  defmodule View do
    use CiPipelineVizWeb, :html

    def show(assigns) do
      ~H"""
      <.link
        :if={@already_configured?}
        href={~p"/"}
        class="border-2 border-zinc-900 font-semibold py-2 px-3 rounded-lg hover:bg-zinc-100"
      >
        Back
      </.link>

      <div class="flex flex-col">
        <.simple_form for={@settings} action={~p"/settings"} method="post" class="mv-4">
          <.input
            field={@settings["base_url"]}
            label="Enter the URL of your Gitlab instance"
            placeholder="https://gitlab.com"
          />

          <.input
            field={@settings["access_token"]}
            label="Enter your Gitlab access token"
            placeholder="glpat-pn8LxA8b8UyfrJxRvVRw"
            type="password"
          />

          <:actions>
            <.button type="submit">Save</.button>
          </:actions>
        </.simple_form>
      </div>
      """
    end
  end

  alias CiPipelineVizWeb.SettingsController.View

  def show(conn, _params) do
    base_url = get_session(conn, :base_url, "https://gitlab.com")
    access_token = get_session(conn, :access_token, nil)

    render(conn, :show, %{
      settings:
        Phoenix.Component.to_form(%{"base_url" => base_url, "access_token" => access_token}),
      already_configured?: access_token != nil
    })
  end

  def save(conn, params) do
    conn
    |> put_session(:base_url, params["base_url"])
    |> put_session(:access_token, params["access_token"])
    |> redirect(to: ~p"/")
  end

  defp render(conn, view, assigns) do
    conn
    |> put_view(View)
    |> Phoenix.Controller.render(view, assigns)
  end
end
