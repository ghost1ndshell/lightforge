defmodule Lightforge.Wow.GearTarget do
  @moduledoc false

  @enforce_keys [:content_type, :priority, :slot_keys, :slot_label, :source, :target_name]
  defstruct [
    :acquired?,
    :content_type,
    :current_label,
    :current_level,
    :note,
    :priority,
    :slot_keys,
    :slot_label,
    :source,
    :source_url,
    :target_name
  ]

  @type t :: %__MODULE__{
          acquired?: boolean() | nil,
          content_type: String.t(),
          current_label: String.t() | nil,
          current_level: integer() | nil,
          note: String.t() | nil,
          priority: pos_integer(),
          slot_keys: [String.t()],
          slot_label: String.t(),
          source: String.t(),
          source_url: String.t() | nil,
          target_name: String.t()
        }
end
