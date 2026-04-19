defmodule Lightforge.WarcraftLogs.Client do
  @moduledoc false

  alias Lightforge.WarcraftLogs.Config

  @report_import_query """
  query ReportImport($code: String!) {
    reportData {
      report(code: $code) {
        code
        title
        startTime
        endTime
        visibility
        owner {
          name
        }
        zone {
          name
        }
        masterData {
          actors(type: "Player") {
            id
            name
            subType
            server
          }
        }
        fights(killType: All) {
          id
          encounterID
          name
          difficulty
          kill
          startTime
          endTime
          friendlyPlayers
        }
      }
    }
  }
  """

  def fetch_report(code) when is_binary(code) and code != "" do
    with :ok <- Config.validate_credentials(),
         {:ok, access_token} <- fetch_access_token(),
         {:ok, body} <- execute_query(access_token, @report_import_query, %{code: code}),
         {:ok, report} <- extract_report(body) do
      {:ok, report}
    end
  end

  def fetch_report(_code), do: {:error, "A Warcraft Logs report code is required."}

  defp fetch_access_token do
    Config.req_options()
    |> Req.new()
    |> Req.post(
      url: Config.oauth_base_url() <> "/token",
      auth: {:basic, "#{Config.client_id()}:#{Config.client_secret()}"},
      form: [grant_type: "client_credentials"],
      headers: [{"user-agent", Config.user_agent()}]
    )
    |> normalize_token_response()
  end

  defp execute_query(access_token, query, variables) do
    Config.req_options()
    |> Req.new()
    |> Req.post(
      url: Config.api_url(),
      headers: [
        {"authorization", "Bearer #{access_token}"},
        {"user-agent", Config.user_agent()}
      ],
      json: %{
        query: query,
        variables: variables
      }
    )
    |> normalize_graphql_response()
  end

  defp extract_report(%{"data" => %{"reportData" => %{"report" => report}}}) when is_map(report),
    do: {:ok, report}

  defp extract_report(%{"data" => %{"reportData" => %{"report" => nil}}}),
    do: {:error, :not_found}

  defp extract_report(_body), do: {:error, "Warcraft Logs returned an unexpected report payload."}

  defp normalize_token_response({:ok, %{status: 200, body: %{"access_token" => access_token}}})
       when is_binary(access_token) and access_token != "" do
    {:ok, access_token}
  end

  defp normalize_token_response({:ok, %{status: 401}}) do
    {:error, "Warcraft Logs rejected the client credentials for token exchange."}
  end

  defp normalize_token_response({:ok, %{status: status, body: body}}) do
    message =
      case body do
        %{"error_description" => value} when is_binary(value) -> value
        %{"error" => value} when is_binary(value) -> value
        _ -> "Warcraft Logs OAuth returned HTTP #{status}."
      end

    {:error, message}
  end

  defp normalize_token_response({:error, reason}) do
    {:error, "Warcraft Logs token exchange failed: #{inspect(reason)}"}
  end

  defp normalize_graphql_response({:ok, %{status: 200, body: %{"errors" => errors}}})
       when is_list(errors) and errors != [] do
    {:error, graphql_error_message(errors)}
  end

  defp normalize_graphql_response({:ok, %{status: 200, body: body}}) when is_map(body),
    do: {:ok, body}

  defp normalize_graphql_response({:ok, %{status: 401}}), do: {:error, :unauthorized}

  defp normalize_graphql_response({:ok, %{status: status, body: body}}) do
    message =
      case body do
        %{"message" => value} when is_binary(value) -> value
        _ -> "Warcraft Logs API returned HTTP #{status}."
      end

    {:error, message}
  end

  defp normalize_graphql_response({:error, reason}) do
    {:error, "Warcraft Logs request failed: #{inspect(reason)}"}
  end

  defp graphql_error_message(errors) do
    errors
    |> Enum.find_value("Warcraft Logs returned a GraphQL error.", fn
      %{"message" => value} when is_binary(value) -> value
      _ -> nil
    end)
  end
end
