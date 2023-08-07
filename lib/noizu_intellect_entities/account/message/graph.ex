#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Intellect.Account.Message.Graph do
  defstruct [
    nodes: nil,
    edges: nil
  ]

  def to_graph([], context, options), do: {:error, :empty}
  def to_graph(messages, context, options) do
    recent_cut_off = (options[:current_time] || DateTime.utc_now()) |> Timex.shift(minutes: -15)

    message_nodes = Enum.map(messages, & &1.identifier)
    message_edges = Enum.map(messages, fn(message) ->
      responding_to = Enum.map(message.responding_to || %{}, fn({x, xm}) ->
        %{
          message: x,
          confidence: xm.confidence,
          comment: xm.comment
        }
      end)

      audience = Enum.map(message.audience || %{}, fn({x, xm}) ->
        %{
          member: x,
          confidence: xm.confidence,
          comment: xm.comment
        }
      end)

      # include recency checks
      contents = cond do
        DateTime.compare(recent_cut_off, message.time_stamp.created_on) == :lt ->
          message.contents && message.contents.body
        message.priority && message.priority > 40 ->
          message.contents && message.contents.body
        :else ->
          message.brief && message.brief.body || message.contents && message.contents.body
      end

      #
      read = message.read_on && true || false

      %{
        id: message.identifier,
        to_nodes: responding_to,
        priority: message.priority,
        sender: message.sender.identifier,
        contents: contents,
        read: read,
        time: message.time_stamp.created_on,
        audience: audience,
      }
    end)

    {
      :ok,
      %__MODULE__{
        nodes: message_nodes,
        edges: message_edges,
      }
    }
  end

  defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol do
    def prompt(subject, prompt_context, context, options) do
      Poison.encode(subject, pretty: true)
    end
    def minder(subject, prompt_context, context, options), do: {:ok, nil}
  end
end
