defmodule SleepingQueensInterfaceWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import SleepingQueensInterfaceWeb.ChannelCase

      # The default endpoint for testing
      @endpoint SleepingQueensInterfaceWeb.Endpoint
    end
  end

  setup _tags do
    # Didn't need.
    # SleepingQueensInterface.DataCase.setup_sandbox(tags)
    :ok
  end
end
