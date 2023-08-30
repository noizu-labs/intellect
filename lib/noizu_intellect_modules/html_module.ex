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
    case Regex.scan(~r/--?-? BEGIN NLP-MSG --?-?\n(?<header>.*?)\n--- BODY ---\n(?<body>.*?)\n--?-? END NLP-MSG --?-?/s, message, capture: :all_names) do
      nil -> []
      captures ->
        parsed_msgs = Enum.map(captures, fn [body, header] ->
          with {:ok, [y]} <- YamlElixir.read_all_from_string(header) do
            {:reply, [sender: y["sender"], for: (y["for"] || []) |> Enum.filter(&is_integer/1), if_no_reply: y["if-no-reply"], mood: y["mood"], at: y["at"], response: body |> String.trim()]}
          end
        end) |> Enum.reject(&is_nil/1)
    end
  end

  def extract_simplified_session_response_details(response) do
    IO.puts "-------------\n" <> response <> "\n----------------\n\n\n\n"
    identity = Enum.map(extract_block(response, "nlp-identity"),
                 fn
                   ([""]) -> nil
                   ([nil]) -> nil
                   ([m]) ->
                   {:identity, m}
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
                 {:objective, [name: y["name"], for: (y["for"] || []) |> Enum.filter(&is_integer/1), overview: y["overview"], tasks: y["tasks"], ping_me: y["ping-me"] ]}
               end
             end
           )  |> Enum.reject(&is_nil/1)

    reflect = Enum.map(extract_block(response, "nlp-reflect"),
               fn
                 ([""]) -> nil
                 ([nil]) -> nil
                 ([m]) ->
                 with {:ok, [y]} <- YamlElixir.read_all_from_string(m) |> IO.inspect do
                   {:intent, [overview: y["overview"], observations: y["observations"]]}
                 end
               end
             )  |> Enum.reject(&is_nil/1)
    ack = Enum.map(extract_block(response, "nlp-mark-read"),
                fn
                  ([""]) -> nil
                  ([nil]) -> nil
                  ([m]) ->
                  with {:ok, [y]} <- YamlElixir.read_all_from_string(m) do
                    {:ack, [for: (y["for"] || []) |> Enum.filter(&is_integer/1), note: y["note"]]}
                  end
                end
              )  |> Enum.reject(&is_nil/1)
    replies = extract_msg_blocks(response)
    response = (identity ++ intent ++ mood ++objective ++ reflect ++ ack ++ replies)
               |> Enum.group_by(&elem(&1, 0))
    if nlp_agent_response_valid?(response) do
      {:ok, response}
    else
      {:error, {:invalid, response}}
    end
  end

  def extract_session_response_details(response) do
    IO.puts "-------------\n" <> response <> "\n----------------\n\n\n\n"
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

  def attr_extract__list(attrs, key, int? \\ true) do
    Enum.find_value(attrs, & elem(&1, 0) == key && elem(&1, 1) || nil)
    |> then(
         fn
           v when is_bitstring(v) ->
             if int? do
               v = v
                   |> String.split(",")
                   |> Enum.map(&String.trim/1)
                   |> Enum.map(&String.to_integer/1)
             else
               v = v
                   |> String.split(",")
                   |> Enum.map(&String.trim/1)
             end
           _ -> nil
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

  def extract_nlp_agent_response(contents) do
    o = Enum.map(contents,
      fn
        ({"nlp-agent", attrs, contents}) ->
          agent = attr_extract__list(attrs, "for", false)
          {:agent, [agent: agent, output: extract_nlp_agent_response(contents)]}
        ({"nlp-message", attrs, contents}) -> extract_nlp_agent_response(contents)
        ({"nlp-intent", _, contents}) ->
          text = Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
          {:intent, text}
        ({"nlp-objective", attrs, contents}) ->
          name = attr_extract__value(attrs, "name")
          ids = attr_extract__list(attrs, "for")
          if name do
            intent = Enum.map(contents,
                          fn
                            {"nlp-intent", _, contents} ->
                              intent = Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
                              with {:ok, p} <-  YamlElixir.read_from_string(intent),
                                   steps <- p["steps"],
                                   true <- is_list(steps) || {:error, {:malformed_intent, :missing_steps}}
                                do
                                {:intent, p}
                              end
                            _ -> nil
                          end
                        ) |> Enum.reject(&is_nil/1)
            with [{:intent, intent}] <- intent do
              {:objective, for: ids, name: name, theory_of_mind: intent["theory-of-mind"], overview: intent["overview"], steps: intent["steps"]}
            else
              _ ->
                # handle error.
                nil
            end
          else
            # else handle error.
            nil
          end
          ({"nlp-mark-read", attrs, contents}) ->
            ids = attr_extract__list(attrs, "for")
            {:ack, [ids: ids, comment: Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()]}
        ({"nlp-msg", attrs, contents}) ->
          mood = Enum.find_value(attrs, & elem(&1, 0) == "mood" && elem(&1, 1) || nil)
          at = Enum.find_value(attrs, & elem(&1, 0) == "at" && elem(&1, 1) || nil)
               |> then(& is_bitstring(&1) && String.split(&1, ",") || nil)
          {:reply, [mood: mood, at: at, response: Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()]}
        ({"nlp-memory", _, contents}) ->
          text = Floki.raw_html(contents)
          with {:ok, memories} <- YamlElixir.read_from_string(text),
               true <- is_list(memories) do
            Enum.map(memories, & {:memory, &1})
          else
            _ ->
              {:error, {:malformed, {:memories, text}}}
          end
        ({"nlp-function-call", attrs, contents}) ->
          function = Enum.find_value(attrs, & elem(&1, 0) == "function" && elem(&1, 1) || nil)
          if function do
            text = Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
            with {:ok, payload} <- YamlElixir.read_from_string(text) do
              {:function_call, [function: function, args: payload]}
            else
              _ ->
                # log error
                {:error, {:malformed, {:function_call, {function, text}}}}
            end
          end
        (_) -> nil
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

    Enum.group_by(o, &elem(&1, 0))
    rescue exception ->
      contents = Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
      IO.inspect(contents, label: "ERROR")
      reraise exception, __STACKTRACE__
    catch exception ->
      contents =  Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
      IO.inspect(contents, label: "ERROR")
      throw exception
  end

  def extract_message_delivery_details(response) do
    {_, xml_tree} = Floki.parse_document(response)
    Enum.map(xml_tree,
      fn
        ({"monitor-response", _, contents}) ->
          contents =  Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
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
    response
    |> Enum.map(
         fn
           ({:ack, _}) -> nil
           ({:reply, _}) -> nil
           ({:memories, _}) -> nil
           ({:message_analysis, _}) -> nil
           (other) -> {:invalid_section, other}
         end
       )
    |> Enum.filter(&(&1))
    |> case do
         [] -> :ok
         issues -> {:issues, issues}
       end
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
          {:nlp_chat_analysis, [contents: Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()]}
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
      ({"nlp-intent", _, contents}) -> {:intent, Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()}
      ({"response", _, contents}) -> {:response, Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()}
      ({"nlp-reflect", _, contents}) -> {:reflect, Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()}
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
