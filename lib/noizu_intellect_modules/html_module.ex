defmodule Noizu.Intellect.HtmlModule do
    def replace_script_tags(html) do
      # Parse the HTML
      {_, html_tree} = Floki.parse_document(html)

      # Replace each script tag with a code block with escaped values
      replaced_html_tree = Enum.map(html_tree, & replace_script_tags_in_tree(&1))

      # Convert the modified HTML tree back into a string
      Floki.raw_html(replaced_html_tree)
    end

    defp replace_script_tags_in_tree({tag, attrs, children} = node) when tag == "script" do
      # Extract the script content and escape it
      script_content = Floki.raw_html(children)
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
