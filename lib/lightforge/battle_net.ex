defmodule Lightforge.BattleNet do
  @moduledoc false

  alias Lightforge.BattleNet.Config
  alias Lightforge.BattleNet.OAuth
  alias Lightforge.Wow.AccountCharacterIndex
  alias Lightforge.Wow.CharacterSnapshot

  def ready?, do: Config.ready?()
  def default_region, do: Config.default_region()
  def region_options, do: Config.region_options()

  def connected?(%{access_token: access_token, expires_at: expires_at})
      when is_binary(access_token) and access_token != "" and is_integer(expires_at) do
    System.system_time(:second) < expires_at
  end

  def connected?(_token_data), do: false

  def authorize_url(state), do: OAuth.authorize_url(state)
  def exchange_code(code), do: OAuth.exchange_code_for_token(code)

  def fetch_account_characters(token_data, region),
    do: AccountCharacterIndex.fetch(token_data, region)

  def fetch_character_snapshot(token_data, attrs), do: CharacterSnapshot.fetch(token_data, attrs)
end
