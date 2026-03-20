defmodule Lightforge.BattleNet.TokenStore do
  @moduledoc false

  use GenServer

  @table __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def put(token_id, token_data) when is_binary(token_id) and is_map(token_data) do
    :ets.insert(@table, {token_id, token_data})
    :ok
  end

  def get(token_id) when is_binary(token_id) do
    case :ets.lookup(@table, token_id) do
      [{^token_id, token_data}] ->
        if expired?(token_data) do
          delete(token_id)
          nil
        else
          token_data
        end

      _ ->
        nil
    end
  end

  def delete(token_id) when is_binary(token_id) do
    :ets.delete(@table, token_id)
    :ok
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{}}
  end

  defp expired?(%{expires_at: expires_at}) when is_integer(expires_at) do
    System.system_time(:second) >= expires_at
  end

  defp expired?(_token_data), do: false
end
