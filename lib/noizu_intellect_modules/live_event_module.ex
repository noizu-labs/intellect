#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Intellect.LiveEventModule do
  @moduledoc """
  The LiveEventModule is used for subscribing to and receiving events between LiveView Components
  for universal state updates such as login/logout events where standard methods fall apart.
  """

  require Record
  require Logger
  alias Phoenix.PubSub

  Record.defrecord(:event, [subject: nil, instance: nil, event: nil, payload: nil])



  def unsubscribe(event(
    subject: s_subject,
    instance: s_instance,
    event: s_event
  ) ) do
    key = [s_subject, s_instance, s_event]
          |> Enum.map(&("#{&1 || "*"}"))
          |> Enum.join(":")
    #Logger.warn("PUBSUB Unsubscribe: #{key}")
    PubSub.unsubscribe(Noizu.Intellect.LiveViewEvent, key)
  end

  def subscribe(msg = event(
    subject: s_subject,
    instance: s_instance,
    event: s_event
  ) ) do

    key = [s_subject, s_instance, s_event]
          |> Enum.map(&("#{&1 || "*"}"))
          |> Enum.join(":")

    #Logger.warn("PUBSUB Subscribe: #{key}")
    PubSub.subscribe(Noizu.Intellect.LiveViewEvent, key)
  end

  def publish(event(
    subject: s_subject,
    instance: s_instance,
    event: s_event,
    payload: _payload
  ) = msg) do
    # This is super inefficient, better routing will be needed in the future.
    # - Consider just switching to Syn and dedicating a message coordinater per User or User Session, although there are some upsides to pushing updates
    # - via pub sub for keeping pages synched across users/devices/sessions with out needing to add a bunch of addtiional logic.
    keys = [
      "#{s_subject}:*:*",
      "#{s_subject}:#{s_instance}:*",
      "#{s_subject}:#{s_instance}:#{s_event}",
      "#{s_subject}:*:#{s_event}",
    ]

    #Logger.info("PUB-SUB-EMIT: #{inspect keys} -> #{inspect msg}")
    Enum.map(keys, fn(key) ->
      PubSub.broadcast(
        Noizu.Intellect.LiveViewEvent,
        key,
        msg
      )
    end)
  end

end
