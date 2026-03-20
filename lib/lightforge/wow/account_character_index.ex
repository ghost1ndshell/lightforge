defmodule Lightforge.Wow.AccountCharacterIndex do
  @moduledoc false

  alias Lightforge.BattleNet.Client
  alias Lightforge.Wow.AccountCharacter

  def fetch(token_data, region) do
    with {:ok, body} <- Client.get_account_profile_summary(token_data, region) do
      {:ok, normalize(body, region)}
    end
  end

  def normalize(body, region) do
    body
    |> Map.get("wow_accounts", [])
    |> Enum.flat_map(&Map.get(&1, "characters", []))
    |> Enum.map(&to_account_character(&1, region))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.ref)
    |> Enum.sort_by(fn character ->
      {-1 * (character.level || 0), String.downcase(character.realm),
       String.downcase(character.name)}
    end)
  end

  def options(characters) do
    Enum.map(characters, &{&1.label, &1.ref})
  end

  def index_by_ref(characters) do
    Map.new(characters, &{&1.ref, &1})
  end

  defp to_account_character(character, region) do
    with name when is_binary(name) and name != "" <- Map.get(character, "name"),
         realm_name when is_binary(realm_name) and realm_name != "" <-
           get_in(character, ["realm", "name"]) do
      realm_slug = get_in(character, ["realm", "slug"])
      level = Map.get(character, "level")
      character_class = get_in(character, ["playable_class", "name"])
      faction = get_in(character, ["faction", "name"])

      %AccountCharacter{
        character_class: character_class,
        faction: faction,
        id: Map.get(character, "id"),
        label: build_label(name, realm_name, level, character_class),
        level: level,
        name: name,
        realm: realm_name,
        realm_slug: realm_slug,
        ref: build_ref(region, realm_slug || realm_name, name),
        region: region
      }
    else
      _ -> nil
    end
  end

  defp build_label(name, realm_name, level, character_class) do
    extras =
      [level_label(level), character_class]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" · ")

    if extras == "" do
      "#{name} · #{realm_name}"
    else
      "#{name} · #{realm_name} · #{extras}"
    end
  end

  defp build_ref(region, realm_slug_or_name, name) do
    [region, to_string(realm_slug_or_name), name]
    |> Enum.join(":")
    |> Base.url_encode64(padding: false)
  end

  defp level_label(level) when is_integer(level), do: "Level #{level}"
  defp level_label(_level), do: nil
end
