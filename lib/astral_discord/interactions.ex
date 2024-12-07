defmodule AstralDiscord.Interactions do
  @moduledoc """
  Register slash commands and handles interactions
  """

  require Logger
  alias Nostrum.Api

  alias AstralDiscord.Interactions.{Register}

  @spec register_commands() :: any()
  def register_commands do
    {public_commands, _private_commands} =
      [
        {:public, Register.get_command()}
      ]
      |> Enum.filter(&(!is_nil(elem(&1, 1))))
      |> Enum.reduce({[], []}, fn {access, command}, {public, private} ->
        if access == :public do
          {[command | public], private}
        else
          {public, [command | private]}
        end
      end)

    Api.bulk_overwrite_global_application_commands(public_commands)
  end

  def handle_interaction(interaction) do
    Logger.metadata(
      interaction_data: interaction.data,
      guild_id: interaction.guild_id,
      channel_id: interaction.channel_id,
      user_id: interaction.user.id
    )

    Logger.info("Interaction received")

    try do
      response = call_interaction(interaction, interaction.data)

      Nostrum.Api.create_interaction_response(interaction, response)
    rescue
      err ->
        Logger.error(err)

        Nostrum.Api.create_interaction_response(interaction, %{
          type: 4,
          data: %{content: "Something went wrong :("}
        })
    end
  end

  defp call_interaction(interaction, %Nostrum.Struct.ApplicationCommandInteractionData{
         name: "register",
         options: nil
       }) do
    Register.handle_interaction(interaction, nil)
  end

  defp call_interaction(interaction, %Nostrum.Struct.ApplicationCommandInteractionData{
         name: "register",
         options: options
       }) do
    Register.handle_interaction(interaction, options)
  end

  defp call_interaction(_interaction, _data) do
    raise "Unknown interaction command"
  end
end
