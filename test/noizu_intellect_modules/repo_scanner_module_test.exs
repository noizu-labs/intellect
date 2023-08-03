



defmodule Noizu.Intellect.RepoScannerModuleTest do
  use ExUnit.Case
  use Mimic


  defmodule Stub do
    @dir_structure %{"" => %{
      "github" => %{
        "noizu_intellect" => %{
          "foo" => %{
            ".gitignore" => {:file, """
            bar/
            subby/*.mop
            **/*.bop
            */bip
            f*y/*.wuzzy
            bimbo/himbo/
            nas/**.apple
            *.never
            **.always
            only*.maybe
            ./only*.heh
            ./bimbo/herbo
            ./anna
            ./henry/five
            """},
            "anna" => %{
              "hey" => {:file, ""}
            },
            "as_a_folder.never" => %{
              "apple" => {:file, ""}
            },
            "bar" => %{},
            "bimbo" => %{
              "anna" => {:file, ""},
              "himbo" => %{
                "hello" => {:file, ""}
              }
            },
            "booma.bop" => {:file, ""},
            "fuzzy" => %{
              "helloa.wuzzy" => {:file, ""},
              "mop" => {:file, ""}
            },
            "hello.bop" => {:file, ""},
            "hello.never" => {:file, ""},
            "henry" => %{
              "five" => {:file, ""}
            },
            "n.always" => {:file, ""},
            "nas" => %{
              "hello.apple" => {:file, ""},
              "nested" => %{
                "hello.apple" => {:file, ""}
              }
            },
            "notbar" => %{
              ".apple" => {:file, ""},
              "bar" => %{
                "snoo" => {:file, ""}
              },
              "bimbo" => %{
                "herbo" => %{
                  "apple" => {:file, ""}
                },
                "himbo" => %{
                  "hello" => {:file, ""}
                }
              },
              "fay" => %{
                "sn.wuzzy" => {:file, ""}
              },
              "fuzzy" => %{
                "helloa.wuzzy" => {:file, ""}
              },
              "nas" => %{
                "hello.apple" => {:file, ""},
                "nested" => %{
                  "hello.apple" => {:file, ""}
                }
              },
              "nuzzy" => %{
                "helloa.wuzzy" => {:file, ""},
                "onlybest.maybe" => {:file, ""}
              },
              "onlyaonly.heh" => {:file, ""},
              "onlybest.maybe" => {:file, ""},
              "subby" => %{
                "hello.mop" => {:file, ""},
                "hello.never" => {:file, ""},
                "n.always" => {:file, ""},
                "nownownow.always" => {:file, ""}
              }
            },
            "noway.always" => {:file, ""},
            "onlyaonly.heh" => {:file, ""},
            "onlybest.maybe" => {:file, ""},
            "subby" => %{
              "hello.mop" => {:file, ""}
            },
            "uppa.bop" => {:file, ""}
          }
        }
      }
    }
    }


    def folder_contents(path) do
      path = String.split(path, "/")
      get_in(@dir_structure, path)
      |> case do
           v when is_map(v) ->
             keys = Map.keys(v) |> Enum.sort()
             {:ok, keys}
           _ -> {:ok,  []}
         end
    end


    def file_contents(path) do
      path = String.split(path, "/")
             |> Enum.map(& Access.key(&1,%{}))
      get_in(@dir_structure, path)
      |> case do
           {:file, contents} -> {:ok, contents}
           _ -> nil
         end
    end


    def file_exists?(path) do
      path = String.split(path, "/")
             |> Enum.map(& Access.key(&1,%{}))
      get_in(@dir_structure, path)
      |> case do
           {:file, _} -> true
           c = %{} -> !(c == %{})
         end
    end

    def is_file?(path) do
      path = String.split(path, "/")
             |> Enum.map(& Access.key(&1,%{}))
      get_in(@dir_structure, path)
      |> case do
           {:file, _} -> true
           _ -> false
         end
    end

    def is_dir?(path) do
      path = String.split(path, "/")
             |> Enum.map(& Access.key(&1,%{}))
      get_in(@dir_structure, path)
      |> case do
           %{} -> true
           _ -> false
         end
    end


    def wildcard(glob) do
      #IO.puts "------ #{glob}"
      wildcard_inner(glob)
      #|> IO.inspect(label: "MATCHES")
    end

    def wildcard_inner(glob, base \\ @dir_structure) do
      case String.split(glob, "/") do
         ["."] -> []
         [h] ->
          #IO.puts " CHECK 1 #{h}"
          {:ok, p} = h
                     |> String.replace(".", "\.")
                     |> String.replace("*", ".*")
                     |> Regex.compile()
          keys = Map.keys(base)
          Enum.map(keys, fn(key) ->
            if String.match?(key, p) do
              key
            else
              nil
            end
          end) |> Enum.reject(&is_nil/1)
        [h|t] ->
          #IO.puts " CHECK #{h}"
          {:ok, p} = h
                     |> String.replace(".", "\.")
                     |> String.replace("*", ".*")
                     |> Regex.compile()
          keys = Map.keys(base)
          Enum.map(keys, fn(key) ->
            if String.match?(key, p) do
              inner = wildcard_inner(Enum.join(t,"/"), Map.get(base, key, %{}))
              Enum.map(inner, &(key <> "/" <> &1))
            else
              []
            end
          end) |> Enum.reject(&is_nil/1) |> List.flatten()
      end
    end

    def folder_subdirs(folder) do
      path = String.split(folder, "/")
             |> Enum.map(& Access.key(&1,%{}))

      get_in(@dir_structure, path)
      |> case do
           d = %{} ->
             {:ok, Enum.filter(Map.keys(d), &(is_dir?(folder <> &1)))}
           _ -> {:ok, []}
         end
    end
  end

  test "scan_folder with specific directory structure returns empty list" do
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :folder_contents, &Stub.folder_contents/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :is_file?, &Stub.is_file?/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :file_exists?, &Stub.file_exists?/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :is_dir?, &Stub.is_dir?/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :wildcard, &Stub.wildcard/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :file_contents, &Stub.file_contents/1)
#    Mimic.stub(Noizu.Intellect.RepoScannerModule, :folder_subdirs, &Stub.folder_subdirs/1)

    foo_dir = List.to_string(:code.priv_dir(:noizu_intellect)) <> "/test/foo"
    assert Noizu.Intellect.RepoScannerModule.scan_folder( foo_dir) == [
             {:file, "#{foo_dir}/.gitignore"},
             {:folder, {"#{foo_dir}/anna", [file: "#{foo_dir}/anna/hey"]}},
             {:folder, {"#{foo_dir}/bimbo", [file: "#{foo_dir}/bimbo/anna"]}},
             {:folder, {"#{foo_dir}/fuzzy", [file: "#{foo_dir}/fuzzy/mop"]}},
             {:folder, {"#{foo_dir}/henry", [file: "#{foo_dir}/henry/five"]}},
             {:folder, {"#{foo_dir}/nas", [{:folder, {"#{foo_dir}/nas/nested", [file: "#{foo_dir}/nas/nested/hello.apple"]}},]}},
             {:folder, {"#{foo_dir}/notbar", [
                       {:file, "#{foo_dir}/notbar/.apple"},
             {:folder, {"#{foo_dir}/notbar/bimbo", [
               {:folder, {"#{foo_dir}/notbar/bimbo/herbo", [file: "#{foo_dir}/notbar/bimbo/herbo/apple"]}},
               {:folder, {"#{foo_dir}/notbar/bimbo/himbo", [file: "#{foo_dir}/notbar/bimbo/himbo/hello"]}}
              ]}},
               {:folder, {"#{foo_dir}/notbar/fay", [{:file, "#{foo_dir}/notbar/fay/sn.wuzzy"}]}},
               {:folder, {"#{foo_dir}/notbar/fuzzy", [{:file, "#{foo_dir}/notbar/fuzzy/helloa.wuzzy"}]}},
               {:folder, {"#{foo_dir}/notbar/nas", [ {:file, "#{foo_dir}/notbar/nas/hello.apple"},
                 {:folder, {"#{foo_dir}/notbar/nas/nested", [{:file, "#{foo_dir}/notbar/nas/nested/hello.apple"}]}},
               ]}},
               {:folder, {"#{foo_dir}/notbar/nuzzy", [{:file, "#{foo_dir}/notbar/nuzzy/helloa.wuzzy"}]}},
               {:file, "#{foo_dir}/notbar/onlyaonly.heh"},
               {:folder, {"#{foo_dir}/notbar/subby", [{:file, "#{foo_dir}/notbar/subby/hello.mop"}]}},
             ]}},
             {:file, "#{foo_dir}/onlyaonly.heh"},
           ]
  end
end
