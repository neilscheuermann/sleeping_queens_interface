defmodule SleepingQueensInterfaceWeb.JoinGameModal do
  use SleepingQueensInterfaceWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="join_game_modal">
        <.header>Join Existing Game</.header>
        <form phx-submit="join_game">
          <input type="text" name="game_id" placeholder="Enter game id" />
          <input type="text" name="game_id" placeholder="Enter your name" />
          <.button type="submit">Join</.button>
        </form>
      </.modal>
    </div>
    """
  end
end
