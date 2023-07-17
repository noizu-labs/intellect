defmodule Noizu.IntellectWeb.ErrorJSONTest do
  use Noizu.IntellectWeb.ConnCase, async: true

  test "renders 404" do
    assert Noizu.IntellectWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Noizu.IntellectWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
