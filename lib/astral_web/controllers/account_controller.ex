defmodule AstralWeb.AccountController do
  use AstralWeb, :controller
  alias Astral.Repo
  alias Errors
  alias Astral.Database.Tables.{Accounts}

  def public(conn, %{"accountId" => account_id}) do
    case Accounts |> Repo.get_by(account_id: account_id) do
      nil ->
        error_details =
          Errors.account()
          |> Map.get(:account_not_found)

        conn
        |> put_status(:not_found)
        |> json(error_details)

      user ->
        conn
        |> put_status(:ok)
        |> json(%{
          id: user.account_id,
          displayName: user.username,
          externalAuths: %{}
        })
    end
  end

  def public2(conn, %{"accountId" => account_id}) do
    case Accounts |> Repo.get_by(account_id: account_id) do
      nil ->
        error_details =
          Errors.account()
          |> Map.get(:account_not_found)

        conn
        |> put_status(:not_found)
        |> json(error_details)

      user ->
        conn
        |> put_status(:ok)
        |> json([
          %{
            id: user.account_id,
            displayName: user.username,
            externalAuths: %{}
          }
        ])
    end
  end

  def externalauths(conn, _params) do
    conn
    |> put_status(:ok)
    |> json([])
  end

  def ssodomains(conn, _params) do
    conn
    |> put_status(200)
    |> json([
      "unrealengine.com",
      "unrealtournament.com",
      "fortnite.com",
      "epicgames.com"
    ])
  end

  def eula(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{})
  end
end
