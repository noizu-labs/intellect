defmodule Noizu.IntellectWeb.LiveViewError do
  defstruct [
    title: nil,
    body: nil,
    raw: false,
    severity: :warning,
    kind: :error,
    error: nil,
    trace: nil,
    time_stamp: nil,
    request_token: nil,
    context: nil
  ]

  def show_details(this, _context) do
    # take into account user context/permissions.
    this.error && true
  end

  def show_trace(this, _context) do
    # take into account user context/permissions.
    this.trace && true
  end
end
