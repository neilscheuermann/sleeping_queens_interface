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

      <.banner />
  """
  slot :inner_block, required: true

  def banner(assigns) do
    ~H"""
    <p class="text-xl text-center">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end
end
