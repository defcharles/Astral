defmodule AstralWeb.ProfileController do
  use AstralWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Astral.Repo
  alias Astral.Database.Tables.{Profiles, Items}
  alias Errors
  import Logger

  def queryprofile(conn, %{"accountId" => account_id}) do
    profile_id = Map.get(conn.query_params, "profileId")

    profile = Repo.get_by(Profiles, account_id: account_id, type: profile_id)

    if profile do
      updated_profile =
        profile
        |> Ecto.Changeset.change(revision: profile.revision + 1)
        |> Repo.update!()

      items =
        from(i in Items,
          where:
            i.account_id == ^profile.account_id and i.profile_id == ^profile_id and
              i.is_stat == false
        )
        |> Repo.all()
        |> Enum.reduce(%{}, fn item, acc ->
          item_map = %{
            "attributes" => item.value,
            "templateId" =>
              if String.contains?(item.template_id, "loadout") do
                "CosmeticLocker:cosmeticlocker_athena"
              else
                item.template_id
              end
          }

          item_map =
            if item.template_id != "Currency:MtxPurchased" do
              if item.quantity != 0 do
                Map.put_new(item_map, "quantity", item.quantity)
              else
                item_map
              end
            else
              Map.put_new(item_map, "quantity", item.quantity)
            end

          Map.put(acc, item.template_id, item_map)
        end)

      stats =
        from(i in Items,
          where:
            i.profile_id == ^profile_id and i.account_id == ^profile.account_id and
              i.is_stat == true,
          select: %{template_id: i.template_id, value: i.value}
        )
        |> Repo.all()
        |> Enum.into(%{}, fn %{template_id: template_id, value: value} ->
          {template_id, format_value(value)}
        end)

      response = %{
        "profileRevision" => updated_profile.revision,
        "profileId" => profile_id,
        "profileChangesBaseRevision" => updated_profile.revision,
        "profileChanges" => [
          %{
            "changeType" => "fullProfileUpdate",
            "profile" => %{
              "profileId" => profile_id,
              "created" =>
                DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
              "updated" =>
                DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
              "rvn" => updated_profile.revision,
              "wipeNumber" => 1,
              "accountId" => updated_profile.account_id,
              "version" => "Astral",
              "items" => items,
              "stats" => %{
                "attributes" => stats
              },
              "commandRevision" => updated_profile.revision
            }
          }
        ],
        "profileCommandRevision" => updated_profile.revision,
        "serverTime" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        "responseVersion" => 1
      }

      conn
      |> json(response)
    else
      error_details =
        Errors.mcp()
        |> Map.get(:template_not_found)

      conn
      |> put_status(:not_found)
      |> json(error_details)
    end
  end

  defp format_value(value) do
    case value do
      %{} -> Map.new(value, fn {k, v} -> {k, format_value(v)} end)
      [] -> []
      _ when is_integer(value) or is_float(value) or is_boolean(value) -> value
      _ -> value
    end
  end
end
