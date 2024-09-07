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

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(:user, user)
     |> assign(:selected_cards, [])
     |> assign(:can_discard_selection?, false)
     |> assign(:can_play_selection?, false)
     |> assign(
       :should_select_opponent_queen?,
       should_select_opponent_queen?(user, rules)
     )
     |> assign(
       :maybe_protect_queen?,
       maybe_protect_queen?(user, rules)
     )
     |> assign(:can_block_steal_queen?, can_block_steal_queen?(user, table))
     |> assign(
       :can_block_put_queen_to_sleep?,
       can_block_put_queen_to_sleep?(user, table)
     )
     |> assign(:should_acknowledge?, should_acknowledge?(user, rules))}
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
        {
          :noreply,
          # TODO::: Implement a handle_event to clear after 5 seconds.
          # https://elixirforum.com/t/flash-message-to-disappear-after-5-seconds/32285/7
          put_flash(
            socket,
            :error,
            "Unable to start game without enough players"
          )
        }
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
    %{
      game_id: game_id,
      selected_cards: selected_cards,
      user: user
    } = socket.assigns

    via = Game.via_tuple(game_id)
    player_position = user.position

    with :ok <- Game.play(via, player_position, selected_cards) do
      broadcast_new_state(game_id)

      {:noreply,
       socket
       |> assign(:selected_cards, [])
       |> assign(:can_play_selection?, false)}
    end
  end

  def handle_event("select_queen", %{"row" => row, "col" => col}, socket) do
    if not should_select_queen?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      {:noreply, socket}
    else
      {row, _} = Integer.parse(row)
      {col, _} = Integer.parse(col)
      game_id = socket.assigns.game_id
      via = Game.via_tuple(game_id)
      player_position = socket.assigns.user.position

      with :ok <- Game.select_queen(via, player_position, row, col) do
        broadcast_new_state(game_id)

        {:noreply, socket}
      end
    end
  end

  def handle_event("acknowledge", _, socket) do
    if not should_acknowledge?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      {:noreply, socket}
    else
      game_id = socket.assigns.game_id
      via = Game.via_tuple(game_id)
      player_position = socket.assigns.user.position

      with :ok <- Game.acknowledge(via, player_position) do
        broadcast_new_state(game_id)

        {:noreply,
         socket
         |> assign(:selected_cards, [])
         |> assign(:can_play_selection?, false)}
      end
    end
  end

  def handle_event("draw_for_jester", _, socket) do
    if not should_draw_for_jester?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      {:noreply, socket}
    else
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
    end
  end

  def handle_event("select_opponent_queen", params, socket) do
    opponent_position = String.to_integer(params["opponent_position"])

    opponent_queen_position =
      String.to_integer(params["opponent_queen_position"])

    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)
    player_position = socket.assigns.user.position

    with :ok <-
           Game.select_opponent_queen(
             via,
             player_position,
             opponent_position,
             opponent_queen_position
           ) do
      broadcast_new_state(game_id)

      {:noreply, socket}
    end
  end

  def handle_event("protect_queen", _params, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    with :ok <- Game.protect_queen(via) do
      broadcast_new_state(game_id)

      {:noreply, socket}
    end
  end

  def handle_event("lose_queen", _params, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    with :ok <- Game.lose_queen(via) do
      broadcast_new_state(game_id)

      {:noreply, socket}
    end
  end

  def handle_event("put_queen_back", %{"row" => row, "col" => col}, socket) do
    if not should_place_queen_back_on_board?(
         socket.assigns.rules.waiting_on,
         socket.assigns.user
       ) do
      {:noreply, socket}
    else
      {row, _} = Integer.parse(row)
      {col, _} = Integer.parse(col)
      game_id = socket.assigns.game_id
      via = Game.via_tuple(game_id)
      queen_coordinate = {row, col}

      with :ok <- Game.put_queen_back(via, queen_coordinate) do
        broadcast_new_state(game_id)

        {:noreply, socket}
      end
    end
  end

  def handle_event("play_again", _params, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    with :ok <- Game.restart_game(via) do
      broadcast_new_state(game_id)

      {:noreply, socket}
    else
      _ ->
        {
          :noreply,
          put_flash(
            socket,
            :error,
            "Unable to start game without enough players"
          )
        }
    end
  end

  def handle_event("navigate_home", _params, socket) do
    {:noreply, Phoenix.LiveView.push_navigate(socket, to: "/")}
  end

  ###
  # Game PubSub updates
  #

  def handle_info({:game_updated, {rules, table}}, socket) do
    %{selected_cards: selected_cards, user: user} = socket.assigns

    {:noreply,
     socket
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(
       :can_discard_selection?,
       can_discard_selection?(socket, selected_cards)
     )
     |> assign(
       :can_play_selection?,
       can_play_selection?(socket, selected_cards)
     )
     |> assign(
       :should_select_opponent_queen?,
       should_select_opponent_queen?(user, rules)
     )
     |> assign(
       :maybe_protect_queen?,
       maybe_protect_queen?(user, rules)
     )
     |> assign(
       :can_block_put_queen_to_sleep?,
       can_block_put_queen_to_sleep?(user, table)
     )
     |> assign(:can_block_steal_queen?, can_block_steal_queen?(user, table))
     |> assign(:should_acknowledge?, should_acknowledge?(user, rules))}
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

  defp get_banner_text(assigns) do
    %{rules: rules, table: table} = assigns
    current_player = get_player(table, rules.player_turn)
    waiting_on = rules.waiting_on

    cond do
      rules.player_count == 1 ->
        "Waiting for more players..."

      rules.state == :initialized ->
        first_player_name = get_player(table, 1).name
        "Waiting for #{first_player_name} to start the game"

      waiting_on ->
        waiting_on_player = get_player(table, waiting_on.player_position)

        "#{waiting_on_player.name}, is #{get_action_text(rules, table)}"

      rules.state == :playing ->
        "#{current_player.name}'s turn"

      rules.state == :game_over ->
        "Game over"

      true ->
        ""
    end
  end

  defp get_action_text(%{waiting_on: %{action: :select_queen}}, _table),
    do: "choosing a queen to pick up"

  defp get_action_text(
         %{waiting_on: %{action: :select_another_queen_from_rose}},
         _table
       ),
       do: "choosing another queen to pick up 🌹"

  defp get_action_text(%{waiting_on: %{action: :draw_for_jester}}, _table),
    do: "drawing for the jester"

  defp get_action_text(%{waiting_on: %{action: :steal_queen}}, _table),
    do: "choosing someone's queen to steal"

  defp get_action_text(
         %{waiting_on: %{action: :place_queen_back_on_board}},
         _table
       ),
       do: "choosing someone's queen to put to sleep"

  defp get_action_text(
         %{waiting_on: %{action: :block_steal_queen}} = rules,
         table
       ),
       do:
         "deciding whether to block #{get_player(table, rules.player_turn).name}'s knight"

  defp get_action_text(
         %{waiting_on: %{action: :block_place_queen_back_on_board}} = rules,
         table
       ),
       do:
         "deciding whether to block #{get_player(table, rules.player_turn).name}'s sleeping potion"

  defp get_action_text(
         %{waiting_on: %{action: :pick_spot_to_return_queen}} = rules,
         table
       ),
       do:
         "deciding where to place #{get_player(table, rules.queen_to_lose.player_position).name}'s #{get_queen_to_lose(table, rules).name} queen"

  defp get_action_text(
         %{waiting_on: %{action: :acknowledge_blocked_by_dog_or_cat_queen}} =
           rules,
         table
       ) do
    queen_name_player_has =
      table
      |> get_player(rules.waiting_on.player_position)
      |> Map.get(:queens)
      |> Enum.find(&(&1.name in ["cat", "dog"]))
      |> Map.get(:name)

    other_queen_name =
      case queen_name_player_has do
        "dog" -> "cat"
        "cat" -> "dog"
      end

    "unabled to pick up the #{other_queen_name} queen"
  end

  defp get_action_text(_rules, _table), do: "__ACTION_TEXT__"

  defp get_header_for_protect_queen_modal(
         %{waiting_on: %{action: :block_steal_queen}} = rules,
         table
       ),
       do:
         "Protect your queen from #{get_player(table, rules.player_turn).name} with a dragon 🐉?"

  defp get_header_for_protect_queen_modal(
         %{
           waiting_on: %{action: :block_place_queen_back_on_board}
         } = rules,
         table
       ),
       do:
         "Protect your queen from #{get_player(table, rules.player_turn).name} with a wand 🪄?"

  defp get_header_for_protect_queen_modal(_rules, _table), do: ""

  # Action cards
  defp get_emoji(%{type: :number}), do: ""
  defp get_emoji(%{type: :jester}), do: "🤹"
  defp get_emoji(%{type: :king}), do: "👑"
  defp get_emoji(%{type: :knight}), do: "⚔️"
  defp get_emoji(%{type: :dragon}), do: "🐉"
  defp get_emoji(%{type: :wand}), do: "🪄"
  defp get_emoji(%{type: :sleeping_potion}), do: "💤"

  # Queens
  defp get_emoji(%{name: "book"}), do: "📚"
  defp get_emoji(%{name: "butterfly"}), do: "🦋"
  defp get_emoji(%{name: "cake"}), do: "🎂"
  defp get_emoji(%{name: "cat"}), do: "🐱"
  defp get_emoji(%{name: "dog"}), do: "🐶"
  defp get_emoji(%{name: "heart"}), do: "🩷"
  defp get_emoji(%{name: "ice cream"}), do: "🍦"
  defp get_emoji(%{name: "ladybug"}), do: "🐞"
  defp get_emoji(%{name: "moon"}), do: "🌙"
  defp get_emoji(%{name: "pancake"}), do: "🥞"
  defp get_emoji(%{name: "peacock"}), do: "🦚"
  defp get_emoji(%{name: "rainbow"}), do: "🌈"
  defp get_emoji(%{name: "rose"}), do: "🌹"
  defp get_emoji(%{name: "starfish"}), do: "⭐"
  defp get_emoji(%{name: "strawberry"}), do: "🍓"
  defp get_emoji(%{name: "sunflower"}), do: "🌻"
  defp get_emoji(_), do: "❌"

  defp get_queen_to_lose(_table, %{queen_to_lose: nil} = _rules), do: nil

  defp get_queen_to_lose(table, rules) do
    player_position_to_lose_queen = rules.queen_to_lose.player_position
    queen_to_lose_index = rules.queen_to_lose.queen_position - 1

    table.players
    |> Enum.find(:players, &(&1.position == player_position_to_lose_queen))
    |> Map.get(:queens)
    |> Enum.at(queen_to_lose_index)
  end

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

  defp should_select_queen?(
         %{action: :select_another_queen_from_rose} = waiting_on,
         user
       )
       when waiting_on.player_position == user.position,
       do: true

  defp should_select_queen?(_waiting_on, _user), do: false

  defp should_place_queen_back_on_board?(
         %{action: :pick_spot_to_return_queen} = waiting_on,
         user
       )
       when waiting_on.player_position == user.position,
       do: true

  defp should_place_queen_back_on_board?(_waiting_on, _user), do: false

  defp should_select_opponent_queen?(
         %{position: waiting_on_position} = _user,
         %{
           waiting_on: %{
             player_position: waiting_on_position,
             action: action
           }
         } = _rules
       )
       when action in [
              :steal_queen,
              :place_queen_back_on_board
            ],
       do: true

  defp should_select_opponent_queen?(_user, _rules), do: false

  defp maybe_protect_queen?(
         %{position: waiting_on_position} = _user,
         %{
           waiting_on: %{
             player_position: waiting_on_position,
             action: action
           }
         } = _rules
       )
       when action in [:block_steal_queen, :block_place_queen_back_on_board],
       do: true

  defp maybe_protect_queen?(_user, _rules), do: false

  defp should_acknowledge?(
         %{position: waiting_on_position} = _user,
         %{
           waiting_on: %{
             player_position: waiting_on_position,
             action: :acknowledge_blocked_by_dog_or_cat_queen
           }
         } = _rules
       ),
       do: true

  defp should_acknowledge?(_user, _rules), do: false

  # TODO::: Do this logic in the game Engine and return a boolean.
  # Maybe a list of common actions rather than individual calls for things 
  # that are required for the UI?
  # 
  # ex: 
  # %{
  #   can_discard_selection?: true,
  #   can_play_selection?: true,
  #   can_block_steal_queen?: true,
  #   can_block_put_queen_to_sleep?: true,
  #   should_draw_for_jester?: true,
  #   should_select_queen?: true,
  #   should_select_opponent_queen?: true,
  #   should_place_queen_back_on_board?: true,
  # }
  defp can_block_steal_queen?(user, table),
    do:
      table
      |> get_player(user.position)
      |> Map.get(:hand, [])
      |> Enum.any?(&(&1.type == :dragon))

  defp can_block_put_queen_to_sleep?(user, table),
    do:
      table
      |> get_player(user.position)
      |> Map.get(:hand, [])
      |> Enum.any?(&(&1.type == :wand))
end
