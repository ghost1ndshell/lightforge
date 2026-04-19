defmodule LightforgeWeb.Api.V1.SnapshotController do
  use LightforgeWeb, :controller

  alias Lightforge.Characters

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def show(conn, %{"region" => region, "realm" => realm, "name" => name}) do
    with character when not is_nil(character) <-
           Characters.get_character_by_identity(region, realm, name),
         snapshot when not is_nil(snapshot) <- Characters.get_latest_snapshot(character) do
      json(conn, %{
        data: %{
          achievements_json: snapshot.achievements_json,
          captured_at: snapshot.captured_at,
          character_id: snapshot.character_id,
          equipped_item_level: snapshot.equipped_item_level,
          id: snapshot.id,
          media_json: snapshot.media_json,
          mythic_json: snapshot.mythic_json,
          profile_json: snapshot.profile_json,
          statistics_json: snapshot.statistics_json
        }
      })
    else
      nil -> {:error, :not_found}
    end
  end
end
