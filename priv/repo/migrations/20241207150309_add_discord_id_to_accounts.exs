defmodule Astral.Repo.Migrations.AddDiscordIdToAccounts do
  use Ecto.Migration

  def change do
    alter table(:Accounts) do
      add :discord_id, :string
    end
  end
end
