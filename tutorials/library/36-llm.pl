%% LIBRARY 36 -- library(llm): a language model as a GOAL
%%
%%     ./cocolog run tutorials/library/36-llm.pl main
%%
%% TIER 2: `use_module(library(llm))', and it is on the library path as
%% `library/llm.pl'. CLAUSES ONLY -- there is no C half and no `.so' to
%% build, which is unusual enough in this family to be the first thing to
%% say about it. What it needs is one layer down: library(curl) for the
%% round trip (`sh modules/curl/build.sh', which needs libcurl),
%% library(json) for both ends of the wire, and library(process) only if
%% you ask for retries.
%%
%% WHY CLAUSES AND NOT A MODULE? Because a module here would be a second
%% binding to a socket, and there is one already. Strip the transport out
%% of "talk to a language model" and what is left is entirely a matter of
%% shape: which environment variable holds the key, what the request body
%% looks like, where in the answer the text sits. That is configuration
%% and grammar, which is what Prolog is for -- the same split library(der)
%% makes when it binds the arithmetic and writes the walk over it in two
%% clauses.
%%
%% AND IT IS WHY THIS LESSON CAN BE HONEST OFFLINE. Of the library's
%% thirty predicates (thirty-one name/arity pairs -- `llm_chat' has two),
%% four can reach the transport: `llm_chat/2,3', `llm_chat_full/4',
%% `llm_json/4' and `llm_post_retrying/6'. Every one of them refuses in
%% three ways before it gets there. Everything else
%% -- the option defaults, the message check, the whole request path, the
%% whole reply path, the retry policy, the backoff arithmetic -- is pure,
%% so this file proves it rather than describing it.
%%
%% THE SURFACE:
%%
%%     llm_chat(+Messages, -Reply)
%%     llm_chat(+Messages, +Options, -Reply)
%%         Messages is a list of msg(Role, Text); Role is one of system,
%%         user, assistant; Text is an ATOM. Reply is an atom.
%%
%%     llm_chat_full(+Messages, +Options, -Status, -Json)
%%     llm_json(+Messages, +Instruction, +Options, -Term)
%%     llm_last_usage(-Json)
%%     llm_provider(?Name, ?Endpoint, ?KeyVar)     dynamic; configuration
%%     llm_default_provider(?Name)                 dynamic
%%
%%     llm_store_chunked/3  llm_embed/3  llm_stream/3    NOT IMPLEMENTED
%%
%% NOTE THE STATUS IS NEVER HIDDEN, for library(curl)'s stated reason: a
%% client that quietly hands you the body of a 500 turns an outage into
%% corrupt data. `llm_chat_full/4' answers it; `llm_chat/2,3' throws on a
%% non-2xx, which is the same rule spelled as a refusal.
%%
%% THIS FILE MAKES NO NETWORK CALL AND NEEDS NO API KEY. That is 20-curl's
%% rule -- a tutorial the suite runs must not depend on somebody else's
%% server being up -- and here it is also a rule about MONEY. A call that
%% reached a provider from inside `make test' would be billed to whoever
%% ran it, so this lesson never calls `llm_chat/2,3' against a REGISTERED
%% provider on any path. The two goals below that do enter `llm_chat/3'
%% name a provider that does not exist, and `llm_chat_full/4' refuses them
%% at its FOURTH goal -- one before it looks for a key, and long before
%% `curl_post/6'.
%%
%% AND THIS FILE NEEDS NO libcurl, which is worth stating so nobody adds a
%% guard for it. `library(llm)' opens with `:- use_module(library(curl)).',
%% and a tier-2 library that is not on the path fails SILENTLY -- the
%% directive succeeds and the consult carries on (lib/library.cicili:344-347
%% answers -1, :450-452 maps anything but 0 to success). So `library(llm)'
%% loads with no curl module built, and every goal below is one of the
%% twenty-six predicates that never reach the transport. Only a call that
%% got as far as `curl_post/6' would notice, and there is none here. The
%% suite therefore needs no HAVE_CURL arm for this lesson.
%%
%% (20-curl.pl is a different case and worth knowing about: it calls
%% `curl_version/1' unguarded in its first line of `main', and
%% test/tutorials.sh has HAVE_TORCH, HAVE_CRYPTO and HAVE_RAY arms but no
%% HAVE_CURL. On a box without libcurl that lesson goes RED rather than
%% SKIPping, which inverts the suite's own rule that "not built here" and
%% "wrong" are different findings. Not this file's to fix.)
%%
%% AND library(llm) IS AN UNRUN SKELETON. Its own header says so: it was
%% written in a tree with no built cocolog, so nothing in it had ever been
%% executed. This file is the first thing that runs it. Every claim below
%% was read out of `library/llm.pl' rather than observed, which means a
%% red line here is news -- it is the library being wrong, not the lesson
%% drifting.

:- use_module(library(llm)).

%% library(json) is the ONE import this lesson adds, and it is the
%% tutorial's own dependency rather than a re-declaration of the
%% library's: the claims below hand `json_atom/2' a request body and
%% `json_parse/2' a handwritten response, which is how the wire is shown
%% with nothing on the wire.
:- use_module(library(json)).

main :-
    format("~n-- a library is not the knowledge base, even when it is all clauses~n"),
    %% 20-curl.pl teaches this about a `.so' and it is easy to read as a
    %% fact about C. It is not. `library(llm)' is pure Prolog, and its
    %% clauses are STILL invisible to `current_predicate/1': a `.pl'
    %% library is registered as a MODULE and consulted with the store
    %% MUTED, and a muted clause marks its predicate as the library's
    %% rather than the program's. `current_predicate/1' answers about
    %% YOUR program.
    ( current_predicate(llm_chat/3) -> CP = yes ; CP = no ),
    must('current_predicate(llm_chat/3) -- a library is not the store', CP, no),
    %% The contrast, in the same breath: this file's own helpers were
    %% consulted unmuted, so they are in the store and it says so.
    ( current_predicate(must/3) -> MP = yes ; MP = no ),
    must('current_predicate(must/3) -- but the program is', MP, yes),
    format("   So the availability probe is a CALL, never this question.~n"),

    format("~n-- a provider is configuration: three facts, in file order~n"),
    findall(N, llm_provider(N, _, _), Names),
    must('every provider', Names, [anthropic, openai]),
    llm_provider(anthropic, Endpoint, KeyVar),
    must('where anthropic posts', Endpoint, 'https://api.anthropic.com/v1/messages'),
    %% THE TABLE HOLDS THE NAME OF AN ENVIRONMENT VARIABLE, NEVER A KEY.
    %% That is the whole reason a lesson can print the provider table on a
    %% laptop with no secrets on it, and the same rule this repository
    %% states for signing keys: a key that becomes a term is on the heap,
    %% in the trail, in every copy anything makes of it, and in the
    %% knowledge base the moment something asserts it.
    must('and which variable holds its key', KeyVar, 'ANTHROPIC_API_KEY'),
    llm_provider(openai, E2, K2),
    must('where openai posts', E2, 'https://api.openai.com/v1/chat/completions'),
    must('and its variable', K2, 'OPENAI_API_KEY'),
    llm_default_provider(Default),
    must('the default provider', Default, anthropic),
    %% Each provider names its own default model. This lesson PRINTS
    %% those and pins neither: a model name changes for reasons outside
    %% this repository, and a tutorial that went red because a vendor
    %% renamed something would be a tutorial nobody trusts. Everything
    %% below passes `model(demo)' explicitly for the same reason.
    llm_model_default(anthropic, ModelA),
    show('anthropic''s default model (not pinned)', ModelA),
    llm_model_default(openai, ModelO),
    show('openai''s default model (not pinned)', ModelO),
    %% Both are `:- dynamic', so a program adds a fourth provider with
    %% `assertz/1' and edits nothing. This lesson does not, because it
    %% would rather stay readable from the top down.

    format("~n-- the options, and the ONE default that matters~n"),
    %% `llm_opt/3' is the whole option table in one predicate, which is
    %% what lets a lesson check the defaults without building a request.
    llm_opt([], timeout, T0),
    llm_opt([timeout(5)], timeout, T1),
    %% THE TIMEOUT DEFAULT IS 600 AND NOT CURL'S 30. `curl_request/5'
    %% defaults `timeout' to 30, which is a fine number for fetching a
    %% page and the wrong one for a generation: a model asked for four
    %% thousand tokens routinely takes longer than half a minute, and what
    %% the caller sees when it does is a TRANSPORT ERROR -- not a slow
    %% answer, not a truncated one, but the library reporting that the
    %% network failed when nothing failed. Overriding it here is not a
    %% preference. It is the difference between a library that works and
    %% one that works on short prompts.
    must('the timeout default -- SIX HUNDRED, not curl''s 30', T0, 600),
    must('and the caller still overrides it', T1, 5),
    llm_opt([], max_tokens, MT),
    must('max_tokens', MT, 4096),
    llm_opt([], max_size, MS),
    %% `max_size' is curl's own ceiling, and it is here because there is
    %% NO STREAMING: a response arrives whole or not at all, so the cap
    %% has to be a refusal rather than a surprise.
    must('max_size (16 MB, curl''s own)', MS, 16777216),
    llm_opt([], retries, R0),
    must('retries -- none unless you ask', R0, 0),
    %% AND ONE OPTION THAT WAS DOCUMENTED AND NOT IMPLEMENTED until this
    %% lesson was written. `system(Text)' is in the library's header block
    %% and had no `llm_opt/3' clause and no reader: a caller who set it got
    %% a model with no system prompt and nothing to say why. Writing a
    %% tutorial is what found it, which is the whole argument for the
    %% convention that a library gets one in the same commit.
    llm_opt([], system, SysNone),
    must('no system prompt unless you ask', SysNone, ''),
    llm_opt([system('Be terse.')], system, SysSet),
    must('and it is read now', SysSet, 'Be terse.'),
    %% What it does is prepend a message, so it is exactly the shorthand
    %% it claimed to be -- checked here through the body builder, because
    %% that is where the difference shows.
    llm_with_system([system('Be terse.')], [msg(user, 'Hello')], Expanded),
    must('system(Text) prepends msg(system, Text)', Expanded,
         [msg(system, 'Be terse.'), msg(user, 'Hello')]),
    llm_with_system([], [msg(user, 'Hello')], Unchanged),
    must('and changes nothing when absent', Unchanged, [msg(user, 'Hello')]),
    llm_opt([], provider, P0),
    must('provider falls back to llm_default_provider/1', P0, anthropic),
    llm_opt([provider(openai)], provider, P1),
    must('or comes out of the options', P1, openai),
    %% The model default is derived THROUGH the provider, and an unknown
    %% provider answers the empty atom rather than failing -- so the
    %% refusal comes from the provider lookup, with the name in it, and
    %% not from a body builder that could not find a model.
    llm_opt([provider(bogus)], model, MB),
    must('an unknown provider has no model, and says so quietly', MB, ''),

    format("~n-- THE REQUEST BODY IS A TERM, and you can look at it~n"),
    %% This is the strongest thing the lesson can show, and it needs no
    %% socket at all: `llm_request_body/4' builds a `json/1' term and
    %% `json_atom/2' turns it into the exact bytes that would go out. The
    %% same message list, through two providers, is two different
    %% documents -- which is the argument for a clause per provider,
    %% stated as two atoms you can read.
    Msgs = [msg(system, 'Be terse.'), msg(user, 'Hello')],
    llm_request_body(anthropic, Msgs, [model(demo), max_tokens(64)], BodyA),
    json_atom(BodyA, WireA),
    show('the anthropic body', WireA),
    must('anthropic hoists the system prompt OUT of the messages',
         WireA,
         '{"system":"Be terse.","model":"demo","max_tokens":64,"messages":[{"role":"user","content":"Hello"}]}'),
    llm_request_body(openai, Msgs, [model(demo), max_tokens(64)], BodyO),
    json_atom(BodyO, WireO),
    show('the openai body', WireO),
    must('openai leaves it IN as a role, and renames the cap',
         WireO,
         '{"model":"demo","max_completion_tokens":64,"messages":[{"role":"system","content":"Be terse."},{"role":"user","content":"Hello"}]}'),
    format("   Two providers, one message list, two documents. Neither is~n"),
    format("   a flag on the other, which is why there is no third clause~n"),
    format("   with an if-then-else in it.~n"),
    %% No system message means no `system' key at all -- not an empty one,
    %% which a provider would read as an instruction to be nothing.
    llm_request_body(anthropic, [msg(user, 'Hello')], [model(demo), max_tokens(64)], BodyN),
    json_atom(BodyN, WireN),
    must('no system message means no system KEY',
         WireN,
         '{"model":"demo","max_tokens":64,"messages":[{"role":"user","content":"Hello"}]}'),
    %% And temperature is OMITTED unless you ask, so what applies is the
    %% provider's own default rather than one this library invented.
    llm_request_body(anthropic, [msg(user, 'Hello')],
                     [model(demo), max_tokens(64), temperature(0)], BodyT),
    json_atom(BodyT, WireT),
    must('an asked-for temperature, and only then',
         WireT,
         '{"temperature":0,"model":"demo","max_tokens":64,"messages":[{"role":"user","content":"Hello"}]}'),
    %% ADDING A PROVIDER IS TWO FACTS AND THREE CLAUSES: `llm_provider/3'
    %% and `llm_model_default/2', then `llm_request_body/4',
    %% `llm_reply_of/3' and `llm_headers/3'. Miss any of the three and the
    %% call fails at that step rather than at the one you were thinking
    %% about, so here is the facts-only half, on purpose:
    assertz(llm_provider(demo_provider, 'https://example.invalid/v1', 'NO_SUCH_KEY_36')),
    assertz(llm_model_default(demo_provider, demo)),
    ( llm_provider(demo_provider, _, _) -> Reg = yes ; Reg = no ),
    must('the facts alone register it', Reg, yes),
    ( llm_request_body(demo_provider, [msg(user, 'Hi')], [model(demo)], _)
    -> BodyForNew = built ; BodyForNew = none ),
    must('but with no llm_request_body/4 clause there is no body', BodyForNew, none),
    %% Left asserted for the rest of the file: `llm_provider/3' is dynamic
    %% precisely so a program can do this, and nothing below asks for a
    %% complete provider list again.

    format("~n-- and the pieces the body is built from~n"),
    llm_split_system([msg(system, 'Be terse.'), msg(user, 'Hello'),
                      msg(assistant, 'Hi')], Sys, Rest),
    must('the system prompt comes out', Sys, 'Be terse.'),
    must('and the rest keeps its order', Rest, [msg(user, 'Hello'), msg(assistant, 'Hi')]),
    llm_split_system([msg(user, 'Hello')], Sys0, _),
    %% The EMPTY ATOM is the flag `llm_request_body/4' tests, which is why
    %% "no system message" and "an empty system message" are the same
    %% thing here and both mean no key.
    must('no system message answers the empty atom', Sys0, ''),
    %% Several system messages are joined with a blank line -- compared
    %% through codes, because an expected value full of escaped
    %% backslashes teaches nothing.
    llm_join_blank(['A', 'B'], Joined),
    atom_codes(Joined, JoinedCodes),
    must('two system prompts, one blank line', JoinedCodes, [65, 10, 10, 66]),
    llm_wire_messages(anthropic, [msg(user, 'Hi')], Wire),
    must('a msg/2 becomes a json/1 object', Wire, [json([role-user, content-'Hi'])]),

    format("~n-- a malformed message is refused BEFORE anything happens~n"),
    %% `llm_check_messages/1' is the SECOND goal in `llm_chat_full/4' --
    %% only `llm_with_system/3' runs before it, and that one cannot fail --
    %% on purpose: posting a malformed message means the provider rejects it
    %% with a sentence about JSON, three network seconds and one billing
    %% event later, and that sentence never names the term you got wrong.
    catch(llm_check_messages(not_a_list), error(llm_error(W1, T1b), C1), true),
    must('a message list that is not a list', W1, bad_message),
    must('  the ball carries the term', T1b, not_a_list),
    must('  and the context is llm_chat/3', C1, llm_chat/3),
    catch(llm_check_messages([msg(tool, 'x')]), error(llm_error(W2, T2), _), true),
    must('a role nobody has heard of', W2, bad_message),
    must('  named in the ball', T2, msg(tool, x)),
    %% THE BEST LESSON IN THIS FILE, and it is free. `double_quotes' is
    %% `codes' here and cannot be changed -- there is no string type -- so
    %% "Hello" is NOT text, it is a list of five integers. A library that
    %% guessed would put `[72,101,108,108,111]' in a JSON document as an
    %% array of numbers and the model would answer a question nobody
    %% asked. `llm_check_messages/1' catches it, and the ball shows you
    %% exactly what you wrote.
    catch(llm_check_messages([msg(user, "Hello")]), error(llm_error(W3, T3), _), true),
    must('a message written with DOUBLE quotes', W3, bad_message),
    must('  is a code list, and the ball proves it',
         T3, msg(user, [72, 101, 108, 108, 111])),
    format("   A message written with double quotes is five integers.~n"),
    format("   Write `msg(user, 'Hello')'. Every text this library takes~n"),
    format("   and every reply it answers is an ATOM.~n"),

    format("~n-- the reply path, from a handwritten response~n"),
    %% `llm_reply_of/3' is the other clause per provider, and it parses
    %% with no I/O -- so a response literal exercises the REAL path,
    %% `json_parse/2' and all, and not a simplified one.
    json_parse('{"id":"msg_01","type":"message","role":"assistant","content":[{"type":"text","text":"Hello there."}],"usage":{"input_tokens":12,"output_tokens":7}}', JA),
    llm_reply_of(anthropic, JA, ReplyA),
    must('anthropic keeps the text in a content BLOCK', ReplyA, 'Hello there.'),
    json_parse('{"choices":[{"index":0,"message":{"role":"assistant","content":"Hello there."}}]}', JO),
    llm_reply_of(openai, JO, ReplyO),
    must('openai keeps it under choices, message, content', ReplyO, 'Hello there.'),
    %% The shapes are NOT interchangeable, and that is the point of two
    %% clauses rather than one that looks in both places: a library that
    %% searched everywhere would answer confidently from a response it did
    %% not understand.
    ( llm_reply_of(openai, JA, _) -> X1 = found ; X1 = no ),
    must('anthropic''s answer through openai''s clause', X1, no),
    %% `llm_first_text/2' walks PAST a json/1 block whose type is not
    %% text, which is why it is a predicate of its own: a thinking block
    %% arrives first and is not the answer.
    llm_first_text([json([type-thinking, thinking-'hmm']),
                    json([type-text, text-'Answer.'])], ReplyT),
    must('it walks past a block that is not text', ReplyT, 'Answer.'),
    %% AND IT FAILS RATHER THAN THROWING when the text is not there. The
    %% caller turns that failure into llm_error(no_reply, Json), carrying
    %% the WHOLE response -- so the reader sees what arrived instead,
    %% which is the only useful thing to say about a shape you did not
    %% expect.
    ( llm_reply_of(anthropic, json([content-[]]), _) -> X2 = found ; X2 = no ),
    must('an empty content list FAILS, for the caller to name', X2, no),

    format("~n-- a missing key is a REFUSAL, not a hang and not an empty answer~n"),
    %% `getenv/2' FAILS for a name that is not set -- it does not throw --
    %% and `llm_key/2' is the if-then-else that turns that ordinary `no'
    %% into a refusal naming the variable. The `unsetenv/1' is what makes
    %% this claim true on a developer's box as well as on a clean one.
    unsetenv('COCOLOG_LESSON36_KEY'),
    ( getenv('COCOLOG_LESSON36_KEY', _) -> G0 = set ; G0 = unset ),
    must('getenv/2 on an unset name FAILS', G0, unset),
    catch(llm_key('COCOLOG_LESSON36_KEY', _), error(llm_error(W4, V4), C4), true),
    must('and llm_key/2 refuses by name', W4, no_key),
    must('  naming the VARIABLE, never a key', V4, 'COCOLOG_LESSON36_KEY'),
    must('  with llm_chat/3 as the context', C4, llm_chat/3),
    %% AN EMPTY KEY IS TREATED AS ABSENT, which is not pedantry: a shell
    %% that exports a variable it never set produces exactly this, and
    %% posting an empty Authorization header buys a 401 instead of a
    %% sentence.
    setenv('COCOLOG_LESSON36_KEY', ''),
    getenv('COCOLOG_LESSON36_KEY', Empty),
    must('an exported-but-empty variable is still there', Empty, ''),
    catch(llm_key('COCOLOG_LESSON36_KEY', _), error(llm_error(W5, _), _), true),
    must('and is refused the same way', W5, no_key),
    %% The read path, once, so it is not mysterious: one `getenv/2', into
    %% a header, and out of scope. It is never asserted, never answered to
    %% a caller, never logged.
    setenv('COCOLOG_LESSON36_KEY', 'not-a-real-key'),
    llm_key('COCOLOG_LESSON36_KEY', ReadBack),
    must('a key that IS there is simply read', ReadBack, 'not-a-real-key'),
    unsetenv('COCOLOG_LESSON36_KEY'),
    %% The one place a key becomes a term at all is the header list, and
    %% it lives exactly as long as the call does. One option per header,
    %% because `curl_headers/2' collects them with a findall.
    llm_headers(anthropic, 'KEY', HA),
    must('anthropic''s headers', HA, [header('x-api-key: KEY'),
                                     header('anthropic-version: 2023-06-01')]),
    llm_headers(openai, 'KEY', HO),
    must('openai''s', HO, [header('Authorization: Bearer KEY')]),
    %% AND NO Content-Type IN EITHER, which is not an omission. `curl_post/6'
    %% builds one from its Type argument and puts it at the FRONT of the
    %% option list -- `atom_concat('Content-Type: ', Type, H)', then
    %% `[body(Data), header(H)|Opts]' (modules/curl/curl.cicili:76) -- so a
    %% content-type here would be a SECOND one on every request. Writing
    %% this lesson is what found the first version doing exactly that.
    format("   `curl_post/6' supplies Content-Type itself, so neither~n"),
    format("   clause repeats it -- two would be one too many.~n"),

    format("~n-- the refusals come in ORDER, and all of them beat the socket~n"),
    %% This is the property that makes the lesson safe, and it is
    %% checkable: `llm_chat_full/4' is the system-prompt expansion, the
    %% message check, the provider lookup, then the key, and only THEN the
    %% body, the headers and `curl_post/6'. A provider nobody registered
    %% cannot get past the third of those, so the two goals below enter
    %% `llm_chat/3' and come straight back out with no key read and nothing
    %% dialled.
    catch(llm_chat([msg(user, 'Hello')], [provider(bogus)], _),
          error(llm_error(W6, P6), C6), true),
    must('an unknown provider', W6, unknown_provider),
    must('  named in the ball', P6, bogus),
    must('  context', C6, llm_chat/3),
    %% And a bad message beats an unknown provider, because the check is
    %% the first goal in the body. Same call, two things wrong, and the
    %% one you hear about is the earlier one.
    catch(llm_chat([msg(user, "Hello")], [provider(bogus)], _),
          error(llm_error(W7, _), _), true),
    must('a bad message beats an unknown provider', W7, bad_message),
    format("   So THREE of the five refusals -- bad_message,~n"),
    format("   unknown_provider and no_key -- are reachable with the~n"),
    format("   network unplugged, and so is the ORDER they come in.~n"),
    format("   The other two, http_status and no_reply, need a server to~n"),
    format("   have answered, so this lesson does not reach them. What it~n"),
    format("   checks instead are their INGREDIENTS: llm_status_ok/1~n"),
    format("   above, and llm_reply_of/3 against a response typed out by~n"),
    format("   hand.~n"),

    format("~n-- the retry policy, which is arithmetic and a rule~n"),
    %% A 400 is a bad request and sending it again is a bad request again:
    %% retrying it wastes the caller's quota and hides the bug. So only a
    %% 429 and the 5xx family are retryable, and the rule is two clauses
    %% you can read rather than a flag in a config.
    ( llm_retryable(429) -> Y1 = yes ; Y1 = no ),
    must('429 is worth sending again', Y1, yes),
    ( llm_retryable(503) -> Y2 = yes ; Y2 = no ),
    must('so is a 503', Y2, yes),
    ( llm_retryable(400) -> Y3 = yes ; Y3 = no ),
    must('a 400 is NOT -- it will be wrong again', Y3, no),
    ( llm_status_ok(200) -> Y4 = yes ; Y4 = no ),
    must('and 2xx is what counts as an answer', Y4, yes),
    ( llm_status_ok(300) -> Y5 = yes ; Y5 = no ),
    must('a 300 does not', Y5, no),
    %% `llm_status_ok/1' wants an INTEGER, which is what `curl_post/6'
    %% answers. The atom '200' is not a status and is not treated as one.
    ( llm_status_ok('200') -> Y6 = yes ; Y6 = no ),
    must('nor does the ATOM ''200''', Y6, no),
    %% The backoff is PURE -- it computes a delay and sleeps nothing, so a
    %% lesson can check the table with no wall clock in it. N counts DOWN
    %% from the retry budget, so read the table rather than the sentence:
    %% with retries(4) the first wait is a second, with retries(3) it is
    %% two, and beyond four it is clamped rather than instant.
    llm_backoff_ms(4, B4), llm_backoff_ms(3, B3),
    llm_backoff_ms(2, B2), llm_backoff_ms(1, B1), llm_backoff_ms(5, B5),
    must('backoff at N=4', B4, 1000),
    must('backoff at N=3', B3, 2000),
    must('backoff at N=2', B2, 4000),
    must('backoff at N=1', B1, 8000),
    must('and clamped above the budget', B5, 1000),
    format("   Deterministic on purpose: two runs of the same failure~n"),
    format("   take the same time. Jitter would be kinder to a server~n"),
    format("   under a thundering herd and worse for a test, and this~n"),
    format("   family pins its timings.~n"),

    format("~n-- what the last call cost, which is the PROVIDER'S number~n"),
    %% `llm_last_usage/1' FAILS before anything has run: it is a global,
    %% and reading one nothing has set raises, which the library catches
    %% and turns into an honest `no'.
    ( llm_last_usage(_) -> U0 = yes ; U0 = no ),
    must('nothing has run yet, so there is no usage', U0, no),
    %% `llm_remember_usage/2' is what fills it, and it takes the response
    %% term -- so a handwritten one demonstrates the whole path.
    llm_remember_usage(anthropic, json([usage-json([input_tokens-12, output_tokens-7])])),
    llm_last_usage(U1),
    must('and then it is what the provider said', U1,
         json([input_tokens-12, output_tokens-7])),
    %% A response with no usage in it LEAVES THE LAST VALUE ALONE rather
    %% than clearing it, which is the difference between "this call did
    %% not report" and "the last call cost nothing".
    llm_remember_usage(anthropic, json([content-[]])),
    llm_last_usage(U2),
    must('a response without usage leaves it alone', U2,
         json([input_tokens-12, output_tokens-7])),
    format("   NO TOKEN COUNTING. There is no tokenizer anywhere in this~n"),
    format("   tree, so this is the provider's arithmetic and not ours --~n"),
    format("   which is the only honest number available. A library that~n"),
    format("   guessed a count would be wrong in the direction of the~n"),
    format("   bill.~n"),

    format("~n-- three predicates that THROW rather than pretend~n"),
    %% A silent failure here would look exactly like "the model had
    %% nothing to say", which is the worst possible way to learn that a
    %% feature does not exist. So each of the three names itself.
    catch(llm_store_chunked(kb, key, text), error(llm_error(N1, S1), _), true),
    must('llm_store_chunked/3', N1, not_implemented),
    must('  and it names itself', S1, llm_store_chunked/3),
    catch(llm_embed([hello], [], _), error(llm_error(N2, S2), _), true),
    must('llm_embed/3', N2, not_implemented),
    must('  likewise', S2, llm_embed/3),
    catch(llm_stream([msg(user, 'hi')], [], _), error(llm_error(N3, S3), _), true),
    must('llm_stream/3', N3, not_implemented),
    must('  and so does this one', S3, llm_stream/3),

    format("~n-- WHAT IT GENUINELY CANNOT DO~n"),
    format("~n"),
    format("   NO STREAMING, and it is not a clause away. modules/curl~n"),
    format("   names the multi interface as absent and cicili's binding~n"),
    format("   does not cover it either, so a response arrives whole or~n"),
    format("   not at all. `llm_stream/3' is a C-half change in~n"),
    format("   modules/curl, which is why it throws instead of looping.~n"),
    format("~n"),
    format("   NO TOKENIZER, so no client-side budget: you cannot ask~n"),
    format("   this library whether a prompt will fit before sending it.~n"),
    format("~n"),
    format("   NO EMBEDDINGS YET. The call is just another endpoint and~n"),
    format("   the storage exists -- cocolog::tensors has a vector~n"),
    format("   column -- but there is no distance operator in any of the~n"),
    format("   Parsi objects, so the search is a matmul in torch or an~n"),
    format("   O(N) walk in Prolog, and that choice belongs to whoever~n"),
    format("   knows how many vectors there are.~n"),
    format("~n"),
    format("   ONE CALL AT A TIME PER PROCESS. libcurl is reached~n"),
    format("   through one easy handle per call and nothing here is~n"),
    format("   concurrent; run_isolated/2 from library(thread) is how~n"),
    format("   two calls happen at once -- and REGISTER THE MODULES~n"),
    format("   BEFORE YOU SPAWN. A thread does NOT do its own~n"),
    format("   use_module: it gets a fresh store filled from the~n"),
    format("   PROCESS-WIDE registry, so a library imported after the~n"),
    format("   spawn is not there. run_isolated/2 also returns NO~n"),
    format("   BINDINGS -- the goal is written to text, re-read on a new~n"),
    format("   machine, and only true/false/error comes back -- so an~n"),
    format("   answer travels by channel or by the database.~n"),
    format("~n"),
    format("   A REPLY DOES NOT FIT IN A CLAUSE. The body column is a~n"),
    format("   Text and a row must fit an 8192-byte page: 8000 stores~n"),
    format("   and 8192 is `allocation overflow'. Anything longer is~n"),
    format("   chunked, the way machine state chunks at 4000.~n"),

    format("~n-- AND WHAT THE CALLS LOOK LIKE, once a key is exported~n"),
    format("~n"),
    format("     $ export ANTHROPIC_API_KEY=sk-...~n"),
    format("~n"),
    format("     ?- llm_chat([msg(user, 'Name three primes.')], Reply).~n"),
    format("~n"),
    format("     ?- llm_chat([ msg(system, 'Answer in one word.'),~n"),
    format("                   msg(user, 'Capital of France?') ],~n"),
    format("                 [ provider(openai), max_tokens(16),~n"),
    format("                   temperature(0), retries(2) ],~n"),
    format("                 Reply).~n"),
    format("~n"),
    format("     ?- llm_chat_full(Messages, [], Status, Json).~n"),
    format("~n"),
    format("     ?- llm_json([msg(user, 'Two European capitals.')],~n"),
    format("                 'An array of objects with name and country.',~n"),
    format("                 [], Term).~n"),
    format("~n"),
    format("   `llm_json/4' is the one worth reaching for from a program:~n"),
    format("   it appends an instruction to answer with JSON and nothing~n"),
    format("   else, then parses the reply -- so what comes back is a~n"),
    format("   TERM, and a reply that was prose throws with the prose in~n"),
    format("   the ball rather than failing. A model's answer becomes a~n"),
    format("   term you can unify against, which is the whole reason this~n"),
    format("   library is a goal and not a shell script.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).