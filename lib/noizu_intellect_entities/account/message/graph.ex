#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Intellect.Account.Message.Graph do
  @derive Ymlr.Encoder
  defstruct [
    message_node_list: nil,
    message_edge_list: nil,
    messages: nil
  ]

  def to_graph([], _channel_members, _context, _options), do: {:error, :empty}
  def to_graph(messages, channel_members, _context, options) do
    recent_cut_off = (options[:current_time] || DateTime.utc_now()) |> Timex.shift(minutes: -5)
    messages = Enum.sort_by(messages, &(&1.time_stamp.created_on), {:desc, DateTime})
    node_list = Enum.map(messages, & &1.identifier)
    edge_list = Enum.map(messages, fn(message) ->
      Enum.map(message.responding_to || %{}, fn({x, xm}) ->
        unless xm.confidence < 30 do
          {message.identifier, x}
        end
      end) |> Enum.reject(&is_nil/1)
    end) |> List.flatten()

    slug_lookup = Enum.map(channel_members, fn(member) ->
      case member do
        %{slug: slug} -> {member.identifier, %{slug: slug, type: "virtual agent"}}
        %{user: %{slug: slug}} -> {member.identifier, %{slug: slug, type: "human operator"}}
      end
    end) |> Map.new()

    nodes = Enum.map(messages, fn(message) ->
      # todo user vdb to determine if recent messages has matching features.
      contents = cond do
        DateTime.compare(recent_cut_off, message.time_stamp.created_on) == :lt ->
          message.contents && message.contents.body
        message.answered_by ->
          message.brief && message.brief.body || message.contents && message.contents.body
        message.priority && message.priority > 60 -> message.contents && message.contents.body
        :else ->
          message.brief && message.brief.body || message.contents && message.contents.body
      end

      %{
        id: message.identifier,
        sender: "#{message.sender.identifier} @#{slug_lookup[message.sender.identifier][:slug] || "???"} (#{slug_lookup[message.sender.identifier][:type] || "virtual agent"})",
        contents: contents,
        processed?: !is_nil(message.read_on),
        review?: is_nil(message.answered_by) && message.priority > 60 && is_nil(message.read_on) && true || false,
        time: DateTime.to_unix(message.time_stamp.created_on),
      }
    end)

    {
      :ok,
      %__MODULE__{
        message_node_list: node_list,
        message_edge_list: edge_list,
        messages: nodes
      }
    }
  end

  defimpl Noizu.Intellect.Prompt.DynamicContext.Protocol do
    def prompt(subject, _prompt_context, _context, _options) do
      {:ok, Ymlr.document!(subject)}
    end
    def minder(_subject, _prompt_context, _context, _options), do: {:ok, nil}
  end
end
