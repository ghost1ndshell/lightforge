defmodule LightforgeWeb.Api.V1.CharacterApiTest do
  use LightforgeWeb.ConnCase, async: false

  alias Lightforge.Characters
  alias Lightforge.Characters.Character
  alias LightforgeWeb.BattleNetSession

  setup {Req.Test, :set_req_test_from_context}
  setup {Req.Test, :verify_on_exit!}

  setup do
    previous_config = Application.get_env(:lightforge, Lightforge.BattleNet.Config, [])

    Application.put_env(:lightforge, Lightforge.BattleNet.Config,
      client_id: "client-id",
      client_secret: "client-secret",
      default_region: "us",
      redirect_uri: "http://www.example.com/auth/bnet/callback",
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    on_exit(fn ->
      Application.put_env(:lightforge, Lightforge.BattleNet.Config, previous_config)
    end)

    :ok
  end

  test "sync persists a character snapshot and serves it from the API", %{conn: conn} do
    Req.Test.expect(__MODULE__, 7, &battle_net_response/1)

    token_data = %{access_token: "battle-token", expires_at: System.system_time(:second) + 3600}

    conn =
      conn
      |> init_test_session(%{})
      |> BattleNetSession.put_token(token_data)

    sync_conn = post(conn, "/api/v1/characters/us/stormrage/illidan/sync")

    assert %{
             "data" => %{
               "status" => "synced",
               "character" => %{
                 "name" => "Illidan",
                 "realm_slug" => "stormrage",
                 "region" => "us"
               },
               "snapshot_id" => snapshot_id
             }
           } = json_response(sync_conn, 200)

    assert is_integer(snapshot_id)
    assert [%Character{name: "Illidan"}] = Characters.list_characters()

    show_conn = get(conn, "/api/v1/characters/us/stormrage/illidan")

    assert %{
             "data" => %{
               "character" => %{
                 "name" => "Illidan",
                 "class_name" => "Demon Hunter",
                 "spec_name" => "Havoc"
               },
               "latest_snapshot" => %{
                 "id" => ^snapshot_id,
                 "equipped_item_level" => 658,
                 "gear_item_count" => 1
               }
             }
           } = json_response(show_conn, 200)

    gear_conn = get(conn, "/api/v1/characters/us/stormrage/illidan/gear")

    assert %{
             "data" => %{
               "snapshot_id" => ^snapshot_id,
               "items" => [
                 %{
                   "item_name" => "Thunderfury",
                   "slot_key" => "MAIN_HAND",
                   "icon_url" => "https://cdn.lightforge.test/items/thunderfury.png"
                 }
               ]
             }
           } = json_response(gear_conn, 200)

    snapshot_conn = get(conn, "/api/v1/characters/us/stormrage/illidan/snapshots/latest")

    assert %{
             "data" => %{
               "id" => ^snapshot_id,
               "equipped_item_level" => 658,
               "profile_json" => %{"name" => "Illidan"},
               "media_json" => %{"assets" => _}
             }
           } = json_response(snapshot_conn, 200)
  end

  test "sync returns unauthorized without a Battle.net session", %{conn: conn} do
    response =
      conn
      |> init_test_session(%{})
      |> post("/api/v1/characters/us/stormrage/illidan/sync")

    assert %{"error" => %{"code" => "unauthorized"}} = json_response(response, 401)
  end

  test "read endpoints return not found for unknown characters", %{conn: conn} do
    assert Characters.list_characters() == []

    response = get(conn, "/api/v1/characters/us/stormrage/illidan")
    assert %{"error" => %{"code" => "not_found"}} = json_response(response, 404)

    response = get(conn, "/api/v1/characters/us/stormrage/illidan/gear")
    assert %{"error" => %{"code" => "not_found"}} = json_response(response, 404)

    response = get(conn, "/api/v1/characters/us/stormrage/illidan/snapshots/latest")
    assert %{"error" => %{"code" => "not_found"}} = json_response(response, 404)
  end

  defp battle_net_response(conn) do
    case URI.decode(conn.request_path) do
      "/profile/wow/character/stormrage/illidan" ->
        Req.Test.json(conn, %{
          "active_spec" => %{"name" => "Havoc"},
          "character_class" => %{"name" => "Demon Hunter"},
          "equipped_item_level" => 658,
          "faction" => %{"name" => "Horde"},
          "level" => 80,
          "name" => "Illidan",
          "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
        })

      "/profile/wow/character/stormrage/illidan/equipment" ->
        Req.Test.json(conn, %{
          "equipped_items" => [
            %{
              "inventory_type" => %{"name" => "Sword"},
              "item" => %{"id" => 19019},
              "level" => %{"value" => 658},
              "name" => "Thunderfury",
              "quality" => %{"type" => "LEGENDARY"},
              "slot" => %{"name" => "Main Hand", "type" => "MAIN_HAND"}
            }
          ]
        })

      "/profile/wow/character/stormrage/illidan/character-media" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{
              "key" => "avatar",
              "value" => "https://cdn.lightforge.test/characters/illidan-avatar.png"
            },
            %{
              "key" => "main-raw",
              "value" => "https://cdn.lightforge.test/characters/illidan-render.png"
            }
          ]
        })

      "/profile/wow/character/stormrage/illidan/statistics" ->
        Req.Test.json(conn, %{
          "health" => %{"effective" => 7_235_000},
          "agility" => %{"effective" => 18_402},
          "melee_crit" => %{"value" => 24.81}
        })

      "/profile/wow/character/stormrage/illidan/achievements" ->
        Req.Test.json(conn, %{
          "recent_events" => [%{"achievement" => %{"id" => 1}}],
          "total_points" => 14_220
        })

      "/profile/wow/character/stormrage/illidan/mythic-keystone-profile" ->
        Req.Test.json(conn, %{
          "current_mythic_rating" => %{"rating" => 2_456.7},
          "current_period" => %{"best_runs" => []}
        })

      "/data/wow/media/item/19019" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{
              "key" => "icon",
              "value" => "https://cdn.lightforge.test/items/thunderfury.png"
            }
          ]
        })

      other ->
        flunk("Unexpected Battle.net request: #{other}")
    end
  end
end
