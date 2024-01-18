defmodule CiPipelineVizWeb.Live.PipelineViz do
  use CiPipelineVizWeb, :live_view

  alias CiPipelineViz.GitlabClient
  alias CiPipelineViz.Entities.Pipeline
  alias CiPipelineVizWeb.Controllers.AuthController

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
    <form
      :if={@current_user == nil}
      action={~p"/auth/gitlab"}
      class="flex flex-col items-center gap-4"
    >
      <div class="w-[400px] flex flex-col">
        <label for="gitlab-base-url-input">Gitlab instance base URL</label>
        <input
          id="gitlab-base-url-input"
          type="text"
          name={AuthController.base_url_param_name()}
          value="https://gitlab.com"
          class="rounded p-1"
        />
        <label for="gitlab-application_id-input">Gitlab application ID</label>
        <input
          id="gitlab-application_id-input"
          type="text"
          name={AuthController.application_id_param_name()}
          placeholder="73a51d93fefec6923c498a8f53de9d89b0be2a1be73db72eaf4329d827f379e6"
          class="rounded p-1"
        />
        <label for="gitlab-application-secret-input">Gitlab application secret</label>
        <input
          id="gitlab-application-secret-input"
          type="text"
          name={AuthController.application_secret_param_name()}
          placeholder="gloas-768d8b69e5555f8e529215d723f3e8a6f362f0aa3e6af837939c47c8258373da"
          class="rounded p-1"
        />
      </div>
      <button type="submit" class="flex items-center gap-1.5 rounded border border-gray-500 p-2">
        <img src={~p"/images/gitlab-logo-500.svg"} width="32" class="-m-2" />
        <span class="-mt-1">Sign in with Gitlab</span>
      </button>
    </form>

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

      <.async_result :let={pipeline} :if={@pipeline != nil} assign={@pipeline}>
        <:loading>loading...</:loading>

        <span>IID: <%= pipeline.iid %></span>
        <canvas id="chart" phx-hook="timelineChart" data-series={prepare_series_data(pipeline)} />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("fetch_pipeline", params, socket) do
    pipeline_iid = String.to_integer(params["pipeline_iid"])

    socket =
      assign_async(socket, :pipeline, fn ->
        {:ok, pipeline} =
          GitlabClient.fetch_pipeline(
            Map.put(
              socket.assigns.current_user.creds,
              :base_url,
              socket.assigns.current_user.base_url
            ),
            params["project_path"],
            pipeline_iid
          )

        {:ok, %{pipeline: pipeline}}
      end)

    {:noreply, socket}
  end

  defp prepare_series_data(%Pipeline{} = pipeline) do
    pipeline.jobs
    |> Enum.sort_by(fn job -> job.started_at end)
    |> Enum.map(fn job ->
      started_at_seconds = DateTime.diff(job.started_at, pipeline.started_at, :second)
      finished_at_seconds = DateTime.diff(job.finished_at, pipeline.started_at, :second)

      %{
        "name" => job.name,
        "queued_at_seconds" => started_at_seconds,
        "queued_duration" => job.queued_duration,
        "run_duration" => finished_at_seconds - started_at_seconds
      }
    end)
    |> Jason.encode!()
  end
end
