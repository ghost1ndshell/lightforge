defmodule LightforgeWeb.CharacterLive do
  use LightforgeWeb, :live_view

  alias Lightforge.BattleNet
  alias Lightforge.Wow.AccountCharacter
  alias Lightforge.Wow.AccountCharacterIndex
  alias LightforgeWeb.BattleNetSession

  @impl true
  def mount(_params, session, socket) do
    token_data = BattleNetSession.token_from_session(session)

    socket =
      socket
      |> assign_new(:current_scope, fn -> nil end)
      |> assign(
        account_characters: [],
        account_characters_by_ref: %{},
        account_characters_error: nil,
        account_characters_loading: false,
        account_characters_region: nil,
        battle_net_connected: BattleNet.connected?(token_data),
        battle_net_ready: BattleNet.ready?(),
        character_form: to_form(default_character_params(), as: :character),
        current_character_label: nil,
        error_message: nil,
        loading: false,
        page_title: "Character Cockpit",
        region_options: BattleNet.region_options(),
        show_selector: false,
        snapshot: nil,
        token_data: token_data
      )
      |> maybe_schedule_account_characters()

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"character" => params}, socket) do
    params =
      params
      |> maybe_reset_selected_character(socket.assigns.account_characters_region)
      |> maybe_apply_selected_character(socket.assigns.account_characters_by_ref)
      |> merge_character_defaults()

    socket =
      socket
      |> assign(:character_form, to_form(params, as: :character))
      |> maybe_schedule_account_characters(params["region"])

    {:noreply, socket}
  end

  def handle_event("load_character", %{"character" => params}, socket) do
    params =
      params
      |> maybe_reset_selected_character(socket.assigns.account_characters_region)
      |> maybe_apply_selected_character(socket.assigns.account_characters_by_ref)
      |> merge_character_defaults()

    form = to_form(params, as: :character)

    cond do
      blank?(params["character_ref"]) ->
        {:noreply,
         socket
         |> assign(
           character_form: form,
           error_message: "Select one linked character before refreshing the cockpit."
         )}

      not socket.assigns.battle_net_ready ->
        {:noreply,
         socket
         |> assign(
           character_form: form,
           error_message: "Battle.net credentials are not configured yet."
         )}

      not socket.assigns.battle_net_connected ->
        {:noreply,
         socket
         |> assign(
           character_form: form,
           error_message: "Connect Battle.net before loading a character."
         )}

      true ->
        send(self(), {:load_character, params})

        {:noreply,
         socket
         |> assign(
           character_form: form,
           error_message: nil,
           loading: true
         )}
    end
  end

  def handle_event("open_selector", _params, socket) do
    {:noreply, assign(socket, show_selector: true)}
  end

  def handle_event("close_selector", _params, socket) do
    {:noreply, assign(socket, show_selector: false)}
  end

  @impl true
  def handle_info({:load_account_characters, region}, socket) do
    case BattleNet.fetch_account_characters(socket.assigns.token_data, region) do
      {:ok, account_characters} ->
        {:noreply,
         assign(socket,
           account_characters: account_characters,
           account_characters_by_ref: AccountCharacterIndex.index_by_ref(account_characters),
           account_characters_error:
             if(account_characters == [],
               do: "No linked WoW characters were returned for this region.",
               else: nil
             ),
           account_characters_loading: false,
           account_characters_region: region
         )}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(
           account_characters: [],
           account_characters_by_ref: %{},
           account_characters_error:
             "Your Battle.net session expired. Connect again to refresh your characters.",
           account_characters_loading: false,
           account_characters_region: nil,
           battle_net_connected: false,
           token_data: nil
         )
         |> put_flash(:error, "Battle.net session expired.")}

      {:error, message} ->
        {:noreply,
         assign(socket,
           account_characters: [],
           account_characters_by_ref: %{},
           account_characters_error: message,
           account_characters_loading: false,
           account_characters_region: nil
         )}
    end
  end

  @impl true
  def handle_info({:load_character, params}, socket) do
    case BattleNet.fetch_character_snapshot(socket.assigns.token_data, params) do
      {:ok, snapshot} ->
        {:noreply,
         socket
         |> assign(
           current_character_label: "#{snapshot.name} · #{snapshot.realm}",
           error_message: nil,
           loading: false,
           show_selector: false,
           snapshot: snapshot
         )
         |> put_flash(:info, "Loaded #{snapshot.name} on #{snapshot.realm}.")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(
           battle_net_connected: false,
           error_message: "Your Battle.net session expired. Connect again to continue.",
           loading: false,
           snapshot: nil,
           token_data: nil
         )
         |> put_flash(:error, "Battle.net session expired.")}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(
           error_message: message,
           loading: false
         )
         |> put_flash(:error, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      battle_net_connected={@battle_net_connected}
      character_selector_enabled={true}
      character_selector_open={@show_selector}
      current_character_label={@current_character_label}
    >
      <section class="forge-shell forge-character-page space-y-6">
        <div class={[
          "space-y-6 transition duration-200",
          @show_selector && "pointer-events-none select-none blur-[3px] saturate-50"
        ]}>
          <%= if @snapshot do %>
            <section class="space-y-3">
              <div class="flex items-center justify-between gap-4 px-1">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Progression
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Current stage
                  </h2>
                </div>
              </div>

              <div class="forge-progression-rail forge-panel rounded-[1.75rem] p-4 sm:p-5">
                <div class="forge-progression-rail-inner">
                  <div class="forge-progression-rail-tracks">
                    <%= for track <- (@snapshot.progression_plan && @snapshot.progression_plan.tracks) || [] do %>
                      <article class="forge-progression-rail-track">
                        <p class="forge-progression-track-label">{track.label}</p>

                        <div class={progression_grid_classes(track.key)}>
                          <%= for badge <- track.badges do %>
                            <article class={progression_badge_classes(badge.state)}>
                              <p class="forge-progression-badge-label">{badge.label}</p>
                              <span class="forge-progression-badge-value">{badge.value}</span>
                            </article>
                          <% end %>
                        </div>
                      </article>
                    <% end %>
                  </div>
                </div>
              </div>
            </section>

            <section class="space-y-3">
              <div class="flex items-center justify-between gap-4 px-1">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Workbench
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Current vs target stats
                  </h2>
                </div>
                <%= if @snapshot.stat_goal_plan do %>
                  <a
                    href={@snapshot.stat_goal_plan.source_url}
                    target="_blank"
                    rel="noreferrer"
                    class="forge-source-pill"
                  >
                    {@snapshot.stat_goal_plan.source_name}
                  </a>
                <% else %>
                  <span class="forge-source-pill">
                    Coming soon
                  </span>
                <% end %>
              </div>

              <section class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                <div class="grid gap-8 xl:grid-cols-[minmax(0,0.88fr)_1px_minmax(0,1.12fr)] xl:items-start">
                  <div class="space-y-6">
                    <div class="flex items-center gap-4">
                      <div class="forge-avatar-shell">
                        <img
                          :if={@snapshot.avatar_url}
                          id="character-avatar"
                          src={@snapshot.avatar_url}
                          alt={"#{@snapshot.name} avatar"}
                          phx-hook="MediaReveal"
                          class="forge-avatar"
                        />
                        <div :if={is_nil(@snapshot.avatar_url)} class="forge-avatar-fallback">
                          <.icon name="hero-user" class="size-7 text-stone-400" />
                        </div>
                      </div>

                      <div class="space-y-2">
                        <h1 class="text-3xl font-semibold tracking-[-0.04em] text-stone-950">
                          {@snapshot.name}
                        </h1>
                        <p class="text-sm leading-6 text-stone-600">
                          {@snapshot.realm} · {String.upcase(@snapshot.region)} · {@snapshot.character_class}
                          <span :if={@snapshot.active_spec}>· {@snapshot.active_spec}</span>
                        </p>
                      </div>
                    </div>

                    <div class="grid gap-3 sm:grid-cols-3">
                      <div class="forge-stat-card">
                        <span class="forge-stat-label">Item Level</span>
                        <span class="forge-stat-value">{@snapshot.equipped_item_level || "?"}</span>
                      </div>
                      <div class="forge-stat-card">
                        <span class="forge-stat-label">Best Key</span>
                        <span class="forge-stat-value">
                          {best_key_label(@snapshot.mythic_summary)}
                        </span>
                      </div>
                      <div class="forge-stat-card">
                        <span class="forge-stat-label">Guild</span>
                        <span class="forge-stat-value">{guild_label(@snapshot.guild)}</span>
                      </div>
                    </div>
                  </div>

                  <div class="forge-top-divider" aria-hidden="true"></div>

                  <div>
                    <%= if @snapshot.stat_goal_plan do %>
                      <div class="grid gap-3">
                        <%= for goal <- @snapshot.stat_goal_plan.goals do %>
                          <article
                            class="forge-stat-goal-row"
                            style={stat_goal_color_style(goal.key)}
                          >
                            <div class="min-w-0">
                              <p class="text-sm font-semibold text-stone-950">{goal.label}</p>
                            </div>

                            <div class="forge-stat-goal-meter">
                              <div class="forge-stat-goal-track">
                                <div
                                  class="forge-stat-goal-fill"
                                  style={"width: #{goal.progress}%"}
                                >
                                  <span class="forge-stat-goal-fill-value">
                                    {goal.current_display}
                                  </span>
                                </div>
                                <span class="forge-stat-goal-target-value">
                                  {goal.target_display}
                                </span>
                              </div>
                            </div>
                          </article>
                        <% end %>
                      </div>
                    <% else %>
                      <div class="rounded-[1.25rem] border border-dashed border-stone-300 bg-white/60 px-4 py-5 text-sm leading-6 text-stone-600">
                        Spec-specific stat goal bars are not wired for this character yet.
                      </div>
                    <% end %>
                  </div>
                </div>
              </section>
            </section>

            <section class="grid gap-6 2xl:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
              <section class="space-y-3">
                <div class="flex items-center justify-between gap-4 px-1">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                      Gear Targets
                    </p>
                    <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                      What to chase next
                    </h2>
                  </div>
                  <%= if @snapshot.gear_plan && @snapshot.gear_plan.guide_url do %>
                    <a
                      href={@snapshot.gear_plan.guide_url}
                      target="_blank"
                      rel="noreferrer"
                      class="forge-source-pill"
                    >
                      {@snapshot.gear_plan.guide_name}
                    </a>
                  <% else %>
                    <span class="forge-source-pill">
                      Coming soon
                    </span>
                  <% end %>
                </div>

                <section class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                  <%= if @snapshot.gear_plan do %>
                    <div class="rounded-[1.2rem] border border-amber-200/70 bg-amber-50/80 px-4 py-3">
                      <p class="text-sm leading-6 text-amber-950">
                        {@snapshot.gear_plan.note}
                      </p>
                    </div>

                    <div class="mt-6 rounded-[1.25rem] border border-dashed border-stone-300 bg-white/60 px-4 py-5 text-sm leading-6 text-stone-600">
                      Midnight-targeted upgrade paths are coming soon.
                    </div>
                  <% else %>
                    <div class="rounded-[1.25rem] border border-dashed border-stone-300 bg-white/60 px-4 py-5 text-sm leading-6 text-stone-600">
                      Curated gear targets are not loaded for this spec yet. The next pass should add your spec to the planner data.
                    </div>
                  <% end %>
                </section>
              </section>

              <section class="space-y-3">
                <div class="px-1">
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Current Content
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Midnight activity state
                  </h2>
                </div>

                <section class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                  <div class="space-y-3">
                    <%= for row <- (@snapshot.content_plan && @snapshot.content_plan.rows) || [] do %>
                      <div class="forge-row-card">
                        <div class="space-y-1">
                          <span class="forge-row-label">{row.label}</span>
                          <p :if={row.detail} class="text-xs leading-5 text-stone-500">
                            {row.detail}
                          </p>
                        </div>
                        <span class="forge-row-value">{row.value}</span>
                      </div>
                    <% end %>
                  </div>
                </section>
              </section>
            </section>

            <section class="grid gap-6 xl:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">
              <section class="space-y-3">
                <div class="px-1">
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Suggested Content
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    What to do this week
                  </h2>
                </div>

                <section class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                  <div class="space-y-3">
                    <%= for {action, index} <- Enum.with_index((@snapshot.content_plan && @snapshot.content_plan.actions) || [], 1) do %>
                      <article class="forge-suggestion-card">
                        <span class="forge-suggestion-index">{index}</span>
                        <div class="space-y-1">
                          <p class="text-sm font-semibold text-stone-950">{action.title}</p>
                          <p class="text-sm leading-6 text-stone-700">{action.detail}</p>
                        </div>
                      </article>
                    <% end %>
                  </div>
                </section>
              </section>

              <section class="space-y-3">
                <div class="px-1">
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Tracked Achievements
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Personal progression watch
                  </h2>
                </div>

                <section class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                  <div class="grid gap-3">
                    <%= for goal <- @snapshot.tracked_achievements || [] do %>
                      <article class="forge-suggestion-card">
                        <span class="forge-suggestion-index">{goal.status}</span>
                        <div class="space-y-1">
                          <p class="text-sm font-semibold text-stone-950">{goal.title}</p>
                          <p class="text-sm leading-6 text-stone-700">{goal.detail}</p>
                          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-stone-500">
                            Next: {goal.next_action}
                          </p>
                        </div>
                      </article>
                    <% end %>
                  </div>
                </section>
              </section>
            </section>

            <section class="space-y-3">
              <div class="flex items-center justify-between gap-4 px-1">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.28em] text-stone-500">
                    Gear Details
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Full equipped items
                  </h2>
                </div>
              </div>

              <details class="forge-panel rounded-[1.75rem] p-5 sm:p-6">
                <summary class="flex cursor-pointer list-none items-center justify-end gap-4">
                  <span class="forge-source-pill">
                    Expand
                  </span>
                </summary>

                <div class="mt-6 overflow-hidden rounded-[1.25rem] border border-stone-200">
                  <table class="min-w-full divide-y divide-stone-200 text-sm">
                    <thead class="bg-stone-50 text-left text-xs font-semibold uppercase tracking-[0.2em] text-stone-500">
                      <tr>
                        <th class="px-4 py-3">Slot</th>
                        <th class="px-4 py-3">Item</th>
                        <th class="px-4 py-3">Quality</th>
                        <th class="px-4 py-3">ilvl</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-stone-200 bg-white/70">
                      <%= for item <- @snapshot.items do %>
                        <tr>
                          <td class="px-4 py-3 font-medium text-stone-700">{item.slot}</td>
                          <td class="px-4 py-3 text-stone-950">{item.name}</td>
                          <td class="px-4 py-3 text-stone-600">{item.quality}</td>
                          <td class="px-4 py-3 text-stone-700">{item.item_level || "?"}</td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </details>
            </section>
          <% else %>
            <section class="forge-empty-state rounded-[1.75rem] border border-dashed border-stone-300 px-6 py-12 text-center">
              <div class="mx-auto flex max-w-xl flex-col items-center space-y-4">
                <div class="flex size-16 items-center justify-center rounded-full bg-amber-100 text-amber-700">
                  <.icon name="hero-sparkles" class="size-8" />
                </div>
                <div class="space-y-2">
                  <h2 class="text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                    Character dashboard ready
                  </h2>
                  <p class="text-sm leading-6 text-stone-600">
                    Connect Battle.net and load one linked character to see current stats, content status, and next-action suggestions.
                  </p>
                </div>
              </div>
            </section>
          <% end %>
        </div>

        <%= if @show_selector do %>
          <div class="fixed inset-0 z-40">
            <button
              type="button"
              phx-click="close_selector"
              class="forge-selector-backdrop absolute inset-0"
              aria-label="Close character selector"
            />

            <div class="relative flex min-h-full items-start justify-center px-4 pb-6 pt-28 sm:px-6">
              <div class="forge-selector-modal w-full max-w-2xl p-5 sm:p-6">
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.3em] text-stone-500">
                      Character Selector
                    </p>
                    <h2 class="mt-2 text-2xl font-semibold tracking-[-0.03em] text-stone-950">
                      Focus the cockpit
                    </h2>
                    <p class="mt-2 text-sm leading-6 text-stone-600">
                      Pick one linked character and refresh the snapshot. The selector closes automatically once the character loads.
                    </p>
                  </div>

                  <button
                    type="button"
                    phx-click="close_selector"
                    class="forge-selector-close inline-flex size-10 items-center justify-center rounded-full"
                    aria-label="Close"
                  >
                    <.icon name="hero-x-mark" class="size-5" />
                  </button>
                </div>

                <%= if not @battle_net_ready do %>
                  <p class="mt-5 rounded-2xl border border-amber-300/70 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-900">
                    Set `BATTLENET_CLIENT_ID`, `BATTLENET_CLIENT_SECRET`, and `BATTLENET_REDIRECT_URI`
                    before starting the auth flow.
                  </p>
                <% end %>

                <.form
                  id="character-form"
                  for={@character_form}
                  phx-change="validate"
                  phx-submit="load_character"
                  class="mt-6 space-y-4"
                >
                  <div class="grid gap-4 sm:grid-cols-[12rem_minmax(0,1fr)]">
                    <.input
                      field={@character_form[:region]}
                      type="select"
                      label="Region"
                      options={@region_options}
                      class="forge-select"
                      error_class="border-red-500"
                    />

                    <div class="space-y-3">
                      <div class="flex items-center justify-between gap-3">
                        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                          Linked account
                        </p>
                        <span
                          :if={@account_characters_loading}
                          class="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.2em] text-stone-500"
                        >
                          <.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
                          Refreshing
                        </span>
                      </div>

                      <.input
                        field={@character_form[:character_ref]}
                        type="select"
                        label="Linked character"
                        options={AccountCharacterIndex.options(@account_characters)}
                        prompt="Select from linked account"
                        class="forge-select"
                        error_class="border-red-500"
                      />

                      <p :if={@account_characters_error} class="text-sm leading-6 text-amber-800">
                        {@account_characters_error}
                      </p>
                    </div>
                  </div>

                  <div class="flex flex-col gap-3 sm:flex-row sm:justify-end">
                    <.button
                      :if={not @battle_net_connected}
                      href={~p"/auth/bnet"}
                      class="inline-flex items-center justify-center rounded-full bg-stone-950 px-5 py-3 text-sm font-semibold text-white transition hover:bg-stone-800"
                    >
                      Connect Battle.net
                    </.button>

                    <button
                      type="button"
                      phx-click="close_selector"
                      class="inline-flex items-center justify-center rounded-full border border-stone-300 bg-white px-5 py-3 text-sm font-semibold text-stone-900 transition hover:border-stone-950"
                    >
                      Cancel
                    </button>

                    <button
                      type="submit"
                      class="inline-flex items-center justify-center gap-2 rounded-full bg-amber-500 px-5 py-3 text-sm font-semibold text-stone-950 transition hover:bg-amber-400 disabled:cursor-not-allowed disabled:opacity-50"
                      disabled={
                        not @battle_net_connected or @loading or
                          blank?(@character_form.params["character_ref"])
                      }
                    >
                      <.icon
                        :if={@loading}
                        name="hero-arrow-path"
                        class="size-4 motion-safe:animate-spin"
                      />
                      {if @loading, do: "Refreshing snapshot...", else: "Load character"}
                    </button>
                  </div>
                </.form>

                <%= if @error_message do %>
                  <p class="mt-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700">
                    {@error_message}
                  </p>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  defp best_key_label(%{best_key: nil}), do: "No key yet"
  defp best_key_label(%{best_key: key}), do: "+#{key}"
  defp best_key_label(_), do: "Unknown"

  defp guild_label(nil), do: "No guild"
  defp guild_label(""), do: "No guild"
  defp guild_label(guild), do: guild

  defp progression_badge_classes(:high) do
    [
      "forge-progression-badge",
      "forge-progression-badge-high"
    ]
  end

  defp progression_badge_classes(:active) do
    [
      "forge-progression-badge",
      "forge-progression-badge-active"
    ]
  end

  defp progression_badge_classes(_state) do
    [
      "forge-progression-badge",
      "forge-progression-badge-pending"
    ]
  end

  defp progression_grid_classes(:mythic_plus) do
    [
      "forge-progression-grid",
      "forge-progression-grid-mythic"
    ]
  end

  defp progression_grid_classes(:raid) do
    [
      "forge-progression-grid",
      "forge-progression-grid-raid"
    ]
  end

  defp progression_grid_classes(_key) do
    [
      "forge-progression-grid"
    ]
  end

  defp default_character_params do
    %{
      "character_ref" => "",
      "region" => BattleNet.default_region()
    }
  end

  defp merge_character_defaults(params) do
    Map.merge(default_character_params(), params)
  end

  defp maybe_apply_selected_character(params, account_characters_by_ref) do
    case Map.get(params, "character_ref") do
      ref when is_binary(ref) and ref != "" ->
        case Map.get(account_characters_by_ref, ref) do
          %AccountCharacter{} = character ->
            params
            |> Map.put("name", character.name)
            |> Map.put("realm", character.realm)
            |> Map.put("realm_slug", character.realm_slug || "")
            |> Map.put("region", character.region)

          _ ->
            params
        end

      _ ->
        params
    end
  end

  defp maybe_reset_selected_character(params, nil), do: params

  defp maybe_reset_selected_character(params, account_characters_region) do
    if Map.get(params, "region") == account_characters_region do
      params
    else
      Map.put(params, "character_ref", "")
    end
  end

  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(value), do: is_nil(value)

  defp stat_goal_color_style(:haste), do: "--forge-goal-rgb: 245 158 11;"
  defp stat_goal_color_style(:crit), do: "--forge-goal-rgb: 244 63 94;"
  defp stat_goal_color_style(:versatility), do: "--forge-goal-rgb: 16 185 129;"
  defp stat_goal_color_style(:mastery), do: "--forge-goal-rgb: 59 130 246;"
  defp stat_goal_color_style(_key), do: "--forge-goal-rgb: 120 113 108;"

  defp maybe_schedule_account_characters(socket),
    do: maybe_schedule_account_characters(socket, nil)

  defp maybe_schedule_account_characters(socket, requested_region) do
    region =
      requested_region || socket.assigns.character_form.params["region"] ||
        BattleNet.default_region()

    cond do
      not connected?(socket) ->
        socket

      not socket.assigns.battle_net_connected ->
        socket

      socket.assigns.account_characters_loading ->
        socket

      socket.assigns.account_characters != [] and
          socket.assigns.account_characters_region == region ->
        socket

      true ->
        send(self(), {:load_account_characters, region})
        assign(socket, account_characters_loading: true, account_characters_error: nil)
    end
  end
end
