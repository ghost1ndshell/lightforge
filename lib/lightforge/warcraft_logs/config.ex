defmodule Lightforge.WarcraftLogs.Config do
  @moduledoc false

  @default_api_url "https://www.warcraftlogs.com/api/v2/client"
  @default_oauth_base_url "https://www.warcraftlogs.com/oauth"
  @default_user_agent "lightforge"

  def ready? do
    client_id() != "" and client_secret() != ""
  end

  def api_url, do: config(:api_url, @default_api_url)
  def oauth_base_url, do: config(:oauth_base_url, @default_oauth_base_url)
  def client_id, do: config(:client_id, "")
  def client_secret, do: config(:client_secret, "")
  def user_agent, do: config(:user_agent, @default_user_agent)
  def req_options, do: config(:req_options, [])

  def validate_credentials do
    if ready?() do
      :ok
    else
      {:error, "Warcraft Logs credentials are not configured yet."}
    end
  end

  defp config(key, default) do
    :lightforge
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
