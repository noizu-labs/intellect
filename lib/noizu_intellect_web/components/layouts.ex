defmodule Noizu.IntellectWeb.Layouts do
  use Noizu.IntellectWeb, :html
  import Noizu.IntellectWeb.CoreComponents
  embed_templates "layouts/*"


  def close_sidebar() do
    Phoenix.LiveView.JS.add_class("hidden", to: "#side-bar-menu")
  end

  def open_sidebar() do
    Phoenix.LiveView.JS.remove_class("hidden", to: "#side-bar-menu")
  end

  def toggle_user_menu() do
    toggle_attribute({"aria-expanded", "true"}, to: "#user-menu-button")
    toggle_attribute({"aria-expanded", "true"}, to: "#user-menu")
  end

end
