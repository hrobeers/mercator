defmodule Mercator.Web.Router do
  use Mercator.Web.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Mercator.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/atlas", PageController, :atlas
    get "/atlas/:address", PageController, :atlas
  end

  scope "/api/unstable/block", Mercator.Web do
    pipe_through :api

    get "/info/:height", BlockController, :info
  end

  scope "/api/unstable/tx", Mercator.Web do
    pipe_through :api

    post "/push", TxController, :push
  end

  scope "/api/unstable/address", Mercator.Web do
    pipe_through :api

    get "/unspent/:address", AddressController, :unspent
    get "/balance/:address", AddressController, :balance
  end

  # Other scopes may use custom stacks.
  # scope "/api", Mercator.Web do
  #   pipe_through :api
  # end
end
