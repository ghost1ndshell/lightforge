defmodule LightforgeWeb.Api.V1.GearingControllerTest do
  use LightforgeWeb.ConnCase, async: true

  alias Lightforge.Characters

  test "shows a curated dungeon path for holy paladin", %{conn: conn} do
    {:ok, character} =
      Characters.create_character(%{
        class_name: "Paladin",
        level: 80,
        name: "Aurellia",
        realm: "Stormrage",
        realm_slug: "stormrage",
        region: "us",
        spec_name: "Holy"
      })

    {:ok, _snapshot} =
      Characters.create_snapshot(
        character,
        %{
          achievements_json: %{},
          captured_at: DateTime.from_naive!(~N[2026-04-07 13:30:00], "Etc/UTC"),
          equipped_item_level: 268,
          media_json: %{},
          mythic_json: %{
            "current_mythic_rating" => %{"rating" => 1875.2},
            "current_period" => %{
              "best_runs" => [
                %{"keystone_level" => 8, "dungeon" => %{"name" => "Ara-Kara, City of Echoes"}},
                %{"keystone_level" => 7, "dungeon" => %{"name" => "The Dawnbreaker"}},
                %{"keystone_level" => 6, "dungeon" => %{"name" => "Eco-Dome Al'dani"}},
                %{"keystone_level" => 5, "dungeon" => %{"name" => "Halls of Atonement"}}
              ]
            }
          },
          profile_json: %{},
          statistics_json: %{
            "mastery" => %{"value" => 22.8},
            "spell_crit" => %{"value" => 19.4},
            "spell_haste" => %{"value" => 18.12},
            "versatility_damage_done_bonus" => 9.1
          }
        },
        [
          %{
            icon_url: "https://cdn.lightforge.test/items/weapon.png",
            inventory_type: "Mace",
            item_level: 268,
            item_name: "Pilgrim's Gavel",
            quality: "Epic",
            raw_json: %{},
            slot_key: "MAIN_HAND",
            slot_name: "Main Hand"
          },
          %{
            icon_url: "https://cdn.lightforge.test/items/off-hand.png",
            inventory_type: "Off-Hand",
            item_level: 264,
            item_name: "Lantern of Open Hands",
            quality: "Epic",
            raw_json: %{},
            slot_key: "OFF_HAND",
            slot_name: "Off-Hand"
          },
          %{
            icon_url: "https://cdn.lightforge.test/items/trinket-one.png",
            inventory_type: "Trinket",
            item_level: 266,
            item_name: "Merciful Ember Idol",
            quality: "Epic",
            raw_json: %{},
            slot_key: "TRINKET_1",
            slot_name: "Trinket"
          },
          %{
            icon_url: "https://cdn.lightforge.test/items/trinket-two.png",
            inventory_type: "Trinket",
            item_level: 263,
            item_name: "Storm-Singed Totem",
            quality: "Epic",
            raw_json: %{},
            slot_key: "TRINKET_2",
            slot_name: "Trinket"
          }
        ]
      )

    response = get(conn, "/api/v1/characters/us/stormrage/aurellia/gearing?mode=dungeons")

    assert %{
             "data" => %{
               "mode" => "dungeons",
               "pending" => false,
               "summary" => %{"headline" => headline},
               "priority_slots" => priority_slots,
               "top_targets" => [
                 %{
                   "slot" => "Weapon",
                   "source_type" => "Dungeon",
                   "target_name" => "Arachnoid Soulcleaver"
                 }
                 | _
               ],
               "current_trinkets" => [_, _],
               "progression" => %{
                 "myth_vault_options" => 2,
                 "keystone_master" => %{"status" => "In progress"}
               },
               "stat_direction" => %{
                 "focus" => [%{"label" => "Haste"} | _],
                 "source_name" => "Method + WingsIsUp"
               },
               "weekly_route" => [%{"label" => "Run Ara-Kara, City of Echoes first"} | _]
             }
           } = json_response(response, 200)

    assert headline =~ "high-impact"
    assert Enum.any?(priority_slots, &(&1["slot"] == "Weapon"))
  end

  test "falls back gracefully for specs without curated targets", %{conn: conn} do
    {:ok, character} =
      Characters.create_character(%{
        class_name: "Demon Hunter",
        level: 80,
        name: "Illidan",
        realm: "Stormrage",
        realm_slug: "stormrage",
        region: "us",
        spec_name: "Havoc"
      })

    {:ok, _snapshot} =
      Characters.create_snapshot(
        character,
        %{
          achievements_json: %{},
          captured_at: DateTime.from_naive!(~N[2026-04-07 13:30:00], "Etc/UTC"),
          equipped_item_level: 268,
          media_json: %{},
          mythic_json: %{},
          profile_json: %{},
          statistics_json: %{
            "mastery" => %{"value" => 21.2},
            "melee_crit" => %{"value" => 24.81},
            "melee_haste" => %{"value" => 17.0},
            "versatility_damage_done_bonus" => 7.3
          }
        },
        [
          %{
            icon_url: "https://cdn.lightforge.test/items/glaive.png",
            inventory_type: "Warglaive",
            item_level: 268,
            item_name: "Felbound Edge",
            quality: "Epic",
            raw_json: %{},
            slot_key: "MAIN_HAND",
            slot_name: "Main Hand"
          }
        ]
      )

    response = get(conn, "/api/v1/characters/us/stormrage/illidan/gearing?mode=raid")

    assert %{
             "data" => %{
               "mode" => "raid",
               "pending" => true,
               "top_targets" => [],
               "stat_direction" => %{
                 "focus" => [
                   %{"label" => "Critical Strike"},
                   %{"label" => "Mastery"}
                 ]
               },
               "summary" => %{
                 "headline" => "Curated raid path is not ready for Havoc Demon Hunter yet."
               }
             }
           } = json_response(response, 200)
  end
end
