defmodule SleepingQueensInterfaceWeb.HomeLiveTest do
  use SleepingQueensInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  @player1 "player1"
  @player2 "player2"

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    assert render(view) =~ "Sleeping Queens"
  end

  test "renders a create game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Create Game"
  end

  # TODO>>>>
  # test "shows create game modal when button is clicked", %{conn: conn} do
  #   {:ok, view, _html} = live(conn, "/")
  #
  #   # Assert that the create game modal is initially not present
  #   # refute render(view) =~ "Create New Game"
  #   # assert has_element?(view, ~s{[id="create_game_modal"][class="relative z-50 hidden"]})
  #   # # assert view |> find_modal("create_game_modal") |> is_nil()
  #
  #   # Click the "Create Game" button
  #   # Assert that the create game modal is now present
  #   assert view
  #          |> element("button", "Create Game")
  #          |> render_click() =~ "Create New Game"
  # end

  test "creating a game redirects to game page with random game id and provided player name",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "create_game", %{"player_name" => @player1})
    {path, _flash} = assert_redirect(view)

    # checks for /game/<ANY_4_CHARACTERS>/
    assert path =~ ~r/game\/([A-Za-z0-9]{4})/
    assert path =~ @player1
  end

  test "renders a join game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Join Game"
  end

  # TODO>>>>
  # test "shows join game modal when button is clicked", %{conn: conn} do
  #   {:ok, view, _html} = live(conn, "/")
  #
  #   # Assert that the join game modal is initially not present
  #   assert view |> find_modal("join_game_modal") |> is_nil()
  #
  #   # Click the "Join Game" button
  #   view
  #   |> click_button("Join Game")
  #
  #   # Assert that the join game modal is now present
  #   assert view |> find_modal("join_game_modal") |> is_not_nil()
  # end

  test "joining a game redirects to game page with provided game id and player name",
       %{conn: conn} do
    # create game with player 1
    {:ok, view1, _html} = live(conn, "/")
    render_click(view1, "create_game", %{"player_name" => @player1})
    {path, _flash} = assert_redirect(view1)
    game_id = extract_game_id(path)

    # join game with player 2
    {:ok, view2, _html} = live(conn, "/")

    render_click(view2, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2
    })

    {path, _flash} = assert_redirect(view2)

    # checks for /game/<ANY_4_CHARACTERS>/ path
    assert path =~ "/game/#{game_id}/#{@player2}"
  end

  # Returns game id from a path structured like "/game/ABCD/player1"
  defp extract_game_id(path) do
    path
    |> String.split("/")
    |> Enum.at(2)
  end
end
