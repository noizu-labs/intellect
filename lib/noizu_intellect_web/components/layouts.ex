defmodule Noizu.IntellectWeb.Layouts do
  use Noizu.IntellectWeb, :html

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

  # from https://github.com/phoenixframework/phoenix_live_view/pull/2004/files
  def toggle_attribute({attr, val}), do: toggle_attribute(%JS{}, {attr, val}, [])

  @doc "See `toggle_attribute/1`."
  def toggle_attribute({attr, val}, opts) when is_list(opts),
      do: toggle_attribute(%Phoenix.LiveView.JS{}, {attr, val}, opts)

  def toggle_attribute(%Phoenix.LiveView.JS{} = js, {attr, val}), do: toggle_attribute(js, {attr, val}, [])

  @doc "See `toggle_attribute/1`."
  def toggle_attribute(%Phoenix.LiveView.JS{} = js, {attr, val}, opts) when is_list(opts) do
    opts = validate_keys(opts, :toggle_attribute, [:to])
    put_op(js, "toggle_attr", %{to: opts[:to], attr: [attr, val]})
  end

  def put_op(%Phoenix.LiveView.JS{ops: ops} = js, kind, args) do
    %Phoenix.LiveView.JS{js | ops: ops ++ [[kind, args]]}
  end

  def validate_keys(opts, kind, allowed_keys) do
    for key <- Keyword.keys(opts) do
      if key not in allowed_keys do
        raise ArgumentError, """
        invalid option for #{kind}
        Expected keys to be one of #{inspect(allowed_keys)}, got: #{inspect(key)}
        """
      end
    end

    opts
  end
end
