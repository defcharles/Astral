defmodule Astral.Version do
  def get(req) do
    user_agent = Map.get(req.headers, "user-agent", "")

    {season, build, cl, lobby} =
      case String.split(user_agent, "-") do
        # get build id (CL) from user agent
        [_, build_id, _ | _] ->
          cl =
            case String.split(build_id, ",") do
              [build_str | _] ->
                build_str

              _ ->
                case String.split(build_id, " ") do
                  [build_str | _] ->
                    build_str

                  _ ->
                    case String.split(user_agent, "-") do
                      [_ | [build_id]] ->
                        case String.split(build_id, "+") do
                          [build_str | _] -> build_str
                          _ -> ""
                        end

                      _ ->
                        ""
                    end
                end
            end

          build =
            case String.split(user_agent, "Release-") do
              [_ | [build_str]] ->
                build_str
                |> String.split("-")
                |> List.first()
                |> (fn build_str ->
                      case String.split(build_str, ".") do
                        [major, minor, patch] -> "#{major}.#{minor}#{patch}"
                        _ -> build_str
                      end
                    end).()

              _ ->
                "2.0"
            end

          # format build

          # extract the season from the version
          season =
            case String.split(build, ".") do
              [season_str | _] ->
                case Integer.parse(season_str) do
                  {season, _} -> season
                  :error -> 2
                end

              _ ->
                2
            end

          real =
            case Float.parse(build) do
              {float, _} -> float
              :error -> 2.0
            end

          # make the build ver a float

          # default values
          {season, real, cl, "LobbySeason#{season}"}

        _ ->
          # this is for s2 winter lobby
          {2, 2.0, "", "LobbyWinterDecor"}
      end

    %{
      season: season,
      build: build,
      CL: cl,
      lobby: lobby
    }
  end
end
