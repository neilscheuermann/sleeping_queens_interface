defmodule SleepingQueensInterfaceWeb.CreateGameModal do
  use SleepingQueensInterfaceWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="create_game_modal">
        <form phx-submit="create_game">
          <input type="text" name="player_name" placeholder="Enter your name" />
          <.button type="submit">Create</.button>
        </form>
      </.modal>
    </div>
    """
  end
end
