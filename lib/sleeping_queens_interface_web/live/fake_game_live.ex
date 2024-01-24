defmodule SleepingQueensInterfaceWeb.FakeGameLive do
  use SleepingQueensInterfaceWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>
      Fake Game Page
    </.header>
    """
  end
end
