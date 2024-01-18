defmodule CiPipelineViz.Entities.Pipeline do
  @enforce_keys [:iid, :duration, :queued_duration, :jobs, :started_at]
  defstruct [:iid, :duration, :queued_duration, :jobs, :started_at]

  @type t :: %__MODULE__{
          iid: iid(),
          duration: float(),
          queued_duration: float(),
          jobs: [CiPipelineViz.Job.t()],
          started_at: DateTime.t()
        }

  @type iid :: integer()
end
