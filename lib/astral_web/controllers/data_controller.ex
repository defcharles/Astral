defmodule AstralWeb.DataController do
  use AstralWeb, :controller
  require Logger

  def datarouter(conn, _params) do
    conn
    |> put_status(204)
    |> json(%{})
  end

  def versioncheck(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{
      type: "NO_UPDATE"
    })
  end

  def fortnite_game(conn, _params) do
    file_path = Path.join(["assets", "contentpages.json"])

    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, contentpages} ->
              json(conn, contentpages)

            {:error, _reason} ->
              conn
              |> put_status(:internal_server_error)
              |> json(%{error: "Invalid JSON format in contentpages.json"})
          end

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Error reading contentpages.json: #{inspect(reason)}"})
      end
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "contentpages.json not found"})
    end
  end

  def theater(conn, _params) do
    file_path = Path.join(["assets", "worldstw.json"])

    case File.read(file_path) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, json} ->
            conn
            |> put_status(200)
            |> json(json)

          {:error, _} ->
            conn
            |> put_status(500)
            |> json(%{error: "Failed to decode JSON"})
        end

      {:error, _} ->
        conn
        |> put_status(500)
        |> json(%{error: "Failed to read file"})
    end
  end

  def feedback(conn, %{"subject" => subject, "feedbackbody" => feedbackbody}) do
    Logger.info("Received feedback: Subject=#{subject}, Feedback Body=#{feedbackbody}")

    conn
    |> put_status(:ok)
    |> json(%{
      subject: subject,
      feedbackbody: feedbackbody
    })
  end

  def social_ban(conn, %{"accountId" => _account_id}) do
    conn
    |> put_status(200)
    |> json([])
  end

  def subscriptions(conn, %{"accountId" => _account_id}) do
    conn
    |> put_status(200)
    |> json([])
  end

  def privacy_settings(conn, %{"accountId" => _account_id}) do
    conn
    |> put_status(200)
    |> json([])
  end

  def content_controls(conn, %{"accountId" => _account_id}) do
    conn
    |> json([])
  end

  def lightswitch(conn, _params) do
    conn
    |> put_status(200)
    |> json([
      %{
        serviceInstanceId: "fortnite",
        status: "UP",
        message: "fortnite is up.",
        maintenanceUri: nil,
        overrideCatalogIds: ["a7f138b2e51945ffbfdacc1af0541053"],
        allowedActions: ["PLAY", "DOWNLOAD"],
        banned: false,
        launcherInfoDTO: %{
          appName: "Fortnite",
          catalogItemId: "4fe75bbc5a674f4f9b356b5c90567da5",
          namespace: "fn"
        }
      }
    ])
  end

  def enabled(conn, _params) do
    conn
    |> put_status(200)
    |> json([])
  end

  def socialban(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{
      bans: [],
      warnings: []
    })
  end

  def access(conn, _params) do
    conn
    |> put_status(204)
    |> json(%{})
  end

  def waitingroom(conn, _params) do
    conn
    |> put_status(:no_content)
    |> json([])
  end

  def tryplayonplatform(conn, _params) do
    conn
    |> put_status(200)
    |> put_resp_header("Content-Type", "text/plain")
    |> text("true")
  end
end
