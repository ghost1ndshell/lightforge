defmodule LightforgeWeb.Api.V1.BattleNetConnectionControllerTest do
  use LightforgeWeb.ConnCase, async: false

  alias Lightforge.BattleNet.TokenStore
  alias LightforgeWeb.BattleNetSession

  setup {Req.Test, :set_req_test_from_context}
  setup {Req.Test, :verify_on_exit!}

  setup do
    previous_config = Application.get_env(:lightforge, Lightforge.BattleNet.Config, [])

    Application.put_env(:lightforge, Lightforge.BattleNet.Config,
      client_id: "client-id",
      client_secret: "client-secret",
      default_region: "us",
      redirect_uri: "http://www.example.com/api/v1/bnet/connect/callback",
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    on_exit(fn ->
      Application.put_env(:lightforge, Lightforge.BattleNet.Config, previous_config)
    end)

    :ok
  end

  test "GET /api/v1/me/bnet/status reports disconnected state", %{conn: conn} do
    conn = get(conn, "/api/v1/me/bnet/status")

    assert %{
             "data" => %{
               "battle_net_ready" => true,
               "connected" => false,
               "provider" => "battle_net"
             }
           } = json_response(conn, 200)
  end

  test "GET /api/v1/me/bnet/status reports connected state when the session has a token", %{conn: conn} do
    token_data = %{access_token: "battle-token", expires_at: System.system_time(:second) + 3600}

    conn =
      conn
      |> init_test_session(%{})
      |> BattleNetSession.put_token(token_data)
      |> get("/api/v1/me/bnet/status")

    assert %{
             "data" => %{
               "battle_net_ready" => true,
               "connected" => true,
               "provider" => "battle_net"
             }
           } = json_response(conn, 200)
  end

  test "POST /api/v1/bnet/connect/start returns a Battle.net authorize URL and stores state",
       %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> post("/api/v1/bnet/connect/start")

    assert %{
             "data" => %{
               "authorize_url" => authorize_url,
               "provider" => "battle_net"
             }
           } = json_response(conn, 200)

    assert authorize_url =~ "https://oauth.battle.net/authorize?"
    assert authorize_url =~ "client_id=client-id"
    assert get_session(conn, :battle_net_oauth_state)
  end

  test "POST /api/v1/bnet/connect/start returns an error when credentials are missing", %{conn: conn} do
    Application.put_env(:lightforge, Lightforge.BattleNet.Config,
      client_id: "",
      client_secret: "",
      default_region: "us",
      redirect_uri: "",
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    conn =
      conn
      |> init_test_session(%{})
      |> post("/api/v1/bnet/connect/start")

    assert %{
             "error" => %{
               "code" => "request_failed",
               "message" => "Battle.net credentials are not configured yet."
             }
           } = json_response(conn, 422)
  end

  test "GET /api/v1/bnet/connect/callback exchanges code, stores token, and redirects to the frontend callback",
       %{conn: conn} do
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
      |> get("/api/v1/bnet/connect/callback?state=state-123&code=grant-code")

    redirect_url = redirected_to(conn, 302)

    assert redirect_url =~ "/auth/bnet/callback?"
    assert redirect_url =~ "status=success"
    assert redirect_url =~ "provider=battle_net"

    token_id = get_session(conn, :battle_net_token_id)
    assert %{access_token: "battle-token"} = TokenStore.get(token_id)

    on_exit(fn -> TokenStore.delete(token_id) end)
  end

  test "GET /api/v1/bnet/connect/callback redirects with an error when state is invalid", %{conn: conn} do
    conn =
      conn
      |> init_test_session(battle_net_oauth_state: "expected-state")
      |> get("/api/v1/bnet/connect/callback?state=wrong-state&code=grant-code")

    redirect_url = redirected_to(conn, 302)

    assert redirect_url =~ "/auth/bnet/callback?"
    assert redirect_url =~ "status=error"
    assert redirect_url =~ "Battle.net+login+state+could+not+be+verified"
  end

  test "GET /api/v1/bnet/connect/callback redirects with an error when Battle.net denies auth",
       %{conn: conn} do
    conn =
      conn
      |> init_test_session(battle_net_oauth_state: "state-123")
      |> get("/api/v1/bnet/connect/callback?state=state-123&error=access_denied")

    redirect_url = redirected_to(conn, 302)

    assert redirect_url =~ "/auth/bnet/callback?"
    assert redirect_url =~ "status=error"
    assert redirect_url =~ "Battle.net+login+was+denied"
  end

  test "GET /api/v1/bnet/connect/callback redirects with an error when code is missing", %{conn: conn} do
    conn =
      conn
      |> init_test_session(battle_net_oauth_state: "state-123")
      |> get("/api/v1/bnet/connect/callback?state=state-123")

    redirect_url = redirected_to(conn, 302)

    assert redirect_url =~ "/auth/bnet/callback?"
    assert redirect_url =~ "status=error"
    assert redirect_url =~ "Battle.net+did+not+return+an+authorization+code"
  end
end
