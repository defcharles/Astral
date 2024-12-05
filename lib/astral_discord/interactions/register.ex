defmodule AstralDiscord.Interactions.Register do
  @moduledoc """
  Handles /register slash command for creating an account on Astral.
  """

  import Nostrum.Struct.Embed
  alias Nostrum.Constants.InteractionCallbackType
  alias Nostrum.Struct.{ApplicationCommand, Interaction}
  alias Astral.Database.Tables.{Accounts, Profiles, Items}
  alias Astral.Repo
  alias AstralDiscord.Behaviour

  @behaviour Behaviour

  @impl AstralDiscord.Behaviour
  @spec get_command() :: ApplicationCommand.application_command_map()
  def get_command,
    do: %{
      name: "register",
      description: "Create an account on Astral",
      options: [
        %{
          type: 3,
          name: "username",
          description: "Username of your choice",
          required: true
        },
        %{
          type: 3,
          name: "email",
          description: "Email of your choice",
          required: true
        },
        %{
          type: 3,
          name: "password",
          description: "Password of your choice",
          required: true
        }
      ]
    }

  @impl Behaviour
  @spec handle_interaction(Interaction.t(), Behaviour.interaction_options()) :: map()
  def handle_interaction(_interaction, options) do
    username = get_option_value(options, "username")
    email = get_option_value(options, "email")
    password = get_option_value(options, "password")

    account_id = UUID.uuid4() |> String.replace("-", "")

    user_changeset =
      Accounts.changeset(%Accounts{}, %{
        email: email,
        password: password,
        username: username,
        account_id: account_id,
        banned: false,
        is_server: false
      })

    case Repo.insert(user_changeset) do
      {:ok, _user} ->
        profiles = [
          %Profiles{account_id: account_id, type: "athena", revision: 1},
          %Profiles{account_id: account_id, type: "profile0", revision: 1},
          %Profiles{account_id: account_id, type: "common_core", revision: 1},
          %Profiles{account_id: account_id, type: "creative", revision: 1},
          %Profiles{account_id: account_id, type: "common_public", revision: 1},
          %Profiles{account_id: account_id, type: "metadata", revision: 1},
          %Profiles{account_id: account_id, type: "theater0", revision: 1},
          %Profiles{account_id: account_id, type: "outpost0", revision: 1},
          %Profiles{account_id: account_id, type: "campaign", revision: 1}
        ]

        Enum.each(profiles, fn profile ->
          case Repo.get_by(Profiles, account_id: profile.account_id, type: profile.type) do
            nil ->
              profile_changeset = Profiles.changeset(%Profiles{}, Map.from_struct(profile))
              Repo.insert(profile_changeset)

            _existing_profile ->
              :ok
          end
        end)

        create_items_and_attributes(account_id)
    end

    embed =
      %Nostrum.Struct.Embed{}
      |> put_title("Astral Registration Completed!")
      |> put_description("Your account has been successfully created!")
      |> put_color(0x00FF00)

    %{
      type: InteractionCallbackType.channel_message_with_source(),
      data: %{
        embeds: [embed],
        flags: 64
      }
    }
  end


  defp get_option_value(options, name) do
    options
    |> Enum.find(fn option -> option.name == name end)
    |> Map.get(:value)
  end

  defp create_items_and_attributes(account_id) do
    items = [
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "AthenaPickaxe:DefaultPickaxe",
        value: %{xp: 0, level: 0, favorite: false, variants: [], item_seen: true},
        quantity: 1,
        is_stat: false
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "AthenaGlider:DefaultGlider",
        value: %{xp: 0, level: 0, favorite: false, variants: [], item_seen: true},
        quantity: 1,
        is_stat: false
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "loadout1",
        value: %{
          favorite: false,
          item_seen: false,
          use_count: 0,
          locker_name: "",
          locker_slots_data: %{
            slots: %{
              Dance: %{items: ["", "", "", "", "", ""]},
              Glider: %{items: ["AthenaGlider:DefaultGlider"]},
              Pickaxe: %{items: ["AthenaPickaxe:DefaultPickaxe"], activeVariants: []},
              Backpack: %{items: [""], activeVariants: [%{variants: []}]},
              ItemWrap: %{items: ["", "", "", "", "", "", ""], activeVariants: [nil, nil, nil, nil, nil, nil, nil]},
              Character: %{items: ["AthenaCharacter:CID_001_Athena_Commando_F_Default"], activeVariants: [%{variants: []}]},
              MusicPack: %{items: [""], activeVariants: [nil]},
              LoadingScreen: %{items: [""], activeVariants: [nil]},
              SkyDiveContrail: %{items: [""], activeVariants: [nil]}
            }
          },
          banner_icon_template: "",
          banner_color_template: ""
        },
        quantity: 1,
        is_stat: false
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "AthenaDance:EID_DanceMoves",
        value: %{favorite: false, item_seen: true, level: 0, max_level_bonus: 0, rnd_sel_cnt: 0, variants: [], xp: 0},
        quantity: 1,
        is_stat: false
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "Token:campaignaccess",
        value: %{level: 0},
        quantity: 2,
        is_stat: false
      },
       %{
        account_id: account_id,
        profile_id: "profile0",
        template_id: "Currency:MtxPurchased",
        value: %{platform: "Shared"},
        quantity: 0,
        is_stat: false
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "Currency:MtxPurchased",
        value: %{platform: "EpicPC"},
        quantity: 0,
        is_stat: false
      }
    ] ++
    Enum.map(1..21, fn i ->
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "HomebaseBannerColor:DefaultColor#{i}",
        value: %{item_seen: true},
        quantity: 1,
        is_stat: false
      }
    end) ++
    Enum.map(1..31, fn i ->
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "HomebaseBannerIcon:StandardBanner#{i}",
        value: %{item_seen: true},
        quantity: 1,
        is_stat: false
      }
    end) ++
    [
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "past_seasons",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "season_match_boost",
        value: 30,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "stash",
        value: %{globalcash: 0},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "loadouts",
        value: ["loadout1"],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "rested_xp_overflow",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "mfa_reward_claimed",
        value: true,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "quest_manager",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "book_level",
        value: 1,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "season_num",
        value: 12,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "season_update",
        value: 1,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "book_xp",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "permissions",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "book_purchased",
        value: false,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "lifetime_wins",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "party_assist_quest",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "purchased_battle_pass_tier_offers",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "rested_xp_exchange",
        value: 0.333,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "level",
        value: 1,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "xp_overflow",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "rested_xp",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "rested_xp_mult",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "accountLevel",
        value: 1,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "competitive_identity",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "inventory_limit_bonus",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "last_applied_loadout",
        value: "loadout1",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "daily_rewards",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "xp",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "season_friend_match_boost",
        value: 10,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "active_loadout_index",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_musicpack",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_glider",
        value: "AthenaGlider:DefaultGlider",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_pickaxe",
        value: "AthenaPickaxe:DefaultPickaxe",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_skydivecontrail",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_backpack",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_dance",
        value: ["", "", "", "", "", ""],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_itemwraps",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_character",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "athena",
        template_id: "favorite_loadingscreen",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "survey_data",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "personal_offers",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "intro_game_played",
        value: true,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "import_friends_claimed",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "mtx_purchase_history",
        value: %{refundsUsed: 0, refundCredits: 3, purchases: []},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "undo_cooldowns",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "mtx_affiliate_set_time",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "inventory_limit_bonus",
        value: 0,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "current_mtx_platform",
        value: "EpicPC",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "mtx_affiliate",
        value: "",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "forced_intro_played",
        value: "Coconut",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "weekly_purchases",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "daily_purchases",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "ban_history",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "in_app_purchases",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "permissions",
        value: [],
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "undo_timeout",
        value: "min",
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "monthly_purchases",
        value: %{},
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "allowed_to_send_gifts",
        value: true,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "mfa_enabled",
        value: true,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "allowed_to_receive_gifts",
        value: true,
        quantity: 1,
        is_stat: true
      },
      %{
        account_id: account_id,
        profile_id: "common_core",
        template_id: "gift_history",
        value: %{},
        quantity: 1,
        is_stat: true
      }
    ]

    Enum.each(items, fn item_attrs ->
      changeset = Items.changeset(%Items{}, item_attrs)

      if changeset.valid? do
        case Repo.insert(changeset) do
          {:ok, _item} -> :ok
          {:error, changeset} ->
            IO.inspect(changeset.errors, label: "Error inserting item")
        end
      else
        IO.inspect(changeset.errors, label: "Invalid changeset")
      end
    end)
  end
end
