
# Astral: Setup Guide
## Download Elixir / Erlang

1. **Download Erlang**  
   First, visit the official Erlang website to download the latest version: [Erlang Downloads](https://www.erlang.org/downloads).  
   **Important:** Ensure that you add Erlang to your system's PATH during installation so that it can be accessed from the command line.

2. **Download Elixir**  
   Once Erlang is installed, go to the [Elixir Installation Page](https://elixir-lang.org/install.html) to download Elixir for your operating system. Be sure to select the version that is compatible with your installed Erlang version.

## Download PostgreSQL

1. **Download PostgreSQL**  
   Start by visiting the official PostgreSQL download page: [PostgreSQL Downloads](https://www.postgresql.org/download/).  
   Select your operating system (Windows, macOS, Linux, etc.) to get the appropriate installer.

2. **Install PostgreSQL**  
   Follow the installation instructions specific to your OS. During installation, make sure to note the following:
   - Choose to install **pgAdmin** (a graphical interface for PostgreSQL).
   - Set a password for the **postgres** user (this is the default superuser account).

3. **Add PostgreSQL to PATH**  
   If the installer does not automatically add PostgreSQL to your system's PATH, you may need to do it manually to access PostgreSQL commands from the terminal. 

# How to Set Up Astral Configuration

To set up Astral, follow these steps carefully:

## 1. Install Dependencies

Before configuring Astral, make sure you have all dependencies installed. Run the following command to install them:

```bash
mix deps.get
```

## 2. Configure Astral.Repo in `config/dev.exs`

Next, you need to configure your `Astral.Repo` settings in the dev config.

1. Open the `config/dev.exs` file.
2. Set your `username` and `password` for the `Astral.Repo` config.

Make sure to replace `"postgres"` and `"passwordhere"` with your actual database username and password.

## 3. Configure Token for Nostrum in `config/dev.exs`

Now, configure your token for the Nostrum API (which is used for the Discord bot).

1. In the same `config/dev.exs` file, edit the following line to your token

```elixir
config :nostrum, :token, "your_token_here"
```

Replace `"your_token_here"` with the actual token you got when creating your bot on Discord.

## 4. Run Database Commands

After setting up your configuration files, you need to set up the database.

Run the following commands to create your database:

```bash
mix ecto.create
mix ecto.migrate
```

## 5. Start the Phoenix Server

Finally, start the Phoenix server to run Astral by using the command provided.

```bash
mix phx.server
```

Once it is running, you can start using Astral!

## Troubleshooting

If you encounter any issues:

- Double-check your database credentials in `config/dev.exs`.
- Make sure your Nostrum token is correct.
- Ensure your database server is running.