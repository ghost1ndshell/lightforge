defmodule Lightforge.Characters.Sync do
  @moduledoc false

  alias Lightforge.Characters
  alias Lightforge.Wow.CharacterSnapshot, as: WowCharacterSnapshot

  def call(token_data, attrs) do
    with {:ok, payload} <- WowCharacterSnapshot.fetch_payload(token_data, attrs),
         {:ok, character} <- Characters.upsert_character(character_attrs(payload)),
         {:ok, snapshot} <-
           Characters.create_snapshot(
             character,
             snapshot_attrs(payload),
             gear_snapshot_item_attrs(payload)
           ) do
      {:ok, %{character: character, snapshot: snapshot}}
    end
  end

  defp character_attrs(%{character_input: input, responses: %{profile: profile}}) do
    %{
      blizzard_character_id: profile["id"],
      class_name: nested_name(profile, ["character_class"]),
      faction_name: nested_name(profile, ["faction"]),
      level: profile["level"],
      name: profile["name"] || input.name,
      region: input.region,
      realm: nested_name(profile, ["realm"]) || input.realm,
      realm_slug: get_in(profile, ["realm", "slug"]) || input.realm_slug,
      spec_name: nested_name(profile, ["active_spec"])
    }
  end

  defp snapshot_attrs(%{responses: responses}) do
    profile = responses.profile

    %{
      achievements_json: normalize_body(responses[:achievements]),
      captured_at: DateTime.utc_now(),
      equipped_item_level: profile["equipped_item_level"],
      media_json: normalize_body(responses[:media]),
      mythic_json: normalize_body(responses[:mythic]),
      profile_json: normalize_body(profile),
      statistics_json: normalize_body(responses[:statistics])
    }
  end

  defp gear_snapshot_item_attrs(%{
         item_media_by_id: item_media_by_id,
         responses: %{equipment: equipment}
       }) do
    equipment
    |> Map.get("equipped_items", [])
    |> Enum.map(fn item ->
      item_id = item_id(item)

      %{
        blizzard_item_id: item_id,
        icon_url: media_asset_url(Map.get(item_media_by_id, item_id, %{}), ["icon"]),
        inventory_type: nested_name(item, ["inventory_type"]),
        item_level: get_in(item, ["level", "value"]),
        item_name: item["name"] || nested_name(item, ["item"]) || "Unknown item",
        quality: quality_label(item),
        raw_json: item,
        slot_key: get_in(item, ["slot", "type"]) || "UNKNOWN",
        slot_name: nested_name(item, ["slot"]) || "Unknown slot"
      }
    end)
  end

  defp normalize_body(nil), do: %{}
  defp normalize_body(body) when is_map(body), do: body
  defp normalize_body(_body), do: %{}

  defp nested_name(body, path) do
    case get_in(body, path ++ ["name"]) do
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp item_id(item) do
    get_in(item, ["item", "id"]) || parse_id_from_href(get_in(item, ["item", "key", "href"]))
  end

  defp parse_id_from_href(value) when is_integer(value), do: value

  defp parse_id_from_href(value) when is_binary(value) do
    case Regex.run(~r/\/item\/(\d+)/, value, capture: :all_but_first) do
      [id] ->
        case Integer.parse(id) do
          {parsed, _} -> parsed
          :error -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_id_from_href(_value), do: nil

  defp media_asset_url(body, keys) when is_map(body) do
    body
    |> Map.get("assets", [])
    |> then(fn assets ->
      Enum.find_value(keys, fn key ->
        assets
        |> Enum.find(&(Map.get(&1, "key") == key))
        |> case do
          %{"value" => value} when is_binary(value) -> value
          _ -> nil
        end
      end)
    end)
  end

  defp media_asset_url(_body, _keys), do: nil

  defp quality_label(item) do
    case get_in(item, ["quality", "type"]) do
      nil -> nil
      value -> value |> String.downcase() |> String.replace("_", " ") |> String.capitalize()
    end
  end
end
