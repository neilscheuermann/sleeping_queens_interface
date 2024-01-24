defmodule SleepingQueensInterfaceWeb.HomeLiveTest do
  use SleepingQueensInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert view.module == SleepingQueensInterfaceWeb.HomeLive
    assert render(view) =~ "Sleeping Queens"
  end
end
