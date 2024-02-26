defmodule CiPipelineViz.Entities.Job do
  @enforce_keys [:id, :duration, :queued_duration, :name, :started_at, :finished_at, :stage]
  defstruct [:id, :duration, :queued_duration, :name, :started_at, :finished_at, :stage]

  @type t :: %__MODULE__{
          id: CiPipelineViz.Entities.Job.Id.t(),
          duration: integer(),
          queued_duration: float(),
          name: String.t(),
          started_at: DateTime.t(),
          finished_at: DateTime.t(),
          stage: CiPipelineViz.Entities.Stage.t()
        }
end
