defmodule AstralWeb.StorefrontController do
  use AstralWeb, :controller

  def keychain(conn, _params) do
    case HTTPoison.get("https://api.nitestats.com/v1/epic/keychain") do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        conn
        |> put_status(200)
        |> json(Jason.decode!(body))

      {:error, %HTTPoison.Error{reason: reason}} ->
        conn
        |> put_status(500)
        |> json(%{error: "Failed to fetch data", reason: reason})
    end
  end

 def receipts(conn, %{"accountId" => _account_id}) do
    conn
    |> put_status(200)      
    |> json([])
  end
  
 def catalog(conn, _params) do
    file_path = Path.join(["assets", "catalog.json"])

    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
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
end