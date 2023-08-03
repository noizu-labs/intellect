defmodule Noizu.Intellect.RepoScannerModule do

  def scan_folder(folder_path) do
    folder_path = cond do
      String.ends_with?(folder_path, "/") -> String.slice(folder_path, 0..-2)
      :else -> folder_path
    end
    gitignore_file = Path.join(folder_path, ".gitignore")
    gitignore_stack = if Noizu.Intellect.RepoScannerModule.file_exists?(gitignore_file) do
      extract_git_ignore(folder_path, gitignore_file)
    else
      []
    end
    do_scan_folder(folder_path, gitignore_stack)
  end

  defp do_scan_folder(folder_path, gitignore_stack) do
    with {:ok, entries} <- Noizu.Intellect.RepoScannerModule.folder_contents(folder_path) do
      entries
      |> Enum.map(&process_entry(&1, folder_path, gitignore_stack))
      |> Enum.reject(&is_nil/1)
    else
      _ -> []
    end
  end

  defp process_entry(entry, folder_path, gitignore_stack) do
    full_path = Path.join(folder_path, entry)
    cond do
      reason = ignored?(entry, full_path, gitignore_stack) ->
        nil
      Noizu.Intellect.RepoScannerModule.is_file?(full_path) ->
        {:file, full_path}
      Noizu.Intellect.RepoScannerModule.is_dir?(full_path) ->
        gitignore_file = Path.join(full_path, ".gitignore")
        gitignore_stack = restrict_git_ignores(full_path, gitignore_stack)
        new_gitignore_stack =
          if Noizu.Intellect.RepoScannerModule.file_exists?(gitignore_file) do
            extract_git_ignore(full_path, gitignore_file)
          else
            []
          end
        do_scan_folder(full_path, gitignore_stack ++ new_gitignore_stack)
        |> case do
          [] -> nil
          nil -> nil
          contents ->
            contents = Enum.sort_by(contents, fn
              ({:file, x}) -> x
              ({:folder, {x, _}}) -> x
            end)
            {:folder, {full_path, contents}}
        end

      true -> nil
    end
  end

  def glob_to_regex(glob) do
    reg = glob
          |> String.replace(".", "\\.")
          #|> String.replace("\/", "\\\/")
          |> String.replace("**/", "<noizu:span:r>")
          |> String.replace("/**", "<noizu:span:l>")
          |> String.replace("*", "[^\/]*")
          |> String.replace("<noizu:span:r>", ".+\/?")
          |> String.replace("<noizu:span:l>", "\/.+")
    Regex.compile!("^" <> reg <> "$")
  end

  def folder_subdirs(folder) do
   #@todo implement get contents filter out files returning only dirs
    folder
    |> Noizu.Intellect.RepoScannerModule.folder_contents() |> elem(1)
    |> Enum.filter(&Noizu.Intellect.RepoScannerModule.is_dir?(folder <> &1))
  end

  def wildcard(path) do
    Path.wildcard(path)
  end

  defp modified_wildcard(folder, glob)
  defp modified_wildcard(folder, {:nested_glob, glob}) do
    folder = cond do
      String.ends_with?(folder, "/") -> String.slice(folder, 0..-2)
      :else -> folder
    end

    cond do
      !String.contains?(glob, "/") ->
        [{:ignore_match, {:regex, glob_to_regex(folder <> "/" <> glob)}}]
      !String.starts_with?(glob, "./") && String.match?(glob, ~r/^[^*\/]+\/$/) -> [{:ignore_match_dir, {:regex, glob_to_regex(String.slice(folder <> "/" <> glob,0..-2))}}]
      String.contains?(glob, "/") ->
        case String.split(glob, "/") do
          ["."] -> [nil]
          [""] -> [{:ignore_all, folder}]
          ["**"] -> [{:ignore_all, folder}]
          ["*"] -> [{:ignore_all, folder}]
          [h|t] ->
            cond do
              String.starts_with?(glob, "**") ->
                [{:ignore_match_keep, {:regex, glob_to_regex(folder <>   glob)}}]
              String.contains?(h, "**" ) ->
                [{:ignore_match_keep, {:regex, glob_to_regex(folder <> "/" <>   glob)}}]
              :else ->
                inner_glob = Enum.join(t, "/")
                Enum.map(Noizu.Intellect.RepoScannerModule.wildcard(folder <> "/" <> h),
                  fn(sub) ->
                    sub = cond do
                      String.ends_with?(sub, "/") -> String.slice(sub, 0..-2)
                      :else -> sub
                    end
                    {:subfolder, {sub, {:nested_glob, inner_glob}}}
                  end)
            end
        end
    end
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp modified_wildcard(folder, glob) do
    folder = cond do
      String.ends_with?(folder, "/") -> String.slice(folder, 0..-2)
      :else -> folder
    end

    cond do
      !String.contains?(glob, "/") -> [{:ignore_child, {:regex, glob_to_regex(glob)}}]
      !String.starts_with?(glob, "./") && String.match?(glob, ~r/^[^*\/]+\/$/) -> [{:ignore_dir, {:regex, glob_to_regex(String.slice(glob,0..-2))}}]
      String.contains?(glob, "/") ->
        case String.split(glob, "/") do
          ["."] -> [nil]
          [""] -> [{:ignore_all, folder}]
          ["**"] -> [{:ignore_subfolders, folder}]
          ["*"] -> [{:ignore_subfolders, folder}]
          [h|t] ->
            cond do
              String.starts_with?(glob, "**") ->
                [{:ignore_match_keep, {:regex, glob_to_regex(folder <> glob)}}]
              String.contains?(h, "**" ) ->
                [{:ignore_match_keep, {:regex, glob_to_regex(folder <> "/" <>   glob)}}]
              :else ->
                inner_glob = Enum.join(t, "/")
                Enum.map(Noizu.Intellect.RepoScannerModule.wildcard(folder <> "/" <> h),
                  fn(sub) ->
                    sub = cond do
                      String.ends_with?(sub, "/") -> String.slice(sub, 0..-2)
                      :else -> sub
                    end
                    {:subfolder, {sub, {:nested_glob, inner_glob}}}
                  end)
            end
        end
    end
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp extract_git_ignore(folder, gitignore_file) do
    with {:ok, content} <- Noizu.Intellect.RepoScannerModule.file_contents(gitignore_file),
         patterns <- String.split(content, "\n") do
      patterns
      |> Enum.map(&modified_wildcard(folder, String.trim(&1)))
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
    else
      _ -> []
    end
  end

  defp restrict_git_ignores(folder, git_ignores) do
    Enum.map(git_ignores, fn
      ({:subfolder, {^folder, inner}}) -> modified_wildcard(folder, inner)
      ({:ignore_match, _}) -> nil
      (glob) -> glob
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp ignored?(entry, full_path, git_ignores) do
    is_dir? = Noizu.Intellect.RepoScannerModule.is_dir?(full_path)
    git_ignores
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.find_value(
      fn
        {:ignore_all, _} -> :ignore_all
        {:ignore_subfolders, entries} -> Noizu.Intellect.RepoScannerModule.is_dir?(full_path) && :ignore_subfolders || nil
        {:nested_glob, glob} -> false
        {:ignore_child, entries} -> Enum.find_value(entries, fn({:ignore_child, {:regex, reg}}) -> String.match?(entry, reg) && :ignore_child || nil  end)
        {:ignore_dir, entries} -> is_dir? && Enum.find_value(entries, fn({:ignore_dir, {:regex, reg}}) -> String.match?(entry, reg) && :ignore_child || nil  end)
        {:ignore_match, entries} -> Enum.find_value(entries, fn({:ignore_match, {:regex, reg}}) -> String.match?(full_path, reg) && :ignore_match || nil  end)
        {:ignore_match_keep, entries} -> Enum.find_value(entries, fn({:ignore_match_keep, {:regex, reg}}) -> String.match?(full_path, reg) && :ignore_match || nil  end)
        {:ignore_match_dir, entries} -> is_dir? && Enum.find_value(entries, fn({:ignore_match_dir, {:regex, reg}}) -> String.match?(full_path, reg) && :ignore_match || nil  end)
        (_) -> nil
      end
    ) || false
  end


  @doc """
  Wrapper to make testing straight forward.
  """
  def folder_contents(folder_path) do
    with {:ok, files} <- File.ls(folder_path) do
      {:ok, Enum.sort(files)}
    end

  end


  @doc """
  Wrapper to make testing straight forward.
  """
  def file_contents(folder_path) do
    File.read(folder_path)
  end

  @doc """
  Wrapper to make testing straight forward.
  """
  def is_file?(full_path) do
    File.regular?(full_path)
  end

  @doc """
  Wrapper to make testing straight forward.
  """
  def is_dir?(full_path) do
    File.dir?(full_path)
  end

  @doc """
  Wrapper to make testing straight forward.
  """
  def file_exists?(full_path) do
    File.exists?(full_path)
  end
end
