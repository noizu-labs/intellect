defmodule Noizu.Intellect.Weaviate.Message do
  use Noizu.Weaviate.Class
  weaviate_class("Message") do
    description "Searchable Message Schema"
    property :content, :text
    property :brief, :text
    property :features, :"text[]"
    property :audience, :"int[]"
    property :responding_to, :"int[]"
  end
end
