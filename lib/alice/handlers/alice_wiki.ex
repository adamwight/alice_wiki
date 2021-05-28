# require IEx;

defmodule Alice.Handlers.Wiki do
  @moduledoc """
  This handler will allow Alice look up wikipedia items.
  """

  use Alice.Router

  @url "https://en.wikipedia.org/w/api.php"

  route ~r/^wiki\s+me\s+(?<term>.+)/i, :fetch_wiki

  @doc "`wiki me ____` - attempts to fetch a wikipedia item."
  def fetch_wiki(conn) do
    conn
    |> get_term()
    |> get_wiki()
    |> build_reply()
    |> reply(conn)
  end

  defp get_term(conn) do
    conn
    |> Alice.Conn.last_capture()
    |> String.downcase()
    |> String.trim()
  end

  def get_wiki(term) do
    Wiki.Action.new(@url)
    |> Wiki.Action.get(
      action: "opensearch",
      search: term
    )
    |> (&(&1.result)).()
  end

  defp build_reply({_, body}) do
    # IEx.pry
    if entry_found?(body) do
      [
        link(body),
        other_links(body)
      ] |> Enum.join("\n")
    else
      "No Wikipedia entry found for '#{Enum.at(body, 0)}'"
    end
  end

  defp entry_found?(body) do
    body
    |> Enum.at(1)
    |> length
    |> Kernel.>(0)
  end

  defp link(body) do
    body
    |> Enum.at(3)
    |> hd
  end

  defp other_links(body) do
    links = filter_links(body)

    if length(links) > 0 do
      ["Others:"]
      |> Enum.concat(links)
      |> Enum.join("\n")
    end
  end

  defp filter_links(body) do
    body
    |> Enum.at(3)
    |> Enum.take(5)
    |> Enum.slice(1..-1)
    |> Enum.map(&process_link/1)
  end

  def process_link(link) do
    link
    |> String.slice(8..-1)
  end
end
