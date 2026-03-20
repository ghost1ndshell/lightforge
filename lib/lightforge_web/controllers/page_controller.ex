defmodule LightforgeWeb.PageController do
  use LightforgeWeb, :controller

  alias Lightforge.BattleNet
  alias LightforgeWeb.BattleNetSession

  def home(conn, _params) do
    render(conn, :home,
      battle_net_connected: BattleNetSession.connected?(conn),
      battle_net_ready: BattleNet.ready?()
    )
  end
end
