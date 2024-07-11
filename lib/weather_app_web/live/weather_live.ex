defmodule WeatherAppWeb.WeatherLive do
  use WeatherAppWeb, :live_view

  @weatherbit_api_key "c4c6cb0ee9154f2d920a60814c28b7e1"

  def render(assigns) do
    ~H"""
    <div>
      <%= if assigns.temperature do %>
        <h2>Current Temperature</h2>
        <%= assigns.temperature %>
      <% else %>
        <p>Error: <%= assigns.error_message %></p>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    fetch_temperature("New York", socket)
  end

  def handle_info({:phoenix_live_view, _}, socket) do
    fetch_temperature("New York", socket)
  end

  def handle_params(_params, socket) do
    {:noreply, socket}
  end

  def fetch_temperature(city, socket) do
    case HTTPoison.get("https://api.weatherbit.io/v2.0/current", params(city)) do
      {:ok, %{status_code: 200, body: body}} ->
        case parse_weatherbit_response(body) do
          {:ok, temperature} ->
            {:ok, assign(socket, temperature: temperature)}

          {:error, reason} ->
            {:ok, assign(socket, error_message: reason)}
        end

      {:ok, %{status_code: 403, body: _body}} ->
        {:ok, assign(socket, error_message: "API key is required. Please check your API key.")}

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, "HTTP request failed with status #{status_code}: #{body}"}

      {:error, error} ->
        {:error, "Failed to make HTTP request: #{inspect(error)}"}
    end
  end

  defp params(city) do
    %{
      query: URI.encode("key=#{@weatherbit_api_key}&city=#{city}&country=US")
    }
  end

  defp parse_weatherbit_response(body) do
    case Jason.decode(body) do
      {:ok, %{"data" => [%{"temp" => temp, "city_name" => city_name}]}} ->
        {:ok, "#{city_name}: #{temp} °C"}

      {:ok, %{"error" => %{"message" => error_message}}} ->
        {:error, error_message}

      {:ok, _} ->
        {:error, "Unexpected response format from Weatherbit API"}

      {:error, _} ->
        {:error, "Failed to parse JSON response from Weatherbit API"}
    end
  end
end
