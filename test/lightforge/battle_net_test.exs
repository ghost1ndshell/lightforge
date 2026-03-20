defmodule Lightforge.BattleNetTest do
  use ExUnit.Case, async: false

  alias Lightforge.BattleNet
  alias Lightforge.Wow.AccountCharacter
  alias Lightforge.Wow.Character

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

  test "fetch_character_snapshot/2 normalizes profile, gear, and media" do
    Req.Test.expect(__MODULE__, 8, &route_response/1)

    token_data = %{access_token: "battle-token", expires_at: System.system_time(:second) + 3600}

    assert {:ok, %Character{} = snapshot} =
             BattleNet.fetch_character_snapshot(token_data, %{
               "region" => "us",
               "realm" => "Stormrage",
               "name" => "Illidan"
             })

    assert snapshot.name == "Illidan"
    assert snapshot.realm == "Stormrage"
    assert snapshot.character_class == "Demon Hunter"
    assert snapshot.active_spec == "Havoc"
    assert snapshot.guild == "Ashen Vanguard"
    assert snapshot.render_url == "https://cdn.lightforge.test/characters/illidan-render.png"
    assert snapshot.avatar_url == "https://cdn.lightforge.test/characters/illidan-avatar.png"
    assert snapshot.mythic_summary.best_key == 10
    assert snapshot.achievement_summary.points == 14_220
    assert snapshot.content_plan.rows |> Enum.any?(&(&1.label == "Phase"))
    assert snapshot.content_plan.actions |> Enum.any?(&(&1.title == "Finish Midnight campaign"))
    assert snapshot.content_plan.milestones |> Enum.any?(&(&1.title == "Season phase"))
    assert snapshot.tracked_achievements |> Enum.any?(&(&1.title == "Ahead of the Curve"))
    assert Enum.any?(snapshot.stat_lines, &(&1.label == "Crit"))
    assert is_nil(snapshot.stat_goal_plan)
    assert snapshot.gear_plan.guide_name == "Coming soon"
    assert snapshot.gear_plan.pending? == true
    assert snapshot.gear_plan.targets == []
    assert snapshot.progression_plan.tracks |> Enum.any?(&(&1.label == "M+"))
    assert snapshot.progression_plan.tracks |> Enum.any?(&(&1.label == "Raid"))

    mythic_track = Enum.find(snapshot.progression_plan.tracks, &(&1.label == "M+"))
    assert Enum.any?(mythic_track.badges, &(&1.label == "Windrunner Spire" and &1.value == "+10"))

    assert snapshot.stat_priority.priorities |> Enum.map(& &1.label) == [
             "Critical Strike",
             "Mastery",
             "Haste"
           ]

    assert Enum.any?(snapshot.items, &(&1.name == "Thunderfury"))

    assert Enum.any?(
             snapshot.items,
             &(&1.icon_url == "https://cdn.lightforge.test/items/thunderfury.png")
           )
  end

  test "fetch_account_characters/2 returns linked characters from the account profile" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/profile/user/wow"

      Req.Test.json(conn, %{
        "wow_accounts" => [
          %{
            "characters" => [
              %{
                "id" => 1,
                "level" => 80,
                "name" => "Nolíght",
                "faction" => %{"name" => "Alliance"},
                "playable_class" => %{"name" => "Priest"},
                "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
              }
            ]
          }
        ]
      })
    end)

    token_data = %{access_token: "battle-token", expires_at: System.system_time(:second) + 3600}

    assert {:ok, [%AccountCharacter{} = character]} =
             BattleNet.fetch_account_characters(token_data, "us")

    assert character.name == "Nolíght"
    assert character.realm_slug == "stormrage"
    assert character.label =~ "Nolíght"
    assert character.label =~ "Priest"
  end

  test "fetch_character_snapshot/2 builds a pre-season Holy Paladin gear plan" do
    Req.Test.expect(__MODULE__, 8, &holy_route_response/1)

    token_data = %{access_token: "battle-token", expires_at: System.system_time(:second) + 3600}

    assert {:ok, %Character{} = snapshot} =
             BattleNet.fetch_character_snapshot(token_data, %{
               "region" => "us",
               "realm" => "Stormrage",
               "name" => "Uther"
             })

    assert snapshot.active_spec == "Holy"
    assert snapshot.gear_plan.guide_name == "Method"
    assert snapshot.gear_plan.pending? == false
    assert snapshot.gear_plan.note =~ "March 17, 2026"
    assert snapshot.guild == "Silver Hand"
    assert snapshot.progression_plan.tracks |> Enum.any?(&(&1.label == "M+"))
    assert snapshot.progression_plan.tracks |> Enum.any?(&(&1.label == "Raid"))

    assert snapshot.content_plan.actions
           |> Enum.any?(&(&1.title == "Secure your Holy Paladin bridge set"))

    assert snapshot.stat_goal_plan.source_name == "Method + WingsIsUp"
    assert Enum.any?(snapshot.stat_goal_plan.goals, &(&1.label == "Haste"))
    assert snapshot.tracked_achievements |> Enum.any?(&(&1.title == "Legendary Item Progression"))

    assert Enum.any?(snapshot.gear_plan.targets, &(&1.target_name == "Reshii Wraps"))

    assert Enum.any?(
             snapshot.gear_plan.targets,
             &(&1.target_name == "Empowering Crystal of Anub'ikkaj")
           )
  end

  defp route_response(conn) do
    case URI.decode(conn.request_path) do
      "/profile/wow/character/stormrage/illidan" ->
        Req.Test.json(conn, %{
          "active_spec" => %{"name" => "Havoc"},
          "character_class" => %{"name" => "Demon Hunter"},
          "equipped_item_level" => 658,
          "faction" => %{"name" => "Horde"},
          "gender" => %{"name" => "Male"},
          "guild" => %{"name" => "Ashen Vanguard"},
          "level" => 80,
          "name" => "Illidan",
          "race" => %{"name" => "Blood Elf"},
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
            },
            %{
              "inventory_type" => %{"name" => "Trinket"},
              "item" => %{"id" => 193_757},
              "level" => %{"value" => 652},
              "name" => "Beacon to the Beyond",
              "quality" => %{"type" => "EPIC"},
              "slot" => %{"name" => "Trinket 1", "type" => "TRINKET_1"}
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
          "stamina" => %{"effective" => 27_100},
          "melee_crit" => %{"value" => 24.81},
          "melee_haste" => %{"value" => 18.12},
          "mastery" => %{"value" => 42.77},
          "versatility_damage_done_bonus" => 8.55
        })

      "/profile/wow/character/stormrage/illidan/achievements" ->
        Req.Test.json(conn, %{
          "total_points" => 14_220,
          "recent_events" => [%{"achievement" => %{"id" => 1}}, %{"achievement" => %{"id" => 2}}]
        })

      "/profile/wow/character/stormrage/illidan/mythic-keystone-profile" ->
        Req.Test.json(conn, %{
          "current_mythic_rating" => %{"rating" => 2_456.7},
          "current_period" => %{
            "best_runs" => [
              %{"keystone_level" => 10, "dungeon" => %{"name" => "Windrunner Spire"}},
              %{"keystone_level" => 8, "dungeon" => %{"name" => "Voidscar Arena"}}
            ]
          }
        })

      "/data/wow/media/item/19019" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{"key" => "icon", "value" => "https://cdn.lightforge.test/items/thunderfury.png"}
          ]
        })

      "/data/wow/media/item/193757" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{"key" => "icon", "value" => "https://cdn.lightforge.test/items/beacon.png"}
          ]
        })

      other ->
        Plug.Conn.send_resp(conn, 404, "unexpected path: #{other}")
    end
  end

  defp holy_route_response(conn) do
    case URI.decode(conn.request_path) do
      "/profile/wow/character/stormrage/uther" ->
        Req.Test.json(conn, %{
          "active_spec" => %{"name" => "Holy"},
          "character_class" => %{"name" => "Paladin"},
          "equipped_item_level" => 658,
          "faction" => %{"name" => "Alliance"},
          "gender" => %{"name" => "Male"},
          "guild" => %{"name" => "Silver Hand"},
          "level" => 80,
          "name" => "Uther",
          "race" => %{"name" => "Human"},
          "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
        })

      "/profile/wow/character/stormrage/uther/equipment" ->
        Req.Test.json(conn, %{
          "equipped_items" => [
            %{
              "inventory_type" => %{"name" => "Hammer"},
              "item" => %{"id" => 101},
              "level" => %{"value" => 658},
              "name" => "Arathi Abbot's Gavel",
              "quality" => %{"type" => "EPIC"},
              "slot" => %{"name" => "Main Hand", "type" => "MAIN_HAND"}
            },
            %{
              "inventory_type" => %{"name" => "Shield"},
              "item" => %{"id" => 102},
              "level" => %{"value" => 655},
              "name" => "Everforged Defender",
              "quality" => %{"type" => "EPIC"},
              "slot" => %{"name" => "Off Hand", "type" => "OFF_HAND"}
            }
          ]
        })

      "/profile/wow/character/stormrage/uther/character-media" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{
              "key" => "avatar",
              "value" => "https://cdn.lightforge.test/characters/uther-avatar.png"
            }
          ]
        })

      "/profile/wow/character/stormrage/uther/statistics" ->
        Req.Test.json(conn, %{
          "health" => %{"effective" => 7_235_000},
          "intellect" => %{"effective" => 18_402},
          "spell_crit" => %{"value" => 24.81},
          "spell_haste" => %{"value" => 18.12},
          "mastery" => %{"value" => 42.77},
          "versatility_damage_done_bonus" => 8.55
        })

      "/profile/wow/character/stormrage/uther/achievements" ->
        Req.Test.json(conn, %{
          "total_points" => 14_220,
          "recent_events" => [%{"achievement" => %{"id" => 1}}]
        })

      "/profile/wow/character/stormrage/uther/mythic-keystone-profile" ->
        Req.Test.json(conn, %{
          "current_mythic_rating" => %{"rating" => 2_456.7},
          "current_period" => %{
            "best_runs" => [
              %{"keystone_level" => 10, "dungeon" => %{"name" => "Magister's Terrace"}}
            ]
          }
        })

      "/data/wow/media/item/101" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{"key" => "icon", "value" => "https://cdn.lightforge.test/items/gavel.png"}
          ]
        })

      "/data/wow/media/item/102" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{"key" => "icon", "value" => "https://cdn.lightforge.test/items/defender.png"}
          ]
        })

      other ->
        Plug.Conn.send_resp(conn, 404, "unexpected path: #{other}")
    end
  end
end
