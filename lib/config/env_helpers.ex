defmodule CiPipelineVizConfig.EnvHelpers do
  require Config

  @spec load_env :: :ok
  def load_env do
    env_file_path = "env/.#{Atom.to_string(Config.config_env())}.env"

    if File.exists?(env_file_path) do
      DotenvParser.load_file(env_file_path)
    end

    :ok
  end

  @spec fetch_string!(String.t()) :: String.t()
  def fetch_string!(var_name), do: System.fetch_env!(var_name)
end
