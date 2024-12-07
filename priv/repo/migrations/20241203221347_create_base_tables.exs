defmodule Astral.Repo.Migrations.CreateBaseTables do
  use Ecto.Migration

  def change do
    create table(:Accounts, primary_key: false) do
      add :account_id, :string, primary_key: true
      add :email, :string
      add :password, :string
      add :username, :string
      add :banned, :boolean, default: false, null: false
      add :is_server, :boolean, default: false, null: false
    end

    create table(:Hotfixes) do
      add :filename, :string
      # use correct type for text instead of custom type in migrations only
      add :value, :text
      add :enabled, :boolean, default: true, null: false
    end

    create table(:Profiles, primary_key: false) do
      add :account_id, :string
      add :type, :string
      add :revision, :integer
    end

    create unique_index(:Profiles, [:type])

    create table(:Tokens, primary_key: false) do
      add :account_id, :string
      add :type, :string
      add :token, :string, null: false, default: ""
      timestamps()
    end

    execute("DROP INDEX IF EXISTS Tokens_token_index")

    alter table(:Tokens) do
      remove :token
    end

    alter table(:Tokens) do
      add :token, :string, null: false, default: ""
    end

    create unique_index(:Tokens, [:token], name: :tokens_token_index)
  end
end
