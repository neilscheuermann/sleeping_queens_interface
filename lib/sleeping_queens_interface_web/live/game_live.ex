defmodule SleepingQueensInterfaceWeb.GameLive do
  use SleepingQueensInterfaceWeb, :live_view

  require Logger

  alias SleepingQueensEngine.Game
  alias SleepingQueensEngine.Table

  def mount(%{"id" => game_id, "player_id" => player_id}, _session, socket) do
    if connected?(socket), do: subscribe_to_game(game_id)

    user = %{position: 1}

    %{game_id: game_id, rules: rules, table: table} =
      Game.get_state(Game.via_tuple(game_id))

    # Only try to talk to the client when the websocket
    # is setup. Not on the initial "static" render.
    socket =
      if connected?(socket) do
        # This represents some meaningful key to your LiveView that you can
        # store and restore state using. Perhaps an ID from the page
        # the user is visiting?
        my_storage_key = player_id <> game_id
        # For handle_params, it could be
        # my_storage_key = params["id"]

        socket
        |> assign(:my_storage_key, my_storage_key)
        # request the browser to restore any state it has for this key.
        |> push_event("restore", %{
          key: my_storage_key,
          event: "getUserData"
        })
      else
        socket
      end

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:rules, rules)
     |> assign(:table, table)
     |> assign(:top_discard, top_discard(table))
     |> assign(:user, user)}
  end

  # Pushed from JS hook. Server requests it to send up any
  # stored settings for the key.
  def handle_event(
        "getUserData",
        %{"player_position" => player_position},
        socket
      ) do
    socket = assign(socket, :user, %{position: player_position})

    {:noreply, socket}
  end

  def handle_event("getUserData", _params, socket) do
    # No expected token data received from the client
    Logger.debug("No LiveView SessionStorage state to restore")
    {:noreply, socket}
  end

  ###
  # Click events
  #

  def handle_event("start_game", _, socket) do
    game_id = socket.assigns.game_id
    via = Game.via_tuple(game_id)

    case Game.start_game(via) do
      :ok ->
        # TODO>>>> Add test for this pubsub update
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
        # TODO>>>> Add test for this pubsub update
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

  def handle_event("discard", %{"card_position" => card_position}, socket) do
    card_position = String.to_integer(card_position)
    # discard_cards()
    {:ok, table} =
      Table.discard_cards(
        socket.assigns.table,
        [card_position],
        socket.assigns.user.position
      )

    {:noreply,
     socket
     |> assign(:table, table)
     |> assign(:top_discard, top_discard(table))}
  end

  def handle_event("discard", _, socket) do
    {:noreply, socket}
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
     |> assign(:table, table)}
  end

  def handle_info({:table_updated, table}, socket) do
    {:noreply, assign(socket, :table, table)}
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
end
