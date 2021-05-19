defmodule ChangelogWeb.Plug.Conn do
  @moduledoc """
  General-purpose, connection-related functions available to controllers.
  """

  import Plug.Conn

  alias ChangelogWeb.Router

  @doc """
  Extracts the user agent from a connection's headers
  """
  def get_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
  end

  @doc """
  Extracts the host from a connection's headers
  """
  def get_host(conn) do
    conn
    |> get_req_header("host")
    |> List.first()
    |> to_string
    |> String.split(":")
    |> List.first()
  end

  @doc """
  Extracts the local referer (path) from a connection's headers. Useful for
  redirecting back to previous page.
  """
  def get_local_referer(conn) do
    referer =
      conn
      |> get_req_header("referer")
      |> Enum.at(0, "")
      |> URI.parse()

    if referer.host == conn.host do
      referer
      |> Map.merge(%{authority: nil, host: nil, scheme: nil, port: nil})
      |> URI.to_string()
    else
      nil
    end
  end

  @doc """
  Extracts and returns the request referer, falling back to the root path
  """
  def referer_or_root_path(conn) do
    with {:ok, referer} <- extract_referer(conn),
         {:ok, path} <- extract_local_path(conn, referer) do
      path
    else
      _fail -> Router.Helpers.root_path(conn, :index)
    end
  end

  defp extract_referer(conn) do
    if referer = conn |> get_req_header("referer") |> List.last() do
      {:ok, referer}
    else
      {:error, "no referer header"}
    end
  end

  defp extract_local_path(conn, referer) do
    uri = URI.parse(referer)
    path = Map.get(uri, :path)

    cond do
      uri.host != conn.host -> {:error, "external referer"}
      String.starts_with?(path, "//") -> {:error, "invalid path"}
      true -> {:ok, path}
    end
  end
end
