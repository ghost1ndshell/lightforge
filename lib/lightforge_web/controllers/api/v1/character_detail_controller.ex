defmodule LightforgeWeb.Api.V1.CharacterDetailController do
  use LightforgeWeb, :controller

  alias Lightforge.CharacterDetails

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def show(conn, %{"region" => region, "realm" => realm, "name" => name}) do
    with {:ok, detail} <- CharacterDetails.get_character_detail(region, realm, name) do
      json(conn, %{data: detail})
    end
  end
end
