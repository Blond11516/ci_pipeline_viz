defmodule CiPipelineViz.Project do
  @enforce_keys [:id, :full_path, :name]
  defstruct [:id, :full_path, :name]

  @type t :: %__MODULE__{
          id: integer(),
          full_path: String.t(),
          name: String.t()
        }
end
