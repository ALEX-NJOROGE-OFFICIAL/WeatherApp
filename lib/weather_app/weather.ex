defmodule WeatherApp.WeatherService do
  @moduledoc false

  @endpoint "https://api.open-meteo.com/v1"

  def fetch_weather(city) do
    url = "#{@endpoint}/weather?city=#{city}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode(body)}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, "HTTP request failed with status #{code}: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end
end
