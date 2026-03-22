defmodule Lightforge.Logs.Report do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Logs.Fight

  schema "wcl_reports" do
    field :code, :string
    field :title, :string
    field :owner_name, :string
    field :visibility, :string
    field :zone_name, :string
    field :start_time, :utc_datetime_usec
    field :end_time, :utc_datetime_usec
    field :raw_json, :map, default: %{}

    has_many :fights, Fight

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [:code, :title, :owner_name, :visibility, :zone_name, :start_time, :end_time, :raw_json])
    |> validate_required([:code, :raw_json])
    |> unique_constraint(:code)
  end
end
