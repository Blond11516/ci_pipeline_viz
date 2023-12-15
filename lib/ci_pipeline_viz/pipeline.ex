defmodule CiPipelineViz.Pipeline do
  @enforce_keys [:iid, :duration, :queued_duration, :jobs, :started_at, :name]
  defstruct [:iid, :duration, :queued_duration, :jobs, :started_at, :name]

  @type t :: %__MODULE__{
          iid: iid(),
          duration: float(),
          queued_duration: float(),
          jobs: [CiPipelineViz.Job.t()],
          started_at: DateTime.t(),
          name: String.t()
        }

  @type iid :: integer()
end
