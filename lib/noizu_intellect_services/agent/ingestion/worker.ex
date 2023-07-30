defmodule Noizu.Intellect.Service.Agent.Ingestion.Worker do
  use Noizu.Entities
  require Noizu.Service.Types
  import Ecto.Query

  require Noizu.Intellect.LiveEventModule
  import Noizu.Intellect.LiveEventModule

  require Noizu.Service.Types
  alias Noizu.Service.Types, as: M

  @vsn 1.0
  @sref "worker-agent"
  @persistence redis_store(Noizu.Intellect.Service.Agent.Ingestion.Worker, Noizu.Intellect.Redis)
  def_entity do
    identifier :dual_ref
    field :agent, nil, Noizu.Entity.Reference
    field :account, nil, Noizu.Entity.Reference
    field :channel, nil, Noizu.Entity.Reference
    field :book_keeping, %{}
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end
  use Noizu.Service.Worker.Behaviour

  #-------------------
  #
  #-------------------
  def init(R.ref(module: __MODULE__, identifier: identifier), _args, _context) do
    %__MODULE__{
      identifier: identifier,
    }
  end

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------

  #-------------------
  #
  #-------------------
  def load(state, context), do: load(state, context, nil)
  def load(state, context, options) do
    with {:ok, worker} <- entity(state.identifier, context) do
      {:ok, worker}
    else
      _ ->
        # TODO we need to handle ref identifiers so we can use the actual ref as our id.
        with {:ok, {agent, channel}} <- id(state.identifier),
             {:ok, agent_entity} <- Noizu.Intellect.Account.Agent.entity(agent, context),
             {:ok, channel_entity} <- Noizu.Intellect.Account.Channel.entity(channel, context),
             {:ok, account} <- ERP.ref(agent_entity.account) do
          worker = %__MODULE__{
                     identifier: state.identifier,
                     agent: agent_entity,
                     channel: channel_entity,
                     account: account
                   } |> shallow_persist(context, options)
          {:ok, worker}
        end
    end
    |> case do
         {:ok, worker} ->
           state = %{state| status: :loaded, worker: worker}
                   |> queue_heart_beat(context, options)
           {:ok, state}
         _ -> {:error, state}
       end
  end

  #---------------------
  #
  #---------------------
  def queue_heart_beat(state, context, options \\ nil, fuse \\ 5_000) do
    # Start HeartBeat
    identifier = {self(), :os.system_time(:millisecond)}
    settings = apply(__pool__(), :__cast_settings__, [])
    timeout = 15_000

    msg = M.s(call: M.call(handler: :heart_beat), context: context, options: options)
    timer = Process.send_after(self(), msg, fuse)
    put_in(state, [Access.key(:worker), Access.key(:book_keeping, %{}), :heart_beat], timer)
  end

  def unread_messages?(_,_,_) do
    true
  end

  def message_history(state,context,options) do
    # We'll actually pull agent digest messages, etc. here.
    Noizu.Intellect.Account.Message.Repo.recent_with_status(state.worker.agent, state.worker.channel, context, options)

  end

  #---------------------
  # process_message_queue
  #---------------------
  def process_message_queue(state, context, options) do
    with true <- unread_messages?(state, context, options),
         {:ok, messages} <- message_history(state, context, options),
         true <- (length(messages) > 0) || {:error, :no_messages},
         {:ok, prompt_context} <- Noizu.Intellect.Prompt.DynamicContext.prepare_prompt_context(state.worker.agent, state.worker.channel, messages, context, options),
         {:ok, request} <- Noizu.Intellect.Prompt.DynamicContext.for_openai(prompt_context, context, options),
         {:ok, request_settings} <- Noizu.Intellect.Prompt.RequestWrapper.settings(request, context, options),
         {:ok, request_messages} <- Noizu.Intellect.Prompt.RequestWrapper.messages(request, context, options)
      do
        IO.inspect(%{messages: request_messages, settings: request_settings}, label: "OPEN AI REQUEST")
        with {:ok, response} <- Noizu.OpenAI.Api.Chat.chat(request_messages, request_settings) do
            # response could be a function call or a response or a mix, need to handle all.
            with %{choices: [%{message: %{content: reply}}|_]} <- response do
              IO.inspect(reply, label: "OPEN AI RESPONSE")



              message = %Noizu.Intellect.Account.Message{
                sender: state.worker.agent,
                channel: state.worker.channel,
                depth: 0,
                user_mood: nil,
                event: :message,
                contents: reply,
                time_stamp: Noizu.Entity.TimeStamp.now()
              }  |> Noizu.Intellect.Entity.Repo.create(context)

              with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(state.worker.channel),
                   {:ok, message} <- message do
                message = %Noizu.IntellectWeb.Message{
                  type: :message,
                  timestamp: message.time_stamp.created_on,
                  user_name: state.worker.agent.slug,
                  profile_image: state.worker.agent.profile_image,
                  mood: :nothing,
                  body: message.contents.body
                }
                Noizu.Intellect.LiveEventModule.publish(event(subject: "chat", instance: sref, event: "sent", payload: message, options: [scroll: true]))
              end


              {:ok, state}
              else
              _ -> {:ok, state}
            end
          else
          _ -> {:ok, state}
        end
    else
      _ -> {:ok, state}
    end
  end

  #---------------------
  #
  #---------------------
  def heart_beat(state, context, options) do
    IO.puts "HEART BEAT"
    state = queue_heart_beat(state, context, options)
    with {:ok, state} <- process_message_queue(state, context, options) do
      {:noreply, state}
    else
      _ -> {:noreply, state}
    end
  end


  defimpl Noizu.Entity.Protocol do
    def layer_identifier(entity, _layer) do
      {:ok, entity.identifier}
    end
  end

  defmodule Repo do
    use Noizu.Repo
    def_repo()
  end
end
