defmodule LightforgeWeb.CharacterLiveTest do
  use LightforgeWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Lightforge.BattleNet.TokenStore

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

    token_id = "test-session-token"

    TokenStore.put(token_id, %{
      access_token: "battle-token",
      expires_at: System.system_time(:second) + 3600
    })

    on_exit(fn ->
      Application.put_env(:lightforge, Lightforge.BattleNet.Config, previous_config)
      TokenStore.delete(token_id)
    end)

    {:ok, token_id: token_id}
  end

  test "loads a character snapshot into the cockpit", %{conn: conn, token_id: token_id} do
    Req.Test.expect(__MODULE__, 9, &route_response/1)

    {:ok, view, _html} =
      conn
      |> init_test_session(battle_net_token_id: token_id)
      |> live(~p"/character")

    _ = :sys.get_state(view.pid)
    render_click(element(view, "button[phx-click=\"open_selector\"]"))

    form =
      form(view, "#character-form", %{
        character: %{
          "character_ref" => Base.url_encode64("us:stormrage:Nolíght", padding: false),
          "region" => "us"
        }
      })

    render_submit(form)
    _ = :sys.get_state(view.pid)

    html = render(view)

    assert html =~ "Nolíght"
    assert html =~ "Guild"
    assert html =~ "Ashen Vanguard"
    assert html =~ "Progression"
    assert html =~ "M+"
    assert html =~ "Windrunner Spire"
    assert html =~ "+10"
    assert html =~ "Raid"
    assert html =~ "Imperator Averzian"
    assert html =~ "Current vs target stats"
    assert html =~ "What to chase next"
    assert html =~ "What to do this week"
    assert html =~ "Finish Midnight campaign"
    assert html =~ "Midnight pre-season"
    assert html =~ "Tracked Achievements"
    assert html =~ "Ahead of the Curve"
    assert html =~ "Coming soon"
    assert html =~ "Midnight-targeted upgrade paths are coming soon."
    refute has_element?(view, "#character-form")
  end

  test "loads a holy paladin with pre-season Midnight gear targets", %{
    conn: conn,
    token_id: token_id
  } do
    Req.Test.expect(__MODULE__, 9, &holy_route_response/1)

    {:ok, view, _html} =
      conn
      |> init_test_session(battle_net_token_id: token_id)
      |> live(~p"/character")

    _ = :sys.get_state(view.pid)
    render_click(element(view, "button[phx-click=\"open_selector\"]"))

    form =
      form(view, "#character-form", %{
        character: %{
          "character_ref" => Base.url_encode64("us:stormrage:Uther", padding: false),
          "region" => "us"
        }
      })

    render_submit(form)
    _ = :sys.get_state(view.pid)

    html = render(view)

    assert html =~ "Current vs target stats"
    assert html =~ "Guild"
    assert html =~ "Silver Hand"
    assert html =~ "M+"
    assert html =~ "Magister&#39;s Terrace"
    assert html =~ "+10"
    assert html =~ "Method + WingsIsUp"
    assert html =~ "March 17, 2026"
    assert html =~ "What to chase next"
    assert html =~ "Secure your Holy Paladin bridge set"
    assert html =~ "Legendary Item Progression"
    assert html =~ "Tracked Achievements"
    refute has_element?(view, "#character-form")
  end

  defp route_response(conn) do
    case URI.decode(conn.request_path) do
      "/profile/user/wow" ->
        Req.Test.json(conn, %{
          "wow_accounts" => [
            %{
              "characters" => [
                %{
                  "id" => 1,
                  "level" => 80,
                  "name" => "Nolíght",
                  "faction" => %{"name" => "Horde"},
                  "playable_class" => %{"name" => "Demon Hunter"},
                  "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
                }
              ]
            }
          ]
        })

      "/profile/wow/character/stormrage/nolíght" ->
        Req.Test.json(conn, %{
          "active_spec" => %{"name" => "Havoc"},
          "character_class" => %{"name" => "Demon Hunter"},
          "equipped_item_level" => 658,
          "faction" => %{"name" => "Horde"},
          "gender" => %{"name" => "Male"},
          "guild" => %{"name" => "Ashen Vanguard"},
          "level" => 80,
          "name" => "Nolíght",
          "race" => %{"name" => "Blood Elf"},
          "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
        })

      "/profile/wow/character/stormrage/nolíght/equipment" ->
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

      "/profile/wow/character/stormrage/nolíght/character-media" ->
        Req.Test.json(conn, %{
          "assets" => [
            %{
              "key" => "avatar",
              "value" => "https://cdn.lightforge.test/characters/nolight-avatar.png"
            },
            %{
              "key" => "main-raw",
              "value" => "https://cdn.lightforge.test/characters/nolight-render.png"
            }
          ]
        })

      "/profile/wow/character/stormrage/nolíght/statistics" ->
        Req.Test.json(conn, %{
          "health" => %{"effective" => 7_235_000},
          "agility" => %{"effective" => 18_402},
          "stamina" => %{"effective" => 27_100},
          "melee_crit" => %{"value" => 24.81},
          "melee_haste" => %{"value" => 18.12},
          "mastery" => %{"value" => 42.77},
          "versatility_damage_done_bonus" => 8.55
        })

      "/profile/wow/character/stormrage/nolíght/achievements" ->
        Req.Test.json(conn, %{
          "total_points" => 14_220,
          "recent_events" => [%{"achievement" => %{"id" => 1}}]
        })

      "/profile/wow/character/stormrage/nolíght/mythic-keystone-profile" ->
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
      "/profile/user/wow" ->
        Req.Test.json(conn, %{
          "wow_accounts" => [
            %{
              "characters" => [
                %{
                  "id" => 1,
                  "level" => 80,
                  "name" => "Uther",
                  "faction" => %{"name" => "Alliance"},
                  "playable_class" => %{"name" => "Paladin"},
                  "realm" => %{"name" => "Stormrage", "slug" => "stormrage"}
                }
              ]
            }
          ]
        })

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
