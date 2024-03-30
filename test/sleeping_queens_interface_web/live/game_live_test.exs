defmodule SleepingQueensInterfaceWeb.GameLiveTest do
  use SleepingQueensInterfaceWeb.ChannelCase
  use SleepingQueensInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  @player1_name "player1"
  @player2_name "player2"
  @total_number_of_draw_cards 68

  test "renders all joined players", %{conn: conn} do
    # Player1 goes to home page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive

    # Creates game and is redirected
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)
    game_id = extract_game_id(path)

    # Player2 goes to home page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive

    # Joins player1's game and is redirected to correct game
    render_click(view, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    {path, _flash} = assert_redirect(view)
    assert extract_game_id(path) == game_id

    # Player2 visits the game page and sees both players
    {:ok, view, _html} = live(conn, path)

    assert view.module == SleepingQueensInterfaceWeb.GameLive
    assert render(view) =~ @player1_name
    assert render(view) =~ @player2_name
  end

  test "shows a start game button if the game hasn't started", %{conn: conn} do
    # Player1 creates game and redirected to game page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)

    # Visit the game page
    {:ok, view, _html} = live(conn, path)

    assert view.module == SleepingQueensInterfaceWeb.GameLive
    assert render(view) =~ "Start Game"
  end

  test "shows flash error when trying to start a game without enough players",
       %{
         conn: conn
       } do
    # Player1 creates game and redirected to game page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)

    # Visit the game page
    {:ok, view, _html} = live(conn, path)
    assert view.module == SleepingQueensInterfaceWeb.GameLive
    assert render(view) =~ "Start Game"

    # Try to start the game
    render_click(view, "start_game")
    assert render(view) =~ "Unable to start game without enough players"
  end

  test "renders correct number of cards in draw pile before and after dealing the cards",
       %{conn: conn} do
    # Player1 goes to home page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive

    # Creates game and is redirected
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)
    game_id = extract_game_id(path)

    # Player2 goes to home page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive

    # Joins player1's game and is redirected to correct game
    render_click(view, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    {path, _flash} = assert_redirect(view)
    assert extract_game_id(path) == game_id

    # Visit game page
    {:ok, view, _html} = live(conn, path)
    assert view.module == SleepingQueensInterfaceWeb.GameLive

    # start game
    render_click(view, "start_game")
    assert render(view) =~ "#{@total_number_of_draw_cards} cards"

    # deal cards
    render_click(view, "deal_cards")
    assert render(view) =~ "#{@total_number_of_draw_cards - 10} cards"
  end

  describe "PubSub" do
    setup :create_game_and_subscribe

    test "updates send correctly to the game topic for needed game actions", %{
      conn: conn,
      game_id: game_id
    } do
      # Visit the game page as player1
      {:ok, view, _html} = live(conn, "/game/#{game_id}/1")

      # TEST starting a game
      render_click(view, "start_game")
      assert_receive({:game_updated, {rules, table}})

      Enum.each(
        table.players,
        &assert(&1.name in [@player1_name, @player2_name])
      )

      assert %SleepingQueensEngine.Rules{
               state: :playing,
               player_count: 2,
               player_turn: 1,
               waiting_on: nil
             } = rules

      # TEST dealing cards
      render_click(view, "deal_cards")
      assert_receive({:game_updated, {_rules, table}})

      assert length(table.draw_pile) == @total_number_of_draw_cards - 10
    end
  end

  defp create_game_and_subscribe(%{conn: conn}) do
    # Player1 creates game
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)
    game_id = extract_game_id(path)

    # Subscribe to the game topic (imitates player1 joining) and should receive all
    # updates in order
    @endpoint.subscribe("game:#{game_id}")

    # Player2 joins game
    {:ok, view, _html} = live(conn, "/")

    render_click(view, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    assert_receive({:table_updated, table})
    assert length(table.players) == 2

    %{game_id: game_id}
  end

  # Returns game id from a path structured like "/game/ABCD/player1_name"
  defp extract_game_id(path) do
    path
    |> String.split("/")
    |> Enum.at(2)
  end
end
