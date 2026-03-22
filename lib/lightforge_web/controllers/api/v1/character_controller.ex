defmodule LightforgeWeb.Api.V1.CharacterController do
  use LightforgeWeb, :controller

  alias Lightforge.Characters

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def index(conn, _params) do
    characters =
      Characters.list_characters()
      |> Enum.map(&serialize_character/1)

    json(conn, %{data: characters})
  end

  def show(conn, %{"region" => region, "realm" => realm, "name" => name}) do
    with character when not is_nil(character) <-
           Characters.get_character_by_identity(region, realm, name) do
      latest_snapshot = Characters.get_latest_snapshot(character)

      json(conn, %{
        data: %{
          character: serialize_character(character),
          latest_snapshot: serialize_snapshot_summary(latest_snapshot)
        }
      })
    else
      nil -> {:error, :not_found}
    end
  end

  def gear(conn, %{"region" => region, "realm" => realm, "name" => name}) do
    with character when not is_nil(character) <-
           Characters.get_character_by_identity(region, realm, name),
         snapshot when not is_nil(snapshot) <- Characters.get_latest_snapshot(character) do
      json(conn, %{
        data: %{
          character: serialize_character(character),
          items: Enum.map(snapshot.gear_snapshot_items, &serialize_gear_item/1),
          snapshot_id: snapshot.id
        }
      })
    else
      nil -> {:error, :not_found}
    end
  end

  defp serialize_character(character) do
    %{
      class_name: character.class_name,
      faction_name: character.faction_name,
      id: character.id,
      level: character.level,
      name: character.name,
      region: character.region,
      realm: character.realm,
      realm_slug: character.realm_slug,
      spec_name: character.spec_name
    }
  end

  defp serialize_snapshot_summary(nil), do: nil

  defp serialize_snapshot_summary(snapshot) do
    %{
      captured_at: snapshot.captured_at,
      equipped_item_level: snapshot.equipped_item_level,
      gear_item_count: length(snapshot.gear_snapshot_items),
      id: snapshot.id
    }
  end

  defp serialize_gear_item(item) do
    %{
      blizzard_item_id: item.blizzard_item_id,
      icon_url: item.icon_url,
      inventory_type: item.inventory_type,
      item_level: item.item_level,
      item_name: item.item_name,
      quality: item.quality,
      slot_key: item.slot_key,
      slot_name: item.slot_name
    }
  end
end
