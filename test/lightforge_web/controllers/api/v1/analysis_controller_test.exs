defmodule LightforgeWeb.Api.V1.AnalysisControllerTest do
  use LightforgeWeb.ConnCase, async: false

  alias Lightforge.Analysis
  alias Lightforge.Logs

  test "POST /api/v1/analysis/fights/:fight_id/import stores a fight-level run with ranked insights",
       %{conn: conn} do
    report = Logs.upsert_report(%{code: "abc123", raw_json: %{}})

    fight =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 3,
        encounter_id: 9001,
        encounter_name: "Imperator Averzian",
        raw_json: %{}
      })

    conn =
      post(conn, "/api/v1/analysis/fights/#{fight.id}/import", %{
        provider: "wowanalyzer",
        score: 82.5,
        source_version: "1.0.0",
        ruleset_version: "midnight-preseason",
        summary_json: %{headline: "Cooldown drift and low uptime"},
        raw_json: %{source: "fixture"},
        insights: [
          %{
            source_key: "cooldown-drift",
            severity: "high",
            category: "cooldowns",
            title: "Major cooldown drift",
            summary: "You delayed major cooldowns several times.",
            recommendation: "Line cooldowns up with the encounter plan.",
            impact_score: 9.4,
            highlighted: true,
            metadata_json: %{casts_missed: 2}
          },
          %{
            source_key: "low-uptime",
            severity: "medium",
            category: "uptime",
            title: "Low damage-over-time uptime",
            summary: "Primary debuff uptime was below target.",
            recommendation: "Refresh the debuff before major movement windows.",
            impact_score: 6.2,
            metadata_json: %{uptime_percent: 71.4}
          }
        ]
      })

    assert %{
             "data" => %{
               "provider" => "wowanalyzer",
               "fight_id" => fight_id,
               "score" => 82.5,
               "insights" => [
                 %{
                   "title" => "Major cooldown drift",
                   "highlighted" => true,
                   "impact_score" => 9.4
                 },
                 %{
                   "title" => "Low damage-over-time uptime",
                   "highlighted" => false,
                   "impact_score" => 6.2
                 }
               ]
             }
           } = json_response(conn, 200)

    assert fight_id == fight.id
  end

  test "GET /api/v1/analysis/fights/:fight_id returns the latest fight-level run", %{conn: conn} do
    report = Logs.upsert_report(%{code: "def456", raw_json: %{}})

    fight =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 7,
        encounter_id: 9002,
        encounter_name: "Vorasius",
        raw_json: %{}
      })

    assert {:ok, _run} =
             Analysis.import_run(fight.id, %{
               provider: "wowanalyzer",
               score: 91.0,
               summary_json: %{headline: "Strong play overall"},
               raw_json: %{source: "fixture"},
               insights: [
                 %{
                   severity: "low",
                   category: "positioning",
                   title: "Minor positioning inefficiency",
                   summary: "Movement was slightly early in one phase.",
                   recommendation: "Hold position longer before the transition.",
                   impact_score: 2.5,
                   metadata_json: %{}
                 }
               ]
             })

    conn = get(conn, "/api/v1/analysis/fights/#{fight.id}")

    assert %{
             "data" => %{
               "fight_id" => fight_id,
               "provider" => "wowanalyzer",
               "insights" => [%{"title" => "Minor positioning inefficiency"}]
             }
           } = json_response(conn, 200)

    assert fight_id == fight.id
  end

  test "GET /api/v1/analysis/fights/:fight_id/participants/:participant_id returns the latest player run",
       %{conn: conn} do
    report = Logs.upsert_report(%{code: "ghi789", raw_json: %{}})

    fight =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 8,
        encounter_id: 9003,
        encounter_name: "Salhadaar",
        raw_json: %{}
      })

    participant =
      Logs.upsert_participant(%{
        fight_id: fight.id,
        actor_id: 44,
        name: "Aeloria",
        class_name: "Priest",
        raw_json: %{}
      })

    assert {:ok, _run} =
             Analysis.import_run(fight.id, %{
               provider: "wowanalyzer",
               participant_id: participant.id,
               score: 77.0,
               summary_json: %{headline: "Healing throughput can improve"},
               raw_json: %{source: "fixture"},
               insights: [
                 %{
                   severity: "high",
                   category: "cooldowns",
                   title: "Late raid cooldown usage",
                   summary: "Raid cooldowns were held too long.",
                   recommendation: "Assign earlier use windows for planned damage.",
                   impact_score: 8.8,
                   highlighted: true,
                   metadata_json: %{}
                 }
               ]
             })

    conn = get(conn, "/api/v1/analysis/fights/#{fight.id}/participants/#{participant.id}")

    assert %{
             "data" => %{
               "participant_id" => participant_id,
               "provider" => "wowanalyzer",
               "insights" => [%{"title" => "Late raid cooldown usage"}]
             }
           } = json_response(conn, 200)

    assert participant_id == participant.id
  end

  test "POST /api/v1/analysis/fights/:fight_id/import rejects participants from another fight", %{conn: conn} do
    report = Logs.upsert_report(%{code: "jkl012", raw_json: %{}})

    fight_one =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 10,
        encounter_id: 9004,
        encounter_name: "Belo'ren",
        raw_json: %{}
      })

    fight_two =
      Logs.upsert_fight(%{
        report_id: report.id,
        warcraftlogs_fight_id: 11,
        encounter_id: 9005,
        encounter_name: "Midnight Falls",
        raw_json: %{}
      })

    participant =
      Logs.upsert_participant(%{
        fight_id: fight_two.id,
        actor_id: 77,
        name: "Bromm",
        class_name: "Warrior",
        raw_json: %{}
      })

    conn =
      post(conn, "/api/v1/analysis/fights/#{fight_one.id}/import", %{
        provider: "wowanalyzer",
        participant_id: participant.id,
        summary_json: %{},
        raw_json: %{},
        insights: []
      })

    assert %{
             "error" => %{
               "code" => "request_failed",
               "message" => "Participant does not belong to the requested fight."
             }
           } = json_response(conn, 422)
  end
end
