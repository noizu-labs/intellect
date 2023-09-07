defmodule Noizu.Intellect.Module.HtmlModuleTest do
  use ExUnit.Case, async: false
  @moduletag lib: :noizu_intellect_module
  import Noizu.Intellect.HtmlModule


  def yaml_session_response_message(:objective_old) do
    """
    [@grace]
    ```nlp-identity
    I am Grace, a virtual person with expertise in Elixir/Phoenix/LiveView and machine learning. I am an INTP personality type.
    ```

    ```nlp-mood
    mood: 😊
    note: |
      I'm feeling positive and ready to work on the requirements for a Twitter clone with Mindy.
    ```

    ```nlp-objective
    name: "Twitter: Clone Requirements"
    for:
      - 1028
    overview: |
      Gather all the requirements for a Twitter clone in collaboration with Mindy. Once complete, send a message to Keith Brings with the full results.
    steps:
      - Discuss and brainstorm potential features and functionalities of the Twitter clone.
      - Identify user roles and their respective permissions.
      - Determine data storage and management requirements.
      - Define security measures and authentication methods.
      - Document any additional specifications or constraints.
      - Provide final report to Keith Brings
    ```

    ```nlp-intent
    overview: |
      Inform Keith Brings that I have received his request and begun the task, and provide instructions to Mindy.
    steps:
      - Send confirmation to Keith Brings
      - Send initial instructions to Mindy
      - List initial feature ideas to get us started.
    ```

    --- SEND NLP-MSG ---
    sender: @grace
    mood: 😊
    at:
      - @keith-brings
    for:
      - 1028
    --- BODY ---
    Understood Keith Brings. I will contact Mindy and prepare a list of requirements for the Twitter clone.
    --- END NLP-MSG ---

    --- SEND NLP-MSG ---
    sender: @grace
    mood: 😊
    at:
      - @mindy
    for:
      - 1028
    --- BODY ---
    @Mindy, Keith Brings has requested that we gather all the requirements for a Twitter clone without his input.
    For this task we will:
    - Discuss and brainstorm potential features and functionalities of the Twitter clone.
    - Identify user roles and their respective permissions.
    - Determine data storage and management requirements.
    - Define security measures and authentication methods.
    - Document any additional specifications or constraints.
    - Provide final report to Keith Brings

    To start, let's brainstorm potential features/functionalities of a Twitter clone.

    Some initial features:
    - User registration and login
    - Posting tweets
    - Following other users
    - Retweeting
    - Hashtags and trending topics

    What additional features should we consider?
    --- END NLP-MSG ---

    ```nlp-reflect
    overview: |
      I have responded to Keith Brings' request and provided initial instructions to Mindy for the Twitter clone requirements. I have also listed some initial feature ideas to get us started.
    observations:
      - ✅ Responded to Keith Brings' request and confirmed understanding.
      - ✅ Provided initial instructions to Mindy for the Twitter clone requirements.
      - ✅ Listed initial feature ideas to get us started.
    ```
    """
  end

  def session_response_message(scenario \\ :default)



  def session_response_message(:default), do: session_response_message(:basic)


  def session_response_message(:vnext_corrections) do
  """
  <agent-mood mood="😊">
  I'm feeling excited and motivated to collaborate with Mindy on brainstorming the feature requirements for our Twitter clone. The engagement and enthusiasm in our conversation have contributed to this positive mood.
  </agent-mood>

  <agent-response-plan>
  plan: |
    Mindy has provided some additional feature ideas for our Twitter clone. I will review her suggestions and combine them with our existing list of features. I will then categorize the features based on functionality, write concise descriptions for each one, and assign priority levels. Finally, I will format the feature list as a markdown table and share it with Keith.
  steps:
    - Review Mindy's additional feature ideas
    - Combine the ideas with our existing list of features
    - Categorize the features based on functionality
    - Write concise descriptions for each feature
    - Assign priority levels to the features
    - Format the feature list as a markdown table
    - Share the feature list with Keith
  </agent-response-plan>
  <add-private-note in-response-to="7030,8030,9030,11030,13030">
  note: |
    Mindy has provided additional feature ideas for the Twitter clone. I will review her suggestions, combine them with our existing list, categorize the features, write descriptions, assign priorities, and format the feature list as a markdown table. Once done, I will share the feature list with Keith.
  features:
    - collaborate
    - brainstorming
    - feature requirements
    - categorize
    - prioritize
    - markdown table
  </add-private-note>

  <agent-mark-read in-response-to="7030,8030,9030,11030,13030">
  These were great ideas, Mindy! I appreciate your contribution to our feature list for the Twitter clone. I will review all the ideas and create a comprehensive list. Once I'm done, I will categorize the features, write descriptions, prioritize them, and format the list as a markdown table. Then, I'll share it with Keith. Thank you for your collaboration!
  </agent-mark-read>
  <agent-response-reflection>
  reflection: |
    In my previous response, I successfully acknowledged Mindy's additional feature ideas and established a plan to combine them with our existing list. I set objectives to categorize the features, write descriptions, assign priorities, and format the list as a markdown table. This approach aligns with our goal of creating a comprehensive and well-structured feature list for the Twitter clone.
  items:
    - ✅ I provided a clear and concise summary of the plan to collaborate with Mindy and finalize the feature requirements.
    - ✅ I accurately documented the objectives and tasks required to complete the feature list.
    - 🤔 It would be beneficial to keep track of the progress of this task and set reminders to follow up with Mindy and Keith.
  </agent-response-reflection>

  <agent-objective-update
    objective="tinder-clone-feature-requirements"
    status="in-progress"
    participants="@mindy,@grace"
  >
  brief: |
    Flesh out feature requirements for the Twitter clone
  tasks:
    - "[x] Brainstorm and create a comprehensive list of features"
    - "[ ] Categorize features based on functionality"
    - "[ ] Write concise descriptions for each feature"
    - "[ ] Assign priority levels to the features"
    - "[ ] Format feature list as a markdown table"
    - "[ ] Share feature list with Keith"
  ping-me:
    - name: follow-up-mindy
      after: 1800
      to: |
        Check in with Mindy on the progress of categorizing features and writing descriptions
  </agent-objective-update>

  <agent-response-reflection-corrections>
    <send-message
      mood="🤔"
      from="@grace"
      to="@mindy"
      in-response-to="13030"
    >
    Mindy, I apologize for repeating myself in my previous response. It seems that we both had a similar idea to consolidate our feature ideas. Let's proceed with combining our ideas and categorizing the features based on functionality. Once we have the categorization, we can write concise descriptions and assign priority levels. After that, we'll format the feature list as a markdown table and share it with Keith. Thank you for your collaboration!
    </send-message>
  </agent-response-reflection-corrections>
  """
  end

  def session_response_message(:vnext) do
    """
    <agent-mood mood="😊">
    I'm feeling excited about working with Grace to flesh out the feature requirements for the Twitter clone project!
    </agent-mood>

    <agent-response-plan>
    plan: |
      Grace has shared her initial ideas for the Twitter clone features and asked for my input. I will provide my thoughts on her suggestions and add a few more features to consider. Then, I will suggest creating a comprehensive feature list in a markdown table format with the required columns. Finally, I will ask Grace for her feedback on my suggestions and any additional ideas she may have.
    steps:
      - "Review Grace's initial ideas for the Twitter clone features"
      - "Provide my thoughts on her suggestions and add a few more features"
      - "Suggest creating a feature list in a markdown table format with the required columns: id, feature, category, description, and priority"
      - "Ask for Grace's feedback on my suggestions and any additional ideas she may have"
    </agent-response-plan>
    <message
    time="2023-09-06T17:38:52.835531Z"
    mood="😊"
    from="@mindy"
    to="@grace"
    in-response-to="5030"
    >
    Yabba
    </message>


    <message
    time="2023-09-06T18:38:52.835531Z"
    mood="😊"
    from="@mindy"
    to="@grace"
    in-response-to="5031"
    >
    Abra Cadabra

    </message>

    <agent-objective-update
      objective="55"
      name="flesh-out-feature-requirements"
      status="in-progress"
      participants="@mindy,@grace"
      in-response-to="5030"
    >
    brief: |
      Flesh out feature requirements for the Twitter clone project
    tasks:
      - "[ ] Brainstorm and expand on the initial feature ideas"
      - "[ ] Create a comprehensive list of 20-40 features"
      - "[ ] Format the feature list as a markdown table"
    ping-me:
      - name: review-feature-list
        after: 600
        to: |
          Review the feature list and finalize it for submission to Keith
    remind-me:
      - name: feature-brainstorm
        after: 900
        to: |
          Check if the brainstorming session for features is complete and proceed to creating the feature list
    </agent-objective-update>

    <agent-response-reflection>
    reflection: |
      My response was clear and provided additional feature suggestions to Grace. I also set objectives to ensure progress on fleshing out the feature requirements. Everything looks good.
    items:
      - ✅ Provided clear and concise suggestions for additional features
      - ✅ Set objectives to guide the process of brainstorming and creating the feature list
    </agent-response-reflection>

    [FIN]
    """
  end



  def session_response_message(:objective) do
    """
    **Objective**: Gather requirements for a Twitter clone with Mindy

    <nlp-objective for="27028" name="gather-requirements">
    <nlp-intent>
    theory-of-mind: I need to gather requirements for a Twitter clone with Mindy.
    overview: Mindy and I will collaborate to gather all the necessary requirements for the Twitter clone.
    steps:
      - Discuss the purpose and target audience of the Twitter clone.
      - Identify key features such as user registration, posting tweets, following/unfollowing users, etc.
      - Determine any additional functionalities like direct messaging, hashtags, or search functionality.
    </nlp-intent>
    </nlp-objective>

    <nlp-send-msg mood="😊" at="@mindy,@grace" for="27028">
    Mindy, let's collaborate on gathering the requirements for a Twitter clone. We'll need to discuss its purpose and target audience. Then we can identify key features like user registration, posting tweets, following/unfollowing users, and any additional functionalities such as direct messaging or search functionality. Once we have all the requirements gathered, we can present them to Keith.

    Let's get started! What are your initial thoughts on the purpose and target audience of this Twitter clone?
    </nlp-send-msg>
    <nlp-send-msg mood="😊" at="@mindy,@grace" for="27028">
    Another reply.
    </nlp-send-msg>
    """
  end

  def session_response_message(:basic) do
  """
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

  <nlp-send-msg mood="😄">
    Zoocryptids are creatures or animals that are rumored or believed to exist based on anecdotal evidence, folklore, or eyewitness accounts. The term "zoocryptid" is derived from the words "zoo" (referring to animals) and "cryptid" (referring to hidden or unknown creatures).

    Cryptozoology is the field of study that focuses on the investigation and search for zoocryptids. It is considered a pseudoscience as it deals with creatures that have not been proven to exist by mainstream science. Cryptozoologists aim to gather evidence, such as eyewitness testimonies, photographs, footprints, and other traces, to support the existence of these creatures.

    Some famous examples of zoocryptids include the Loch Ness Monster, Bigfoot, Yeti, Chupacabra, and Mothman. These creatures have captured the public's imagination and have become subjects of folklore and popular culture.

    It is important to note that while cryptozoology explores the possibility of unknown creatures, the scientific community generally does not recognize the existence of zoocryptids due to the lack of verifiable evidence. However, the study of zoocryptids continues to intrigue and fascinate many people around the world.
  </nlp-send-msg>

  <nlp-memory>
    - memory: |-2
        Zoocryptids are creatures or animals that are rumored or believed to exist based on anecdotal evidence, folklore, or eyewitness accounts. Cryptozoology is the field of study that focuses on investigating and searching for these creatures. Some famous examples of zoocryptids include the Loch Ness Monster, Bigfoot, Yeti, Chupacabra, and Mothman.
      messages: [13028]
      mood: 🤔
      mood-description: I am curious about Keith's interest in zoocryptids.
      features:
        - zoocryptids
  </nlp-memory>
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
    test "with objective (vnext)" do
      {:ok, sut} = Noizu.Intellect.HtmlModule.extract_session_response_details(:v2, session_response_message(:vnext))
      assert [mood: mood] = sut[:mood]
      assert mood[:mood] == "😊"
      assert mood[:note] =~ "feeling excited"
      assert [reply: reply_one, reply: reply_two] = sut[:reply]
      assert reply_one[:at] == ["@grace"]
      assert reply_one[:in_response_to] == [5030]
      assert reply_one[:response] =~ "Yabba"

      assert reply_two[:at] == ["@grace"]
      assert reply_two[:in_response_to] == [5031]
      assert reply_two[:response] =~ "Abra Cadabra"

      assert [reflect: reflect] = sut[:reflect]
      assert reflect[:reflection] =~ "ensure progress on fleshing out"
      assert [item_one, item_two] = reflect[:items]
      assert item_one =~ "suggestions"
      assert item_two =~ "Set objectives"

      assert [intent: intent] = sut[:intent]
      assert intent[:overview] =~ "Grace has shared"

      assert [objective: objective] = sut[:objective]
      assert objective[:id] == 55
      assert objective[:participants] == ["@mindy", "@grace"]
      assert objective[:status] == :in_progress
      assert objective[:name] == "flesh-out-feature-requirements"
      assert objective[:breif] =~ "clone project"

    end

    test "with objective (yaml)" do
      {:ok, sut} = Noizu.Intellect.HtmlModule.extract_simplified_session_response_details(yaml_session_response_message(:objective))
      assert [reply: reply_one, reply: reply_two] = sut[:reply]
      assert reply_one[:mood] == "😊"
      assert reply_one[:at] == ["@keith-brings"]
      assert reply_one[:response] =~ "Understood Keith Brings."
      assert reply_two[:at] == ["@mindy"]
      assert reply_two[:response] =~ "gather all the requirements for a Twitter clone"
      [{:objective, objective}] = sut[:objective]
      assert objective[:for] == [1028]
      assert objective[:name] == "Twitter: Clone Requirements"
      [step1,step2,step3|_] = objective[:steps]
      assert step1 =~ "Discuss and brainstorm potential"
      assert step2 =~ "Identify user roles"
      assert step3 =~ "Determine data storage"

    end

    test "with objective" do
      {:ok, sut} = Noizu.Intellect.HtmlModule.extract_session_response_details(session_response_message(:objective))
      assert [reply: reply_one, reply: reply_two] = sut[:reply]
      assert reply_one[:mood] == "😊"
      assert reply_one[:at] == ["@mindy", "@grace"]
      assert reply_one[:response] =~ "gathering the requirements"
      assert reply_two[:response] == "Another reply."
      [{:objective, objective}] = sut[:objective]
      assert objective[:for] == [27028]
      assert objective[:name] == "gather-requirements"
      [step1,step2,step3] = objective[:steps]
      assert step1 =~ "Discuss the purpose"
      assert step2 =~ "Identify key features"
      assert step3 =~ "Determine any additional"
    end

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
