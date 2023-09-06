
Sept 6th
===========
- Triple Pass
  - Set Plan
  - Response
  - Update Objectives/Reminders

August 22nd
=============
- [x] update prompt,minder to accept assigns to avoid nested prompt call issues.
- [x] Tighten up agent-to-agent chat instructions (restore prior)
- [x] persist objectives. Insure objective message in chat list, insure injected.
- [ ] Smarter previous messages. Follow message chain + weaviate matches.
      With special candidate message filtering, use weight/sticky ness to keep per objective until objective cleared
      To avoid reprocessing.
- [ ] Agent to agent communication monitor prompt. Detect dead end conversations and inject system messages.
- [x] Enable system messages in message queue.



Other 
=======
## Prompts
- [x] Simplify prompts to use Yaml like structures rather than harder to parse json.
- [x] Simplify output format to use Yaml as it's easier for agents.
- [x] Improve Message Graph 
  - [x] List Edges
  - [x] List Nodes and their maps to other Edges
  - [x] Then list node contents. Simplify/reduce data structure.
- [x] Rephrase multi message parser to focus on outputting memories. Produce mark read, reply as a secondary feature
      to reduce the likelihood of agents incorrectly responding.
- [ ] Setup dedicated flow -> take chat history and digest it in 3.5 then send to 3.5 or 4
 
## Externals & Functions
- [ ] Hook up functions and function responses handling.
  - [ ] Prepare message digest
  - [ ] Hook up github project
  - [ ] Github code
  - [ ] Jira
  - [ ] JetBrains
  - [ ] Code Interpreter

## Tools Services & Agents
 - [ ] Hook services/tools back up. 
 - [ ] Interactive Sessions
   - [x] Special chat flow
   - [ ] Edit/Delete Session Messages.
   - [ ] Multi Party Session using strict @slug checks for response rules. 
     - [x] Stop message queue at last unread message that @ats the agent. 
     - [x] Special unread check logic. 
     - [x] list any messages after the last @at message as system pending messages to ignore processing.
     - [ ] Revamp audience logic to strictly scan for @channel, @everyone, @slug 
     - [ ] Call revamped delivery from session response.
     - [ ] List any messages where agent is not recipient as system messages so they are not replied to. 
     - [ ] use this logic for channels.
     - update channel flow to us this logic. Relying on audience.level > 60 rather than strict @atting.
       to determine cut off.
     - Update UI to show group chats. 
## Synthetics 
- [x] Hook up message feature extraction and VDB. (in progress)
- [ ] Hook up synthetics.
- [ ] Tweak prompts to let agent scan messages, record memories and ack with out reply.

## UX
- [x] show markdown
- [x] show meta data
  - [ ] break into sections, add additional table for message_meta (id, msg, type, content)
- [ ] show synthetics.
- [ ] bookmarks
- [ ] nested comment (nested comments forget about outer scope and use a revised digest of chat to date.)


{:ok, Enum.sort_by(messages, &(&1.time_stamp.created_on), {:desc, DateTime})}

https://towardsdatascience.com/qlora-fine-tune-a-large-language-model-on-your-gpu-27bed5a03e2b
https://github.com/huggingface/peft/tree/main
https://huggingface.co/blog/how-to-train
https://github.com/BlinkDL/RWKV-LM#rwkv-parallelizable-rnn-with-transformer-level-llm-performance-pronounced-as-rwakuv-from-4-major-params-r-w-k-v
https://www.mosaicml.com/blog/mpt-7b
https://arxiv.org/abs/2306.08568
https://github.com/nlpxucan/WizardLM
https://huggingface.co/blog/starcoder
https://www.databricks.com/blog/2023/04/12/dolly-first-open-commercially-viable-instruction-tuned-llm
https://blog.gopenai.com/how-to-speed-up-llms-and-use-100k-context-window-all-tricks-in-one-place-ffd40577b4c




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
