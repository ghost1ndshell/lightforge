defmodule Lightforge.Wow.AccountCharacter do
  @moduledoc false

  @enforce_keys [:label, :name, :realm, :ref, :region]
  defstruct [
    :character_class,
    :faction,
    :id,
    :label,
    :level,
    :name,
    :realm,
    :realm_slug,
    :ref,
    :region
  ]
end
