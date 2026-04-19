defmodule LightforgeWeb.Api.V1.CharacterSyncController do
  use LightforgeWeb, :controller

  alias Lightforge.Characters
  alias LightforgeWeb.BattleNetSession

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def create(conn, %{"region" => region, "realm" => realm, "name" => name}) do
    token_data =
      conn
      |> get_session()
      |> BattleNetSession.token_from_session()

    with {:ok, %{character: character, snapshot: snapshot}} <-
           Characters.sync_character_from_battle_net(token_data, %{
             region: region,
             realm: realm,
             name: name
           }) do
      json(conn, %{
        data: %{
          character: serialize_character(character),
          snapshot_id: snapshot.id,
          status: "synced"
        }
      })
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
end
