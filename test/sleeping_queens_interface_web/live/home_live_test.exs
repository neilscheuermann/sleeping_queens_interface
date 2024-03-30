defmodule SleepingQueensInterfaceWeb.HomeLiveTest do
  use SleepingQueensInterfaceWeb.ChannelCase
  use SleepingQueensInterfaceWeb.ConnCase

  alias SleepingQueensEngine.Game

  import Phoenix.LiveViewTest

  @player1_name "player1"
  @player2_name "player2"
  @player3_name "player3"

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    assert render(view) =~ "Sleeping Queens"
  end

  test "renders a create game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Create Game"
  end

  test "creating a game redirects to game page with random game id and player's position",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view)

    # checks for /game/<ANY_4_CHARACTERS>/<PLAYER_POSITION>
    assert path =~ ~r/game\/([A-Za-z0-9]{4})\/1/
  end

  test "renders a join game button", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "Join Game"
  end

  test "joining a game redirects to game page with provided game id and player's position",
       %{conn: conn} do
    # create game with player 1
    {:ok, view1, _html} = live(conn, "/")
    render_click(view1, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view1)
    game_id = extract_game_id(path)

    # join game with player 2
    {:ok, view2, _html} = live(conn, "/")

    render_click(view2, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    {path, _flash} = assert_redirect(view2)

    assert path =~ "/game/#{game_id}/2"
  end

  test "when a player joins a game, a pubsub message with the updated rules and table is sent to those subscribed to that game's topic",
       %{conn: conn} do
    # create game with player 1
    {:ok, view1, _html} = live(conn, "/")
    render_click(view1, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view1)
    game_id = extract_game_id(path)

    # Subscribe to the game topic
    @endpoint.subscribe("game:#{game_id}")

    # join game with player 2
    {:ok, view2, _html} = live(conn, "/")

    render_click(view2, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    {path, _flash} = assert_redirect(view2)
    assert extract_game_id(path) == game_id

    # Make sure this subscribed process receives the message.
    assert_receive({:game_updated, {rules, table}})
    assert rules.player_count == 2

    Enum.each(
      table.players,
      assert(&(&1.name in [@player1_name, @player2_name]))
    )
  end

  test "cannot join a game that has already started",
       %{conn: conn} do
    # create game with player 1
    {:ok, view1, _html} = live(conn, "/")
    render_click(view1, "create_game", %{"player_name" => @player1_name})
    {path, _flash} = assert_redirect(view1)
    game_id = extract_game_id(path)

    # join game with player 2
    {:ok, view2, _html} = live(conn, "/")

    render_click(view2, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player2_name
    })

    {path, _flash} = assert_redirect(view2)
    assert path =~ "/game/#{game_id}/2"

    # Start game
    via = Game.via_tuple(game_id)
    assert :ok = Game.start_game(via)
    %{rules: %{state: :playing}} = Game.get_state(via)

    # player 3 tries to join game but doesn't get redirected and sees a flash message
    {:ok, view3, _html} = live(conn, "/")

    render_click(view3, "join_game", %{
      "game_id" => game_id,
      "player_name" => @player3_name
    })

    :ok = refute_redirected(view3, "/game/#{game_id}/3")
    assert render(view3) =~ "Unable to join game"
  end

  # # TODO>>>> Can I return an error rather than the home live view crashing?
  # # Right now it's crashing in Game.add_player because there's not process in 
  # # the registry when it tries to call GenServer.call(game, {:add_player, name})
  # test "cannot join a game that doesn't exist",
  #      %{conn: conn} do
  #   non_existent_game_id = "XXXX"
  #   {:ok, view, _html} = live(conn, "/")
  #
  #   render_click(view, "join_game", %{
  #     "game_id" => non_existent_game_id,
  #     "player_name" => @player2_name
  #   })
  #
  #   :ok = refute_redirected(view, "/game/#{non_existent_game_id}/2")
  #   assert render(view) =~ "Unable to join game"
  # end

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
  #
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

  # Returns game id from a path structured like "/game/ABCD/player_position"
  defp extract_game_id(path) do
    path
    |> String.split("/")
    |> Enum.at(2)
  end
end
