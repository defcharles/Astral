defmodule Astral.Database.Tables.Hotfixes do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :filename, :value, :enabled]}

  schema "Hotfixes" do
    field :filename, :string
    # need to use special type for text since ecto doesnt support by default ( from what i know )
    field :value, Astral.Database.Types.Text
    field :enabled, :boolean, default: true
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:filename, :value, :enabled])
    |> validate_required([:filename, :value, :enabled])
  end
end
