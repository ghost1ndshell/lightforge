defmodule LightforgeWeb.Router do
  use LightforgeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LightforgeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/api/v1", LightforgeWeb.Api.V1 do
    pipe_through :api

    get "/me/bnet/status", BattleNetConnectionController, :status
    post "/bnet/connect/start", BattleNetConnectionController, :start
    get "/bnet/connect/callback", BattleNetConnectionController, :callback

    get "/characters", CharacterController, :index

    get "/characters/:region/:realm/:name/snapshots/latest", SnapshotController, :show
    get "/characters/:region/:realm/:name/gear", CharacterController, :gear
    get "/characters/:region/:realm/:name", CharacterController, :show
    post "/characters/:region/:realm/:name/sync", CharacterSyncController, :create

    post "/logs/reports/:code/import", LogReportController, :create
    get "/logs/reports/:code", LogReportController, :show

    post "/analysis/fights/:fight_id/import", AnalysisController, :create
    get "/analysis/fights/:fight_id", AnalysisController, :show_fight
    get "/analysis/fights/:fight_id/participants/:participant_id", AnalysisController, :show_participant
  end

  scope "/", LightforgeWeb do
    pipe_through :browser

    get "/auth/bnet", BattleNetAuthController, :request
    get "/auth/bnet/callback", BattleNetAuthController, :callback
    delete "/auth/logout", BattleNetAuthController, :logout
    get "/", PageController, :home
    live "/character", CharacterLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LightforgeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lightforge, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LightforgeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
