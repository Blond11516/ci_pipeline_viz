defmodule CiPipelineViz.Job do
  @enforce_keys [:id, :duration, :queued_duration, :name, :stage]
  defstruct [:id, :duration, :queued_duration, :name, :stage]

  @type t :: %__MODULE__{
          id: CiPipelineViz.Job.Id.t(),
          duration: integer(),
          queued_duration: float(),
          name: String.t(),
          stage: CiPipelineViz.Stage.t()
        }
end
