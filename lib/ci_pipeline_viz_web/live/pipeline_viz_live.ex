defmodule CiPipelineVizWeb.Live.PipelineViz do
  use CiPipelineVizWeb, :live_view

  alias CiPipelineViz.GitlabClient
  alias CiPipelineViz.Entities.Pipeline

  @impl true
  def mount(_, session, socket) do
    socket =
      assign(socket,
        base_url: session["base_url"],
        access_token: session["access_token"],
        pipeline_form: to_form(%{"instance_url" => "https://gitlab.com"}),
        pipeline: nil
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link
      href={~p"/settings"}
      class="border-2 border-zinc-900 font-semibold py-2 px-3 rounded-lg hover:bg-zinc-100"
    >
      Settings
    </.link>

    <div class="flex flex-col">
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
        <:failed :let={{:error, reason}}><%= reason %></:failed>

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
        with {:ok, pipeline} <-
               GitlabClient.fetch_pipeline(
                 %{
                   base_url: socket.assigns.base_url,
                   access_token: socket.assigns.access_token
                 },
                 params["project_path"],
                 pipeline_iid
               ) do
          {:ok, %{pipeline: pipeline}}
        end
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
