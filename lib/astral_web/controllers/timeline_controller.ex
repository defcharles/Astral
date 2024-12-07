defmodule AstralWeb.TimelineController do
  use AstralWeb, :controller

  # no params are needed for this func
  def timeline(conn, _params) do
    ua = get_req_header(conn, "user-agent") |> List.first() || ""

    # gets data from user-agent / ua
    ver = Astral.Version.get(%{headers: %{"user-agent" => ua}})

    active_events = [
      %{
        eventType: "EventFlag.Season#{ver.season}",
        activeUntil: "9999-01-01T00:00:00.000Z",
        activeSince: "2020-01-01T00:00:00.000Z"
      },
      %{
        # usually formatted as LobbySeason{season}
        eventType: "EventFlag.#{ver.lobby}",
        activeUntil: "9999-01-01T00:00:00.000Z",
        activeSince: "2020-01-01T00:00:00.000Z"
      }
    ]

    response = %{
      channels: %{
        "client-matchmaking" => %{
          states: [],
          cacheExpire: "9999-01-01T00:00:00.000Z"
        },
        "client-events" => %{
          states: [
            %{
              validFrom: "0001-01-01T00:00:00.000Z",
              activeEvents: active_events,
              state: %{
                activeStorefronts: [],
                eventNamedWeights: %{},
                seasonNumber: "#{ver.season}",
                seasonTemplateId: "AthenaSeason:athenaseason#{ver.season}",
                matchXpBonusPoints: 0,
                seasonBegin: "2020-01-01T00:00:00Z",
                seasonEnd: "9999-01-01T00:00:00Z",
                seasonDisplayedEnd: "9999-01-01T00:00:00Z",
                weeklyStoreEnd: "9999-01-01T00:00:00Z",
                stwEventStoreEnd: "9999-01-01T00:00:00.000Z",
                stwWeeklyStoreEnd: "9999-01-01T00:00:00.000Z",
                sectionStoreEnds: %{
                  "Featured" => "9999-01-01T00:00:00.000Z"
                },
                dailyStoreEnd: "9999-01-01T00:00:00.000Z"
              }
            }
          ],
          cacheExpire: "9999-01-01T00:00:00.000Z"
        }
      },
      eventsTimeOffsetHrs: 0,
      cacheIntervalMins: 10,
      currentTime: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }

    conn
    |> put_status(:ok)
    |> json(response)
  end
end
