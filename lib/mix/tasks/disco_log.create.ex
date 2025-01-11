defmodule Mix.Tasks.DiscoLog.Create do
  @moduledoc """
  Creates the necessary discord channels for DiscoLog.
  """
  use Mix.Task

  alias DiscoLog.Config

  @default_tags Enum.map(~w(plug live_view oban tesla), &%{name: &1})

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)
    config = Config.read!()

    with {:ok, %{status: 200, body: channels}} <-
           list_channels(config.discord_client, config.guild_id),
         {:ok, %{status: 201, body: %{"id" => category_id}}} <-
           fetch_or_create_channel(
             config.discord_client,
             channels,
             config.guild_id,
             4,
             "disco-log",
             nil
           ),
         {:ok, %{status: 201, body: occurrence}} <-
           fetch_or_create_channel(
             config.discord_client,
             channels,
             config.guild_id,
             15,
             "occurrences",
             category_id,
             %{available_tags: @default_tags}
           ),
         {:ok, %{status: 201, body: info}} <-
           fetch_or_create_channel(
             config.discord_client,
             channels,
             config.guild_id,
             0,
             "info",
             category_id
           ),
         {:ok, %{status: 201, body: error}} <-
           fetch_or_create_channel(
             config.discord_client,
             channels,
             config.guild_id,
             0,
             "error",
             category_id
           ) do
      Mix.shell().info("Discord channels for DiscoLog were created successfully!")
      Mix.shell().info("Complete the configuration by adding the following to your config")

      Mix.shell().info("""
      config :disco_log,
        otp_app: :app_name,
        token: "#{config.token}",
        guild_id: "#{config.guild_id}",
        category_id: "#{category_id}",
        occurrences_channel_id: "#{occurrence["id"]}",
        info_channel_id: "#{info["id"]}",
        error_channel_id: "#{error["id"]}"
      """)
    end
  end

  defp list_channels(discord_client, guild_id) do
    discord_client.module.request(discord_client.client, :get, "/guilds/#{guild_id}/channels", [])
  end

  defp fetch_or_create_channel(
         discord_client,
         channels,
         guild_id,
         type,
         name,
         parent_id,
         extra \\ %{}
       ) do
    channels
    |> Enum.find(&match?(%{"type" => ^type, "name" => ^name, "parent_id" => ^parent_id}, &1))
    |> case do
      nil ->
        discord_client.module.request(
          discord_client.client,
          :post,
          "/guilds/#{guild_id}/channels",
          json:
            Map.merge(
              %{
                parent_id: parent_id,
                name: name,
                type: type
              },
              extra
            )
        )

      channel when is_map(channel) ->
        {:ok, channel}
    end
  end
end
