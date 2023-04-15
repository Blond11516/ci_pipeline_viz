defmodule CiPipelineViz.Pipeline do
  @enforce_keys [:iid, :duration, :queued_duration, :jobs]
  defstruct [:iid, :duration, :queued_duration, :jobs]

  @type t :: %__MODULE__{
          iid: iid(),
          duration: float(),
          queued_duration: float(),
          jobs: [CiPipelineViz.Job.t()]
        }

  @type iid :: integer()
end
