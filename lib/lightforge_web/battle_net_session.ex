defmodule LightforgeWeb.BattleNetSession do
  @moduledoc false

  import Plug.Conn

  alias Lightforge.BattleNet.TokenStore

  @oauth_state_key :battle_net_oauth_state
  @token_id_key :battle_net_token_id

  def connected?(%Plug.Conn{} = conn) do
    conn
    |> get_session()
    |> token_from_session()
    |> is_map()
  end

  def connected?(session) when is_map(session) do
    session
    |> token_from_session()
    |> is_map()
  end

  def connected?(_other), do: false

  def token_from_session(session) when is_map(session) do
    session
    |> fetch_value(@token_id_key)
    |> case do
      token_id when is_binary(token_id) -> TokenStore.get(token_id)
      _ -> nil
    end
  end

  def put_token(conn, token_data) do
    token_id = get_session(conn, @token_id_key) || random_token_id()
    :ok = TokenStore.put(token_id, token_data)
    put_session(conn, @token_id_key, token_id)
  end

  def put_oauth_state(conn, state), do: put_session(conn, @oauth_state_key, state)
  def oauth_state(conn), do: get_session(conn, @oauth_state_key)

  def clear(conn) do
    if token_id = get_session(conn, @token_id_key) do
      :ok = TokenStore.delete(token_id)
    end

    conn
    |> delete_session(@token_id_key)
    |> delete_session(@oauth_state_key)
  end

  defp random_token_id do
    24
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp fetch_value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
