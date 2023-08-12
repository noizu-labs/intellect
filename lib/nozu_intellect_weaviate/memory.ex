defmodule Noizu.Intellect.Weaviate.Memory do
  use Noizu.Weaviate.Class
  weaviate_class("Memory") do
    description "Searchable Agent Memory"
    property :identifier, :int
    property :content, :text
    property :created_on, :date
    property :features, :"text[]"
    property :agent, :int
    property :messages, :"int[]"
  end
end
