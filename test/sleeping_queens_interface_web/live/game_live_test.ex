defmodule SleepingQueensInterfaceWeb.GameLiveTest do
  use SleepingQueensInterfaceWeb.ChannelCase
  use SleepingQueensInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  @player1_name "player1"
  @player2_name "player2"

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

    # Anyone vising the game page would see both players
    {:ok, view, _html} = live(conn, "/game/#{game_id}/any_name")

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
    game_id = extract_game_id(path)

    # Visit the game page
    {:ok, view, _html} = live(conn, "/game/#{game_id}/any_name")

    assert view.module == SleepingQueensInterfaceWeb.GameLive
    assert render(view) =~ "Start Game"
  end

  test "shows flash error when trying to start a game without enough players", %{
    conn: conn
  } do
    # Player1 creates game and redirected to game page
    {:ok, view, _html} = live(conn, "/")
    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)
    game_id = extract_game_id(path)

    # Visit the game page
    {:ok, view, _html} = live(conn, "/game/#{game_id}/any_name")

    assert view.module == SleepingQueensInterfaceWeb.GameLive
    assert render(view) =~ "Start Game"

    # Visit the game page
    render_click(view, "start_game")
    assert render(view) =~ "Unable to start game without enough players"
  end

  # Returns game id from a path structured like "/game/ABCD/player1_name"
  defp extract_game_id(path) do
    path
    |> String.split("/")
    |> Enum.at(2)
  end
end
