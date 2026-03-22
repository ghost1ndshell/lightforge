defmodule LightforgeWeb.Api.V1.FallbackController do
  @moduledoc """
  	Simple error translator
  """
  use LightforgeWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "not_found", message: "Resource not found"}})
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: %{code: "unauthorized", message: "Unauthorized"}})
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: %{code: "forbidden", message: "Forbidden"}})
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{code: "request_failed", message: message}})
  end

  def call(conn, _) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: %{code: "internal_error", message: "Unexpected error"}})
  end
end
