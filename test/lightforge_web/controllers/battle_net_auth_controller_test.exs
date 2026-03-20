defmodule LightforgeWeb.BattleNetAuthControllerTest do
  use LightforgeWeb.ConnCase, async: false

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

    on_exit(fn ->
      Application.put_env(:lightforge, Lightforge.BattleNet.Config, previous_config)
    end)

    :ok
  end

  test "GET /auth/bnet redirects to Blizzard authorize URL", %{conn: conn} do
    conn = get(conn, ~p"/auth/bnet")
    redirect_url = redirected_to(conn, 302)

    assert redirect_url =~ "https://oauth.battle.net/authorize?"
    assert redirect_url =~ "client_id=client-id"
    assert get_session(conn, :battle_net_oauth_state)
  end

  test "GET /auth/bnet/callback exchanges code and stores token in memory", %{conn: conn} do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/token"

      Req.Test.json(conn, %{
        "access_token" => "battle-token",
        "expires_in" => 3600,
        "refresh_token" => "refresh-token",
        "scope" => "wow.profile",
        "token_type" => "bearer"
      })
    end)

    conn =
      conn
      |> init_test_session(battle_net_oauth_state: "state-123")
      |> get(~p"/auth/bnet/callback?state=state-123&code=grant-code")

    assert redirected_to(conn) == ~p"/character"

    token_id = get_session(conn, :battle_net_token_id)
    assert %{access_token: "battle-token"} = TokenStore.get(token_id)

    on_exit(fn -> TokenStore.delete(token_id) end)
  end
end
