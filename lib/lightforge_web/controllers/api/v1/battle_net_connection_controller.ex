defmodule LightforgeWeb.Api.V1.BattleNetConnectionController do
  use LightforgeWeb, :controller

  alias Lightforge.BattleNet
  alias LightforgeWeb.BattleNetSession

  action_fallback LightforgeWeb.Api.V1.FallbackController

  @frontend_callback_path "/auth/bnet/callback"

  def status(conn, _params) do
    connected? =
      conn
      |> get_session()
      |> BattleNetSession.connected?()

    json(conn, %{
      data: %{
        battle_net_ready: BattleNet.ready?(),
        connected: connected?,
        provider: "battle_net"
      }
    })
  end

  def start(conn, _params) do
    state = random_state()

    with {:ok, authorize_url} <- BattleNet.authorize_url(state) do
      conn
      |> BattleNetSession.put_oauth_state(state)
      |> json(%{
        data: %{
          authorize_url: authorize_url,
          provider: "battle_net"
        }
      })
    end
  end

  def callback(conn, params) do
    cond do
      params["error"] ->
        redirect_with_status(conn, :error, "Battle.net login was denied: #{humanize_error(params["error"])}.")

      params["state"] != BattleNetSession.oauth_state(conn) ->
        conn
        |> BattleNetSession.clear()
        |> redirect_with_status(:error, "Battle.net login state could not be verified. Try again.")

      not is_binary(params["code"]) ->
        redirect_with_status(conn, :error, "Battle.net did not return an authorization code.")

      true ->
        case BattleNet.exchange_code(params["code"]) do
          {:ok, token_data} ->
            conn
            |> delete_session(:battle_net_oauth_state)
            |> BattleNetSession.put_token(token_data)
            |> redirect_with_status(:success, "Battle.net connected.")

          {:error, message} ->
            redirect_with_status(conn, :error, message)
        end
    end
  end

  defp redirect_with_status(conn, status, message) do
    query =
      URI.encode_query(%{
        "message" => message,
        "provider" => "battle_net",
        "status" => to_string(status)
      })

    redirect(conn, to: @frontend_callback_path <> "?" <> query)
  end

  defp random_state do
    18
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp humanize_error(error) when is_binary(error) do
    error
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_error(_error), do: "Unknown error"
end
