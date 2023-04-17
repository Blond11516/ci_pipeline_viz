defmodule CiPipelineViz.Stage do
  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: CiPipelineViz.Stage.Id.t(),
          name: String.t()
        }
end
