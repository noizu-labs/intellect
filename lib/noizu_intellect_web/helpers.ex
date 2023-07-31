defmodule Noizu.IntellectWeb.Helpers do

  defmodule SlugGenerator do
    @prefixes ~w(Dr Ms PHD Phd Mr Ms Miz Esq Dr. Ms. PHD. Phd. Mr. Ms. Miz. Esq.)
    @suffixes ~w(Jr Sr Jr. Sr. 1st 2nd 3rd 4th I II III IV i ii iii iv 1st. 2nd. 3rd. 4th. I. II. III. IV. i. ii. iii. iv.)

    @doc """
    Generates a unique slug for a given string by applying a series of transformations and checks.

    ## Parameters

    - `mod`: The module that provides a `by_handle/1` function to check if a slug already exists.
    - `string`: The input string to generate a slug from.
    - `params`: Additional parameters that will be passed to the `by_handle/1` function.
    - `context`: The context that will be passed to the `by_handle/1` function.
    - `options`: A keyword list of options to customize the slug generation. It can include:
      - `:min`: The minimum length of the slug (default is 4).
      - `:max`: The maximum length of the slug (default is 12).
      - `:prefix`: A string that will always be prefixed to the slug.
      - `:suffix`: A string that will always be suffixed to the slug.
    - `iteration`: An internal parameter used for recursion. It starts at 0 and increments each time a potential slug is found to exist.

    ## How it works

    The function first splits the input string into words. It then generates a list of potential slugs based on the words, the `prefix` and `suffix` options, and the current `iteration` count. The potential slugs are generated in the following order:

    1. The first and last word of the input string.
    2. The first and last word of the input string with the first letter of the last word.
    3. The first and last word of the input string with the first letter of the first word.
    4. All words of the input string.
    5. All words of the input string with the prefix and suffix added, if they exist.

    The function then checks each potential slug in order to see if it exists by calling the `by_handle/1` function on the `mod` module. If a slug is found to exist, the function increments the `iteration` count and tries again. This process continues until a unique slug is found.

    ## Examples

    Given the input string "Dr. Keith Ian Flash Brings 2nd", the function will generate the following potential slugs:

     - "keithb",
     - "kbrings",
     - "keithbrings",
     - "keithianbrings",
     - "keithianflashbrings",
     - "drkeithb",
     - "drkbrings",
     - "drkeithbrings",
     - "drkeithianbrings",
     - "drkeithianflashbrings",
     - "keithb2nd",
     - "kbrings2nd",
     - "keithbrings2nd",
     - "keithianbrings2nd",
     - "keithianflashbrings2nd",
     - "drkeithb2nd",
     - "drkbrings2nd",
     - "drkeithbrings2nd",
     - "drkeithianbrings2nd",
     - "drkeithianflashbrings2nd"

    And so on, until a unique slug is found.

    """
    def generate_unique_slug(mod, string, params, context, options, iteration \\ 0) do
      options = options || []
      min = get_in(options, [:min]) || 4
      max = get_in(options, [:max]) || 14
      prefix = get_in(options, [:prefix]) || ""
      suffix = get_in(options, [:suffix]) || ""

      slug = string
             |> String.replace(~r/[^a-zA-Z0-9 \-]/, "")
             |> String.split()
             |> generate_potential_slugs(min, max, prefix, suffix, iteration)
             |> Enum.find(&slug_does_not_exist?(mod, &1, params, context, options))

      if slug, do: {:ok, slug}, else: generate_unique_slug(mod, string, params, context, options, iteration + 1)
    end

    #------------------------------
    #
    #------------------------------
    def generate_potential_slugs(words, min, max, prefix, suffix, iteration) do
      {prefix_word, base_words, suffix_word} = extract_prefixes_and_suffixes(words)

        base_words
        |> generate_word_combinations()
        |> add_prefix_and_suffix(prefix_word, suffix_word)
        |> Enum.uniq()
        |> Enum.map(&(generate_slug(&1, min, max, prefix, suffix, iteration)))
        |> Enum.uniq()
    end

    #------------------------------
    #
    #------------------------------
    defp extract_prefixes_and_suffixes(words) do
      {prefix, words_without_prefix} = extract_word(words, @prefixes)
      {suffix, words_without_suffix} = extract_word(Enum.reverse(words_without_prefix), @suffixes)
      {prefix, Enum.reverse(words_without_suffix), suffix}
    end


    #------------------------------
    #
    #------------------------------
    defp extract_word([h|t] = words, word_list) do
      cond do
        Enum.member?(word_list, h) -> {h, t}
        :else -> {nil, words}
      end
    end

    #------------------------------
    #
    #------------------------------
    defp generate_word_combinations(words) when length(words) > 1 do
      first = List.first(words)
      last = List.last(words)
      middle = Enum.slice(words, 1..-2)

      [
        [first, String.first(last)],
        [String.first(first), last],
        [first, last],
      ] |> then(
             fn(list) ->
               list ++ (if length(middle) > 0 do
                          Enum.map_reduce(middle, [], fn(w,acc) ->
                            acc = acc ++ [w]
                            entry = [first] ++ acc ++ [last]
                            {entry, acc}
                          end)
                          |> elem(0)
                        else
                          []
                        end)
             end
           )
    end
    defp generate_word_combinations(words), do: [words]

    #------------------------------
    #
    #------------------------------
    defp add_prefix_and_suffix(word_combinations, prefix_word, suffix_word) do
      word_combinations
      |> add_word(prefix_word)
      |> add_word_end(suffix_word)
    end

    #------------------------------
    #
    #------------------------------
    defp add_word(word_combinations, nil), do: word_combinations
    defp add_word(word_combinations, word) do
      word_combinations ++ Enum.map(word_combinations, &([word | &1]))
    end


    #------------------------------
    #
    #------------------------------
    defp add_word_end(word_combinations, nil), do: word_combinations
    defp add_word_end(word_combinations, word) do
      word_combinations ++ Enum.map(word_combinations, &(&1 ++ [word]))
    end

    #------------------------------
    #
    #------------------------------
    defp generate_slug(words, _min, max, prefix, suffix, iteration) do
      word = words
             |> Enum.map(&String.replace(&1, ~r/[^a-zA-Z0-9\-]/, ""))
             |> Enum.map_join("", &String.downcase/1)
      base_slug = String.slice(word, 0, max - String.length(prefix) - String.length(suffix))
      suffix = if iteration > 0, do: "#{iteration}#{suffix}", else: suffix
      "#{prefix}#{base_slug}#{suffix}"
    end


    #------------------------------
    #
    #------------------------------
    defp slug_does_not_exist?(mod, slug, params, context, options) do
      args = case params do
        nil -> [slug, context, options]
        _ when is_list(params) -> [slug | params] ++ [context, options]
        _ -> [slug, params, context, options]
      end
      case apply(mod, :by_handle, args) do
        {:ok, _record} -> false
        _ -> true
      end
    end

  end

  defmodule Time do

    def elapsed_time(timestamp) do
      now = DateTime.utc_now()
      duration = Timex.diff(now, timestamp, :second)
      cond do
        duration <= 15 -> "just now"
        duration <= 60 -> "#{div(duration, 60)} seconds ago"
        duration < 60 * 60 -> "#{div(duration, 60)} minutes ago"
        duration < 60 * 60 * 24 -> "#{div(duration, 60*60)} hours ago"
        duration < 60 * 60 * 24 * 7 -> "#{div(duration, 60*60*24)} days ago"
        :else ->
          Timex.format!(timestamp, "{Mshort} {D}, {YYYY}")
      end
    end

  end

  defmodule CodeUtils do


    def inner_html(message, tag) do
      case Floki.find(message, tag) do
        [{tag, _, inner}] -> {:ok, Floki.raw_html(inner, pretty: false, encode: false)}
      end
    end

    def extract_message(message) do
      nop = extract_tag(message, "nlp-nop")
      reply = extract_tag(message, "nlp-reply")
      intent = extract_tag(message, "nlp-intent")
      cot = extract_tag(message, "nlp-cot")
      functions = extract_function(message, "nlp-function")
      reflect = extract_tag(message, "nlp-reflect")
      cond do
        reply.count > 0 -> {:ok, {reply, %{raw: message, functions: functions, intent: intent, cot: cot, reflect: reflect}}}
        nop.count > 0 -> {:error, {:nop, %{raw: message, functions: functions, intent: intent, cot: cot, reflect: reflect}}}
        :else -> {:error, {:empty_reply, %{raw: message, functions: functions, intent: intent, cot: cot, reflect: reflect}}}
      end
    end

    def extract_tag(html, tag) do
      tag = Floki.find(html, tag)
      count = length(tag)
      content = if (count > 0), do: Enum.map(tag, &(Floki.raw_html([&1], pretty: false, encode: false))), else: nil
      %{tag: tag, count: count, content: content}
    end

    def extract_function(html, tag) do
      tag = Floki.find(html, tag)
      count = length(tag)
      content = if (count > 0) do
        Enum.map(tag, fn({tag, args, body}) ->
          function = Enum.find_value(args, fn({k,v}) -> k == "function" && v end)
          args = Floki.raw_html(body, pretty: false, encode: false)
          %{
          name: function,
          arguments: args
          }
        end)
      else
        nil
      end
      %{tag: tag, count: count, content: content}
    end



    def parse_llm_response(html, allowed \\ []) do
      with {:ok, document} <- Floki.parse_document(html) do
        document
        #|> Enum.reverse(document)
        |> CodeUtils.escape_llm_response(allowed)
        #|> Enum.reverse()
      else
        _ -> "[PARSE ERROR]"
      end
    end

    def strip_llm_response(document, allowed \\ []) do
        document
        #|> Enum.reverse(document)
        |> CodeUtils.do_strip_llm_response(allowed)
        #|> Enum.reverse()
        |> Floki.raw_html(pretty: false, encode: false)
    end


    def html_to_markdown(html) do
      with {:ok, document} <- Floki.parse_document(html) do
        CodeUtils.replace_html_with_text(document)
        |> CodeUtils.replace_code_blocks()
        |> Floki.raw_html(pretty: false, encode: false)
      else
        _ -> "[PARSE ERROR]"
      end
    end

    def replace_html_with_text(document) do
      Floki.traverse_and_update(document, fn
        {"code", attr, contents}  ->
          {"code", attr, replace_html_with_text(contents)}
        {"br", [], []} -> "\n"
        {"b", _, contents} -> ["*", replace_html_with_text(contents), "*"]
        {_, _, contents} ->
          contents = replace_html_with_text(contents)
          contents
        elem when is_bitstring(elem) -> elem
        _ -> ""
      end)
    end

    def unstrip_llm_response(document, allowed) do
      Floki.traverse_and_update(document, fn
        {{:strip, tag}, attributes, contents} ->
          {tag, attributes, unstrip_llm_response(contents, allowed)}
        {elem, attributes, contents} -> {elem, attributes, contents}
        elem when is_bitstring(elem) -> elem
        _ -> ""
      end)
    end


    def escape_llm_response(document, allowed) do
      case document do
        [v] when is_bitstring(v) ->
        cond do
          String.contains?(v, "`") ->
            with {:ok, d} <- Earmark.as_html!(v, escape: false, inner_html: true) |> Floki.parse_document() do
              [d]
            else
              error ->
                [v]
            end
            :else ->  [v]
        end
        v -> v
      end
      |>  Floki.traverse_and_update(fn
        {"nlp-reply", _, contents} ->
           [{"br", [], []}] ++ escape_llm_response(contents, allowed)
        {"nlp-meta", _, contents} ->
          ""
        {"nlp-query", attributes, contents} ->
          {"pre", [], [{"code", [{"class", "query"}] ++ attributes, escape_llm_response(contents, allowed)}]}
        {"nlp-intent", attributes, contents} ->
          ""
        {"nlp-" <> nlp, attributes, contents} ->
          {"nlp-" <> nlp, attributes, escape_llm_response(contents, allowed)}
        {"llm-fim-content", attributes, contents} ->
          {"llm-fim-content", attributes, unstrip_llm_response(contents, allowed)}
        {"llm-" <> nlp, attributes, contents} ->
          {"llm-" <> nlp, attributes, escape_llm_response(contents, allowed)}
        {:llm_code_type, [], contents} -> {:llm_code_type, [], contents}
        {"code", attributes, contents} ->
          c = Enum.find_value(attributes, fn({k,v})-> k == "class" && v end)
          case c do
            "assistant to=functions" <> _ -> ""
            _ -> {"code", attributes, escape_llm_response(contents, allowed)}
          end
        {tag, attributes, contents} when tag in ["br", "p", "b", "pre", "ul", "ol", "li"] ->
          {tag, attributes, escape_llm_response(contents, allowed)}
        "" ->
           ""
        elem when is_bitstring(elem) ->
          Earmark.as_html!(elem, escape: false, inner_html: true)
        {{:strip, tag}, attributes, contents} ->
          {{:strip, tag}, attributes, contents}
        {tag, attributes, contents} ->
          {{:strip, tag}, attributes, contents}
        v ->
          v
      end)
    end



    def do_strip_llm_response(document, allowed) do
      case document do
        [v] when is_bitstring(v) ->
          cond do
            String.contains?(v, "`") ->
              with {:ok, d} <- Earmark.as_html!(v, escape: false, inner_html: true)
                               |> Floki.parse_document() do
                [d]
              else
                error ->
                  [v]
              end
            :else ->  [v]
          end
        v -> v
      end
     #  document
    |>  Floki.traverse_and_update(fn
        {"nlp-reply", attributes, contents} ->
          do_strip_llm_response(contents, allowed)
        {"nlp-intent", attributes, contents} ->
          #IO.puts "DROP nil-#{elem}"
          {:comment, [], contents}
        {"nlp-" <> elem, attributes, contents} when elem in ["fim", "git", "reply", "conclusion", "request", "query", "pub", "cr", "memory"] ->
          {"nlp-" <> elem, attributes, do_strip_llm_response(contents, allowed)}
        {"llm-fim-content", attributes, contents} ->
          {"llm-fim-content", attributes, contents}
        {"llm-" <> elem, attributes, contents} ->
          {"llm-" <> elem, attributes, do_strip_llm_response(contents, allowed)}
        {"code" = tag, attributes, contents} ->
          # if not inline then add a inner element to show type.
          cond do
            v = Enum.find_value(attributes, fn({k,v}) -> k == "class" && v != "inline" && v end) ->
              case contents do
                [{"llm-code-type", [], ^v}|_] -> {"code", attributes, do_strip_llm_response(contents, allowed)}
                c when is_bitstring(c) ->
                  #IO.puts "INJECT CODE_TYPE #{inspect attributes} - #{inspect contents}"
                  {"code", attributes, do_strip_llm_response([{"llm-code-type", [], v}, c], allowed)}
                _ ->
                  #IO.puts "INJECT CODE_TYPE #{inspect attributes} - #{inspect contents}"
                  {"code", attributes, do_strip_llm_response([{"llm-code-type", [], v}] ++ contents, allowed)}
              end
            :else ->
              {"code", attributes, do_strip_llm_response(contents, allowed)}
          end


        {tag, attributes, contents} when tag in ["p", "b", "pre", "ul", "ol", "li"] ->
          {tag, attributes, do_strip_llm_response(contents, allowed)}
        #{"nlp-" <> _, attributes, contents} -> nil
        {{:strip, tag}, attributes, contents} ->
          cond do
            Enum.member?(allowed, tag) -> {tag, attributes, do_strip_llm_response(contents, allowed)}
            :else ->
              contents = do_strip_llm_response(contents, allowed)
              # @pri-1 need to escape html inside of attributes
              attributes = Enum.map(attributes,
                             fn({k,v}) ->
                               v2 = v && String.replace(v, "<", "&lt;") |> String.replace(">", "&gt;")
                               v2 = v2 && Poison.encode!(v2)
                               if v2 do
                                 "#{k}=\"#{v}\""
                               else
                                 "#{k}"
                               end
                             end)
                           |> Enum.join(" ")
              |> case do
                 "" -> ""
                 v -> " " <> v
                 end

              ["<#{tag}#{attributes}>"] ++  contents ++ ["</#{tag}>"]
          end
        {tag, attributes, contents} ->
          {tag, attributes, contents}
          "" ->
                nil
        elem when is_bitstring(elem) ->
          Earmark.as_html!(elem, escape: false, inner_html: true)
        v ->
          v
      end)
    end


    def replace_code_blocks(data) do
      Enum.map(data, &replace_code_block/1)
    end

    defp replace_code_block(item) when is_list(item) do
      Enum.map(item, &replace_code_block/1)
    end

    defp replace_code_block({"code", attrs, content}) do
      nested_code = replace_code_blocks(content)
      depth = calculate_nesting_depth(content)
      backticks = String.duplicate("`", depth + 3)

      language = Enum.find_value(attrs,
        fn
          ({"class", v}) -> v
          ({"data-code-type", v}) -> v
          (_) -> false
        end) || "markdown"
      "#{backticks}#{language}\n#{nested_code}\n#{backticks}"
    end

    defp replace_code_block(item), do: item

    defp calculate_nesting_depth(content) do
      Enum.reduce(content, 0, fn item, acc ->
        if is_tuple(item) and elem(item, 0) == "code" do
          nested_depth = calculate_nesting_depth(elem(item, 2))
          max(acc, nested_depth + 1)
        else
          acc
        end
      end)
    end
  end
end
