defmodule SleepingQueensInterfaceWeb.GameLive do
  use SleepingQueensInterfaceWeb, :live_view

  require Logger

  alias SleepingQueensEngine.Game
  alias SleepingQueensEngine.Table

  def mount(
        %{"id" => game_id, "player_position" => player_position},
        _session,
        socket
      ) do
    if connected?(socket), do: subscribe_to_game(game_id)

    user = %{position: String.to_integer(player_position)}

    %{game_id: game_id, rules: rules, table: table} =
      Game.get_state(Game.via_tuple(game_id))

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(:user, user)
     |> assign(:selected_cards, [])
     |> assign(:can_discard_selection?, false)
     |> assign(:can_play_selection?, false)}
  end

  ###
  # Click events
  #

  def handle_event("start_game", _, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    case Game.start_game(via) do
      :ok ->
        broadcast_new_state(game_id)
        {:noreply, socket}

      :error ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Unable to start game without enough players"
         )}
    end
  end

  def handle_event("deal_cards", _args, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    case Game.deal_cards(via) do
      :ok ->
        broadcast_new_state(game_id)
        {:noreply, socket}

      :error ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Unable to start game without enough players"
         )}
    end
  end

  def handle_event("select", %{"card_position" => card_position}, socket) do
    card_position = String.to_integer(card_position)
    selected_cards = socket.assigns.selected_cards

    selected_cards =
      if card_position in selected_cards do
        Enum.reject(selected_cards, &(&1 == card_position))
      else
        [card_position | selected_cards]
      end

    {:noreply,
     socket
     |> assign(:selected_cards, selected_cards)
     |> assign(
       :can_discard_selection?,
       can_discard_selection?(socket, selected_cards)
     )}
  end

  def handle_event("discard", _, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)
    player_position = socket.assigns.user.position
    selected_cards = socket.assigns.selected_cards

    with :ok <- Game.discard(via, player_position, selected_cards) do
      broadcast_new_state(game_id)

      {:noreply,
       socket
       |> assign(:selected_cards, [])
       |> assign(:can_discard_selection?, false)}
    end
  end

  def handle_event("select_queen", %{"row" => row, "col" => col}, socket) do
    {row, _} = Integer.parse(row)
    {col, _} = Integer.parse(col)
    # TODO>>>> Replace hard coded value
    {:ok, table} =
      Table.select_queen(
        socket.assigns.table,
        {row, col},
        socket.assigns.user.position
      )

    {:noreply, assign(socket, :table, table)}
  end

  ###
  # Game PubSub updates
  #

  def handle_info({:game_updated, {rules, table}}, socket) do
    {:noreply,
     socket
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(
       :can_discard_selection?,
       can_discard_selection?(socket, socket.assigns.selected_cards)
     )}
  end

  ###
  # Private Functions
  #

  defp top_discard(table) do
    List.first(table.discard_pile)
  end

  defp get_player(table, player_position),
    do:
      Enum.find(table.players, fn player ->
        player.position == player_position
      end)

  defp get_score(player) do
    player.queens
    |> Enum.map(& &1.value)
    |> Enum.sum()
  end

  defp subscribe_to_game(game_id) do
    Phoenix.PubSub.subscribe(
      SleepingQueensInterface.PubSub,
      "game:#{game_id}"
    )
  end

  defp broadcast_new_state(game_id) do
    via = Game.via_tuple(game_id)
    %{rules: rules, table: table} = Game.get_state(via)

    Phoenix.PubSub.broadcast(
      SleepingQueensInterface.PubSub,
      "game:#{game_id}",
      {:game_updated, {rules, table}}
    )
  end

  defp can_discard_selection?(_socket, []), do: false

  defp can_discard_selection?(socket, selected_cards) do
    via = Game.via_tuple(socket.assigns.game_id)
    player_position = socket.assigns.user.position

    case Game.validate_discard_selection(via, player_position, selected_cards) do
      {:ok, _next_action} -> true
      :error -> false
    end
  end
end
