defmodule SleepingQueensInterfaceWeb.GameLive do
  use SleepingQueensInterfaceWeb, :live_view

  alias SleepingQueensEngine.Table
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.Player

  # TODO>>>> Replace hard coded values and connect to GenServer
  def mount(params, _session, socket) do
    user = %{position: 1}
    player1 = Player.new(params["player_name"])
    player2 = Player.new("leslie")
    player3 = Player.new("andy")
    player4 = Player.new("april")
    player5 = Player.new("tom")
    players = [player1, player2, player3, player4, player5]

    table = setup_table(players)

    {:ok,
     socket
     |> assign(:table, table)
     |> assign(:top_discard, top_discard(table))
     |> assign(:user, user)}
  end

  def handle_event("deal_cards", _args, socket) do
    table = Table.deal_cards(socket.assigns.table)

    {:noreply, assign(socket, :table, table)}
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
  # Private Functions
  #

  defp setup_table(players) do
    players
    |> Table.new()
    |> Table.deal_cards()
  end

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
end
