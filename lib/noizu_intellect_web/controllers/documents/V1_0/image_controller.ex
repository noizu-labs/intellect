defmodule Noizu.IntellectWeb.Documents.V1_0.ImageController do
  use Noizu.IntellectWeb, :controller
  import Plug.Conn

  def get(conn, %{"type" => "profile", "image" => image} = _params) do
    cond do
      image == "default" ->
        path = "/github/noizu_intellect/priv/static/images/profile/default"
        contents = File.read!(path)
        conn
        |> put_resp_content_type("application/png")
        |> send_resp(200, contents)
      :else ->
        path = "/github/noizu_intellect/user-content/images/profile/#{image}"
        contents = File.read!(path)
        conn
        |> put_resp_content_type("application/png")
        |> send_resp(200, contents)
    end
  end

end
