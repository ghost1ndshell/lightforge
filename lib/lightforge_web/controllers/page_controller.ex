defmodule LightforgeWeb.PageController do
  use LightforgeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
