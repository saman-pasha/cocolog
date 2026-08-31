%% cocolog -- library(llm): a language model as a GOAL.
%%
%%     :- use_module(library(llm)).
%%
%% TIER 2, and clauses only -- there is no C half and no `.so' to build.
%% Everything it needs already exists one layer down:
%%
%%     the request     json_codes/2        library(json)
%%     the round trip  curl_post/6         library(curl)   [needs libcurl]
%%     the response    json_parse/2        library(json)
%%     the key         getenv/2            compiled in
%%     backoff         proc_sleep/1        library(process) [only if retries]
%%
%% SO THE ONLY DEPENDENCY IT ADDS IS THE ONE library(curl) ALREADY HAS.
%% That is the whole argument for it being clauses: a module here would be
%% a second binding to a socket, and there is one already.
%%
%% WHERE IT LIVES. `library/llm.pl', beside the other nine, so
%% `library(llm)' finds it with no path set at all: `lb_find' probes each
%% $COCOLOG_LIBRARY entry, then `library', then <exedir>/library, for
%% NAME.so before NAME.pl (lib/library.cicili:193-237, lb_probe at :84-90).
%% The design notes live in `library/llm/' -- a directory, not a library:
%% nothing probes it, and a `.pl' put there would need the `library(Dir/Name)'
%% spelling instead (:326-328).
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     llm_chat(+Messages, -Reply)
%%     llm_chat(+Messages, +Options, -Reply)
%%         Messages is a list of msg(Role, Text); Role is one of system,
%%         user, assistant; Text is an atom. Reply is an ATOM.
%%
%%     llm_chat_full(+Messages, +Options, -Status, -Json)
%%         the HTTP status and the whole parsed response.
%%
%%     llm_json(+Messages, +Instruction, +Options, -Term)
%%         ask for JSON back and parse it. Throws rather than answering
%%         something shaped differently.
%%
%%     llm_provider(?Name, ?Endpoint, ?KeyVar)     dynamic; configuration
%%     llm_default_provider(?Name)                 dynamic
%%     llm_last_usage(-Json)                       what the last call cost
%%
%% NO ARITY HIDES THE STATUS on llm_chat_full/4, for library(curl)'s
%% stated reason: a client that quietly hands you the body of a 500 turns
%% an outage into corrupt data. `llm_chat/2,3' does check it -- it throws
%% on a non-2xx -- which is the same rule, spelled as a refusal.
%%
%% ---- OPTIONS ----------------------------------------------------------
%%
%%     provider(P)     default: llm_default_provider/1
%%     model(M)        default: the provider's
%%     timeout(S)      default 600  -- SEE BELOW, this one matters
%%     max_tokens(N)   default 4096
%%     temperature(T)  default: the provider's (omitted from the body)
%%     system(Text)    convenience; prepends msg(system, Text)
%%     retries(N)      default 0
%%     max_size(B)     default 16777216 (curl's own)
%%
%% THE TIMEOUT DEFAULT IS 600 AND NOT CURL'S 30, and that is the single
%% most important line in this file. `curl_request/5' defaults
%% `timeout' to 30 (modules/curl/curl.cicili:82); a generation of any
%% length exceeds that routinely, and what the caller then sees is a
%% transport error rather than an answer. Overriding it here is not a
%% preference, it is the difference between a library that works and one
%% that works on short prompts.
%%
%% ---- WHAT IT REFUSES TO GUESS -----------------------------------------
%%
%% It THROWS, and the ball names the term, which is this repository's
%% discipline in library(json), library(xml) and library(html) alike:
%%
%%     error(llm_error(no_key, KeyVar),        llm_chat/3)
%%     error(llm_error(http_status, Status),   llm_chat/3)
%%     error(llm_error(no_reply, Json),        llm_chat/3)
%%     error(llm_error(unknown_provider, P),   llm_chat/3)
%%     error(llm_error(bad_message, M),        llm_chat/3)
%%
%% A refusal a reader cannot tell from an empty answer is not a refusal,
%% and "the model said nothing" and "the endpoint 500'd" are different
%% findings.
%%
%% ---- HONEST LIMITS ----------------------------------------------------
%%
%% NO STREAMING. `modules/curl' names the multi interface and streaming
%% as absent, so a response arrives whole or not at all. `max_size(B)'
%% is here so that stays a refusal rather than a surprise.
%%
%% NO TOKEN COUNTING. There is no tokenizer anywhere in this tree.
%% `llm_last_usage/1' reports what the PROVIDER said it cost, which is
%% the only honest number available.
%%
%% ONE CALL PER PROCESS AT A TIME. libcurl is reached through one easy
%% handle per call and nothing here is concurrent; `run_isolated/2' from
%% library(thread) is how two calls happen at once, and each thread needs
%% its own `use_module' before it starts.
%%
%% NO GARBAGE COLLECTION (STATUS.md). A reply arrives as codes -- one
%% heap cell per byte -- and the heap only grows within a solution. A
%% long conversation held in one deterministic goal will grow until that
%% goal ends. Keep a turn short, or hold the transcript in the knowledge
%% base rather than on the heap.
%%
%% A REPLY DOES NOT FIT IN A CLAUSE. The `body' column is a Text and a
%% row must fit an 8192-byte page (parsi/01-schema.parsi:23-30): 8000
%% stores, 8192 is `allocation overflow'. Anything longer is chunked, the
%% way machine state chunks at 4000 -- `llm_store_chunked/3' below is the
%% shape, not yet the implementation.
%%
%% THE KEY IS READ AND NEVER HELD. `getenv/2' at the call, into the
%% header, and not asserted, not returned, not logged. A key that becomes
%% a term is on the heap, in the trail, in every copy anything makes of
%% that term, and in the knowledge base the moment something asserts it.
%% This repository states the rule for signing keys and it is the same
%% rule.
%%
%% ---- STATUS -----------------------------------------------------------
%%
%% THIS IS A SKELETON. Nothing in it has been RUN: there is no built
%% cocolog in the tree it was written in. Every predicate it calls was
%% checked against source, and the three marked `NOT IMPLEMENTED' throw
%% rather than pretending. Before trusting it, check in this order:
%%   1. that `curl_post/6' really is +Url,+Type,+Data,+Opts,-Status,-Body
%%      (modules/curl/curl.cicili:75-76 says so)
%%   2. that a `json([k-v])' with an atom value writes `"k":"v"'
%%   3. that the response shape below matches the provider you point at
%%
%% A NEW LIBRARY GETS A TUTORIAL IN THE SAME COMMIT -- the convention in
%% tutorials/README.md. `tutorials/library/36-llm.pl' is the next free
%% number, and it must make NO NETWORK CALL, the way 20-curl.pl does not:
%% a tutorial the suite runs cannot depend on somebody else's server.

:- use_module(library(curl)).
:- use_module(library(json)).

%% library(process) is wanted ONLY for retries(N) with N > 0, and a
%% missing one costs this file nothing: a library that is NOT FOUND is
%% SILENT. coco_library_load answers -1 for it (lib/library.cicili:344-347)
%% and lb_directive_hook maps anything but 0 to success (:450-452), so
%% nothing is printed and the consult carries on. The warning at
%% lib/kb.cicili:730 is for the OTHER case -- found, and would not load.
%% Either way the absence surfaces at llm_sleep/1 as an existence_error
%% naming proc_sleep/1, and every other path here still works.
:- use_module(library(process)).

:- dynamic llm_provider/3.
:- dynamic llm_default_provider/1.

%% ---- providers, as configuration rather than as code -------------------
%%
%% A provider is three facts and two clauses: where to post, which
%% environment variable holds the key, what the body looks like and where
%% the reply sits in the answer. Adding one is adding those, not editing
%% anything below.

llm_provider(anthropic, 'https://api.anthropic.com/v1/messages', 'ANTHROPIC_API_KEY').
llm_provider(openai,    'https://api.openai.com/v1/chat/completions', 'OPENAI_API_KEY').

llm_default_provider(anthropic).

llm_model_default(anthropic, 'claude-sonnet-4-5').
llm_model_default(openai,    'gpt-4o').

%% ---- the entry points --------------------------------------------------

%% llm_chat(+Messages, -Reply) is det.
llm_chat(Messages, Reply) :-
    llm_chat(Messages, [], Reply).

%% llm_chat(+Messages, +Options, -Reply) is det.
%% Throws on a non-2xx status or a response with no reply in it.
llm_chat(Messages, Options, Reply) :-
    llm_chat_full(Messages, Options, Status, Json),
    (   llm_status_ok(Status)
    ->  true
    ;   throw(error(llm_error(http_status, Status), llm_chat/3))
    ),
    llm_opt(Options, provider, Provider),
    (   llm_reply_of(Provider, Json, Reply)
    ->  true
    ;   throw(error(llm_error(no_reply, Json), llm_chat/3))
    ).

%% llm_chat_full(+Messages, +Options, -Status, -Json) is det.
%% The status is answered, never checked, and never hidden.
llm_chat_full(Messages, Options, Status, Json) :-
    llm_check_messages(Messages),
    llm_opt(Options, provider, Provider),
    (   llm_provider(Provider, Endpoint, KeyVar)
    ->  true
    ;   throw(error(llm_error(unknown_provider, Provider), llm_chat/3))
    ),
    llm_key(KeyVar, Key),
    llm_request_body(Provider, Messages, Options, Body),
    json_codes(Body, BodyCodes),
    llm_headers(Provider, Key, Headers),
    llm_opt(Options, timeout, Timeout),
    llm_opt(Options, max_size, MaxSize),
    llm_opt(Options, retries, Retries),
    append(Headers, [timeout(Timeout), max_size(MaxSize)], CurlOpts),
    llm_post_retrying(Retries, Endpoint, BodyCodes, CurlOpts, Status, RespCodes),
    json_parse(RespCodes, Json),
    llm_remember_usage(Provider, Json).

%% llm_json(+Messages, +Instruction, +Options, -Term) is det.
%% Instruction is appended as a system message telling the model to answer
%% with JSON and nothing else. The reply is parsed; a reply that is not
%% JSON throws with the text that was there instead, rather than failing.
llm_json(Messages, Instruction, Options, Term) :-
    atom_concat('Answer with JSON only, no prose and no code fence. ',
                Instruction, Sys),
    append(Messages, [msg(system, Sys)], Messages1),
    llm_chat(Messages1, Options, Reply),
    catch(json_parse(Reply, Term),
          error(syntax_error(What), _),
          throw(error(llm_error(not_json, What-Reply), llm_json/4))).

%% llm_last_usage(-Json) is semidet.
%% What the provider said the last call cost. A global rather than a
%% clause: it is one value that is overwritten, not a relation, and an
%% assert would leave a row per call in the knowledge base.
llm_last_usage(Json) :-
    catch(nb_getval(llm_usage, Json), _, fail).

%% ---- the two per-provider clauses --------------------------------------

%% llm_request_body(+Provider, +Messages, +Options, -JsonTerm)
%%
%% Anthropic takes the system prompt OUT of the message list and beside
%% it; OpenAI leaves it in as a role. That difference is exactly why this
%% is a clause per provider and not one body with flags in it.
llm_request_body(anthropic, Messages, Options, json(Pairs)) :-
    llm_split_system(Messages, System, Rest),
    llm_opt(Options, model, Model),
    llm_opt(Options, max_tokens, MaxTokens),
    llm_wire_messages(anthropic, Rest, Wire),
    Base = [model-Model, max_tokens-MaxTokens, messages-Wire],
    (   System == ''
    ->  Pairs0 = Base
    ;   Pairs0 = [system-System|Base]
    ),
    llm_add_temperature(Options, Pairs0, Pairs).

llm_request_body(openai, Messages, Options, json(Pairs)) :-
    llm_opt(Options, model, Model),
    llm_opt(Options, max_tokens, MaxTokens),
    llm_wire_messages(openai, Messages, Wire),
    Pairs0 = [model-Model, max_completion_tokens-MaxTokens, messages-Wire],
    llm_add_temperature(Options, Pairs0, Pairs).

%% llm_reply_of(+Provider, +Json, -Reply)
%%
%% Where the text sits in the answer. Fails rather than throws -- the
%% caller turns the failure into llm_error(no_reply, Json), which carries
%% the whole response so the reader can see what arrived instead.
llm_reply_of(anthropic, json(Pairs), Reply) :-
    memberchk(content-Content, Pairs),
    llm_first_text(Content, Reply).

llm_reply_of(openai, json(Pairs), Reply) :-
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-json(Msg), Choice),
    memberchk(content-Reply, Msg),
    atom(Reply).

llm_first_text([json(Block)|Rest], Reply) :-
    (   memberchk(type-text, Block),
        memberchk(text-Reply, Block),
        atom(Reply)
    ->  true
    ;   llm_first_text(Rest, Reply)
    ).

%% llm_headers(+Provider, +Key, -CurlHeaderOptions)
%%
%% Several header(H) options are collected by curl_headers/2 with a
%% findall (modules/curl/curl.cicili:106), so one option per header is
%% the right shape and the joining is not ours to do.
llm_headers(anthropic, Key, [header(KeyHeader),
                             header('anthropic-version: 2023-06-01'),
                             header('content-type: application/json')]) :-
    atom_concat('x-api-key: ', Key, KeyHeader).

llm_headers(openai, Key, [header(KeyHeader),
                          header('content-type: application/json')]) :-
    atom_concat('Authorization: Bearer ', Key, KeyHeader).

%% ---- the plumbing ------------------------------------------------------

%% llm_key(+KeyVar, -Key)
%% Read at the call. Never asserted, never answered to a caller.
llm_key(KeyVar, Key) :-
    (   getenv(KeyVar, Key), Key \== ''
    ->  true
    ;   throw(error(llm_error(no_key, KeyVar), llm_chat/3))
    ).

%% llm_post_retrying(+N, +Url, +BodyCodes, +Opts, -Status, -RespCodes)
%%
%% Retry only a TRANSPORT failure or a 429/5xx. A 400 is a bad request and
%% sending it again is a bad request again -- retrying it wastes the
%% caller's quota and hides the bug.
llm_post_retrying(0, Url, Body, Opts, Status, Resp) :-
    !,
    curl_post(Url, 'application/json', Body, Opts, Status, Resp).
llm_post_retrying(N, Url, Body, Opts, Status, Resp) :-
    N > 0,
    (   catch(curl_post(Url, 'application/json', Body, Opts, S0, R0), _, fail),
        \+ llm_retryable(S0)
    ->  Status = S0, Resp = R0
    ;   llm_backoff_ms(N, Ms),
        llm_sleep(Ms),
        N1 is N - 1,
        llm_post_retrying(N1, Url, Body, Opts, Status, Resp)
    ).

llm_retryable(429).
llm_retryable(S) :- integer(S), S >= 500, S =< 599.

%% Doubling from 1s. Deterministic, so two runs of the same failure take
%% the same time -- a random jitter would be better against a thundering
%% herd and worse for a test, and this family pins its timings.
llm_backoff_ms(N, Ms) :-
    Shift is 4 - N,
    (   Shift < 0 -> P = 0 ; P = Shift ),
    Ms is 1000 * (2 ** P).

%% proc_sleep/1 is library(process)'s. If that library is absent the
%% directive at the head of this file WARNED and continued, so this is
%% where the absence surfaces -- as an existence_error naming
%% proc_sleep/1, which is the truthful message.
llm_sleep(Ms) :- proc_sleep(Ms).

%% llm_status_ok(+Status)
llm_status_ok(S) :- integer(S), S >= 200, S =< 299.

%% llm_check_messages(+Messages)
%% Refuse a malformed message rather than posting something the provider
%% will reject with a message about JSON.
llm_check_messages(Ms) :-
    (   is_list(Ms)
    ->  true
    ;   throw(error(llm_error(bad_message, Ms), llm_chat/3))
    ),
    llm_check_each(Ms).

llm_check_each([]).
llm_check_each([M|Ms]) :-
    (   M = msg(Role, Text),
        llm_role(Role),
        atom(Text)
    ->  true
    ;   throw(error(llm_error(bad_message, M), llm_chat/3))
    ),
    llm_check_each(Ms).

llm_role(system).
llm_role(user).
llm_role(assistant).

%% llm_split_system(+Messages, -SystemText, -Rest)
%% Several system messages are joined with a blank line between them.
llm_split_system(Ms, System, Rest) :-
    findall(T, member(msg(system, T), Ms), Sys),
    findall(msg(R, T), ( member(msg(R, T), Ms), R \== system ), Rest),
    llm_join_blank(Sys, System).

llm_join_blank([], '').
llm_join_blank([S], S) :- !.
llm_join_blank([S|Ss], Out) :-
    llm_join_blank(Ss, Rest),
    atom_concat(S, '\n\n', S1),
    atom_concat(S1, Rest, Out).

%% llm_wire_messages(+Provider, +Messages, -JsonList)
llm_wire_messages(_, [], []).
llm_wire_messages(P, [msg(Role, Text)|Ms], [json([role-Role, content-Text])|Js]) :-
    llm_wire_messages(P, Ms, Js).

%% llm_add_temperature(+Options, +Pairs0, -Pairs)
%% Omitted entirely when the caller did not ask, so the provider's own
%% default applies rather than one this library invented.
llm_add_temperature(Options, Pairs0, Pairs) :-
    (   memberchk(temperature(T), Options)
    ->  Pairs = [temperature-T|Pairs0]
    ;   Pairs = Pairs0
    ).

%% llm_remember_usage(+Provider, +Json)
%% The cut matters. Without it the first clause leaves a choice point and
%% llm_chat_full/4 answers twice on backtracking -- one of the quiet ways
%% a deterministic-looking predicate is not, and the kind of thing this
%% repository's own retractall/1 bug was.
llm_remember_usage(_, json(Pairs)) :-
    !,
    (   memberchk(usage-Usage, Pairs)
    ->  catch(nb_setval(llm_usage, Usage), _, true)
    ;   true
    ).
llm_remember_usage(_, _).

%% ---- options, with their defaults in one place -------------------------

llm_opt(Options, provider, V) :-
    (   memberchk(provider(V0), Options) -> V = V0
    ;   llm_default_provider(V) -> true
    ;   V = anthropic
    ).
llm_opt(Options, model, V) :-
    (   memberchk(model(V0), Options)
    ->  V = V0
    ;   llm_opt(Options, provider, P),
        (   llm_model_default(P, V) -> true ; V = '' )
    ).
llm_opt(Options, timeout, V) :-
    ( memberchk(timeout(V0), Options) -> V = V0 ; V = 600 ).
llm_opt(Options, max_tokens, V) :-
    ( memberchk(max_tokens(V0), Options) -> V = V0 ; V = 4096 ).
llm_opt(Options, max_size, V) :-
    ( memberchk(max_size(V0), Options) -> V = V0 ; V = 16777216 ).
llm_opt(Options, retries, V) :-
    ( memberchk(retries(V0), Options) -> V = V0 ; V = 0 ).

%% ---- NOT IMPLEMENTED ---------------------------------------------------
%%
%% These three are the shape of what the agent above this library needs.
%% They throw rather than failing, because a silent failure here would
%% look exactly like "the model had nothing to say".

%% llm_store_chunked(+KB, +Key, +Text)
%% A reply longer than a page, into the knowledge base as chunks -- the
%% way a machine travels, and for the same reason: parsi/01-schema.parsi:23-30
%% says 8000 stores and 8192 is `allocation overflow'. The split is
%% `*chunk-bytes* 4000' at lib/zigurat-kb.cicili:49, applied in coco_zg_save
%% (:708, :736-738) -- NOT in lib/state.cicili, which produces one unbounded
%% buffer and knows nothing about rows. The chunking belongs to the BACKEND,
%% which is why --local has none of it.
llm_store_chunked(_, _, _) :-
    throw(error(llm_error(not_implemented, llm_store_chunked/3), llm_store_chunked/3)).

%% llm_embed(+Texts, +Options, -Vectors)
%% The call is just another endpoint. The STORAGE exists --
%% cocolog::tensors has a Vector<Double> column split at 512
%% (parsi/01-schema.parsi:155-166) -- and the similarity is
%% tensor_binary(matmul, ...) from modules/torch. What does NOT exist is
%% any distance operator in parsi/*.parsi, so the search is a matmul in
%% torch or an O(N) walk in Prolog, and that choice belongs to whoever
%% knows how many vectors there are.
llm_embed(_, _, _) :-
    throw(error(llm_error(not_implemented, llm_embed/3), llm_embed/3)).

%% llm_stream(+Messages, +Options, :OnChunk)
%% CANNOT be built on library(curl) as it stands: modules/curl's header
%% names the multi interface and streaming as absent, and cicili's own
%% binding does not cover the multi interface either. This is a C-half
%% change in modules/curl, not a clause.
llm_stream(_, _, _) :-
    throw(error(llm_error(not_implemented, llm_stream/3), llm_stream/3)).
