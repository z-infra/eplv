defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def default(socket) do
    assign(socket,
      score: 0,
      message: "Make a guess",
      time: time(),
      number: Enum.random(1..10),
      win: false
    )
  end

  def mount(_params, _session, socket) do
    {:ok, default(socket)}
  end

  def win(socket, guess) do
    {:noreply,
     assign(socket,
       message: "Your guess: #{guess}",
       score: socket.assigns.score + 1,
       time: time(),
       win: true,
       number: Enum.random(1..10)
     )}
  end

  def lose(socket, guess) do
    {:noreply,
     assign(socket,
       message: "Your guess: #{guess}",
       score: socket.assigns.score - 1,
       time: time(),
       win: false
     )}
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    {guess_number, _} = Integer.parse(guess)

    if guess_number == socket.assigns.number do
      win(socket, guess)
    else
      lose(socket, guess)
    end
  end

  def handle_params(_params, _addr, socket) do
    {:noreply, default(socket)}
  end

  def reset(socket) do
    {:noreply, default(socket)}
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <h1>Your score: <%= @score %></h1>
      <h2>
        <%= @message %><br>
      </h2>
      <h3>
        Time: <%= @time %>
      </h3>
      <h2>
        <%= for n <- 1..10 do %>
          <.link href="#" phx-click="guess" phx-value-number={n} >
            <%= n %>
          </.link>
        <% end %>
      </h2>
      <%= if @win do %>
        <h1>
          You Win!!!<br>
          <.link patch={~p"/guess"}>Reset</.link>
        </h1>
      <% end %>
    """
  end

  def time() do
    with time <- DateTime.utc_now() do
      [time.hour, time.minute, time.second]
      |> Enum.join(":")
    end
  end
end
