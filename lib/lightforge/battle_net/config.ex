defmodule Lightforge.BattleNet.Config do
  @moduledoc false

  @default_oauth_base_url "https://oauth.battle.net"
  @default_api_host_template "https://%{region}.api.blizzard.com"
  @default_region "us"
  @default_scope "wow.profile"
  @default_user_agent "lightforge"
  @region_locales %{
    "eu" => "en_GB",
    "kr" => "ko_KR",
    "tw" => "zh_TW",
    "us" => "en_US"
  }

  def ready? do
    client_id() != "" and client_secret() != "" and redirect_uri() != ""
  end

  def available_regions, do: Map.keys(@region_locales)

  def region_options do
    available_regions()
    |> Enum.map(&{String.upcase(&1), &1})
  end

  def default_region, do: normalize_region(config(:default_region, @default_region))

  def normalize_region(nil), do: @default_region

  def normalize_region(region) when is_binary(region) do
    normalized = region |> String.trim() |> String.downcase()

    if normalized in available_regions() do
      normalized
    else
      @default_region
    end
  end

  def locale(region) do
    Map.get(@region_locales, normalize_region(region), "en_US")
  end

  def namespace(:profile, region), do: "profile-#{normalize_region(region)}"
  def namespace(:static, region), do: "static-#{normalize_region(region)}"

  def oauth_base_url do
    config(:oauth_base_url, @default_oauth_base_url)
    |> String.trim_trailing("/")
  end

  def api_base_url(region) do
    config(:api_host_template, @default_api_host_template)
    |> String.replace("%{region}", normalize_region(region))
    |> String.trim_trailing("/")
  end

  def oauth_scope, do: config(:scope, @default_scope)
  def user_agent, do: config(:user_agent, @default_user_agent)
  def redirect_uri, do: config(:redirect_uri, "")
  def client_id, do: config(:client_id, "")
  def client_secret, do: config(:client_secret, "")
  def req_options, do: config(:req_options, [])

  def validate_credentials do
    if ready?() do
      :ok
    else
      {:error, "Battle.net credentials are not configured yet."}
    end
  end

  defp config(key, default) do
    :lightforge
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
