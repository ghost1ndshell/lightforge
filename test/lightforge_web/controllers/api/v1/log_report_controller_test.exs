defmodule LightforgeWeb.Api.V1.LogReportControllerTest do
  use LightforgeWeb.ConnCase, async: false

  alias Lightforge.Logs

  setup {Req.Test, :set_req_test_from_context}
  setup {Req.Test, :verify_on_exit!}

  setup do
    previous_config = Application.get_env(:lightforge, Lightforge.WarcraftLogs.Config, [])

    Application.put_env(:lightforge, Lightforge.WarcraftLogs.Config,
      client_id: "wcl-client-id",
      client_secret: "wcl-client-secret",
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    on_exit(fn ->
      Application.put_env(:lightforge, Lightforge.WarcraftLogs.Config, previous_config)
    end)

    :ok
  end

  test "POST /api/v1/logs/reports/:code/import imports a report with fights and participants", %{conn: conn} do
    Req.Test.expect(__MODULE__, 2, &warcraft_logs_response/1)

    conn = post(conn, "/api/v1/logs/reports/abc123/import")

    assert %{
             "data" => %{
               "code" => "abc123",
               "title" => "Midnight Progress",
               "fight_count" => 1,
               "fights" => [
                 %{
                   "encounter_name" => "Imperator Averzian",
                   "participant_count" => 2,
                   "participants" => [
                     %{"name" => "Aeloria"},
                     %{"name" => "Bromm"}
                   ]
                 }
               ]
             }
           } = json_response(conn, 200)

    assert [%{code: "abc123"}] = Logs.list_reports()
  end

  test "GET /api/v1/logs/reports/:code returns a stored imported report", %{conn: conn} do
    Req.Test.expect(__MODULE__, 2, &warcraft_logs_response/1)
    assert {:ok, _report} = Logs.import_report("abc123")

    conn = get(conn, "/api/v1/logs/reports/abc123")

    assert %{
             "data" => %{
               "code" => "abc123",
               "title" => "Midnight Progress",
               "fight_count" => 1
             }
           } = json_response(conn, 200)
  end

  test "POST /api/v1/logs/reports/:code/import returns an error when credentials are missing", %{conn: conn} do
    Application.put_env(:lightforge, Lightforge.WarcraftLogs.Config,
      client_id: "",
      client_secret: "",
      req_options: [plug: {Req.Test, __MODULE__}]
    )

    conn = post(conn, "/api/v1/logs/reports/abc123/import")

    assert %{
             "error" => %{
               "code" => "request_failed",
               "message" => "Warcraft Logs credentials are not configured yet."
             }
           } = json_response(conn, 422)
  end

  test "GET /api/v1/logs/reports/:code returns not found when no import exists", %{conn: conn} do
    conn = get(conn, "/api/v1/logs/reports/missing")
    assert %{"error" => %{"code" => "not_found"}} = json_response(conn, 404)
  end

  defp warcraft_logs_response(conn) do
    case conn.request_path do
      "/oauth/token" ->
        Req.Test.json(conn, %{
          "access_token" => "wcl-access-token",
          "token_type" => "bearer"
        })

      "/api/v2/client" ->
        Req.Test.json(conn, %{
          "data" => %{
            "reportData" => %{
              "report" => %{
                "code" => "abc123",
                "title" => "Midnight Progress",
                "startTime" => 1_742_649_600_000,
                "endTime" => 1_742_650_200_000,
                "visibility" => "PUBLIC",
                "owner" => %{"name" => "RaidLead"},
                "zone" => %{"name" => "The Midnight Bastion"},
                "masterData" => %{
                  "actors" => [
                    %{
                      "id" => 11,
                      "name" => "Aeloria",
                      "server" => "Stormrage",
                      "subType" => "Priest"
                    },
                    %{
                      "id" => 12,
                      "name" => "Bromm",
                      "server" => "Stormrage",
                      "subType" => "Warrior"
                    }
                  ]
                },
                "fights" => [
                  %{
                    "id" => 3,
                    "encounterID" => 9001,
                    "name" => "Imperator Averzian",
                    "difficulty" => 5,
                    "kill" => true,
                    "startTime" => 1200,
                    "endTime" => 225000,
                    "friendlyPlayers" => [11, 12]
                  }
                ]
              }
            }
          }
        })

      other ->
        flunk("Unexpected Warcraft Logs request: #{other}")
    end
  end
end
