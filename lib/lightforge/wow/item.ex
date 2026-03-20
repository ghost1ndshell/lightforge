defmodule Lightforge.Wow.Item do
  @moduledoc false

  @enforce_keys [:id, :name, :slot, :slot_key]
  defstruct [
    :icon_url,
    :id,
    :inventory_type,
    :item_level,
    :name,
    :quality,
    :slot,
    :slot_key
  ]
end
