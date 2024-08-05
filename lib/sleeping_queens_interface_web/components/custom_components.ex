defmodule SleepingQueensInterfaceWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """
  use Phoenix.Component

  @doc ~S"""
  Renders a card

  ## Examples

      <.card card={card} card_position={card_position}/>
  """
  attr :card, :map
  attr :card_position, :integer, default: nil
  attr :class, :string, default: nil

  def card(assigns) do
    ~H"""
    <div
      class={[
        "w-16 h-24 border border-gray-700 shadow hover:shadow-lg rounded overflow-hidden",
        @class
      ]}
      phx-click="select"
      phx-value-card_position={@card_position}
    >
      <div class="p-1">
        <%= if @card.type == :number, do: @card.value, else: @card.type %>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders a queen card

  ## Examples

      <.queen_card queen={queen} row={row} col={col}/>
  """

  def queen_card(assigns) do
    ~H"""
    <div class="flex flex-col p-1 justify-between w-16 h-24 bg-fuchsia-300 border border-gray-700 rounded overflow-hidden">
      <div>
        <%= @queen.name %>
      </div>
      <div>
        <%= @queen.value %>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders the banner for game info

  ## Examples

      <.banner>
        Some interesting text...
      </.banner>
  """
  slot :inner_block, required: true

  def banner(assigns) do
    ~H"""
    <p class="text-lg text-center">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc ~S"""
  Player icon with inner content

  ## Examples

      <.player />
  """
  attr :action_required?, :boolean, default: false
  slot :inner_block, required: true

  def player(assigns) do
    ~H"""
    <span class={"#{@action_required? and "bg-yellow-200 rounded-full"}"}>
      <svg
        class="w-24"
        xmlns="http://www.w3.org/2000/svg"
        fill="black"
        viewBox="0 0 24 24"
        strokeWidth={1.5}
        stroke="currentColor"
        className="w-6 h-6"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
        />
      </svg>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
