defmodule Merchandise do
  defstruct name: "chocolate",
  url: "https://google.com",
  price: -1,
  time: 0
end

defmodule LohacoWitch.Scraping do
  @lohaco_url Application.fetch_env!(:lohaco_witch, :lohaco_url)

  def run(parsed_html) do
    marchandices(
      parsed_html |> name_and_href,
      parsed_html |> price
    )
  end

  def name_and_href(parsed_html) do
    searched_list = parsed_html
    |> Floki.find(".black--text")
    |> Floki.find(".text-decoration-none")
    |> Floki.find("a")
    %{
      names: searched_list |> extract_name,
      hrefs: searched_list |> extract_hrefs
    }
  end
  defp extract_name(searched_list) do
    searched_list
    |> Enum.map(&match_name/1)
    |> Enum.filter(&(&1 != nil))
    |> Enum.map(&tirmming/1)
  end
  defp match_name({"a", _, [name]}), do: name
  defp match_name(_), do: nil
  defp tirmming(s) do
    s |> String.trim |> String.replace("　", " ")
  end
  defp extract_hrefs(searched_list) do
    searched_list
    |> Enum.map(&extract_href/1)
    |> Enum.filter(
      fn s -> s |> String.slice(0, 6) == "/store" end
    )
    |> Enum.map(&("#{@lohaco_url}#{&1}"))
  end
  defp extract_href({"a", attrs, _}) do
    attrs
    |> Enum.map(&extract_href_from_attr/1)
    |> Enum.filter(&(&1 != nil))
    |> Enum.at(0)
  end
  defp extract_href_from_attr({"href", href}), do: href
  defp extract_href_from_attr(_), do: nil

  def price(parseed_html) do
    ret = parseed_html
    |> Floki.find(".text-h4")
    |> Floki.find(".text-sm-h3")
    |> Floki.find("span")
    |> Enum.map(&extract_price/1)
    |> Enum.filter(&(&1 != nil))
    %{prices: ret}
  end
  defp extract_price({"span", _, [price]}) do
    price
    |> String.replace(",", "")
    |> String.to_integer()
  end
  defp extract_price(_), do: nil

  defp timestamp() do
    {a, b, _} = :erlang.now
    (a |> Integer.to_string) <> (b |> Integer.to_string) |> String.to_integer
  end

  defp marchandices(%{names: names, hrefs: hrefs}, %{prices: prices}) do
    Enum.zip([names, hrefs, prices])
    |> Enum.map(&make_merchandise/1)
  end
  defp make_merchandise({name, href, price}) do
    %Merchandise{name: name, url: href, price: price, time: timestamp()}
  end
end
