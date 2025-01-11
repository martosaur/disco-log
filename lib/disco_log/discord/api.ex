defmodule DiscoLog.Discord.API do
  @moduledoc """
  A module for working with Discord REST API.
  https://discord.com/developers/docs/reference

  This module is also a behavior. The default implementation uses the `Req` HTTP client. 
  If you want to use a different client, you'll need to implement the behavior and 
  put it under the `discord_client_module` configuration option.
  """

  defstruct [:client, :module]

  @typedoc """
  The client can be any term. It is passed as a first argument to `c:request/4`. For example, the 
  default `DiscoLog.Discord.API.Client` client uses `Req.Request.t()` as a client.
  """
  @type client() :: any()
  @type response() :: {:ok, %{status: non_neg_integer(), body: any()}} | {:error, Exception.t()}

  @callback client(token :: String.t()) :: %__MODULE__{client: client(), module: atom()}
  @callback request(client :: client(), method :: atom(), url :: String.t(), opts :: keyword()) ::
              response()

  @spec list_active_threads(client(), String.t()) :: response()
  def list_active_threads(%__MODULE__{} = client, guild_id) do
    client.module.request(client.client, :get, "/guilds/:guild_id/threads/active",
      path_params: [guild_id: guild_id]
    )
  end

  @spec get_channel(client(), String.t()) :: response()
  def get_channel(%__MODULE__{} = client, channel_id) do
    client.module.request(client.client, :get, "/channels/:channel_id",
      path_params: [channel_id: channel_id]
    )
  end

  @spec get_gateway(client()) :: response()
  def get_gateway(%__MODULE__{} = client) do
    client.module.request(client.client, :get, "/gateway/bot", [])
  end

  @spec post_message(client(), String.t(), Keyword.t()) :: response()
  def post_message(%__MODULE__{} = client, channel_id, fields) do
    client.module.request(client.client, :post, "/channels/:channel_id/messages",
      path_params: [channel_id: channel_id],
      form_multipart: fields
    )
  end

  @spec post_thread(client(), String.t(), Keyword.t()) :: response()
  def post_thread(%__MODULE__{} = client, channel_id, fields) do
    client.module.request(client.client, :post, "/channels/:channel_id/threads",
      path_params: [channel_id: channel_id],
      form_multipart: fields
    )
  end
end
