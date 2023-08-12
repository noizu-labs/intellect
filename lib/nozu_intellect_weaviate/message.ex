defmodule Noizu.Intellect.Weaviate.Message do
  use Noizu.Weaviate.Class
  weaviate_class("Message") do
    description "Searchable Message Schema"
    property :identifier, :int
    property :content, :text
    property :action, :text
    property :sender, :string
    property :created_on, :date
    property :features, :"text[]"
    property :audience, :"int[]"
    property :responding_to, :"int[]"
  end
end
