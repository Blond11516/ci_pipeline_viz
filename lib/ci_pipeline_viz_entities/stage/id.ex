defmodule CiPipelineViz.Entities.Stage.Id do
  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{
          id: integer()
        }

  @spec from_gid(String.t()) :: t()
  def from_gid("gid://gitlab/Ci::Stage/" <> gid), do: %__MODULE__{id: String.to_integer(gid)}
end
