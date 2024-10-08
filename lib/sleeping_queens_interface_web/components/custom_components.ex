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
  attr :emoji, :string
  attr :bg_color, :string, default: ""
  attr :card_position, :integer, default: nil
  attr :class, :list, default: []

  def card(assigns) do
    bg_color =
      case assigns.card.type do
        :knight -> "bg-red-200"
        :sleeping_potion -> "bg-red-200"
        :dragon -> "bg-blue-200"
        :wand -> "bg-blue-200"
        :jester -> "bg-teal-200"
        :king -> "bg-violet-400"
        _ -> "bg-amber-50"
      end

    assigns = assign(assigns, :bg_color, bg_color)

    ~H"""
    <div
      class={[
        "w-16 h-24 border border-gray-700 shadow hover:shadow-lg rounded overflow-hidden",
        @bg_color
        | @class
      ]}
      phx-click="select"
      phx-value-card_position={@card_position}
    >
      <p :if={@card.type == :number} class="p-1 text-2xl"><%= @card.value %></p>
      <p :if={@card.type != :number} class="p-1 pb-0 text-xl"><%= @emoji %></p>
      <p :if={@card.type == :king} class="p-1 pt-0 text-xs text-slate-50">
        <%= @card.name %>
      </p>
    </div>
    """
  end

  @doc ~S"""
  Renders a queen card

  ## Examples

      <.queen_card queen={queen} row={row} col={col}/>
  """
  attr :name, :string, required: true
  attr :emoji, :string, required: true
  attr :value, :integer, required: true
  attr :special?, :boolean, required: true
  attr :shrink?, :boolean, default: false
  attr :class, :list, default: []
  attr :rest, :global, include: ~w(disabled), doc: "something...."

  def queen_card(assigns) do
    # `pointer-events-none` CSS property is added so the event isn't emitted
    ~H"""
    <div
      class={[
        "flex flex-col p-1 justify-between bg-fuchsia-300 border border-gray-700 rounded",
        "#{if @shrink?, do: "w-8 h-12", else: "w-12 h-20"}",
        "#{if @special?, do: "border-2 border-yellow-600 bg-fuchsia-100"}",
        "#{if @rest[:disabled], do: "text-gray-500 bg-gray-300 pointer-events-none"}"
        | @class
      ]}
      {@rest}
    >
      <p class={if @shrink?, do: "", else: "text-xl"}><%= @emoji %></p>
      <p class="text-xs text-slate-50 overflow-hidden"><%= @name %></p>
      <p><%= @value %></p>
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
    <p class="text-lg text-center whitespace-nowrap overflow-x-auto">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc ~S"""
  Player icon, name, and score

  ## Examples

      <.player />
  """
  attr :name, :string, required: true
  attr :score, :integer, required: true
  attr :action_required?, :boolean, default: false

  def player(assigns) do
    ~H"""
    <div class={["#{@action_required? and "bg-yellow-200 rounded-2xl"}"]}>
      <div class="flex">
        <svg
          class="w-10"
          xmlns="http://www.w3.org/2000/svg"
          fill="black"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
          />
        </svg>
        <div class="w-18">
          <p class="block text-center text-2xl font-bold">
            <%= @score %><span class="text-sm"> pts</span>
          </p>
        </div>
      </div>
      <p class="text-xl font-bold whitespace-nowrap overflow-x-auto">
        <%= @name %>
      </p>
    </div>
    """
  end
end
