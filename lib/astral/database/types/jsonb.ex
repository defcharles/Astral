defmodule Astral.Database.Types.Jsonb do
  use Ecto.Type

  def type, do: :map

  # kinda just turns a map into a jsonb

  def cast(value) do
    case value do
      %{} ->
        {:ok, value}

      "" ->
        {:ok, %{}}

      binary when is_binary(binary) ->
        case Jason.decode(binary) do
          {:ok, decoded} -> {:ok, decoded}
          _ -> {:ok, binary}
        end

      value when is_integer(value) or is_float(value) or is_boolean(value) ->
        {:ok, value}

      value when is_list(value) ->
        {:ok, value}

      _ ->
        :error
    end
  end

  def load(value) do
    case value do
      %{} ->
        {:ok, value}

      "" ->
        {:ok, %{}}

      binary when is_binary(binary) ->
        case Jason.decode(binary) do
          {:ok, decoded} -> {:ok, decoded}
          _ -> {:ok, binary}
        end

      value when is_integer(value) or is_float(value) or is_boolean(value) ->
        {:ok, value}

      value when is_list(value) ->
        {:ok, value}

      _ ->
        :error
    end
  end

  def dump(value) do
    case value do
      %{} -> Jason.encode(value)
      "" -> {:ok, ""}
      binary when is_binary(binary) -> {:ok, binary}
      value when is_integer(value) or is_float(value) or is_boolean(value) -> {:ok, value}
      value when is_list(value) -> Jason.encode(value)
      _ -> :error
    end
  end

  def equal?(value1, value2) do
    value1 == value2
  end
end
