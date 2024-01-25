defmodule SleepingQueensInterfaceWeb.HomeLive do
  use SleepingQueensInterfaceWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Sleeping Queens
      </.header>

      <.button phx-click={show_modal("create_game_modal")}>
        Create Game
      </.button>
      <!-- Create Game Modal -->
      <div>
        <.modal id="create_game_modal">
          <.header>Create New Game</.header>
          <form phx-submit="create_game">
            <input type="text" name="player_name" placeholder="Enter your name" />
            <.button type="submit">Create</.button>
          </form>
        </.modal>
      </div>

      <.button phx-click={show_modal("join_game_modal")}>
        Join Game
      </.button>
      <!-- Join Game Modal -->
      <div>
        <.modal id="join_game_modal">
          <.header>Join Existing Game</.header>
          <form phx-submit="join_game">
            <input type="text" name="game_id" placeholder="enter game id" />
            <input type="text" name="player_name" placeholder="enter your name" />
            <.button type="submit">Join</.button>
          </form>
        </.modal>
      </div>
    </div>
    """
  end

  def handle_event("create_game", %{"player_name" => player_name}, socket)
      when is_binary(player_name) do
    {:noreply,
     Phoenix.LiveView.push_redirect(socket,
       to: "/game/#{generate_random_id()}/#{player_name}"
     )}
  end

  def handle_event(
        "join_game",
        %{"game_id" => game_id, "player_name" => player_name},
        socket
      )
      when is_binary(game_id) do
    {:noreply,
     Phoenix.LiveView.push_navigate(socket,
       to: "/game/#{game_id}/#{player_name}"
     )}
  end

  defp generate_random_id do
    :crypto.strong_rand_bytes(2)
    |> Base.encode16()
    |> binary_part(0, 4)
  end
end
