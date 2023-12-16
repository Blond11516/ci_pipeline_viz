defmodule CiPipelineVizWeb.Live.PipelineViz do
  use CiPipelineVizWeb, :live_view

  alias CiPipelineViz.GitlabClient
  alias CiPipelineViz.Pipeline

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

      <.async_result :let={pipeline} :if={@pipeline != nil} assign={@pipeline}>
        <:loading>loading...</:loading>

        <span>IID: <%= pipeline.iid %></span>
        <div id="chart" phx-hook="timelineChart" data-series={prepare_series_data(pipeline)} />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("fetch_pipeline", params, socket) do
    fetch_params = %{
      creds: socket.assigns.current_user.creds,
      project_path: params["project_path"],
      pipeline_iid: params["pipeline_iid"]
    }

    {:noreply, assign_async(socket, :pipeline, fn -> fetch_pipeline(fetch_params) end)}
  end

  defp fetch_pipeline(params) do
    pipeline_iid = String.to_integer(params.pipeline_iid)

    {:ok, pipeline, _} =
      GitlabClient.fetch_pipeline(
        params.creds,
        params.project_path,
        pipeline_iid
      )

    {:ok, %{pipeline: pipeline}}
  end

  defp prepare_series_data(%Pipeline{} = pipeline) do
    run_data =
      Enum.map(pipeline.jobs, fn job ->
        started_at_seconds = DateTime.diff(job.started_at, pipeline.started_at, :second)
        finished_at_seconds = DateTime.diff(job.finished_at, pipeline.started_at, :second)

        %{
          "x" => job.name,
          "y" => [
            started_at_seconds + job.queued_duration,
            finished_at_seconds + job.queued_duration
          ]
        }
      end)

    queue_data =
      Enum.map(pipeline.jobs, fn job ->
        started_at_seconds = DateTime.diff(job.started_at, pipeline.started_at, :second)

        %{
          "x" => job.name,
          "y" => [started_at_seconds, started_at_seconds + job.queued_duration]
        }
      end)

    Jason.encode!([
      %{"data" => run_data, "name" => "Duration (s)"},
      %{"data" => queue_data, "name" => "Queued (s)"}
    ])
  end
end
