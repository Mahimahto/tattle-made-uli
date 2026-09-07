defmodule UliCommunityWeb.LocaleController do
  use UliCommunityWeb, :controller

  @supported_locales ["en", "hi"]

  def set(conn, %{"locale" => locale}) when locale in @supported_locales do
    conn
    |> put_session(:locale, locale)
    |> redirect(to: return_path(conn))
  end

  def set(conn, _params) do
    redirect(conn, to: return_path(conn))
  end

  defp return_path(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
        uri = URI.parse(referer)
        if uri.host == conn.host, do: uri.path || "/", else: "/"
      _ ->
        "/"
    end
  end
end
