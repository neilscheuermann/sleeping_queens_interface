defmodule SleepingQueensInterfaceWeb.HomeLiveTest do
  use SleepingQueensInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    assert render(view) =~ "Sleeping Queens"
  end

  test "renders a create game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Create Game"
  end

  test "redirects to game page with random game code when creating a game", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    render_click(view, "create_game", %{"player_name" => "Neil"})
    {path, _flash} = assert_redirect view

    # checks for /game/<ANY_4_CHARACTERS>/ path
    assert path =~ ~r/game\/([A-Za-z0-9]{4})/
  end

  test "renders a join game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Join Game"
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
end
