DO $block$
        DECLARE
            current_ts TIMESTAMP WITHOUT TIME ZONE = NOW();
            BEGIN

            insert into service (identifier, slug, type, details, prompt, minder, settings, created_on, modified_on)
            values (
                       generate_uid('Service'),
                       'gpt-term',
                       'tool',
                       create_versioned_string('gpt-term','Simulated Command Line Terminal'),
                       create_versioned_string(
                        'gpt-term prompt',

                        '⌜tool|gpt-term|nlp0.5⌝\n' ||
                        'Virtual Command Line Terminal\n'
                        '🙋 @gpt-term, @term\n' || $str$

                           Oh YEAH BABY

                        $str$
                        ),
                       create_versioned_string(
                        'gpt-git minder\n',
                        '⌜extend➤gpt-term⌝\n' ||
                        'Additional Instructions:\n' ||
                        '[None]\n' ||
                        '⌞extend⌟'
                        ),
                        null,
                        current_ts,
                        current_ts
                   );
/*
            insert into service (identifier, slug, type, details, prompt, minder, settings, created_on, modified_on)
            values (
                       generate_uid('Service'),
                       'gpt-git',
                       'tool',
                       create_versioned_string('gpt-git','Virtual Git Repo'),
                       create_versioned_string(
                        'gpt-git prompt',

                        '⌜tool|gpt-git|nlp0.5⌝' ||
                        'Virtual GIT Terminal' ||
                        '🙋 @gpt-git, @git' ||
                        $str$------
                        @gpt-git provides a virtual GIT tool allowing agents to save changes to a virtual git environment with out outputing all changes to screen.
                        This allows operators to view only diffs or whole files after changes are made as desired.
                        Usage:
                        @gpt-git adds a simulated interactive git command line tool to your simulated bash terminal with a few modifications:
                        - List repos: `@gpt-git repos`
                        - Change repo (and pwd in @term): `@gpt-git repo&lt;repo-name&gt;`
                        - Retrieve file chunks: `@gpt-git [repo] cat&lt;path&gt; --from=&lt;start-offset&gt; --to=&lt;end-position&gt; [--format=&lt;binary,hex,*text&gt;]`
                        - Generate Diff: `@gpt-git diff [&lt;revision&gt;] [&lt;path&gt;] [--format=&lt;*git|unified|patch&gt;]`
                        - Create/Update/Fetch gist `@gpt-git gist [command]&lt;gist-name&gt; [payload]
                        - Apply runtime extension/update `@gpt-git extend&lt;extension prompt&gt;`
                        Examples:
                        - `@gpt-git cat image.jpg --from=0X00 --to=0xFF --encoding=hex`
                        - `@gpt-git repo twitter-prototype &amp;&amp; tree`
                        - ```
                          @gpt-git gist create todo-list&lt;&lt;&lt;EOF
                           - [ ] party.
                           EOF;
                          ```
                        - `@gpt-git gist cat todo-list`
                        - `@gpt-git gist log todo-list`

                        Terminal Usage:
                        gpt-git may also be invoked from within your @gpt-term simulated terminal.
                        ````example
                        @gpt-term
                        ```bash
                        gpt-git repo demo-project
                        echo "Hello World" &gt;&gt; new.txt
                        gpt-git add new.txt
                        gpt-git commit -a -m "Adding sample file"
                        ```
                        ````

                        Response Format:
                        When called directly.
                        ```format
                       &lt;gpt-git&gt;
                        ``````bash
                        {@term output}
                        ``````
                       &lt;/gpt-git&gt;
                        ```
                        $str$ || '⌞tool⌟'
                        ),
                       create_versioned_string(
                        'gpt-git minder',
                        '⌜extend➤gpt-git⌝\n' ||
                        'Additional Instructions:\n' ||
                        '[None]\n' ||
                        '⌞extend⌟'
                        $str$),
                        nil,
                        current_ts,
                        current_ts
                   );
*/
END;
$block$ LANGUAGE plpgsql;
