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
    messages = Enum.sort_by(messages, &(&1.time_stamp.created_on), {:desc, DateTime})
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
        slugs = %{
          1019 => "grace",
          2019 => "mindy",
          1016 => "keith"
        }

        type = %{
          1019 => "virtual agent",
          2019 => "virtual agent",
          1016 => "human operator"
        }

        %{
          member: %{
            identifier: x,
            slug: slugs[x],
            type: type[x]
          },
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

      sender_type = case message.sender do
        %Noizu.Intellect.Account.Agent{} -> "virtual agent"
        %Noizu.Intellect.Account.Member{} -> "human"
      end

      slug = case message.sender do
        %Noizu.Intellect.Account.Agent{} -> message.sender.slug
        %Noizu.Intellect.Account.Member{} -> message.sender.user.slug
      end

      %{
        id: message.identifier,
        to_nodes: responding_to,
        priority: message.priority,
        sender: %{
           type: sender_type,
           identifier: message.sender.identifier,
           slug: slug
        },
        contents: contents,
        read: read,
        reply?: is_nil(message.answered_by) && message.priority > 40 && is_nil(read) && true || false,
        time: message.time_stamp.created_on,
        recipients: audience,
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
