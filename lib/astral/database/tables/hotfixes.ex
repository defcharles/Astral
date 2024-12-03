defmodule Astral.Database.Tables.Hotfixes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "Hotfixes" do
    field :filename, :string
    field :value, Astral.Database.Types.Text # need to use special type for text since ecto doesnt support by default ( from what i know )
    field :enabled, :boolean, default: true
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:filename, :value, :enabled])
    |> validate_required([:filename, :value, :enabled])
  end
end
