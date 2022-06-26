defmodule LohacoWitch do
  @lohaco_url Application.fetch_env!(:lohaco_witch, :lohaco_url)
  @user_agent [{"User-agent", "hmdyt"}]

  def main(argv) do
    argv
    |> OptionParser.parse
    |> cli_handler
    |> run
  end
  def cli_handler({_, [query], _}), do: query
  def cli_handler(_) do
    IO.puts """
    usage: lohaco_witch <query>
    """
    System.halt(1)
  end

  def run(query) do
    query
    |> search_url
    |> fetch_html
    |> decode_response
    |> parse_html
    |> LohacoWitch.Scraping.run
    |> IO.inspect
  end

  def search_url(query) do
    "#{@lohaco_url}/search?p=#{query}"
    |> URI.encode
  end

  def fetch_html(url) do
    url
    |> HTTPoison.get(@user_agent)
    |> handle_response
  end

  def handle_response({_, %{status_code: status_code, body: body}}) do
    {
      status_code |> check_status_code,
      body
    }
  end

  defp check_status_code(200), do: :ok
  defp check_status_code(_), do: :error

  def decode_response({:ok, body}), do: body
  def decode_response({:error, body}) do
    IO.puts """
    Error fetching lohaco
    #{body}
    """
    System.halt(2)
  end

  def parse_html(body) do
    body
    |> Floki.parse_document
    |> handle_parse_html
  end

  defp handle_parse_html({:ok, document}), do: document
  defp handle_parse_html(_) do
    IO.puts """
    Error parsing html
    """
    System.halt(2)
  end
end
