defmodule AstralWeb.Router do
  use AstralWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AstralWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AstralWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/catalog/api/shared/bulk/offers", StorefrontController, :offers
    get "/socialban/api/public/v1/:accountId", DataController, :social_ban
    get "/presence/api/v1/_/:accountId/settings/subscriptions", DataController, :subscriptions
    get "/fortnite/api/game/v2/privacy/account/:accountId", DataController, :privacy_settings
    get "/content-controls/:accountId", DataController, :content_controls
  end

  scope "/account/api", AstralWeb do
    pipe_through :api

    post "/oauth/token", TokenController, :token
    delete "/oauth/sessions", DataController, :enabled
    delete "/oauth/sessions/*path", DataController, :enabled
    get "/oauth/verify", DataController, :enabled

    get "/public/account", AccountController, :public2
    get "/public/account/:accountId", AccountController, :public
    get "/public/account/:accountId/*path", AccountController, :externalauths

    get "/epicdomains/ssodomains", AccountController, :ssodomains
  end

  scope "/fortnite/api", AstralWeb do
    pipe_through :api
    
    post "/feedback/Bug", DataController, :feedback
    get "/game/v2/world/info", DataController, :theater
    get "/matchmaking/session/findPlayer/:accountId", MatchmakingController, :findplayer
    get "/game/v2/matchmakingservice/ticket/player/:accountId", DataController, :access
    post "/game/v2/tryPlayOnPlatform/account/:accountId", DataController, :tryplayonplatform
    get "/versioncheck", DataController, :versioncheck
    get "/v2/versioncheck", DataController, :versioncheck
    get "/v2/versioncheck/*path", DataController, :versioncheck
    get "/cloudstorage/user/*path", DataController, :access
    post "/game/v2/grant_access/*path", DataController, :access
    get "/game/v2/enabled_features", DataController, :access
    get "/receipts/v1/account/:accountId/receipts", StorefrontController, :receipts
    put "/cloudstorage/user/:accountId/ClientSettings.Sav", DataController, :access
    get "/game/v2/twitch/*path", DataController, :access
    get "/calendar/v1/timeline", TimelineController, :timeline
    get "/cloudstorage/system", DataController, :c_system
    get "/cloudstorage/system/config", DataController, :c_system
    get "/cloudstorage/system/:filename", DataController, :c_fetch
  end

  scope "/fortnite/api/game/v2", AstralWeb do
    pipe_through :api

    post "/profileToken/verify/:accountId", DataController, :enabled
    post "/profile/:accountId/client/RefreshExpeditions", ProfileController, :queryprofile
    post "/profile/:accountId/client/QueryProfile", ProfileController, :queryprofile
    post "/profile/:accountId/client/ClientQuestLogin", ProfileController, :queryprofile
    post "/profile/:accountId/client/EquipBattleRoyaleCustomization", ProfileController, :equipbattleroyalecustomization

    post "/profile/:accountId/client/IncrementNamedCounterStat", ProfileController, :queryprofile
    post "/profile/:accountId/client/SetMtxPlatform", ProfileController, :queryprofile
    post "/profile/:accountId/client/GetMcpTimeForLogin", ProfileController, :queryprofile
    get "/events/tournamentandhistory/:accountId/:region/*path", DataController, :enabled
  end

  scope "/fortnite/api/storefront/v2", AstralWeb do
    pipe_through :api
    get "/catalog", StorefrontController, :catalog
    get "/keychain", StorefrontController, :keychain
  end

  scope "/datarouter/api/v1/public", AstralWeb do
    pipe_through :api

    post "/data", DataController, :datarouter
  end

  scope "/lightswitch/api", AstralWeb do
    pipe_through :api

    get "/service/bulk/status", DataController, :lightswitch
  end

  scope "/socialban/api", AstralWeb do
    pipe_through :api

    get "/public/v1/:accountId/ban", DataController, :socialban
  end

  scope "/waitingroom/api", AstralWeb do
    get "/waitingroom", DataController, :waitingroom
  end

  scope "/content/api/pages", AstralWeb do
    pipe_through :api

    get "/fortnite-game", DataController, :fortnite_game
  end

  scope "/friends/api", AstralWeb do
    pipe_through :api

    get "/public/blocklist/:accountId", DataController, :enabled
    get "/public/friends/:accountId", DataController, :enabled
    get "/public/list/fortnite/:accountId/recentPlayers", DataController, :enabled
    get "/v1/:accountId/blocklist", DataController, :enabled
    get "/v1/:accountId/settings", DataController, :enabled
    get "/v1/:accountId/recent/fortnite", DataController, :enabled
  end

  # Other scopes may use custom stacks.
  # scope "/api", AstralWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:astral, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AstralWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
