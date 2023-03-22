defmodule CiPipelineVizConfig do
  require Config

  @spec load_env :: :ok
  def load_env do
    env_file_path = "env/.#{Atom.to_string(Config.config_env())}.env"

    if File.exists?(env_file_path) do
      DotenvParser.load_file(env_file_path)
    end

    :ok
  end

  @spec gitlab_client_secret() :: String.t()
  def gitlab_client_secret do
    System.fetch_env!("GITLAB_CLIENT_SECRET")
  end

  @spec gitlab_redirect_uri() :: String.t()
  def gitlab_redirect_uri do
    System.fetch_env!("GITLAB_REDIRECT_URI")
  end

  @spec gitlab_client_id() :: String.t()
  def gitlab_client_id do
    System.fetch_env!("GITLAB_CLIENT_ID")
  end

  # @spec get_boolean(String.t(), boolean()) :: boolean()
  # defp get_boolean(var_name, default) do
  #   case System.get_env(var_name) do
  #     "true" -> true
  #     "false" -> false
  #     _ -> default
  #   end
  # end

  # @spec get_integer(String.t(), integer()) :: integer()
  # defp get_integer(var_name, default) do
  #   with {:ok, value} <- System.fetch_env(var_name),
  #        int <- String.to_integer(value) do
  #     int
  #   else
  #     _ -> default
  #   end
  # end
end
