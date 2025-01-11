defmodule Mix.Tasks.DiscoLog.Cleanup do
  @moduledoc """
  Delete all threads and messages from channels.
  """
  use Mix.Task

  alias DiscoLog.Config

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)
    config = Config.read!()

    # Delete all threads from occurrences channel
    delete_threads(config.discord_client, config.guild_id, config.occurrences_channel_id)

    # Delete all messages from info and error channels
    for channel_id <- [config.info_channel_id, config.error_channel_id] do
      delete_channel_messages(config.discord_client, channel_id)
    end

    Mix.shell().info("Messages from DiscoLog Discord channels were deleted successfully!")
  end

  defp delete_threads(client, guild_id, channel_id) do
    {:ok, %{status: 200, body: %{"threads" => threads}}} =
      DiscoLog.Discord.API.list_active_threads(client, guild_id)

    threads
    |> Enum.filter(&(&1["parent_id"] == channel_id))
    |> Enum.map(fn %{"id" => thread_id} ->
      {:ok, %{status: 200}} =
        client.module.request(client.client, :delete, "/channels/#{thread_id}", [])
    end)
  end

  defp delete_channel_messages(client, channel_id) do
    {:ok, %{status: 200, body: messages}} =
      client.module.request(client.client, :get, "/channels/#{channel_id}/messages", [])

    for %{"id" => message_id} <- messages do
      client.module.request(
        client.client,
        :delete,
        "/channels/#{channel_id}/messages/#{message_id}",
        []
      )
    end
  end
end
