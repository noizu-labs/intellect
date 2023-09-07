defmodule Noizu.Intellect.HtmlModule do
  require Logger
  def to_yaml(value) do
    Ymlr.document!(value) |> String.trim_leading("---\n")
  end
#
#  def to_yaml__newline(value, v) do
#    cond do
#      is_list(value) && is_map(v) -> false
#      is_struct(v) -> true
#      is_map(v) -> true
#      is_list(v) -> true
#      :else -> false
#    end
#  end
#
#  def to_yaml(value, offset \\ 0, new_line \\ false) do
#    padding = String.duplicate(" ", offset)
#    cond do
#      is_struct(value) ->
#        v = value
#            |> Map.from_struct()
#            |> Enum.map(fn {k, v} -> "#{k}:#{to_yaml__newline(value, v) && "\n" || " "}#{to_yaml(v, offset + 2, to_yaml__newline(value, v))}" end)
#            |> Enum.join("\n#{padding}")
#        if new_line, do: padding <> v, else: v
#      is_map(value) ->
#        v = value
#        |> Enum.map(fn {k, v} -> "#{k}:#{to_yaml__newline(value, v) && "\n" || " "}#{to_yaml(v, offset + 2, to_yaml__newline(value, v))}" end)
#        |> Enum.join("\n#{padding}")
#        if new_line, do: padding <> v, else: v
#      is_list(value) ->
#        v = value
#        |> Enum.map(fn v -> "-#{to_yaml__newline(value, v) && "\n" || " "}#{to_yaml(v, offset + 2, to_yaml__newline(value, v))}" end)
#        |> Enum.join("\n#{padding}")
#        if new_line, do: padding <> v, else: v
#      is_bitstring(value) && String.contains?(value, "\n") ->
#        #padding = String.duplicate(" ", offset + 2)
#        value = value
#                |> String.split("\n")
#                |> Enum.join("\n#{padding}")
#        "|-2\n#{padding}" <> value
#      :else ->
#        "#{inspect(value)}"
#    end |> then(& if offset == 0, do: &1 <> "\n", else: &1)
#
#  end


  def extract_message_completion_details(response) do
    {_, xml_tree} = Floki.parse_document(response)
    Enum.map(xml_tree,
      fn
        ({"monitor-response", _, contents}) ->
          text = Floki.text(contents)
          with {:ok, yaml} <- YamlElixir.read_from_string(text) do
            message_analysis = (with s <- yaml["message_analysis"]["chat-history"],
                                     true <- is_list(s) do
                                  Enum.map(s, fn(message) ->
                                    id = message["id"]
                                      Enum.map((message["answered"]),
                                        fn(answer) ->
                                          by = answer["by"]
                                          if is_integer(by) do
                                            by && {:answered_by, {id, by}}
                                          end
                                        end) |> Enum.reject(&is_nil/1)
                                  end)
                                else
                                  _ -> []
                                end) |> List.flatten()
            message_analysis
          else
            x = {:error, %YamlElixir.ParsingError{}} ->
              Logger.error("[INVALID YAML]\n#{text}")
              x
          end
        (_) -> nil
      end)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
  end

  defp extract_block(message, block) do
    Regex.scan(~r/(^|\n)(```+)#{block}[ \t]*\n(?<body>.*?)\n\2[ \t]*(\n|$)/s, message, capture: ["body"]) || []
  end

  defp extract_msg_blocks(message) do
    case Regex.scan(~r/\[📧:NLP-MSG\]\n(?<header>.*?)\n--- BODY ---\n(?<body>.*?)\n\[📧:NLP-MSG:END\]/s, message, capture: :all_names) do
      nil -> []
      captures ->
        parsed_msgs = Enum.map(captures, fn [body, header] ->
          body = String.replace(body, ~r/\[📧:NLP-MSG:REVIEW\][\n\r\t\s\S.]*(⌟|\[📧:NLP-MSG:END\])+/, "")
          with {:ok, [y]} <- YamlElixir.read_all_from_string(header) do
            for = is_integer(y["for"]) && [y["for"]] || y["for"] || []
            rec = is_bitstring(y["at"]) && [y["at"]] || y["at"] || []
            {:reply, [sender: y["sender"], for: for |> Enum.filter(&is_integer/1), if_no_reply: y["if-no-reply"], mood: y["mood"], at: rec, response: body |> String.trim()]}
          end
        end) |> Enum.reject(&is_nil/1)
    end
  end

  def extract_simplified_session_response_details(response) do
    IO.puts "-------------\n" <> response <> "\n----------------\n\n\n\n"
    review = Enum.map(extract_block(response, "nlp-review"),
                 fn
                   ([""]) -> nil
                   ([nil]) -> nil
                   ([m]) ->
                   {:review, m}
                 end
               )  |> Enum.reject(&is_nil/1)
    intent = Enum.map(extract_block(response, "nlp-intent"),
      fn([m]) ->
        with {:ok, [y]} <- YamlElixir.read_all_from_string(m) do
          {:intent, [overview: y["overview"], steps: y["observation"]]}
        end
      end
    )  |> Enum.reject(&is_nil/1)
    mood = Enum.map(extract_block(response, "nlp-mood"),
               fn
                 ([""]) -> nil
                 ([nil]) -> nil
                 ([m]) ->
                 with {:ok, [y]} <- YamlElixir.read_all_from_string(m) do
                   {:mood, [mood: y["mood"], note: y["note"]]}
                 end
               end
             )  |> Enum.reject(&is_nil/1)
    objective = Enum.map(extract_block(response, "nlp-objective"),
             fn
               ([""]) -> nil
               ([nil]) -> nil
               ([m]) ->
               with {:ok, [y]} <- YamlElixir.read_all_from_string(m) do
                 for = is_integer(y["for"]) && [y["for"]] || y["for"] || []

                 {:objective, [name: y["name"], for: (for) |> Enum.filter(&is_integer/1), summary: y["summary"], tasks: y["tasks"], ping_me: y["ping-me"] ]}
               end
             end
           )  |> Enum.reject(&is_nil/1)

    reflect = Enum.map(extract_block(response, "nlp-reflect"),
               fn
                 ([""]) -> nil
                 ([nil]) -> nil
                 ([m]) ->
                 with {:ok, [y]} <- YamlElixir.read_all_from_string(m) |> IO.inspect do
                   {:reflect, [overview: y["overview"], observations: y["observations"]]}
                 end
               end
             )  |> Enum.reject(&is_nil/1)

    follow_up = Enum.map(extract_block(response, "nlp-follow-up"),
            fn
              ([m]) when is_bitstring(m) ->
                m = String.trim(m)
                unless m == "" do
                  {:follow_up, [id: :os.system_time(:millisecond), instructions: m]}
                end
                (_) -> nil
            end
          )  |> Enum.reject(&is_nil/1)

    ack = Enum.map(extract_block(response, "nlp-mark-read"),
                fn
                  ([""]) -> nil
                  ([nil]) -> nil
                  ([m]) ->
                  with {:ok, [y]} <- YamlElixir.read_all_from_string(m) do
                    for = is_integer(y["for"]) && [y["for"]] || y["for"] || []
                    {:ack, [for: for |> Enum.filter(&is_integer/1), note: y["note"]]}
                  end
                end
              )  |> Enum.reject(&is_nil/1)
    replies = extract_msg_blocks(response)
    response = (review ++ intent ++ mood ++objective ++ reflect ++ ack ++ replies ++ follow_up)
               |> Enum.group_by(&elem(&1, 0))
    if nlp_agent_response_valid?(response) do
      {:ok, response}
    else
      {:error, {:invalid, response}}
    end
  end

  def extract_session_response_details(response), do: extract_session_response_details(:v1, response)

  def extract_session_response_details(:v2, nil), do: {:error, :empty_reply}
  def extract_session_response_details(:v2, response) do
    {_, xml_tree} = Floki.parse_document(response)
    response = extract_nlp_agent_response(xml_tree)
    {:ok, response}
  end

  def extract_session_response_details(:v1, response) do
    {_, xml_tree} = Floki.parse_document(response)
    response = extract_nlp_agent_response(xml_tree)
    if nlp_agent_response_valid?(response) do
      {:ok, response}
    else
      {:error, {:invalid, response}}
    end
  end


  def attr_extract__value(attrs, key) do
    Enum.find_value(attrs, & elem(&1, 0) == key && elem(&1, 1) || nil)
    |> then(
         fn
           v when is_bitstring(v) -> String.trim(v)
           _ -> nil
         end
       )
  end


  def attr_extract__integer(attrs, key) do
    attr_extract__value(attrs, key)
    |> case do
         "infinity" -> :infinity
         v when is_bitstring(v) ->
           cond do
             String.match?(v, ~r/^[0-9]+$/ ) -> String.to_integer(v)
             :else -> nil
           end
         _ -> nil
       end
  end

  def attr_extract__list(attrs, key, type \\ :int) do
    Enum.find_value(attrs, & elem(&1, 0) == key && elem(&1, 1) || nil)
    |> then(
         fn
           v when is_bitstring(v) ->
             v = String.trim(v)
             cond do
               v == "" -> []
               type == :int ->
                 v
                 |> String.split(",")
                 |> Enum.map(&String.trim/1)
                 |> Enum.map(&String.to_integer/1)
               type == :slug ->
                 v
                 |> String.split(",")
                 |> Enum.map(&String.trim/1)
                 |> Enum.filter(& String.match?(&1, ~r/^@[a-zA-Z][a-zA-Z0-9_\-]*$/))
               :else ->
                 v
                 |> String.split(",")
                 |> Enum.map(&String.trim/1)
             end
           _ -> []
         end
       )
  end

  def nlp_agent_response_valid?(response) do
    cond do
      (r = response[:reply]
      is_list(r) && length(r) > 0) -> true

      (r = response[:function_call]
      is_list(r) && length(r) > 0) -> true
      :else -> false
    end
  end

  def extract_time(value, now \\ nil) do
    now = now || DateTime.utc_now()
    value
    |> case do
         "" -> nil
         "infinity" -> :infinity
         v when is_bitstring(v) ->
           cond do
             String.match?(v, ~r/[0-9]-/ ) -> DateTime.from_iso8601(v)
             String.match?(v, ~r/^[0-9]+$/ ) ->
               case Integer.parse(v) do
                 {v, _} -> {:ok, Timex.shift(now, seconds: v)}
                 _ -> nil
               end
             String.match?(v, ~r/^[0-9]+ (second|minute|hour|day|week|month|year)s?$/ ) ->
               case Regex.run(~r/^([0-9]+) (second|minute|hour|day|week|month|year)s?$/, v) do
                 [_, m, period] ->
                   period = case period do
                     "second" -> :seconds
                     "minute" -> :minutes
                     "hour" -> :hours
                     "day" -> :days
                     "week" -> :weeks
                     "month" -> :months
                     "years" -> :years
                     _ -> nil
                   end
                   period && {:ok, Timex.shift(now, [{period, String.to_integer(m)}])}
                 _ -> nil
               end
             :else -> nil
           end
         _ -> nil
       end
    |> case do
         {:ok, t} -> t
         _ -> nil
       end
  end

  def attr_extract__time(attrs, field, now \\ nil) do
    attr_extract__value(attrs, field)
    |> extract_time(now)
  end

  def trim_html(raw) do
    raw = Regex.replace(~r/(^[\s\t\n]*)(\n[\s\t]*[^\s\t\n])/, raw, "\\2")
    Regex.replace(~r/[\s\t\n]*$/, raw, "")
  end




  @objective_status_map %{
    "in-progress" => :in_progress,
    "pending" => :pending,
    "new" => :new,
    "active" => :active,
    "blocked" => :blocked,
    "completed" => :complted,
    "in-review" => :in_review,
    "stalled" => :stalled
  }

  #------------------------
  #
  #------------------------
  defp extract_nlp_agent_response__extract_tag(tag, contents) do
    Enum.map(contents,
      fn
        ({tag, _, contents}) ->
          {:ok,
            Floki.raw_html(contents, pretty: false, encode: false)
            |> trim_html()
          }
        _ -> nil
      end
    )
    |> Enum.filter(& Kernel.match?({:ok, _}, &1))
    |> Enum.map(& elem(&1, 1))
    |> Enum.join("\n")
  end

  #------------------------
  #
  #------------------------
  defp extract_nlp_agent_response__strip_tags(tags, contents) do
    Enum.map(contents,
      fn
        tag = {name, attrs, contents} -> unless Enum.member?(tags, name), do: tag
        other -> other
      end
    )
    |> Enum.reject(&is_nil/1)
    |> Floki.raw_html([pretty: false, encode: false])
    |> String.trim()
  end


  #------------------------
  #
  #------------------------
  defp extract_nlp_agent_response__objective__reminder(_), do: nil
  defp extract_nlp_agent_response__objective(attrs, contents) do
    with {:ok, [yaml]} <- Floki.raw_html(contents, pretty: false, encode: false)
                          |> trim_html()
                          |> YamlElixir.read_all_from_string(),
         %{"brief" => objective, "tasks" => tasks} <- yaml
      do
      id = attr_extract__integer(attrs, "objective")
      for = attr_extract__list(attrs, "in-response-to")
      participants = attr_extract__list(attrs, "participants", :slug)
      name = attr_extract__value(attrs, "name")
      status = @objective_status_map[attr_extract__value(attrs, "status")]
      [ping_me, remind_me] =
        ["ping-me", "remind-me"]
        |> Enum.map(
             fn(key) ->
               [extract_nlp_agent_response__objective__reminder(yaml[key])]
               |> List.flatten()
               |> Enum.reject(&is_nil/1)
             end
           )
      {:objective,
        [
          id: id,
          participants: participants,
          status: status,
          name: name,
          for: for,
          brief: objective,
          tasks: tasks,
          ping_me: ping_me,
          remind_me: remind_me
        ]
      }
    else
      _ -> nil
    end
  end
  defp extract_nlp_agent_response__send_message(attrs, contents) do
    mood = attr_extract__value(attrs, "mood")
    from = attr_extract__value(attrs, "from")
    to = attr_extract__list(attrs, "to", :slug)
    in_response_to = attr_extract__list(attrs, "in-response-to")
    {:reply,
      [
        mood: mood,
        at: to,
        from: from,
        in_response_to: in_response_to,
        response: Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
      ]
    }
  end
  defp extract_nlp_agent_response__corrections(_, contents) do
    Enum.map(contents,
      fn
        ({send_message, attrs, contents}) when send_message in ["message", "send-message"] ->
          extract_nlp_agent_response__send_message(attrs, contents)
        _ -> nil
      end
    )
    |> Enum.reject(&is_nil/1)
  end
  defp extract_nlp_agent_response__mark_read(attrs, contents) do
    ids = attr_extract__list(attrs, "in-response-to")
    {:ack,
      [
        ids: ids,
        comment: Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
      ]
    }
  end
  defp extract_nlp_agent_response__react(attrs, contents) do
    ids = attr_extract__list(attrs, "in-response-to")
    reaction = attr_extract__value(attrs, "reaction") || "👁"
    {:react,
      [
        ids: ids,
        reaction: reaction,
        comment: Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
      ]
    }
  end
  defp extract_nlp_agent_response__plan(attrs, contents) do
    body = Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
    with {:ok, [%{"plan" => plan, "steps" => steps}]} <- YamlElixir.read_all_from_string(body) do
      {
        :intent,
        [
          overview: plan,
          steps: steps
        ]
      }
    else
      _ -> nil
    end
  end
  defp extract_nlp_agent_response__reflect(attrs, contents) do
    body = Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
    with {:ok, %{"items" => items, "reflection" => reflection}} <- YamlElixir.read_from_string(body) do
      {:reflect,
        [
          reflection: reflection,
          items: items
        ]
      }
    else
      _ -> nil
    end
  end
  defp extract_nlp_agent_response__mood(attrs, contents) do
    mood = attr_extract__value(attrs, "mood")
    body = Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
    {:mood,
      [
        mood: mood,
        note: body
      ]
    }
  end
  defp extract_nlp_agent_response__reminder(:set, attrs, contents) do
    condition = extract_nlp_agent_response__extract_tag("condition", contents)
    brief = extract_nlp_agent_response__extract_tag("brief", contents)
    instructions = extract_nlp_agent_response__strip_tags(["brief", "condition"], contents)
    {:follow_up,
      [
        id: attr_extract__integer(attrs, "reminder"),
        name: attr_extract__value(attrs, "name"),
        brief: brief,
        remind_after: attr_extract__time(attrs, "after"),
        remind_until: attr_extract__time(attrs, "until"),
        repeat: attr_extract__integer(attrs, "repeat"),
        condition: condition,
        instructions: instructions
      ]
    }
  end
  defp extract_nlp_agent_response__reminder(:disable, attrs, contents) do
    note = contents
           |> Floki.raw_html([pretty: false, encode: false])
           |> String.trim()
    {:disable_follow_up,
      [
        id: attr_extract__integer(attrs, "reminder"),
        note: note
      ]
    }
  end
  defp extract_nlp_agent_response__reminder(:snooze, attrs, contents) do
    note = contents
           |> Floki.raw_html([pretty: false, encode: false])
           |> String.trim()
    {:snooze_follow_up,
      [
        id: attr_extract__integer(attrs, "reminder"),
        until: attr_extract__time(attrs, "until"),
        note: note
      ]
    }
  end
  defp extract_nlp_agent_response__reminder(:clear, attrs, contents) do
    note = contents
           |> Floki.raw_html([pretty: false, encode: false])
           |> String.trim()
    {:clear_follow_up,
      [
        id: attr_extract__integer(attrs, "reminder"),
        until: attr_extract__time(attrs, "until"),
        note: note
      ]
    }
  end
  defp extract_nlp_agent_response__reminder(:delete, attrs, contents) do
    note = contents
           |> Floki.raw_html([pretty: false, encode: false])
           |> String.trim()
    {:delete_follow_up,
      [
        id: attr_extract__integer(attrs, "reminder"),
        note: note
      ]
    }
  end

  #------------------------
  #
  #------------------------
  defp extract_nlp_agent_response__objective__reminder(entry) when is_map(entry) do
    e_id = entry["id"]
    name = entry["name"]
    brief = entry["brief"]
    enabled = entry["enabled"]
    instructions = entry["to"]
    remind_after = extract_time(entry["after"])
    cond do
      name && brief && remind_after && instructions -> true
      e_id && (name || brief || remind_after || !is_nil(enabled) || instructions) -> true
      :else -> false
    end
    |> if do
         %{
           id: e_id,
           name: name,
           enabled: enabled,
           brief: brief,
           remind_after: remind_after,
           instructions: instructions
         }
       end
  end
  defp extract_nlp_agent_response__objective__reminder(entries) when is_list(entries) do
    Enum.map(entries, &extract_nlp_agent_response__objective__reminder/1)
    |> Enum.reject(&is_nil/1)
  end


  def extract_nlp_agent_response(contents) do
    o = Enum.map(contents,
      fn
        ({"agent-response-reflection-corrections", attrs, contents}) ->
          extract_nlp_agent_response__corrections(attrs, contents)
        ({send_message, attrs, contents}) when send_message in ["message", "send-message"] ->
          extract_nlp_agent_response__send_message(attrs, contents)
        ({"agent-mark-read", attrs, contents}) ->
          extract_nlp_agent_response__mark_read(attrs, contents)
        ({"agent-response-plan", attrs, contents}) ->
          extract_nlp_agent_response__plan(attrs, contents)
        ({"agent-response-reflection", attrs, contents}) ->
          extract_nlp_agent_response__reflect(attrs, contents)
        ({"agent-mood", attrs, contents}) ->
          extract_nlp_agent_response__mood(attrs, contents)
        ({"agent-objective-update", attrs, contents}) ->
          extract_nlp_agent_response__objective(attrs, contents)
        ({"agent-reminder-set", attrs, contents}) ->
          extract_nlp_agent_response__reminder(:set, attrs, contents)
        ({"agent-reminder-clear", attrs, contents}) ->
          extract_nlp_agent_response__reminder(:clear, attrs, contents)
        ({"agent-reminder-delete", attrs, contents}) ->
          extract_nlp_agent_response__reminder(:delete, attrs, contents)
        ({"agent-reminder-disable", attrs, contents}) ->
          extract_nlp_agent_response__reminder(:disable, attrs, contents)
        ({"agent-reminder-snooze", attrs, contents}) ->
          extract_nlp_agent_response__reminder(:disable, attrs, contents)
        (_) -> nil
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

    Enum.group_by(o, &elem(&1, 0)) |> IO.inspect(label: "RESPONSE DATA")
    rescue exception ->
      contents = Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
      IO.inspect(contents, label: "ERROR")
      reraise exception, __STACKTRACE__
    catch exception ->
      contents =  Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
      IO.inspect(contents, label: "ERROR")
      throw exception
  end

  def extract_message_delivery_details(response) do
    {_, xml_tree} = Floki.parse_document(response)
    Enum.map(xml_tree,
      fn
        ({"monitor-response", _, contents}) ->
          contents =  Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()
          IO.puts contents
          with {:ok, yaml} <- YamlElixir.read_from_string(contents) do
            summary = if s = yaml["message_details"]["summary"] do
              [{:summary, {String.trim(s["content"], "'"), s["action"], s["features"]}}]
              else
              []
            end
            summary
          else
            x = {:error, %YamlElixir.ParsingError{}} ->
              Logger.error("[INVALID YAML]\n#{contents}")
              x
          end
        (_) -> nil
      end)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
  end


  def valid_response?(response) do
    cond do
      is_nil(response[:reply]) && is_nil(response[:ack]) -> {:invalid_response, :reply_required}
#      is_nil(response[:reflect]) -> {:invalid_response, :reflect_required}
#      is_nil(response[:intent]) -> {:invalid_response, :intent_required}
#      is_nil(response[:mood]) -> {:invalid_response, :mood_required}
      :else -> :ok
    end
#
#    response
#    |> Enum.map(
#         fn
#           ({:ack, _}) -> nil
#           ({:reply, _}) -> nil
#           ({:memories, _}) -> nil
#           ({:message_analysis, _}) -> nil
#           (other) -> {:invalid_section, other}
#         end
#       )
#    |> Enum.filter(&(&1))
#    |> case do
#         [] -> :ok
#         issues -> {:invalid_response, {:issues, issues}}
#       end
  end

  def repair_response(response) do
    repair = Enum.map(response,
      fn
        (x = {:ack, _}) -> x
        (x = {:reply, _}) -> x
        (x = {:memories, _}) -> x
        (x = {:nlp_chat_analysis, _}) -> x
        (section) -> {:unsupported, section}
      end
    )
    has_response = Enum.find_value(repair,
      fn
        ({:ack, _}) -> true
        ({:reply, _}) -> true
        (_) -> nil
      end)
    has_response && {:ok, repair} || {:error, {:repair_attempt, repair}}
  end

  def extract_response_sections(response) do
    {_, html_tree} = Floki.parse_document(response)
    o = Enum.map(html_tree,
      fn
        (_x = {"nlp-chat_analysis", _, contents}) ->
          {:nlp_chat_analysis, [contents: Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()]}
        (_x = {"agent-response", _, contents}) ->
          text = Floki.text(contents)
          with {:ok, yaml} <- YamlElixir.read_from_string(text) do
            memories = (with s <- yaml["memories"],
                             true <- is_list(s) do
                          Enum.map(s, fn
                            (x = %{"memory" => _}) -> {:memory, x}
                            (_) -> nil
                          end) |> Enum.reject(&is_nil/1)
                        else
                          _ -> []
                        end)
            replies = (with s <- yaml["replies"],
                            true <- is_list(s) do
                         Enum.map(s, fn(x) ->
                           with %{"for" => [_|_], "response" => response} <- x do
                             mood = x["mood"]
                             mood = mood && String.trim(mood)
                             a = [{:ids, x["for"]}, {:response, response}, {:mood, mood}]
                             if i = x["nlp-intent"] do
                               {:reply, a ++ [{:intent, Ymlr.document!(i)}]}
                             else
                               {:reply, a}
                             end
                           else
                             _ -> nil
                           end
                         end) |> Enum.reject(&is_nil/1)
                       else
                         _ -> []
                       end)
            mark = (with s <- yaml["mark-processed"],
                         true <- is_list(s) do
                      Enum.map(s, fn(x) ->
                        with %{"for" => [h|t]} <- x do
                          {:ack, [ids: [h|t]]}
                        else
                          _ -> nil
                        end
                      end) |> Enum.reject(&is_nil/1)
                    else
                      _ -> []
                    end)
            memories ++ replies ++ mark
            else
            x = {:error, %YamlElixir.ParsingError{}} ->
              Logger.error("[INVALID YAML]\n#{text}")
              x
          end
        (_) -> nil
      end)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
    {:ok, o}
  end


  def extract_reply_meta(reply) do
    sections = Enum.map(reply, fn
      ({"nlp-intent", _, contents}) -> {:intent, Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()}
      ({"response", _, contents}) -> {:response, Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()}
      ({"nlp-reflect", _, contents}) -> {:reflect, Floki.raw_html(contents, pretty: false, encode: false) |> trim_html()}
      (_) -> nil
    end)
               |> Enum.filter(&(&1))
    {:ok, sections}
  end



  def replace_script_tags(html) do
    # Parse the HTML
    {_, html_tree} = Floki.parse_document(html)

    # Replace each script tag with a code block with escaped values
    replaced_html_tree = Enum.map(html_tree, & replace_script_tags_in_tree(&1))

    # Convert the modified HTML tree back into a string
    Floki.raw_html(replaced_html_tree, pretty: false, encode: false)
  end

  defp replace_script_tags_in_tree({tag, attrs, children} = _node) when tag == "script" do
    # Extract the script content and escape it
    script_content = Floki.raw_html(children, pretty: false, encode: false)
    escaped_script_content = escape_script_content(script_content)
    {:ok, back} = Floki.parse_document(escaped_script_content)
    # Replace the script tag with a code block
    attrs = Enum.map(attrs, fn({tag, attr}) -> "#{tag} = #{inspect attr}" end) |> Enum.join(" ")
    {"code", [], ["<script #{attrs}>"] ++ back ++ ["</script>"]}
  end
  defp replace_script_tags_in_tree({tag, attrs, children}) do
    # Recursively replace script tags in the children
    replaced_children = Enum.map(children, &replace_script_tags_in_tree/1)

    # Return the node with the modified children
    {tag, attrs, replaced_children}
  end
  defp replace_script_tags_in_tree(other) do
    # Return any other value as is
    other
  end

  defp escape_script_content(script_content) do
    String.replace(script_content, ~r/([<>])/, fn match ->
      case match do
        "<" -> "&lt;"
        ">" -> "&gt;"
      end
    end)
  end
end
