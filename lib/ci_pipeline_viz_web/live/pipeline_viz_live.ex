defmodule CiPipelineVizWeb.Live.PipelineViz do
  use CiPipelineVizWeb, :live_view

  alias CiPipelineViz.GitlabCilent
  alias CiPipelineViz.Project

  @impl true
  def mount(_, session, socket) do
    socket =
      assign(socket,
        current_user: session["current_user"],
        search: to_form(%{}),
        projects: [],
        selected_project: nil,
        loading_projects: false
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

      <div :if={@selected_project == nil}>
        <.simple_form for={@search} phx-change="search_projects" class="mb-4" phx-submit="noop">
          <.input
            field={@search["term"]}
            label="Search for your project"
            placeholder="Gitlab"
            phx-debounce={500}
          />
        </.simple_form>

        <div :if={@loading_projects}>
          loading...
        </div>

        <ul id="projects" phx-update="replace" class="flex flex-col gap-4">
          <li :for={project <- @projects} phx-click="select_project" phx-value-project-id={project.id}>
            <.project_card project={project} selectable />
          </li>
        </ul>
      </div>

      <div :if={@selected_project != nil}>
        <.project_card project={@selected_project} />
      </div>
    </div>
    """
  end

  attr :project, Project, required: true
  attr :selectable, :boolean, default: false

  defp project_card(assigns) do
    ~H"""
    <div class={[
      "border-2 border-orange-400 rounded-md bg-orange-200 p-2",
      @selectable && "cursor-pointer hover:outline outline-orange-400"
    ]}>
      <div class="text-lg"><%= @project.name %></div>
      <div class="text-base text-neutral-500"><%= @project.full_path %></div>
    </div>
    """
  end

  @impl true
  def handle_event("search_projects", params, socket) do
    send(self(), {:search_projects, {socket.assigns.current_user.creds, params["term"]}})

    {:noreply, assign(socket, :loading_projects, true)}
  end

  def handle_event("select_project", params, socket) do
    project_id = String.to_integer(params["project-id"])
    project = Enum.find(socket.assigns.projects, &(&1.id == project_id))

    {:noreply, assign(socket, :selected_project, project)}
  end

  def handle_event("noop", _, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:search_projects, {creds, search_term}}, socket) do
    projects =
      GitlabCilent.search_projects(
        creds,
        search_term
      )

    {:noreply, assign(socket, projects: projects, loading_projects: false)}
  end
end
