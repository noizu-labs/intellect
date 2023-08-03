- [ ] Hook up functions and function responses handling.
  - [ ] Hook up github project
  - [ ] Github code
  - [ ] Jira
  - [ ] JetBraings
  - [ ] Code Interpreter
- [ ] Hook up message feature extraction and VDB. 
  - [ ] Switch to local postgres or modify docker container. 
- [ ] Hook up synthetics.
- [ ] Tweak prompts to let agent scan messages, record memories and ack with out reply.










        # Example 1 - Agent replies to a high priority and medium priority message and ignores (acks) a low priority message.

        ## Input

        ### New Messages

        ```yaml
        messages:
        - id: 435027
        processed: false
        priority: 1.0
        sender:
        id: 1016
        type: human
        slug: keith-brings
        name: Keith Brings
        sent-on: "2023-07-31 16:28:20.011348Z"
        contents: |-1
         What year is it.
        - id: 435029
        processed: false
        priority: 0.5
        sender:
        id: 1012
        type: human
        slug: steve-queen
        name: Steve McQueen
        sent-on: "2023-07-31 16:29:20.011348Z"
        contents: |-1
         and how are you doing today?
        - id: 435030
        processed: false
        priority: 0.1
        sender:
        id: 1010
        type: human
        slug: steve-queen
        name: Steve McQueen
        sent-on: "2023-07-31 16:29:50.011348Z"
        contents: |-1
         Yo @denmark whats up?
        ```

        ## Output

        ### ✔ Output - valid output
        <reply-message for="435027,435029">
        <nlp-intent>
        [...]
        </nlp-intent>
        <response>
        Hey steve, I am pretty good. Keith It's Monday July 31st.
        </response>
        <nlp-reflect>
        [...]
        </nlp-reflect>
        </reply-message>
        <ack for="435030">Ignoring Low Priority</ack>

        ### ❌ Output - invalid response, acks high priority message but does not reply-message.
        <ack for="435027,435029,435030">Acknowledge</ack>

        # Example 2 - Agent ignores message queue of only low priority messages.

        ## Input

        ### New Messages
        ```yaml
        messages:
        - id: 335027
          processed: false
          priority: 0.0
          sender:
          id: 1016
          type: human
          slug: keith-brings
          name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           What year is it.
        - id: 335029
          processed: false
          priority: 0.0
          sender:
          id: 1016
          type: human
          slug: keith-brings
          name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           Why is year.
        ```

        ## Output
        ### ✔ Output

        <ack for="335027">Ignoring Low Priority</ack>

        ### ❌ Output - invalid response, reply-message to a zero-priority message.
        <reply-message for="335027">
        [...]
        </reply-message>

        # Example 3 - Agent replies to high priority messages.

        ## Input

        ### New Messages
        ```yaml
        messages:
        - id: 635027
          processed: false
          priority: 1.0
          sender:
          id: 1016
          type: human
          slug: keith-brings
          name: Keith Brings
          sent-on: "2023-07-31 16:28:20.011348Z"
          contents: |-1
           What year is it.
        ```

        ## Output
        ### ✔ Output

        <reply-message for="635027">
        [...]
        </reply-message>

        ### ❌ Output - ignores high priority message

        <ack for="635027">Acknowledging your message</ack>
