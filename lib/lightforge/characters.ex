defmodule Lightforge.Characters do
  @moduledoc """
  Persistence-facing context for stored character state.

  Encounter analytics from Warcraft Logs or WoWAnalyzer should live in separate
  logs/analysis contexts later rather than being packed into these snapshot tables.
  """

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Lightforge.Characters.Character
  alias Lightforge.Characters.CharacterSnapshot
  alias Lightforge.Characters.GearSnapshotItem
  alias Lightforge.Characters.Sync
  alias Lightforge.Repo

  def list_characters do
    Character
    |> order_by_character_identity()
    |> Repo.all()
  end

  def get_character!(id), do: Repo.get!(Character, id)

  def get_character(id) do
    Repo.get(Character, id)
  end

  def get_character_by_identity(region, realm_slug, name) do
    normalized_region = normalize_identity_segment(region)
    normalized_realm_slug = normalize_identity_segment(realm_slug)
    normalized_name = normalize_identity_segment(name)

    from(character in Character,
      where:
        character.region == ^normalized_region and
          character.realm_slug == ^normalized_realm_slug and
          fragment("lower(?)", character.name) == ^normalized_name
    )
    |> Repo.one()
  end

  def create_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  def upsert_character(attrs) do
    identity = character_identity_from_attrs(attrs)

    case get_character_by_identity(identity.region, identity.realm_slug, identity.name) do
      nil -> create_character(attrs)
      character -> update_character(character, attrs)
    end
  end

  def create_snapshot(character_or_id, attrs, gear_items_attrs \\ [])

  def create_snapshot(%Character{id: character_id}, attrs, gear_items_attrs) do
    attrs = Map.put(attrs, :character_id, character_id)

    Multi.new()
    |> Multi.insert(:snapshot, CharacterSnapshot.changeset(%CharacterSnapshot{}, attrs))
    |> insert_gear_items(gear_items_attrs)
    |> Repo.transaction()
    |> case do
      {:ok, %{snapshot: snapshot}} ->
        {:ok, Repo.preload(snapshot, :gear_snapshot_items)}

      {:error, _step, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  def create_snapshot(character_id, attrs, gear_items_attrs) when is_integer(character_id) do
    create_snapshot(%Character{id: character_id}, attrs, gear_items_attrs)
  end

  def list_snapshots(%Character{id: character_id}) do
    from(snapshot in CharacterSnapshot,
      where: snapshot.character_id == ^character_id,
      order_by: [desc: snapshot.captured_at, desc: snapshot.inserted_at],
      preload: [:gear_snapshot_items]
    )
    |> Repo.all()
  end

  def list_snapshots(character_id) when is_integer(character_id) do
    list_snapshots(%Character{id: character_id})
  end

  def get_latest_snapshot(%Character{id: character_id}) do
    from(snapshot in CharacterSnapshot,
      where: snapshot.character_id == ^character_id,
      order_by: [desc: snapshot.captured_at, desc: snapshot.inserted_at],
      limit: 1,
      preload: [:gear_snapshot_items]
    )
    |> Repo.one()
  end

  def get_latest_snapshot(character_id) when is_integer(character_id) do
    get_latest_snapshot(%Character{id: character_id})
  end

  def create_gear_snapshot_item(%CharacterSnapshot{id: snapshot_id}, attrs) do
    attrs = Map.put(attrs, :character_snapshot_id, snapshot_id)

    %GearSnapshotItem{}
    |> GearSnapshotItem.changeset(attrs)
    |> Repo.insert()
  end

  def create_gear_snapshot_item(snapshot_id, attrs) when is_integer(snapshot_id) do
    create_gear_snapshot_item(%CharacterSnapshot{id: snapshot_id}, attrs)
  end

  def sync_character_from_battle_net(token_data, attrs) do
    Sync.call(token_data, attrs)
  end

  defp character_identity_from_attrs(attrs) do
    %{
      region: fetch_attr!(attrs, :region),
      realm_slug: fetch_attr!(attrs, :realm_slug),
      name: fetch_attr!(attrs, :name)
    }
  end

  defp fetch_attr!(attrs, key) when is_atom(key) do
    Map.get(attrs, key) || Map.fetch!(attrs, Atom.to_string(key))
  end

  defp insert_gear_items(multi, []), do: multi

  defp insert_gear_items(multi, gear_items_attrs) when is_list(gear_items_attrs) do
    Enum.reduce(Enum.with_index(gear_items_attrs), multi, fn {item_attrs, index}, acc ->
      Multi.insert(acc, {:gear_snapshot_item, index}, fn %{snapshot: snapshot} ->
        item_attrs
        |> Map.new()
        |> Map.put(:character_snapshot_id, snapshot.id)
        |> then(&GearSnapshotItem.changeset(%GearSnapshotItem{}, &1))
      end)
    end)
  end

  defp normalize_identity_segment(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp order_by_character_identity(query) do
    from(character in query,
      order_by: [
        asc: character.region,
        asc: character.realm_slug,
        asc: character.name
      ]
    )
  end
end
