defmodule Lightforge.BattleNet.Client do
  @moduledoc false

  alias Lightforge.BattleNet.Config

  def get_account_profile_summary(token_data, region) do
    request_json(
      token_data,
      region,
      "/profile/user/wow",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_profile_summary(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name),
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_equipment_summary(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name) <> "/equipment",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_character_media_summary(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name) <> "/character-media",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_character_statistics_summary(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name) <> "/statistics",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_character_achievements_summary(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name) <> "/achievements",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_character_mythic_keystone_profile(token_data, region, realm_slug, character_name) do
    request_json(
      token_data,
      region,
      character_path(realm_slug, character_name) <> "/mythic-keystone-profile",
      namespace: Config.namespace(:profile, region)
    )
  end

  def get_item_media_summary(token_data, region, item_id) do
    request_json(
      token_data,
      region,
      "/data/wow/media/item/#{item_id}",
      namespace: Config.namespace(:static, region)
    )
  end

  defp request_json(token_data, region, path, opts) do
    params =
      [namespace: Keyword.fetch!(opts, :namespace), locale: Config.locale(region)]
      |> Keyword.merge(Keyword.get(opts, :params, []))

    Config.req_options()
    |> Req.new()
    |> Req.get(
      url: Config.api_base_url(region) <> path,
      headers: [
        {"authorization", "Bearer #{token_data.access_token}"},
        {"user-agent", Config.user_agent()}
      ],
      params: params
    )
    |> normalize_response()
  end

  defp normalize_response({:ok, %{status: 200, body: body}}) when is_map(body), do: {:ok, body}

  defp normalize_response({:ok, %{status: 200, body: body}}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _ -> {:error, "Battle.net returned an unreadable response body."}
    end
  end

  defp normalize_response({:ok, %{status: 401}}), do: {:error, :unauthorized}
  defp normalize_response({:ok, %{status: 404}}), do: {:error, :not_found}

  defp normalize_response({:ok, %{status: status, body: body}}) do
    detail =
      case body do
        %{"detail" => value} when is_binary(value) -> value
        _ -> "Battle.net API returned HTTP #{status}."
      end

    {:error, detail}
  end

  defp normalize_response({:error, reason}) do
    {:error, "Battle.net request failed: #{inspect(reason)}"}
  end

  defp character_path(realm_slug, character_name) do
    encoded_realm = encode_segment(realm_slug)
    encoded_name = encode_segment(character_name)

    "/profile/wow/character/#{encoded_realm}/#{encoded_name}"
  end

  defp encode_segment(value) do
    value
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end
end
