defmodule Astral.Database.Tables.Accounts do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:account_id, :string, autogenerate: false}

  schema "Accounts" do
    field :email, :string
    field :password, :string
    field :username, :string
    field :discord_id, :string
    field :banned, :boolean, default: false
    field :is_server, :boolean, default: false
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:account_id, :email, :password, :username, :discord_id, :banned, :is_server])
    |> validate_required([:account_id, :email, :password, :username, :discord_id])
  end
end
