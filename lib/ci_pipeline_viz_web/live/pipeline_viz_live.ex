defmodule CiPipelineVizWeb.Live.PipelineViz do
  use CiPipelineVizWeb, :live_view

  alias CiPipelineViz.GitlabClient

  @impl true
  def mount(_, session, socket) do
    socket =
      assign(socket,
        current_user: session["current_user"],
        loading_pipeline: false,
        pipeline_form: to_form(%{}),
        pipeline: nil,
        loading: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link :if={@current_user == nil} href={~p"/auth/gitlab"}>Sign in</.link>

    <div :if={@current_user} class="flex flex-col">
      <div>Hello <%= @current_user.name %></div>
      <.link href={~p"/auth/signout"} method="delete">Sign out</.link>

      <.simple_form for={@pipeline_form} phx-submit="fetch_pipeline" class="mv-4">
        <.input
          field={@pipeline_form["project_path"]}
          label="Enter the full path of the project the pipeline belongs to"
          placeholder="gitlab-org/gitlab"
        />

        <.input
          field={@pipeline_form["pipeline_iid"]}
          label="Enter the iid of the pipeline you wish to visualize"
          placeholder="10000"
        />

        <.button type="submit">Visualize</.button>
      </.simple_form>

      <div :if={@loading}>
        loading...
      </div>

      <div :if={@pipeline != nil}>
      <span><%= @pipeline.iid %></span>
      <ul>
        <li :for={job <- @pipeline.jobs}>
          <span><%= job.name %>: <%= job.duration %>s</span>
        </li>
      </ul>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("fetch_pipeline", params, socket) do
    fetch_params = %{
      creds: socket.assigns.current_user.creds,
      project_path: "inkscape/inkscape",
      pipeline_iid: "21233"
      # project_path: params["project_path"],
      # pipeline_iid: params["pipeline_id"]
    }

    send(self(), {:fetch_pipeline, fetch_params})

    {:noreply, assign(socket, :loading, true)}
  end

  @impl true
  def handle_info({:fetch_pipeline, params}, socket) do
    pipeline_iid = String.to_integer(params.pipeline_iid)

    {:ok, pipeline} =
      GitlabClient.fetch_pipeline(
        params.creds,
        params.project_path,
        pipeline_iid
      )

    {:noreply, assign(socket, pipeline: pipeline, loading: false)}
  end
end
