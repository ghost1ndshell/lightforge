defmodule Lightforge.Wow.CharacterSnapshot do
  @moduledoc false

  alias Lightforge.BattleNet.Client
  alias Lightforge.BattleNet.Config
  alias Lightforge.Wow.Character
  alias Lightforge.Wow.ContentPlanner
  alias Lightforge.Wow.GearPlanner
  alias Lightforge.Wow.Item
  alias Lightforge.Wow.MidnightSeason
  alias Lightforge.Wow.ProgressionPlanner
  alias Lightforge.Wow.SpecPriority
  alias Lightforge.Wow.StatGoalPlanner
  alias Lightforge.Wow.TrackedAchievementPlanner

  def fetch(token_data, attrs) do
    with {:ok, %{character_input: character_input, item_media_by_id: item_media_by_id} = payload} <-
           fetch_payload(token_data, attrs) do
      responses = payload.responses
      {:ok, to_character(character_input, responses, item_media_by_id)}
    end
  end

  def fetch_payload(token_data, attrs) do
    with :ok <- validate_token(token_data),
         {:ok, character_input} <- normalize_input(attrs),
         {:ok, responses} <- fetch_core_responses(token_data, character_input),
         {:ok, item_media_by_id} <-
           fetch_item_media(token_data, character_input.region, responses.equipment) do
      {:ok,
       %{
         character_input: character_input,
         item_media_by_id: item_media_by_id,
         responses: responses
       }}
    end
  end

  def normalize_input(attrs) when is_map(attrs) do
    region = Config.normalize_region(fetch_value(attrs, "region") || fetch_value(attrs, :region))
    realm = fetch_value(attrs, "realm") || fetch_value(attrs, :realm) || ""
    realm_slug = fetch_value(attrs, "realm_slug") || fetch_value(attrs, :realm_slug)
    name = fetch_value(attrs, "name") || fetch_value(attrs, :name) || ""

    normalized_realm = String.trim(realm)
    normalized_name = String.trim(name)

    cond do
      normalized_realm == "" ->
        {:error, "Enter a realm before loading a character."}

      normalized_name == "" ->
        {:error, "Enter a character name before loading a character."}

      true ->
        {:ok,
         %{
           region: region,
           realm: normalized_realm,
           realm_slug: normalize_realm_slug(realm_slug, normalized_realm),
           name: normalized_name
         }}
    end
  end

  def normalize_input(_attrs), do: {:error, "Character inputs are invalid."}

  def slugify(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[\p{Mn}]/u, "")
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  def slugify(_value), do: ""

  defp validate_token(token_data) do
    if is_map(token_data) and is_binary(token_data.access_token) and token_data.access_token != "" do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp fetch_core_responses(token_data, %{region: region, realm_slug: realm_slug, name: name}) do
    name_path = normalize_character_path(name)

    [
      {:profile, fn -> Client.get_profile_summary(token_data, region, realm_slug, name_path) end},
      {:equipment,
       fn -> Client.get_equipment_summary(token_data, region, realm_slug, name_path) end},
      {:media,
       fn -> Client.get_character_media_summary(token_data, region, realm_slug, name_path) end},
      {:statistics,
       fn ->
         Client.get_character_statistics_summary(token_data, region, realm_slug, name_path)
       end},
      {:achievements,
       fn ->
         Client.get_character_achievements_summary(token_data, region, realm_slug, name_path)
       end},
      {:mythic,
       fn ->
         Client.get_character_mythic_keystone_profile(token_data, region, realm_slug, name_path)
       end}
    ]
    |> Task.async_stream(fn {key, fun} -> {key, fun.()} end, timeout: :infinity)
    |> Enum.reduce_while({:ok, %{}}, fn
      {:ok, {key, {:ok, response}}}, {:ok, acc} ->
        {:cont, {:ok, Map.put(acc, key, response)}}

      {:ok, {key, {:error, :not_found}}}, {:ok, acc}
      when key in [:statistics, :achievements, :mythic] ->
        {:cont, {:ok, Map.put(acc, key, nil)}}

      {:ok, {_key, {:error, :not_found}}}, _acc ->
        {:halt, {:error, "That character could not be found in Battle.net."}}

      {:ok, {_key, {:error, :unauthorized}}}, _acc ->
        {:halt, {:error, :unauthorized}}

      {:ok, {_key, {:error, reason}}}, _acc ->
        {:halt, {:error, reason}}

      {:exit, reason}, _acc ->
        {:halt, {:error, "Battle.net request exited unexpectedly: #{inspect(reason)}"}}
    end)
  end

  defp fetch_item_media(token_data, region, equipment_body) do
    item_ids =
      equipment_body
      |> equipped_items()
      |> Enum.map(&item_id/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    item_ids
    |> Task.async_stream(
      fn item_id -> {item_id, Client.get_item_media_summary(token_data, region, item_id)} end,
      max_concurrency: 8,
      timeout: :infinity
    )
    |> Enum.reduce({:ok, %{}}, fn
      {:ok, {item_id, {:ok, body}}}, {:ok, acc} ->
        {:ok, Map.put(acc, item_id, body)}

      {:ok, {_item_id, {:error, _reason}}}, {:ok, acc} ->
        {:ok, acc}

      {:exit, _reason}, {:ok, acc} ->
        {:ok, acc}
    end)
  end

  defp to_character(character_input, responses, item_media_by_id) do
    profile = responses.profile
    media = responses.media
    mythic_summary = normalize_mythic_summary(responses[:mythic])
    achievement_summary = normalize_achievement_summary(responses[:achievements])
    stat_lines = normalize_stat_lines(responses[:statistics])
    character_class = nested_name(profile, ["character_class"])
    active_spec = nested_name(profile, ["active_spec"])
    items = normalize_items(responses.equipment, item_media_by_id)

    %Character{
      achievement_summary: achievement_summary,
      active_spec: active_spec,
      avatar_url: media_asset_url(media, ["avatar", "inset"]),
      character_class: character_class,
      content_plan:
        ContentPlanner.build(%{
          achievement_summary: achievement_summary,
          active_spec: active_spec,
          character_class: character_class,
          equipped_item_level: profile["equipped_item_level"],
          mythic_summary: mythic_summary
        }),
      content_summary: normalize_content_summary(mythic_summary, achievement_summary),
      equipped_item_level: profile["equipped_item_level"],
      faction: nested_name(profile, ["faction"]),
      gear_plan: GearPlanner.build(character_class, active_spec, items),
      gender: nested_name(profile, ["gender"]),
      guild: nested_name(profile, ["guild"]),
      level: profile["level"],
      mythic_summary: mythic_summary,
      name: profile["name"] || character_input.name,
      progression_plan:
        ProgressionPlanner.build(%{
          mythic_summary: mythic_summary
        }),
      race: nested_name(profile, ["race"]),
      realm: nested_name(profile, ["realm"]) || character_input.realm,
      realm_slug: get_in(profile, ["realm", "slug"]) || character_input.realm_slug,
      region: character_input.region,
      render_url: media_asset_url(media, ["main-raw", "main", "avatar"]),
      stat_goal_plan: StatGoalPlanner.build(character_class, active_spec, stat_lines),
      stat_priority: SpecPriority.for_character(character_class, active_spec),
      stat_lines: stat_lines,
      tracked_achievements:
        TrackedAchievementPlanner.build(%{
          active_spec: active_spec,
          character_class: character_class,
          mythic_summary: mythic_summary
        }),
      suggestions:
        build_suggestions(profile["equipped_item_level"], mythic_summary, achievement_summary),
      items: items
    }
  end

  defp normalize_items(equipment_body, item_media_by_id) do
    equipment_body
    |> equipped_items()
    |> Enum.map(fn item ->
      id = item_id(item)

      %Item{
        icon_url: media_asset_url(Map.get(item_media_by_id, id, %{}), ["icon"]),
        id: id,
        inventory_type: nested_name(item, ["inventory_type"]),
        item_level: get_in(item, ["level", "value"]),
        name: item["name"] || nested_name(item, ["item"]) || "Unknown item",
        quality: quality_label(item),
        slot: nested_name(item, ["slot"]) || "Unknown slot",
        slot_key: slot_key(item)
      }
    end)
    |> Enum.sort_by(&slot_order/1)
  end

  defp equipped_items(%{"equipped_items" => items}) when is_list(items), do: items
  defp equipped_items(_body), do: []

  defp item_id(item) do
    get_in(item, ["item", "id"]) || get_in(item, ["item", "key", "href"]) |> parse_id_from_href()
  end

  defp parse_id_from_href(value) when is_integer(value), do: value

  defp parse_id_from_href(value) when is_binary(value) do
    case Regex.run(~r/\/item\/(\d+)/, value, capture: :all_but_first) do
      [id] ->
        case Integer.parse(id) do
          {parsed, _} -> parsed
          :error -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_id_from_href(_value), do: nil

  defp quality_label(item) do
    item
    |> get_in(["quality", "type"])
    |> case do
      nil -> "Unknown"
      value -> value |> String.downcase() |> String.replace("_", " ") |> String.capitalize()
    end
  end

  defp slot_key(item) do
    get_in(item, ["slot", "type"]) || "UNKNOWN"
  end

  defp slot_order(%Item{slot_key: slot_key}) do
    Enum.find_index(
      [
        "HEAD",
        "NECK",
        "SHOULDER",
        "BACK",
        "CHEST",
        "SHIRT",
        "TABARD",
        "WRIST",
        "HANDS",
        "WAIST",
        "LEGS",
        "FEET",
        "FINGER_1",
        "FINGER_2",
        "TRINKET_1",
        "TRINKET_2",
        "MAIN_HAND",
        "OFF_HAND"
      ],
      &(&1 == slot_key)
    ) || 999
  end

  defp media_asset_url(body, keys) when is_map(body) do
    assets = Map.get(body, "assets", [])

    Enum.find_value(keys, fn key ->
      assets
      |> Enum.find(&(Map.get(&1, "key") == key))
      |> case do
        %{"value" => value} when is_binary(value) -> value
        _ -> nil
      end
    end)
  end

  defp media_asset_url(_body, _keys), do: nil

  defp nested_name(body, path) do
    case get_in(body, path ++ ["name"]) do
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp fetch_value(map, key), do: Map.get(map, key)

  defp normalize_character_path(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_character_path(_value), do: ""

  defp normalize_realm_slug(realm_slug, _realm) when is_binary(realm_slug) and realm_slug != "" do
    realm_slug
  end

  defp normalize_realm_slug(_realm_slug, realm), do: slugify(realm)

  defp normalize_stat_lines(nil), do: []

  defp normalize_stat_lines(body) do
    [
      stat_line(
        :health,
        "Health",
        stat_number(body, [["health", "effective"], ["health", "max"]])
      ),
      stat_line(:primary, "Primary", primary_stat_value(body)),
      percentage_line(
        :crit,
        "Crit",
        stat_percentage(body, ["melee_crit", "spell_crit", "ranged_crit", "crit"])
      ),
      percentage_line(
        :haste,
        "Haste",
        stat_percentage(body, ["melee_haste", "spell_haste", "haste"])
      ),
      percentage_line(:mastery, "Mastery", stat_percentage(body, ["mastery"])),
      percentage_line(
        :versatility,
        "Vers",
        stat_percentage(body, ["versatility", "versatility_damage_done_bonus"])
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_achievement_summary(nil), do: %{points: nil, recent_count: nil}

  defp normalize_achievement_summary(body) do
    recent_count =
      body
      |> Map.get("recent_events", [])
      |> case do
        events when is_list(events) -> length(events)
        _ -> nil
      end

    %{
      points:
        first_present([
          body["total_points"],
          body["achievement_points"],
          get_in(body, ["summary", "points"])
        ]),
      recent_count: recent_count
    }
  end

  defp normalize_mythic_summary(nil),
    do: %{
      best_key: nil,
      best_dungeon: nil,
      dungeon_runs: [],
      run_count: 0,
      score: nil,
      vault_options: 0
    }

  defp normalize_mythic_summary(body) do
    best_runs =
      first_present([
        get_in(body, ["current_period", "best_runs"]),
        get_in(body, ["current_season", "best_runs"]),
        body["best_runs"]
      ])

    best_runs = if is_list(best_runs), do: best_runs, else: []

    best_run =
      Enum.max_by(best_runs, &first_present([&1["keystone_level"], &1["mythic_level"], 0]), fn ->
        nil
      end)

    %{
      best_key:
        first_present([
          best_run && best_run["keystone_level"],
          best_run && best_run["mythic_level"]
        ]),
      best_dungeon:
        first_present([
          best_run && get_in(best_run, ["dungeon", "name"]),
          best_run && get_in(best_run, ["dungeon", "short_name"])
        ]),
      dungeon_runs: normalize_dungeon_runs(best_runs),
      run_count: length(best_runs),
      score:
        first_present([
          get_in(body, ["current_mythic_rating", "rating"]),
          get_in(body, ["current_period", "mythic_rating", "rating"]),
          get_in(body, ["current_season", "mythic_rating", "rating"])
        ]),
      vault_options: MidnightSeason.vault_options(length(best_runs))
    }
  end

  defp normalize_dungeon_runs(best_runs) when is_list(best_runs) do
    best_runs
    |> Enum.reduce(%{}, fn run, acc ->
      name =
        first_present([
          get_in(run, ["dungeon", "name"]),
          get_in(run, ["dungeon", "short_name"])
        ])

      key_level = first_present([run["keystone_level"], run["mythic_level"]])

      if is_binary(name) and is_integer(key_level) do
        Map.update(acc, name, key_level, &max(&1, key_level))
      else
        acc
      end
    end)
    |> Enum.map(fn {name, key_level} -> %{name: name, key_level: key_level} end)
    |> Enum.sort_by(& &1.name)
  end

  defp normalize_dungeon_runs(_best_runs), do: []

  defp normalize_content_summary(mythic_summary, achievement_summary) do
    %{
      mythic_label:
        case mythic_summary.best_key do
          nil ->
            "No Mythic+ profile loaded yet"

          key ->
            "Best key: +#{key}" <>
              if mythic_summary.best_dungeon, do: " in #{mythic_summary.best_dungeon}", else: ""
        end,
      achievement_label:
        case achievement_summary.points do
          nil -> "Achievement points unavailable"
          points -> "#{points} achievement points tracked"
        end,
      run_count: mythic_summary.run_count || 0
    }
  end

  defp build_suggestions(item_level, mythic_summary, achievement_summary) do
    item_level = if is_integer(item_level), do: item_level, else: 0

    []
    |> maybe_add_suggestion(
      is_nil(mythic_summary.best_key),
      "Start a weekly Mythic+ track. A single completed key gives you a clean baseline for upgrades and vault planning."
    )
    |> maybe_add_suggestion(
      not is_nil(mythic_summary.best_key) and mythic_summary.best_key < 10,
      "Push at least one higher key this week. Your current best suggests there is still easy room to improve vault quality."
    )
    |> maybe_add_suggestion(
      item_level < MidnightSeason.focused_readiness(),
      "Prioritize efficient upgrade sources first: targeted dungeon keys and reliable raid-quality slots will move your floor faster than scattered farming on the squished item-level scale."
    )
    |> maybe_add_suggestion(
      item_level >= MidnightSeason.focused_readiness() and
        item_level < MidnightSeason.selective_readiness(),
      "Focus on targeted slots now. Your item level is high enough that trinkets, weapon slots, and vault choices matter more than broad farming."
    )
    |> maybe_add_suggestion(
      achievement_summary.points && achievement_summary.points < 15_000,
      "Keep one achievement goal active alongside gear progression so the cockpit stays useful for both power and completion tracking."
    )
    |> Enum.take(4)
  end

  defp stat_line(_key, _label, nil), do: nil

  defp stat_line(key, label, value) do
    %{key: key, label: label, raw_value: value, value: format_number(value)}
  end

  defp percentage_line(_key, _label, nil), do: nil

  defp percentage_line(key, label, value) do
    %{key: key, label: label, raw_value: value, value: format_percentage(value)}
  end

  defp primary_stat_value(body) do
    first_present([
      stat_number(body, [["strength", "effective"]]),
      stat_number(body, [["agility", "effective"]]),
      stat_number(body, [["intellect", "effective"]])
    ])
  end

  defp stat_percentage(body, keys) do
    Enum.find_value(keys, fn key ->
      first_present([
        safe_get_in(body, [key, "value"]),
        safe_get_in(body, [key, "rating_bonus"]),
        safe_get_in(body, [key, "effective"]),
        body[key]
      ])
    end)
  end

  defp stat_number(body, paths) do
    Enum.find_value(paths, fn path ->
      value = safe_get_in(body, path)
      if is_number(value), do: value, else: nil
    end)
  end

  defp first_present(values) do
    Enum.find(values, fn value -> not is_nil(value) end)
  end

  defp maybe_add_suggestion(list, true, suggestion), do: list ++ [suggestion]
  defp maybe_add_suggestion(list, false, _suggestion), do: list

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) when is_float(value) do
    value
    |> Float.round(1)
    |> :erlang.float_to_binary(decimals: 1)
  end

  defp format_number(value), do: to_string(value)

  defp format_percentage(value) when is_integer(value), do: "#{value}%"

  defp format_percentage(value) when is_float(value) do
    "#{Float.round(value, 2)}%"
  end

  defp format_percentage(value), do: "#{value}%"

  defp safe_get_in(data, []), do: data

  defp safe_get_in(data, [key | rest]) when is_map(data) do
    case Map.get(data, key) do
      nil -> nil
      value -> safe_get_in(value, rest)
    end
  end

  defp safe_get_in(_data, _path), do: nil
end
