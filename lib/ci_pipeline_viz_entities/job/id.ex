defmodule CiPipelineViz.Entities.Job.Id do
  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{
          id: integer()
        }

  defimpl String.Chars do
    def to_string(%CiPipelineViz.Entities.Job.Id{} = id), do: Integer.to_string(id.id)
  end

  @spec from_gid(String.t()) :: t()
  def from_gid("gid://gitlab/Ci::Build/" <> gid), do: %__MODULE__{id: String.to_integer(gid)}
end
