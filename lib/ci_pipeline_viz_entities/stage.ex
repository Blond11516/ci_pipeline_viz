defmodule CiPipelineViz.Entities.Stage do
  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: CiPipelineViz.Entities.Stage.Id.t(),
          name: String.t()
        }
end
