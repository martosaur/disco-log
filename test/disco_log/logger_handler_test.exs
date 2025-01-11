defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: true

  import Mox
  require Logger
  alias DiscoLog.Discord.API

  @moduletag config: [supervisor_name: __MODULE__]

  setup :setup_supervisor
  setup :attach_logger_handler
  setup :verify_on_exit!

  test "skips logs that are not info or lower than error" do
    # The test can't fail but there will be :remove_failing_handler error
    Logger.debug("Debug message")
    Logger.warning("Warning message")
  end

  describe "info level" do
    test "info log string type" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info("Info message")

      assert_receive [{:path_params, [channel_id: "info_channel_id"]} | _]
    end

    test "info log report type map" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(%{message: "Info message"})

      assert_receive [{:path_params, [channel_id: "info_channel_id"]} | _]
    end

    test "info log report type keyword" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(message: "Info message")

      assert_receive [{:path_params, [channel_id: "info_channel_id"]} | _]
    end

    test "info log report type struct" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(%Foo{})

      assert_receive [{:path_params, [channel_id: "info_channel_id"]} | _]
    end

    test "info log erlang format" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      :logger.info("Hello ~s", ["world"])

      assert_receive [{:path_params, [channel_id: "info_channel_id"]} | _]
    end
  end

  describe "error level" do
    test "error log string type" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error("Error message")

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "error log report type struct" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%Foo{})

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "error log report type map" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%{message: "Error message"})

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "error log report type keyword" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(message: "Error message")

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "error log erlang format" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      :logger.error("Hello ~s", ["world"])

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "error log IO data" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(["Hello", " ", "world"])

      assert_receive [{:path_params, [channel_id: "error_channel_id"]} | _]
    end

    test "a logged raised exception is" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        raise "Unique Error"
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "badarith error" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        1 + to_string(1)
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "undefined function errors" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      # This function does not exist and will raise when called
      {m, f, a} = {DiscoLog, :invalid_fun, []}

      Task.start(fn ->
        apply(m, f, a)
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "throws" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        throw("This is a test")
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end
  end

  describe "with a crashing GenServer" do
    setup do
      %{test_genserver: start_supervised!(DiscoLog.TestGenServer, restart: :temporary)}
    end

    test "a GenServer raising an error is reported",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn -> Keyword.fetch!([], :foo) end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "a GenServer throw is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        throw(:testing_throw)
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "abnormal GenServer exit is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, :bad_exit, :no_state}
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "an exit while calling another GenServer is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      # Get a PID and make sure it's done before using it.
      {pid, monitor_ref} = spawn_monitor(fn -> :ok end)
      assert_receive {:DOWN, ^monitor_ref, _, _, _}

      run_and_catch_exit(test_genserver, fn ->
        GenServer.call(pid, :ping)
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "a timeout while calling another GenServer is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      {:ok, agent} = Agent.start_link(fn -> nil end)

      run_and_catch_exit(test_genserver, fn ->
        Agent.get(agent, & &1, 0)
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "bad function call causing GenServer crash is reported",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        raise "Hello World"
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "an exit with a struct is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, %Mint.HTTP1{}, :no_state}
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end

    test "GenServer timeout is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        DiscoLog.TestGenServer.run(
          test_genserver,
          fn -> Process.sleep(:infinity) end,
          _timeout = 0
        )
      end)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end
  end

  defp run_and_catch_exit(test_genserver_pid, fun) do
    catch_exit(DiscoLog.TestGenServer.run(test_genserver_pid, fun))
  end
end
