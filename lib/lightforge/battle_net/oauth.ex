defmodule Lightforge.BattleNet.OAuth do
  @moduledoc false

  alias Lightforge.BattleNet.Config

  def authorize_url(state) when is_binary(state) do
    with :ok <- Config.validate_credentials() do
      params =
        URI.encode_query(%{
          "client_id" => Config.client_id(),
          "redirect_uri" => Config.redirect_uri(),
          "response_type" => "code",
          "scope" => Config.oauth_scope(),
          "state" => state
        })

      {:ok, "#{Config.oauth_base_url()}/authorize?#{params}"}
    end
  end

  def exchange_code_for_token(code) when is_binary(code) and code != "" do
    with :ok <- Config.validate_credentials() do
      Config.req_options()
      |> Req.new()
      |> Req.post(
        url: "#{Config.oauth_base_url()}/token",
        auth: {:basic, "#{Config.client_id()}:#{Config.client_secret()}"},
        form: [
          grant_type: "authorization_code",
          code: code,
          redirect_uri: Config.redirect_uri()
        ],
        headers: [{"user-agent", Config.user_agent()}]
      )
      |> normalize_token_response()
    end
  end

  def exchange_code_for_token(_), do: {:error, "Missing Battle.net authorization code."}

  defp normalize_token_response({:ok, %{status: 200, body: body}}) do
    token_body = normalize_body(body)
    expires_in = Map.get(token_body, "expires_in", 0)
    access_token = Map.get(token_body, "access_token", "")

    if access_token == "" do
      {:error, "Battle.net token exchange returned an empty access token."}
    else
      {:ok,
       %{
         access_token: access_token,
         expires_at: System.system_time(:second) + parse_integer(expires_in),
         expires_in: parse_integer(expires_in),
         refresh_token: Map.get(token_body, "refresh_token"),
         scope: Map.get(token_body, "scope", ""),
         token_type: Map.get(token_body, "token_type", "bearer")
       }}
    end
  end

  defp normalize_token_response({:ok, %{status: 401}}) do
    {:error, "Battle.net rejected the client credentials for token exchange."}
  end

  defp normalize_token_response({:ok, %{status: status, body: body}}) do
    detail =
      body
      |> normalize_body()
      |> Map.get("error_description") || "Battle.net OAuth returned HTTP #{status}."

    {:error, detail}
  end

  defp normalize_token_response({:error, reason}) do
    {:error, "Battle.net token exchange failed: #{inspect(reason)}"}
  end

  defp normalize_body(body) when is_map(body), do: body

  defp normalize_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp normalize_body(_body), do: %{}

  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, _} -> parsed
      :error -> 0
    end
  end

  defp parse_integer(_value), do: 0
end
