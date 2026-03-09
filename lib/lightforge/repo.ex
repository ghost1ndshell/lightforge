defmodule Lightforge.Repo do
  use Ecto.Repo,
    otp_app: :lightforge,
    adapter: Ecto.Adapters.Postgres
end
