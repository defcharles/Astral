defmodule AstralWeb.TokenController do
  use AstralWeb, :controller
  alias Astral.Repo
  alias Astral.Database.Tables.{Accounts, Tokens}
  alias Joken
  alias Errors
  import Ecto.Query

  @token_expiry 28800
  @refresh_expiry 86400

  def token(conn, %{"grant_type" => grant_type} = params) do
    case grant_type do
      "password" ->
        case Repo.get_by(Accounts, email: params["username"]) do
          %Accounts{password: hashed_password} = user ->
            if params["password"] == hashed_password do
              claims = %{
                "sub" => user.email,
                "type" => "access",
                "exp" =>
                  DateTime.utc_now() |> DateTime.add(@token_expiry, :second) |> DateTime.to_unix()
              }

              access_token = Joken.generate_and_sign!(claims)

              refresh_claims = %{
                "sub" => user.account_id,
                "exp" =>
                  DateTime.utc_now()
                  |> DateTime.add(@refresh_expiry, :second)
                  |> DateTime.to_unix()
              }

              refresh_token = Joken.generate_and_sign!(refresh_claims)

              Repo.delete_all(
                from t in Tokens,
                  where: t.account_id == ^user.account_id and t.type in ["access", "refresh"]
              )

              with {:ok, _} <-
                     Repo.insert(%Tokens{
                       account_id: user.account_id,
                       token: access_token,
                       type: "access"
                     }),
                   {:ok, _} <-
                     Repo.insert(%Tokens{
                       account_id: user.account_id,
                       token: refresh_token,
                       type: "refresh"
                     }) do
                json(conn, %{
                  access_token: access_token,
                  expires_in: 28800,
                  expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(28800, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  token_type: "bearer",
                  refresh_token: refresh_token,
                  refresh_expires: 86400,
                  refresh_expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(86400, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  client_id: "client_id",
                  internal_client: true,
                  account_id: "#{user.account_id}",
                  client_service: "fortnite",
                  app: "fortnite",
                  in_app_id: "#{user.account_id}",
                  device_id: UUID.uuid4(),
                  displayName: user.username
                })
              else
                _error ->
                  error_details =
                    Errors.basic()
                    |> Map.get(:general_error)

                  conn
                  |> put_status(:internal_server_error)
                  |> json(error_details)
              end
            else
              error_details =
                Errors.account()
                |> Map.get(:invalid_credentials)

              conn
              |> put_status(:not_found)
              |> json(error_details)
            end

          nil ->
            error_details =
              Errors.account()
              |> Map.get(:account_not_found)

            conn
            |> put_status(:not_found)
            |> json(error_details)
        end

      "client_credentials" ->
        claims = %{
          "sub" => params["client_id"],
          "type" => "client_credentials",
          "exp" =>
            DateTime.utc_now() |> DateTime.add(@token_expiry, :second) |> DateTime.to_unix()
        }

        access_token = Joken.generate_and_sign!(claims)

        json(conn, %{
          access_token: access_token,
          expires_in: @token_expiry,
          expires_at:
            DateTime.utc_now()
            |> DateTime.add(@token_expiry, :second)
            |> DateTime.truncate(:second)
            |> DateTime.to_iso8601(),
          token_type: "bearer",
          client_id: "client_id",
          internal_client: true,
          client_service: "fortnite",
          device_id: UUID.uuid4()
        })

      "refresh_token" ->
        case Repo.all(
               from t in Tokens,
                 where: t.token == ^params["refresh_token"] and t.type == "refresh"
             ) do
          [token | _] ->
            case Repo.get(Accounts, token.account_id) do
              %Accounts{} = user ->
                access_claims = %{
                  "sub" => user.email,
                  "type" => "access",
                  "exp" =>
                    DateTime.utc_now()
                    |> DateTime.add(@token_expiry, :second)
                    |> DateTime.to_unix()
                }

                access_token = Joken.generate_and_sign!(access_claims)

                refresh_claims = %{
                  "sub" => user.account_id,
                  "exp" =>
                    DateTime.utc_now()
                    |> DateTime.add(@refresh_expiry, :second)
                    |> DateTime.to_unix()
                }

                refresh_token = Joken.generate_and_sign!(refresh_claims)

                json(conn, %{
                  access_token: access_token,
                  expires_in: 28800,
                  expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(28800, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  token_type: "bearer",
                  refresh_token: refresh_token,
                  refresh_expires: 86400,
                  refresh_expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(86400, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  client_id: "client_id",
                  internal_client: true,
                  account_id: "#{user.account_id}",
                  client_service: "fortnite",
                  app: "fortnite",
                  in_app_id: "#{user.account_id}",
                  device_id: UUID.uuid4(),
                  displayName: user.username
                })

                Repo.delete(token)

              _ ->
                error_details =
                  Errors.account()
                  |> Map.get(:account_not_found)

                conn
                |> put_status(:not_found)
                |> json(error_details)
            end

          [] ->
            error_details =
              Errors.authentication().oauth()
              |> Map.get(:invalid_refresh)

            conn
            |> put_status(:not_found)
            |> json(error_details)

          _ ->
            error_details =
              Errors.authentication().oauth()
              |> Map.get(:invalid_refresh)

            conn
            |> put_status(:not_found)
            |> json(error_details)
        end

        case Repo.get_by(Tokens, token: params["refresh_token"]) do
          %Tokens{account_id: account_id} ->
            case Repo.get(Accounts, account_id) do
              %Accounts{} = user ->
                access_claims = %{
                  "sub" => user.email,
                  "type" => "access",
                  "exp" =>
                    DateTime.utc_now()
                    |> DateTime.add(@token_expiry, :second)
                    |> DateTime.to_unix()
                }

                access_token = Joken.generate_and_sign!(access_claims)

                refresh_claims = %{
                  "sub" => user.account_id,
                  "exp" =>
                    DateTime.utc_now()
                    |> DateTime.add(@refresh_expiry, :second)
                    |> DateTime.to_unix()
                }

                refresh_token = Joken.generate_and_sign!(refresh_claims)

                json(conn, %{
                  access_token: access_token,
                  expires_in: 28800,
                  expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(28800, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  token_type: "bearer",
                  refresh_token: refresh_token,
                  refresh_expires: 86400,
                  refresh_expires_at:
                    DateTime.utc_now()
                    |> DateTime.add(86400, :second)
                    |> DateTime.truncate(:second)
                    |> DateTime.to_iso8601(),
                  client_id: "client_id",
                  internal_client: true,
                  account_id: "#{user.account_id}",
                  client_service: "fortnite",
                  app: "fortnite",
                  in_app_id: "#{user.account_id}",
                  device_id: UUID.uuid4(),
                  displayName: user.username
                })

                Repo.delete(%Tokens{token: params["refresh_token"], account_id: account_id})

              _ ->
                error_details =
                  Errors.account()
                  |> Map.get(:account_not_found)

                conn
                |> put_status(:not_found)
                |> json(error_details)
            end

          _ ->
            error_details =
              Errors.authentication().oauth()
              |> Map.get(:invalid_refresh)

            conn
            |> put_status(:not_found)
            |> json(error_details)
        end

      "device_auth" ->
        case Repo.get(Accounts, params["account_id"]) do
          %Accounts{password: hashed_password} = user ->
            if params["secret"] == hashed_password do
              claims = %{
                "sub" => user.email,
                "type" => "access",
                "exp" =>
                  DateTime.utc_now() |> DateTime.add(@token_expiry, :second) |> DateTime.to_unix()
              }

              access_token = Joken.generate_and_sign!(claims)

              json(conn, %{
                access_token: access_token,
                expires_in: @token_expiry,
                expires_at:
                  DateTime.utc_now()
                  |> DateTime.add(@token_expiry, :second)
                  |> DateTime.to_iso8601(),
                token_type: "bearer",
                client_id: "client_id",
                internal_client: true,
                client_service: "fortnite",
                device_id: UUID.uuid4(),
                displayName: user.username
              })
            else
              error_details =
                Errors.authentication().oauth()
                |> Map.get(:invalid_refresh)

              conn
              |> put_status(:not_found)
              |> json(error_details)
            end

          _ ->
            error_details =
              Errors.account()
              |> Map.get(:account_not_found)

            conn
            |> put_status(:not_found)
            |> json(error_details)
        end

      _ ->
        error_details =
          Errors.authentication()
          |> Map.get(:wrong_grant_type)

        conn
        |> put_status(:bad_request)
        |> json(error_details)
    end
  end
end
