defmodule SleepingQueensInterfaceWeb.HomeLive do
  use SleepingQueensInterfaceWeb, :live_view
  use SleepingQueensInterfaceWeb, :router

  alias SleepingQueensInterfaceWeb.Router.Helpers, as: Routes
  alias SleepingQueensInterfaceWeb.CreateGameModal
  alias SleepingQueensInterfaceWeb.JoinGameModal

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Sleeping Queens
      </.header>

      <.button phx-click={show_modal("create_game_modal")}>
        Create Game
      </.button>

      <.button phx-click={show_modal("join_game_modal")}>
        Join Game
      </.button>
      <!-- Modals -->
      <.live_component module={CreateGameModal} id="create_game_modal" />
      <.live_component module={JoinGameModal} id="join_game_modal" />
    </div>
    """
  end

  def handle_event("create_game", %{"player_name" => player_name}, socket)
      when is_binary(player_name) do
    game_id = player_name <> "_" <> generate_random_id()
    {:noreply, Phoenix.LiveView.push_redirect(socket, to: "/game/#{game_id}")}
  end

  def handle_event("join_game", %{"game_id" => game_id}, socket)
      when is_binary(game_id) do
    {:noreply, Phoenix.LiveView.push_redirect(socket, to: "/game/#{game_id}")}
  end

  defp generate_random_id do
    :crypto.strong_rand_bytes(2)
    |> Base.encode16()
    |> binary_part(0, 4)
  end
end
