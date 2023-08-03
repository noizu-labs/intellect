defmodule GitFolderScanner do

  def scan_folder(folder_path) do
    gitignore_stack = []
    do_scan_folder(folder_path, gitignore_stack)
  end

  defp do_scan_folder(folder_path, gitignore_stack) do
    with {:ok, entries} <- folder_contents(folder_path) do
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
      ignored?(full_path, gitignore_stack) -> nil
      is_file?(full_path) -> {:file, full_path}
      is_dir?(full_path) ->
        gitignore_file = Path.join(full_path, ".gitignore")
        gitignore_stack = restrict_git_ignores(full_path, gitignore_stack)
        new_gitignore_stack =
          if file_exists?(gitignore_file) do
            extract_git_ignore(full_path, gitignore_file) ++ gitignore_stack
          else
            gitignore_stack
          end
        contents = do_scan_folder(full_path, new_gitignore_stack)
        {:folder, {full_path, contents}}
      true -> nil
    end
  end

  defp modified_wildcard(folder, glob) do
    cond do
      String.starts_with?(glob, "**/") ->
                                     # {:partial, {:all_subfolders, String.trim_leading(glob, "**/")}}
                                     [{:pending}]
      String.starts_with?(glob, "*/") ->
                                #{:partial, {:subfolders, String.trim_leading(glob, "*/")}}
                                [{:pending}]
      String.contains("**") ->
                         #Path.wildcard(folder <> glob)
                         [{:pending}]
      Regex.match?(~r/[^*]+[^\/]+\/.*/, glob) ->
           # Pending
        [{:pending}]
      String.ends_with?(glob, "/*") ->
        #[folder <> String.trim_trailing(glob, "*")]
        [{:pending}]
      :else -> Path.wildcard(folder <> glob) ++ [{:partial, glob}]
    end
  end

  defp extract_git_ignore(folder, gitignore_file) do
    with {:ok, content} <- File.read(gitignore_file),
         patterns <- String.split(content, "\n") do
      patterns
      |> Enum.map(&modified_wildcard(folder, &1))
      |> List.flatten()
    else
      _ -> []
    end
  end

  defp restrict_git_ignores(folder, gitignores) do
    Enum.map(gitignores, fn
      ({:partial, glob}) -> modified_wildcard(folder, glob)

    end)

    Enum.filter(gitignores, &String.starts_with(&1, folder))
  end

  defp ignored?(path, gitignore_globs) do
    Enum.member?(gitignore_globs, path)
  end


  @doc """
  Wrapper to make testing straight forward.
  """
  def folder_contents(folder_path) do
    File.ls(folder_path)
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
