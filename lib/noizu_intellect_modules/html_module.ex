defmodule Noizu.Intellect.HtmlModule do



  def valid_response?(response) do
    response
    |> Enum.map(
         fn
           ({:ack, _}) -> nil
           ({:reply, _}) -> nil
           ({:nlp_chat_analysis, _}) -> nil
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

  def extract_relevancy_response(response) do
    {_, html_tree} = Floki.parse_document(response)
    sections = Enum.map(html_tree,
                 fn
                   (x = {"nlp-intent", attrs, contents}) -> {:intent, Floki.raw_html(contents, pretty: false, encode: false)}
                   (x = {"relevance", attrs, contents}) ->
                     Enum.map(contents,
                       fn
                         (x = {"relevancy", attr, contents}) ->
                           member = Enum.find_value(attr,
                             fn
                               ({"for-user", x}) -> String.to_integer(x)
                               (_) -> nil
                             end)
                           message = Enum.find_value(attr,
                             fn
                               ({"for-message", ""}) -> nil
                               ({"for-message", x}) -> String.to_integer(x)
                               (_) -> nil
                             end)
                           weight = Enum.find_value(attr,
                             fn
                               ({"value", x}) -> String.to_float(x)
                               (_) -> nil
                             end)
                           contents = case contents |> IO.inspect() do
                            v when is_bitstring(v) -> v
                            v -> Floki.raw_html(v, pretty: false, encode: false)
                           end
                           {:relevancy, [member: member, weight: weight, message: message, contents: contents]}
                       end)
                   (_) -> nil
                 end)
               |> List.flatten()
               |> Enum.filter(&(&1))
    {:ok, sections}
  end

  def extract_response_sections(response) do
    {_, html_tree} = Floki.parse_document(response)
    sections = Enum.map(html_tree, fn
      (x = {"ack", attrs, []}) ->
        ids = Enum.find_value(attrs, fn
          ({"for", ids}) ->
            ids
            |> String.split(",")
            |> Enum.map(&(String.trim(&1)))
            |> Enum.map(&(String.to_integer(&1)))
          (_) -> nil
        end)
        unless ids == [] do
          {:ack, [ids: ids]}
        else
          {:error, {:malformed_section, x}}
        end
      (x = {"reply", attrs, contents}) ->
        ids = Enum.find_value(attrs, fn
          ({"for", ids}) ->
            ids
            |> String.split(",")
            |> Enum.map(&(String.trim(&1)))
            |> Enum.map(&(String.to_integer(&1)))
          (_) -> nil
        end)
        unless ids == [] do
          with {:ok, sections} <- extract_reply_meta(contents) do
            {:reply, [{:ids, ids}|sections]}
          end
        else
          {:error, {:malformed_section, x}}
        end
      (x = {"nlp-chat-analysis",_,contents}) -> {:nlp_chat_analysis, [contents: Floki.raw_html(contents, pretty: false, encode: false) |> String.trim()]}
      (other = {_,_,_}) -> {:other, other}
      (other) when is_bitstring(other) ->
        case String.trim(other) do
          "" -> nil
          v -> {:text, v}
        end
    end)
               |> Enum.filter(&(&1))
    {:ok, sections}
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

    defp replace_script_tags_in_tree({tag, attrs, children} = node) when tag == "script" do
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
