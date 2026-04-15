defmodule LightforgeWeb.Api.V1.GearingController do
  use LightforgeWeb, :controller

  alias Lightforge.Gearing

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def show(conn, %{"region" => region, "realm" => realm, "name" => name} = params) do
    mode = Map.get(params, "mode", "dungeons")

    with {:ok, plan} <- Gearing.get_character_plan(region, realm, name, mode) do
      json(conn, %{data: plan})
    end
  end
end
