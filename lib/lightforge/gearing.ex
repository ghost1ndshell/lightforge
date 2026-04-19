defmodule Lightforge.Gearing do
  @moduledoc false

  alias Lightforge.Characters
  alias Lightforge.Gearing.Recommendation

  def get_character_plan(region, realm, name, mode) do
    with character when not is_nil(character) <-
           Characters.get_character_by_identity(region, realm, name),
         snapshot when not is_nil(snapshot) <- Characters.get_latest_snapshot(character) do
      {:ok, Recommendation.build(character, snapshot, mode)}
    else
      nil -> {:error, :not_found}
    end
  end
end
