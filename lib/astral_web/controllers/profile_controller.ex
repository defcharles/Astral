defmodule AstralWeb.ProfileController do
  use AstralWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Astral.Repo
  alias Astral.Database.Tables.{Profiles, Accounts, Items}
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

# you can only equip one thing before it stops working and idk why so yea very dtc 
# also tiva dont be on my dick i tried to do my best i did what you wanted me todo so yea enought yap for tonight

def equipbattleroyalecustomization(conn, %{"accountId" => account_id}) do
  slot_item = Map.get(conn.body_params, "itemToSlot")
  slot_type = Map.get(conn.body_params, "slotName")
  index = Map.get(conn.body_params, "indexWithinSlot")
  profile_id = Map.get(conn.query_params, "profileId")

  if Enum.any?([slot_item, slot_type, index, profile_id, account_id], &is_nil(&1)) do
    conn |> json(%{error: "Missing required parameters."}) |> halt()
  end

  item_key = String.replace(slot_item, "item:", "")

  if is_nil(profile_id) or is_nil(account_id) do
    conn |> json(%{error: "Profile or account ID is required."}) |> halt()
  end

  profile = Repo.get_by(Profiles, account_id: account_id, type: profile_id)
  account = Repo.get_by(Accounts, account_id: account_id)

  if is_nil(profile) or is_nil(account) do
    conn |> json(%{error: "Account or profile not found."}) |> halt()
  end

  changes = []

  existing_item = Repo.one(from i in Items, where: i.account_id == ^account_id and i.profile_id == ^profile_id and i.template_id == ^item_key)

  if is_nil(existing_item) do
    if String.contains?(item_key, "_random") or item_key == "" do
      changes = [%{changeType: "statModified", name: "favorite_#{String.downcase(slot_type)}", value: item_key}]
      Repo.transaction(fn ->
        Repo.update!(Profiles.changeset(profile, %{revision: profile.revision + 1}))
        Repo.insert!(%Items{account_id: account_id, profile_id: profile_id, template_id: item_key, value: item_key})
      end)
    else
      conn |> json(%{error: "Item could not be found"}) |> halt()
    end
  end

  slot = case slot_type do
    "Dance" when is_number(index) and index in 0..5 -> "favorite_dance"
    "Character" -> "favorite_character"
    "Backpack" -> "favorite_backpack"
    "Pickaxe" -> "favorite_pickaxe"
    "Glider" -> "favorite_glider"
    _ when slot_type in ["SkyDiveContrail", "MusicPack", "LoadingScreen"] -> "favorite_#{String.downcase(slot_type)}"
    _ -> nil
  end

  if slot do
    stat_item = Repo.one(from i in Items, where: i.account_id == ^account_id and i.profile_id == ^profile_id and i.template_id == ^slot)

    if stat_item do
      updated_value = case slot_type do
        "ItemWrap" when index in [-1, 0..6] -> List.duplicate(item_key, 7)
        "Dance" when is_number(index) -> List.replace_at(stat_item.value, index, item_key)
        _ -> item_key
      end

      Repo.update!(Items.changeset(stat_item, %{value: updated_value}))
      changes = [%{changeType: "statModified", name: slot, value: updated_value} | changes]
      Repo.update!(Profiles.changeset(profile, %{revision: profile.revision + 1}))
      conn |> json(profile_update(profile, changes))
    end
  end

  Repo.update!(Profiles.changeset(profile, %{revision: profile.revision + 1}))
  conn |> json(profile_update(profile, changes))
end

defp profile_update(profile, changes) do
  %{
    "profileRevision" => profile.revision + 1,
    "profileId" => profile.type,
    "profileChangesBaseRevision" => profile.revision,
    "profileChanges" => changes,
    "profileCommandRevision" => profile.revision || 0,
    "serverTime" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
    "responseVersion" => 1
  }
end
end