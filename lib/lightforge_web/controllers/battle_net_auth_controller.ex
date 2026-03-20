defmodule LightforgeWeb.BattleNetAuthController do
  use LightforgeWeb, :controller

  alias Lightforge.BattleNet
  alias LightforgeWeb.BattleNetSession

  def request(conn, _params) do
    state = random_state()

    case BattleNet.authorize_url(state) do
      {:ok, authorize_url} ->
        conn
        |> BattleNetSession.put_oauth_state(state)
        |> redirect(external: authorize_url)

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, params) do
    cond do
      params["error"] ->
        conn
        |> put_flash(:error, "Battle.net login was denied: #{humanize_error(params["error"])}.")
        |> redirect(to: ~p"/")

      params["state"] != BattleNetSession.oauth_state(conn) ->
        conn
        |> BattleNetSession.clear()
        |> put_flash(:error, "Battle.net login state could not be verified. Try again.")
        |> redirect(to: ~p"/")

      not is_binary(params["code"]) ->
        conn
        |> put_flash(:error, "Battle.net did not return an authorization code.")
        |> redirect(to: ~p"/")

      true ->
        case BattleNet.exchange_code(params["code"]) do
          {:ok, token_data} ->
            conn
            |> delete_session(:battle_net_oauth_state)
            |> BattleNetSession.put_token(token_data)
            |> put_flash(:info, "Battle.net connected. Enter a character to inspect.")
            |> redirect(to: ~p"/character")

          {:error, message} ->
            conn
            |> put_flash(:error, message)
            |> redirect(to: ~p"/")
        end
    end
  end

  def logout(conn, _params) do
    conn
    |> BattleNetSession.clear()
    |> put_flash(:info, "Battle.net disconnected.")
    |> redirect(to: ~p"/")
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
