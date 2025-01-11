defmodule Mix.Tasks.DiscoLog.Sample do
  @moduledoc """
  Creates some sample logs and errors.
  """
  use Mix.Task

  require Logger

  @impl Mix.Task
  def run(_args) do
    # Ensure disco_log is started
    {:ok, _} = Application.ensure_all_started(:disco_log)

    # Logger.info("✨ DiscoLog Hello")
    # Logger.error("🔥 DiscoLog error test")
    # Logger.info(%{id: 1, username: "Bob"})

    try do
      raise "🚨 DiscoLog is raising an error !"
    rescue
      exception ->
        Logger.error(reason: {exception, __STACKTRACE__})
    end
  end
end
