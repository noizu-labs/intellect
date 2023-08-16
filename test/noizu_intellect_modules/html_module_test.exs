defmodule Noizu.Intellect.Module.HtmlModuleTest do
  use ExUnit.Case, async: false
  @moduletag lib: :noizu_intellect_module
  import Noizu.Intellect.HtmlModule

  def session_response_message() do
  """
  <nlp-agent for="@grace">
  <nlp-intent>
    overview: |-2
      I will provide an overview of what zoocryptids are and their significance in cryptozoology.
    steps:
      - Provide a definition of zoocryptids.
      - Explain the field of cryptozoology and its focus on the study of zoocryptids.
      - Discuss some famous examples of zoocryptids.
  </nlp-intent>

  <nlp-function-call function="bizbop">
  name: hero
  arg: 5
  </nlp-function-call>

  <nlp-reply mood="😄">
    Zoocryptids are creatures or animals that are rumored or believed to exist based on anecdotal evidence, folklore, or eyewitness accounts. The term "zoocryptid" is derived from the words "zoo" (referring to animals) and "cryptid" (referring to hidden or unknown creatures).

    Cryptozoology is the field of study that focuses on the investigation and search for zoocryptids. It is considered a pseudoscience as it deals with creatures that have not been proven to exist by mainstream science. Cryptozoologists aim to gather evidence, such as eyewitness testimonies, photographs, footprints, and other traces, to support the existence of these creatures.

    Some famous examples of zoocryptids include the Loch Ness Monster, Bigfoot, Yeti, Chupacabra, and Mothman. These creatures have captured the public's imagination and have become subjects of folklore and popular culture.

    It is important to note that while cryptozoology explores the possibility of unknown creatures, the scientific community generally does not recognize the existence of zoocryptids due to the lack of verifiable evidence. However, the study of zoocryptids continues to intrigue and fascinate many people around the world.
  </nlp-reply>

  <nlp-memory>
    - memory: |-2
        Zoocryptids are creatures or animals that are rumored or believed to exist based on anecdotal evidence, folklore, or eyewitness accounts. Cryptozoology is the field of study that focuses on investigating and searching for these creatures. Some famous examples of zoocryptids include the Loch Ness Monster, Bigfoot, Yeti, Chupacabra, and Mothman.
      messages: [13028]
      mood: 🤔
      mood-description: I am curious about Keith's interest in zoocryptids.
      features:
        - zoocryptids
  </nlp-memory>
  </nlp-agent>
  """
  end

  def delivery_details_happy_path() do
    """
    <monitor-response>
      message_details:
        replying_to:
          - message:
            for: 123401
            confidence: 42
            explanation: "Apple Bapple"
            complete: true
            completed_by: 532
          - message:
            for: 123501
            confidence: 43
            explanation: "BApple Snapple"
          - message:
            for: 123601
            confidence: 43
      audience:
        - member:
          for: 111102
          confidence: 33
          explanation: "Henry"
        - member:
          for: 111202
          confidence: 44
          explanation: "Ford"
      summary:
        content: "Brief Details."
        features:
          - "AAA"
          - "BBB"
    </monitor-response>
    """
  end

  def valid_response() do
    """

    <mark-read for="1,2,3,4,5"/>
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
  <mark-read for="1,2,3,4,5"/>
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

  describe "yaml parsing suite" do

    test "should convert map to yaml" do
      map = %{a: 1, b: 2, c: 3}
      assert to_yaml(map) == """
             a: 1
             b: 2
             c: 3
             """
    end

    test "should convert nested map to yaml" do
      map = %{a: %{b: 1, c: 2}, d: 3}
      assert to_yaml(map) == """
             a:
               b: 1
               c: 2
             d: 3
             """
    end

    test "should convert list to yaml" do
      list = [1, 2, 3]
      assert to_yaml(list) == """
             - 1
             - 2
             - 3
             """
    end

    test "should convert nested list to yaml" do
      list = [1, [2, 3], 4]
      assert to_yaml(list) == """
             - 1
             - - 2
               - 3
             - 4
             """
    end

    test "should convert complex data structure to yaml" do
      data = %{a: [1,2,3,4], b: [%{c: 1, d: 2}, %{c: [5, %{beta: 7, zeta: 8, mecka: [1,2,3]}, "apple"], d: 5}, "hey"], f: "apple aple\n apple"}

      assert to_yaml(data) == """
             a:
               - 1
               - 2
               - 3
               - 4
             b:
               - c: 1
                 d: 2
               - c:
                   - 5
                   - beta: 7
                     mecka:
                       - 1
                       - 2
                       - 3
                     zeta: 8
                   - apple
                 d: 5
               - hey
             f: |-
               apple aple
                apple
             """
    end
  end

  describe "Handle Session Channel Response" do
    @tag :wip
    test "happy path" do
      sut = Noizu.Intellect.HtmlModule.extract_session_response_details(session_response_message())
      IO.inspect sut
      [agent: [sender: sender, sections: sections]] = sut

      assert sender == "@grace"

      sections = Enum.group_by(sections, & elem(&1, 0))

      [{:reply, reply}] = sections[:reply]
      assert reply[:mood] == "😄"
      assert reply[:response] =~ "subjects of folklore and popular culture"

      [{:intent, intent}] = sections[:intent]
      assert intent =~ "I will provide an overview of what"

      [{:memory, memory}] = sections[:memory]
      assert memory["features"] == ["zoocryptids"]

      [{:function_call, call}] = sections[:function_call]
      assert call[:function] == "bizbop"
      assert call[:args]["arg"] == 5
    end
  end

  describe "Handle Message Delivery Response" do
    test "happy path" do
      sut = Noizu.Intellect.HtmlModule.extract_message_delivery_details(delivery_details_happy_path)
      assert sut == [
               audience: {111102, 33, "Henry"},
               audience: {111202, 44, "Ford"},
               responding_to: {123401, 42, {true, 532}, "Apple Bapple"},
               responding_to: {123501, 43, {nil, nil}, "BApple Snapple"},
               responding_to: {123601, 43, {nil, nil}, nil},
               summary: {"Brief Details.", ["AAA", "BBB"]}
             ]
    end
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
