defmodule SleepingQueensInterfaceWeb.GameLive do
  use SleepingQueensInterfaceWeb, :live_view

  require Logger

  alias SleepingQueensEngine.Game

  def mount(
        %{"id" => game_id, "player_position" => player_position},
        _session,
        socket
      ) do
    if connected?(socket), do: subscribe_to_game(game_id)

    user = %{position: String.to_integer(player_position)}

    %{game_id: game_id, rules: rules, table: table} =
      Game.get_state(Game.via_tuple(game_id))

    rules.waiting_on |> IO.inspect(label: ">>>>waiting_on")

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(:user, user)
     |> assign(:selected_cards, [])
     |> assign(:can_discard_selection?, false)
     |> assign(:can_play_selection?, false)
     |> assign(:select_opponents_queen?, select_opponents_queen?(user, rules))}
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
     )
     |> assign(
       :can_play_selection?,
       can_play_selection?(socket, selected_cards)
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

  def handle_event("play", _, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)
    player_position = socket.assigns.user.position
    selected_cards = socket.assigns.selected_cards

    with :ok <- Game.play(via, player_position, selected_cards) do
      broadcast_new_state(game_id)

      {:noreply,
       socket
       |> assign(:selected_cards, [])
       |> assign(:can_play_selection?, false)}
    end
  end

  def handle_event("select_queen", %{"row" => row, "col" => col}, socket) do
    if should_select_queen?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      {row, _} = Integer.parse(row)
      {col, _} = Integer.parse(col)
      game_id = socket.assigns.game_id
      via = Game.via_tuple(game_id)
      player_position = socket.assigns.user.position

      with :ok <- Game.select_queen(via, player_position, row, col) do
        broadcast_new_state(game_id)

        {:noreply,
         socket
         |> assign(:selected_cards, [])
         |> assign(:can_play_selection?, false)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("draw_for_jester", _, socket) do
    if should_draw_for_jester?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      game_id = socket.assigns.game_id
      via = Game.via_tuple(game_id)
      player_position = socket.assigns.user.position

      with :ok <- Game.draw_for_jester(via, player_position) do
        broadcast_new_state(game_id)

        {:noreply,
         socket
         |> assign(:selected_cards, [])
         |> assign(:can_play_selection?, false)}
      end
    else
      {:noreply, socket}
    end
  end

  ###
  # Game PubSub updates
  #

  def handle_info({:game_updated, {rules, table}}, socket) do
    rules.waiting_on |> IO.inspect(label: ">>>>updated waiting_on")

    {:noreply,
     socket
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(
       :can_discard_selection?,
       can_discard_selection?(socket, socket.assigns.selected_cards)
     )
     |> assign(
       :can_play_selection?,
       can_play_selection?(socket, socket.assigns.selected_cards)
     )
     |> assign(
       :select_opponents_queen?,
       select_opponents_queen?(socket.assigns.user, rules)
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

  defp can_play_selection?(_socket, []), do: false

  defp can_play_selection?(socket, selected_cards) do
    via = Game.via_tuple(socket.assigns.game_id)
    player_position = socket.assigns.user.position

    case Game.validate_play_selection(via, player_position, selected_cards) do
      {:ok, _next_action} -> true
      :error -> false
    end
  end

  defp should_draw_for_jester?(%{action: :draw_for_jester} = waiting_on, user)
       when waiting_on.player_position == user.position,
       do: true

  defp should_draw_for_jester?(_waiting_on, _user), do: false

  defp should_select_queen?(%{action: :select_queen} = waiting_on, user)
       when waiting_on.player_position == user.position,
       do: true

  defp should_select_queen?(_waiting_on, _user), do: false

  defp get_banner_text(assigns) do
    %{rules: rules, table: table} = assigns
    current_player = get_player(table, rules.player_turn)
    waiting_on = rules.waiting_on

    cond do
      rules.state == :initialized ->
        "Waiting to start..."

      waiting_on ->
        waiting_on_player = get_player(table, rules.waiting_on.player_position)

        "#{waiting_on_player.name}, #{get_action_text(waiting_on.action)}"

      rules.state == :playing ->
        "#{current_player.name}'s turn"
    end
  end

  defp get_action_text(:select_queen), do: "select a queen"
  defp get_action_text(:draw_for_jester), do: "draw for the jester"

  defp get_action_text(:choose_queen_to_steal),
    do: "chose someone's queen to steal"

  defp get_action_text(:choose_queen_to_place_back_on_board),
    do: "choose someone's queen to put to sleep"

  defp get_action_text(:block_steal_queen),
    do: "thwarted the knight with a dragon"

  defp get_action_text(:block_place_queen_back_on_board),
    do: "blocked the potion with a wand"

  defp action_required?(_player, %{rules: %{state: state}})
       when state != :playing,
       do: false

  defp action_required?(player, assigns) do
    is_waiting_on_player?(player, assigns) or is_players_turn(player, assigns)
  end

  defp is_waiting_on_player?(%{position: player_position}, %{
         rules: %{waiting_on: %{player_position: player_position}}
       }),
       do: true

  defp is_waiting_on_player?(_player, _assigns), do: false

  defp is_players_turn(%{position: player_position}, %{
         rules: %{waiting_on: nil, player_turn: player_position}
       }),
       do: true

  defp is_players_turn(_player, _assigns), do: false

  defp select_opponents_queen?(
         %{position: waiting_on_position} = _user,
         %{
           waiting_on: %{
             player_position: waiting_on_position,
             action: action
           }
         } = _rules
       )
       when action in [
              :choose_queen_to_steal,
              :choose_queen_to_place_back_on_board
            ],
       do: true

  defp select_opponents_queen?(_user, _rules), do: false
end
