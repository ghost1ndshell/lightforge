defmodule Lightforge.Wow.Character do
  @moduledoc false

  alias Lightforge.Wow.Item

  @enforce_keys [:name, :realm, :region]
  defstruct [
    :active_spec,
    :achievement_summary,
    :avatar_url,
    :character_class,
    :content_plan,
    :content_summary,
    :equipped_item_level,
    :faction,
    :gear_plan,
    :gender,
    :guild,
    :level,
    :mythic_summary,
    :name,
    :progression_plan,
    :race,
    :realm,
    :realm_slug,
    :region,
    :render_url,
    :stat_goal_plan,
    :stat_priority,
    :stat_lines,
    :tracked_achievements,
    :suggestions,
    items: []
  ]

  @type t :: %__MODULE__{
          active_spec: String.t() | nil,
          achievement_summary: map() | nil,
          avatar_url: String.t() | nil,
          character_class: String.t() | nil,
          content_plan: map() | nil,
          content_summary: map() | nil,
          equipped_item_level: integer() | nil,
          faction: String.t() | nil,
          gear_plan: map() | nil,
          gender: String.t() | nil,
          guild: String.t() | nil,
          level: integer() | nil,
          mythic_summary: map() | nil,
          name: String.t(),
          progression_plan: map() | nil,
          race: String.t() | nil,
          realm: String.t(),
          realm_slug: String.t() | nil,
          region: String.t(),
          render_url: String.t() | nil,
          stat_goal_plan: map() | nil,
          stat_priority: map() | nil,
          stat_lines: [map()] | nil,
          tracked_achievements: [map()] | nil,
          suggestions: [String.t()] | nil,
          items: [Item.t()]
        }
end
