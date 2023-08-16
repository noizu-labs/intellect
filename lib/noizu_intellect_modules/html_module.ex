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

  def extract_session_response_details(response) do
    {_, xml_tree} = Floki.parse_document(response)
    Enum.map(xml_tree,
      fn
        ({"nlp-agent", attrs, contents}) ->
          sender = Enum.find_value(attrs, & elem(&1, 0) == "for" && elem(&1, 1) || nil)
          inner = extract_nlp_agent_response(contents)
          {:agent, [sender: sender, sections: inner]}
        (_) -> nil
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
  end

  def extract_nlp_agent_response(contents) do
    Enum.map(contents,
      fn
        ({"nlp-intent", _, contents}) ->
          text = Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()
          {:intent, text}
        ({"nlp-reply", attrs, contents}) ->
          mood = Enum.find_value(attrs, & elem(&1, 0) == "mood" && elem(&1, 1) || nil)
          at = Enum.find_value(attrs, & elem(&1, 0) == "at" && elem(&1, 1) || nil)
          {:reply, [mood: mood, at: at, response: "#{at || ""}" <> Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()]}
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
  end

  def extract_message_delivery_details(response) do
    {_, xml_tree} = Floki.parse_document(response)
    Enum.map(xml_tree,
      fn
        ({"monitor-response", _, contents}) ->
          text = Floki.text(contents)
          with {:ok, yaml} <- YamlElixir.read_from_string(text) do
            IO.inspect(yaml, label: "YAML", pretty: true)
            yaml2 = yaml["message_analysis"]["message_details"] || yaml["message_details"]
            audience = (with s <- yaml["audience"] || yaml2["audience"],
                             true <- is_list(s) do
                          Enum.map(s, fn(x) ->
                            {:audience, {x["for"], x["confidence"], x["explanation"]}}
                          end)
                        else
                          _ -> []
                        end)
            responding_to = (with s <- yaml["relates-to"] ||yaml2["relates-to"],
                                  true <- is_list(s) do
                               Enum.map(s, fn(x) ->
                                 {:responding_to, {x["for"], x["confidence"], {x["complete"], x["completed_by"]}, x["explanation"]}}
                               end)
                             else
                               _ -> []
                             end)
            summary = (with s <- yaml["summary"] || yaml2["summary"],
                            false <- is_nil(s) do
                         [{:summary, {String.trim(s["content"], "'"), s["action"], s["features"]}}]
                       else
                         _ -> []
                       end)
            message_analysis = (with s <- yaml["message_analysis"]["chat-history"],
                                     false <- is_nil(s) do
                                  [{:message_analysis, Ymlr.document!(s)}]
                                else
                                  _ -> []
                                end)
            audience ++ responding_to ++ summary ++ message_analysis
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
