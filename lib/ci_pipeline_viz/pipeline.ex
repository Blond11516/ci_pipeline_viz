defmodule CiPipelineViz.Pipeline do
  @enforce_keys [:iid, :duration, :queued_duration]
  defstruct [:iid, :duration, :queued_duration]

  @type t :: %__MODULE__{
          iid: iid(),
          duration: float(),
          queued_duration: float()
        }

  @type iid :: integer()
end
