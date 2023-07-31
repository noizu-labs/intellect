defmodule Noizu.Intellect.Module.HtmlModuleTest do
  use ExUnit.Case, async: false
  @moduletag lib: :noizu_intellect_module


  def valid_response() do
    """

    <ack for="1,2,3,4,5"/>
    <reply for="6,7">
      <nlp-intent>
      I will do a thing
      </nlp-intent>
      <response>My actual response</response>
      <nlp-reflect>
      My Reflection on my response.
      </nlp-reflect>
    </reply>
    <reply for="8,9">
      <nlp-intent>
      Another Intent
      </nlp-intent>
      <response>Another response</response>
      <nlp-reflect>
      More Reflections
      </nlp-reflect>
    </reply>
    """
  end

  def malformed_response() do
  """
  Ignore this
  <ack for="1,2,3,4,5"/>
  Ignore this as well
  <reply for="6,7">
    <nlp-intent>
    I will do a thing
    </nlp-intent>
    <response>My actual response</response>
    <nlp-reflect>
    My Reflection on my response.
    </nlp-reflect>
  </reply>
  <reply for="8,9">
    <nlp-intent>
    Another Intent
    </nlp-intent>
    <response>Another response</response>
    <nlp-reflect>
    More Reflections
    </nlp-reflect>
  </reply>
  Ignore this as well
  <unexpected>Ignore this</unexpected>
  """
  end



  test "extract_response_sections - valid" do
    {:ok, response} = Noizu.Intellect.HtmlModule.extract_response_sections(valid_response())
    valid? = Noizu.Intellect.HtmlModule.valid_response?(response)
    assert valid? == :ok
    response = Enum.group_by(response, &(elem(&1, 0)))

    [ack] = response.ack
    assert ack == {:ack, [ids: [1,2,3,4,5]]}
    [reply_one, reply_two] = response.reply
    assert reply_one == {:reply, [ids: [6,7], intent: "I will do a thing", response: "My actual response", reflect: "My Reflection on my response."]}
    assert reply_two == {:reply, [ids: [8,9], intent: "Another Intent", response: "Another response", reflect: "More Reflections"]}
  end

  test "extract_response_sections - malformed but repairable" do
    {:ok, response} = Noizu.Intellect.HtmlModule.extract_response_sections(malformed_response())
    valid? = Noizu.Intellect.HtmlModule.valid_response?(response)
    assert valid? != :ok
    assert valid? == {:issues, [invalid_section: {:text, "Ignore this"}, invalid_section: {:text, "Ignore this as well"}, invalid_section: {:text, "Ignore this as well"}, invalid_section: {:other, {"unexpected", [], ["Ignore this"]}}]}
    {:ok, repair} = Noizu.Intellect.HtmlModule.repair_response(response)
    repair = Enum.group_by(repair, &(elem(&1, 0)))

    [ack] = repair.ack
    assert ack == {:ack, [ids: [1,2,3,4,5]]}
    [reply_one, reply_two] = repair.reply
    assert reply_one == {:reply, [ids: [6,7], intent: "I will do a thing", response: "My actual response", reflect: "My Reflection on my response."]}
    assert reply_two == {:reply, [ids: [8,9], intent: "Another Intent", response: "Another response", reflect: "More Reflections"]}
  end

  test "extract_meta_data" do

  end

end
