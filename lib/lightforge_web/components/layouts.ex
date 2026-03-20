defmodule LightforgeWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LightforgeWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :battle_net_connected, :boolean, default: false
  attr :character_selector_enabled, :boolean, default: false
  attr :character_selector_open, :boolean, default: false
  attr :current_character_label, :string, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-[linear-gradient(180deg,#fffaf2_0%,#f5efe5_24%,#efe8dc_100%)] text-stone-900">
      <div class="pointer-events-none absolute inset-x-0 top-0 h-[34rem] bg-[radial-gradient(circle_at_top,rgba(245,158,11,0.2),transparent_42%),radial-gradient(circle_at_18%_24%,rgba(251,191,36,0.18),transparent_28%),radial-gradient(circle_at_88%_18%,rgba(120,53,15,0.12),transparent_24%)]" />

      <header class="relative z-10 px-4 pt-4 sm:px-6 lg:px-8">
        <div class="mx-auto flex max-w-7xl items-center justify-between gap-4 rounded-full border border-white/70 bg-white/75 px-5 py-3 shadow-[0_16px_48px_rgba(28,25,23,0.08)] backdrop-blur">
          <a href={~p"/"} class="flex items-center gap-3">
            <div class="flex size-10 items-center justify-center rounded-full bg-stone-950 text-amber-300">
              <.icon name="hero-fire" class="size-5" />
            </div>
            <div>
              <p class="text-[0.68rem] font-semibold uppercase tracking-[0.28em] text-stone-500">
                Lightforge
              </p>
              <p class="text-sm font-semibold text-stone-950">Workbench</p>
            </div>
          </a>

          <div class="hidden items-center gap-2 lg:flex">
            <.link navigate={~p"/"} class="forge-nav-link">
              Home
            </.link>
            <.link navigate={~p"/character"} class="forge-nav-link">
              Character
            </.link>
            <button
              :if={@character_selector_enabled}
              type="button"
              phx-click="open_selector"
              class={[
                "forge-nav-link inline-flex items-center gap-2 border border-transparent bg-transparent",
                @character_selector_open && "border-stone-300 bg-white/80 text-stone-950"
              ]}
            >
              <.icon name="hero-adjustments-horizontal" class="size-4" /> Character Selector
            </button>
          </div>

          <div class="flex items-center gap-3">
            <div
              :if={@current_character_label}
              class="hidden rounded-full border border-stone-200 bg-stone-50 px-3 py-2 text-xs font-medium text-stone-600 xl:block"
            >
              {@current_character_label}
            </div>

            <span class={[
              "hidden rounded-full px-3 py-2 text-xs font-semibold uppercase tracking-[0.24em] sm:inline-flex",
              @battle_net_connected && "bg-emerald-100 text-emerald-700",
              not @battle_net_connected && "bg-stone-200 text-stone-500"
            ]}>
              {if @battle_net_connected, do: "Connected", else: "Offline"}
            </span>

            <.theme_toggle />

            <%= if @battle_net_connected do %>
              <.link
                href={~p"/auth/logout"}
                method="delete"
                class="inline-flex items-center justify-center rounded-full border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-900 transition hover:border-stone-950"
              >
                Disconnect
              </.link>
            <% else %>
              <.link
                href={~p"/auth/bnet"}
                class="inline-flex items-center justify-center rounded-full bg-stone-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-stone-800"
              >
                Connect
              </.link>
            <% end %>
          </div>
        </div>
      </header>

      <main class="relative z-10 px-4 pb-16 pt-8 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-7xl">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
