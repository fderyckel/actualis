defmodule Actualis.Capability.Registry do
  @moduledoc "Resolves configured domain handlers without introducing a Core dependency on them."

  @spec fetch(term()) :: {:ok, module()} | {:error, map()}
  def fetch(capability) when is_binary(capability) do
    handler =
      :actualis_core
      |> Application.fetch_env!(:capability_handlers)
      |> Enum.find(fn candidate ->
        Code.ensure_loaded?(candidate) and function_exported?(candidate, :capability, 0) and
          candidate.capability() == capability
      end)

    if handler,
      do: {:ok, handler},
      else: {:error, invalid_command()}
  end

  def fetch(_capability), do: {:error, invalid_command()}

  defp invalid_command do
    %{
      "code" => "invalid_command",
      "message" => "The capability request is invalid",
      "details" => %{}
    }
  end
end
