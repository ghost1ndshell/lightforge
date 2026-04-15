defmodule LightforgeWeb.Api.V1.CharacterApiTest do
  use LightforgeWeb.ConnCase, async: false

  alias Lightforge.Characters
  alias Lightforge.Characters.Character
  alias Lightforge.Analysis
  alias Lightforge.Logs
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
                 "equipped_item_level" => 268,
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
               "equipped_item_level" => 268,
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

    response = get(conn, "/api/v1/characters/us/stormrage/illidan/detail")
    assert %{"error" => %{"code" => "not_found"}} = json_response(response, 404)
  end

  test "detail endpoint returns composed snapshot, gear, gearing, and analysis", %{conn: conn} do
    {:ok, character} =
      Characters.create_character(%{
        region: "us",
        realm: "Stormrage",
        realm_slug: "stormrage",
        name: "Illidan",
        class_name: "Demon Hunter",
        spec_name: "Havoc",
        level: 80
      })

    {:ok, snapshot} =
      Characters.create_snapshot(
        character,
        %{
          captured_at: DateTime.utc_now(),
          equipped_item_level: 268,
          profile_json: %{"name" => "Illidan"},
          statistics_json: %{"melee_crit" => %{"value" => 24.81}},
          achievements_json: %{"total_points" => 14_220},
          mythic_json: %{"current_mythic_rating" => %{"rating" => 2_456.7}},
          media_json: %{
            "assets" => [
              %{"key" => "main-raw", "value" => "https://cdn.lightforge.test/illidan.png"}
            ]
          }
        },
        [
          %{
            blizzard_item_id: 19019,
            icon_url: "https://cdn.lightforge.test/items/thunderfury.png",
            inventory_type: "Sword",
            item_level: 268,
            item_name: "Thunderfury",
            quality: "LEGENDARY",
            slot_key: "MAIN_HAND",
            slot_name: "Main Hand"
          },
          %{
            blizzard_item_id: 193_757,
            icon_url: "https://cdn.lightforge.test/items/beacon.png",
            inventory_type: "Trinket",
            item_level: 262,
            item_name: "Beacon to the Beyond",
            quality: "EPIC",
            slot_key: "TRINKET_1",
            slot_name: "Trinket 1"
          }
        ]
      )

    report = Logs.upsert_report(%{code: "abc123", raw_json: %{}})

    fight =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 7,
        encounter_id: 9002,
        encounter_name: "Vorasius",
        raw_json: %{},
        kill: true
      })

    participant =
      Logs.upsert_participant(%{
        fight_id: fight.id,
        actor_id: 44,
        name: "Illidan",
        server_name: "Stormrage",
        class_name: "Demon Hunter",
        spec_name: "Havoc",
        role: "damager",
        item_level: 268,
        raw_json: %{}
      })

    assert {:ok, _run} =
             Analysis.import_run(fight.id, %{
               provider: "wowanalyzer",
               participant_id: participant.id,
               score: 77.0,
               summary_json: %{headline: "Keep momentum on cooldown windows"},
               raw_json: %{source: "fixture"},
               insights: [
                 %{
                   severity: "high",
                   category: "cooldowns",
                   title: "Major cooldown drift",
                   summary: "You delayed major cooldowns several times.",
                   recommendation: "Line cooldowns up with the encounter plan.",
                   impact_score: 9.4,
                   highlighted: true,
                   metadata_json: %{casts_missed: 2}
                 }
               ]
             })

    response = get(conn, "/api/v1/characters/us/stormrage/illidan/detail")

    assert %{
             "data" => %{
               "character" => %{
                 "name" => "Illidan",
                 "class_name" => "Demon Hunter"
               },
               "snapshot" => %{
                 "id" => snapshot_id,
                 "equipped_item_level" => 268
               },
               "items" => [
                 %{"item_name" => "Thunderfury"},
                 %{"item_name" => "Beacon to the Beyond"}
               ],
               "analysis" => %{
                 "provider" => "wowanalyzer",
                 "score" => 77.0,
                 "fight" => %{
                   "encounter_name" => "Vorasius",
                   "report_code" => "abc123"
                 },
                 "insights" => [
                   %{
                     "title" => "Major cooldown drift",
                     "highlighted" => true
                   }
                 ]
               },
               "gearing" => %{
                 "mode" => "dungeons",
                 "summary" => %{"headline" => headline}
               }
             }
           } = json_response(response, 200)

    assert snapshot_id == snapshot.id
    assert headline =~ "Curated dungeon path is not ready"
  end

  defp battle_net_response(conn) do
    case URI.decode(conn.request_path) do
      "/profile/wow/character/stormrage/illidan" ->
        Req.Test.json(conn, %{
          "active_spec" => %{"name" => "Havoc"},
          "character_class" => %{"name" => "Demon Hunter"},
          "equipped_item_level" => 268,
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
              "level" => %{"value" => 268},
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
