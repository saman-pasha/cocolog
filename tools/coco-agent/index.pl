%% index.pl -- the three retrieval files, built from the repository itself.
%%
%%     cocolog --local run clauses.pl index.pl ix_main
%%     ...                                     -- --check     validate, write nothing
%%     ...                                     -- --no-run    skip recording stdout
%%
%% THE COCOLOG REWRITE OF index.py, and the Python is gone.
%%
%% Nothing here is written by hand except the twenty-three capability rows and
%% the eight exemplar rows, and the builder validates every path and every
%% anchor those name. IN PYTHON THEY WERE LIST-OF-DICT LITERALS; here they are
%% CLAUSES, which is the shape they should always have had -- `listing(ix_capability/5)'
%% prints the topic table, and a row can be queried rather than parsed.
%%
%%   surface.jsonl     one row per library: its own header block, verbatim,
%%                     plus the name/arity it DOCUMENTS -- for the .pl
%%                     libraries AND for the loadable modules, which are
%%                     `library(NAME)' to a caller exactly as the .pl are
%%   exemplars.jsonl   whole files and anchored spans, with what they print
%%   capabilities.json the topic table, every path in it checked
%%
%% A HEADER BLOCK IS THE ONLY AUTHORITY ON WHAT A LIBRARY OFFERS.
%% library/json.pl has seventy clause heads and documents ten; a clause-head
%% listing would offer json_hex4/3 as API, and a model handed that will call
%% it. So the surface is what the file says about itself -- the leading %%
%% block, and every `%% name(...)' doc line whose name the file actually
%% defines. That last condition matters: without it, prose naming
%% split_string/4 as a thing cocolog does NOT have would enter the index as a
%% thing it does.
%%
%% EXEMPLARS ARE ANCHORED BY SUBSTRING, NEVER BY LINE. A line-range citation
%% rots faster than a file citation, and silently: the span still resolves, it
%% just teaches half a predicate. Each anchor must match EXACTLY ONCE or the
%% build fails.
%%
%% AND THEY ARE RUN. Each runnable exemplar carries the stdout `cocolog
%% --local run FILE main' actually produced, recorded at index time. It is the
%% only grounding signal in the repository a stale comment cannot corrupt: the
%% model sees behaviour, not just appearance.
%%
%% ONE OUTPUT IS BYTE-IDENTICAL TO THE PYTHON'S AND TWO ARE NOT, and the
%% difference is spacing rather than data. capabilities.json is written with
%% indent(1), which reproduces json.dumps(indent=1) exactly. The two JSONL
%% files were compact, and Python's compact form puts a space after every `:'
%% and `,' where library(json)'s puts none -- a decision that library states
%% and defends in its own header ("the default because the common caller is a
%% wire"). Changing a shipped library to make a tool's output diff smaller is
%% the tail wagging the dog, so the files are regenerated in cocolog's form
%% and the equivalence claim is about the DATA: parse both, compare the terms.
%% test/lint.sh does exactly that.

:- use_module(library(json)).
:- use_module(library(process)).

%% ---- where things are -------------------------------------------------

ix_root(Root) :-
    (   getenv('COCOLOG_ROOT', R) -> Root = R
    ;   working_directory(Root, Root)
    ).

ix_path(Rel, Abs) :- ix_root(Root), atomic_list_concat([Root, '/', Rel], Abs).

ix_here(Rel, Abs) :- ix_path('tools/coco-agent/', D), atom_concat(D, Rel, Abs).

ix_bin(Bin) :-
    (   getenv('COCOLOG_BIN', B) -> Bin = B ; ix_path(cocolog, Bin) ).

%% Tier 1 is compiled in or preloaded and needs no import; tier 2 sits on the
%% library path. The distinction is the WHEN axis the linter uses too.
ix_tier_dir(2, 'library').
ix_tier_dir(1, 'lib/swipl').

%% ---- the surface --------------------------------------------------------

%% THE .pl LIBRARIES FIRST, THEN THE LOADABLE MODULES, in that order, so a
%% row's `kind' says which of the two a `library(NAME)' is.
ix_surface(Rows) :-
    findall(Row,
            ( ix_tier_dir(Tier, Dir),
              ix_pl_files(Dir, Files),
              member(Rel-Abs, Files),
              ix_surface_row(Tier, Dir, Rel, Abs, Row)
            ),
            PlRows),
    ix_module_rows(ModRows),
    append(PlRows, ModRows, Rows).

%% Sorted by name within a directory, which is what os.listdir + sorted gave.
ix_pl_files(Dir, Files) :-
    ix_path(Dir, Full),
    (   exists_directory(Full)
    ->  atomic_list_concat([Full, '/*.pl'], Pattern),
        expand_file_name(Pattern, Abs0),
        sort(Abs0, Abs),
        findall(R-A,
                ( member(A, Abs), ix_basename(A, B),
                  atomic_list_concat([Dir, '/', B], R) ),
                Files)
    ;   Files = []
    ).

ix_basename(Path, Base) :-
    atom_codes(Path, Cs),
    (   append(_, [0'/|B], Cs), \+ memberchk(0'/, B)
    ->  atom_codes(Base, B)
    ;   Base = Path
    ).

ix_module_of(Rel, Mod) :-
    ix_basename(Rel, B),
    atom_codes(B, Cs),
    append(M, ".pl", Cs),
    !,
    atom_codes(Mod, M).

ix_surface_row(Tier, _Dir, Rel, Abs, json(Row)) :-
    ix_module_of(Rel, Mod),
    read_file_to_codes(Abs, Src),
    ix_header_block(Src, Header),
    length(Header, HB),
    ix_heads(Abs, Heads),
    length(Heads, NH),
    ix_documented(Src, Heads, Doc),
    (   Tier =:= 1
    ->  Import = @(null)
    ;   atomic_list_concat([':- use_module(library(', Mod, ')).'], Import)
    ),
    atom_codes(HeaderA, Header),
    Row = [ path-Rel, module-Mod, tier-Tier, kind-pl, import-Import,
            header-HeaderA, header_bytes-HB, documented-Doc, heads-NH ].

%% The leading run of %% lines: the file's own account of itself. Ends at the
%% first line that is not a %% comment, blank lines inside it kept, trailing
%% blanks trimmed.
ix_header_block(Src, Header) :-
    ix_lines(Src, Lines),
    ix_header_take(Lines, [], Kept0),
    ix_drop_trailing_blank(Kept0, Kept),
    ix_unlines_nolast(Kept, Header).

ix_header_take([], Acc, Out) :- !, reverse(Acc, Out).
ix_header_take([L|Ls], Acc, Out) :-
    (   append("%%", _, L)
    ->  ix_header_take(Ls, [L|Acc], Out)
    ;   ix_blank(L), Acc \== []
    ->  ix_header_take(Ls, [L|Acc], Out)
    ;   reverse(Acc, Out)
    ).

ix_blank(L) :- \+ ( member(C, L), \+ ix_space(C) ).

ix_space(0' ).  ix_space(0'\t).  ix_space(0'\r).
ix_space(0'\n). ix_space(11).    ix_space(12).

ix_drop_trailing_blank(Ls, Out) :-
    reverse(Ls, R0),
    ix_skip_blank(R0, R1),
    reverse(R1, Out).

ix_skip_blank([L|T], R) :- ix_blank(L), !, ix_skip_blank(T, R).
ix_skip_blank(L, L).

%% ---- the doc lines -------------------------------------------------------
%%
%% `%%   name(+A, -B)' or `%%   name//1' or `%%   name/3', at any indent. The
%% name must be one the file DEFINES, or prose about a predicate that does not
%% exist here would enter the index as one that does.

ix_documented(Src, Heads, Doc) :- ix_documented(Src, "%%", Heads, Doc).

%% THE MARKER IS AN ARGUMENT because a module's is `;;', and a run of them:
%% `;;;;' is one comment marker and not two, so the prefix is `;;' followed
%% by however many more the file writes. Everything after it -- the optional
%% quote, the name, the `/N', the `//N', the argument list read through
%% clauses.pl -- is the same grammar for both kinds of file.
ix_documented(Src, Marker, Heads, Doc) :-
    ix_lines(Src, Lines),
    findall(K,
            ( member(L, Lines),
              ix_rstrip(L, L1),
              ix_doc_line(Marker, L1, Name, Arity),
              atomic_list_concat([Name, '/', Arity], K),
              ix_head_known(K, Name, Heads)
            ),
            Ks),
    sort(Ks, Doc).

%% `name/*' IS A MATCH FOR `name/3', and only here. A strcmp chain records no
%% arity -- shape 3 keys every name it finds as `name/*' -- so library(bigint)
%% and library(tensorflow), whose C++ dispatchers are chains, would have
%% answered "documents 0" over a header that lists their whole surface. What
%% the wildcard confirms is that the module registers the NAME; the arity in
%% the doc line is the header's word and nothing checks it, which is the
%% chain's limit and is worth having over no check at all.
ix_head_known(K, _, Heads) :- memberchk(K, Heads), !.
ix_head_known(_, Name, Heads) :-
    atom_concat(Name, '/*', Star),
    memberchk(Star, Heads).

ix_doc_prefix("%%", L, R) :- append("%%", R, L).
ix_doc_prefix(";;", L, R) :- append(";;", R0, L), ix_semis(R0, R).

ix_semis([0';|T], R) :- !, ix_semis(T, R).
ix_semis(L, L).

%% The Python it replaced, with `^%%' where the marker is now an argument:
%% `^%%\\s+'?([a-z_$][A-Za-z0-9_]*)'?\\s*(?:/(\\d+)|//(\\d+)|\\(([^)]*)\\))'
ix_doc_line(Marker, L, Name, Arity) :-
    ix_doc_prefix(Marker, L, R0),
    ix_ws1(R0, R1),
    ix_opt_quote(R1, R2),
    ix_name(R2, NameCs, R3),
    ix_opt_quote(R3, R4),
    ix_ws(R4, R5),
    atom_codes(Name, NameCs),
    ix_doc_arity(R5, Arity).

ix_opt_quote([0''|T], T) :- !.
ix_opt_quote(L, L).

ix_name([C|T], [C|Ns], R) :- ix_name_start(C), ix_name_rest(T, Ns, R).

ix_name_start(C) :- C >= 0'a, C =< 0'z.
ix_name_start(0'_).
ix_name_start(0'$).

ix_name_rest([C|T], [C|Ns], R) :- ix_name_char(C), !, ix_name_rest(T, Ns, R).
ix_name_rest(L, [], L).

ix_name_char(C) :- C >= 0'a, C =< 0'z.
ix_name_char(C) :- C >= 0'A, C =< 0'Z.
ix_name_char(C) :- C >= 0'0, C =< 0'9.
ix_name_char(0'_).

%% A DCG head occupies arity+2, which is the one place that has to be right.
ix_doc_arity([0'/, 0'/|T], Arity) :- !, ix_digits1(T, Ds, _), number_codes(N, Ds), Arity is N + 2.
ix_doc_arity([0'/|T], Arity) :- !, ix_digits1(T, Ds, _), number_codes(Arity, Ds).
ix_doc_arity([0'(|T], Arity) :- ix_upto_paren(T, ArgCs), ix_arity_of(ArgCs, Arity).

ix_upto_paren([0')|_], []) :- !.
ix_upto_paren([C|T], [C|R]) :- ix_upto_paren(T, R).

%% ROUTED THROUGH THE SAME GRAMMAR rather than reimplemented, because a second
%% comma counter that disagrees about a 0'c literal or a quoted atom is
%% exactly the bug the clauses.pl rewrite removed -- and that one really
%% happened.
ix_arity_of(ArgCs, Arity) :-
    (   ix_blank(ArgCs)
    ->  Arity = 0
    ;   append("p(", ArgCs, A0),
        append(A0, ").", Doc),
        cc_split_clauses(Doc, [Span|_]),
        catch(cc_read_head(Doc, Span, cc_clause(_, head(_, A), _)), _, fail)
    ->  Arity = A
    ;   Arity = 0
    ).

ix_heads(Abs, Keys) :-
    (   catch(cc_heads_of(Abs, Ks), _, fail)
    ->  findall(K, ( member(N/A, Ks), atomic_list_concat([N, '/', A], K) ), Keys)
    ;   Keys = []
    ).

%% ---- the loadable modules ------------------------------------------------
%%
%% TIER 2 HAS TWO KINDS AND A CALLER CANNOT TELL THEM APART. `library(json)'
%% is a .pl on the library path; `library(tcp)' is a .so dlopen'd from
%% modules/tcp; both are one `use_module' and neither says which it is. The
%% index had rows for the first kind only -- so a request routed to torch,
%% tcp or tensorflow reached the model with its NAMES, out of the blocklist
%% in block D, and not one line saying what any of them is for. Fifteen
%% modules, and half the tree's capability table pointed at them.
%%
%% A MODULE'S HEADER IS THE SAME KIND OF DOCUMENT, in the same voice; the
%% comment marker is Lisp's, and `;;;;' is `%%'. It is the .cicili's, not the
%% README's: modules/torch and modules/tensorflow each carry seventeen
%% kilobytes of README, which is the right size for a reader and four times
%% the budget of a prompt block. What the index serves is the file's own
%% account of itself, as it does for a library.
%%
%% ITS HEADS COME FROM build.pl'S OWN SHAPES, not from a second reader. A
%% module registers what it defines in a ("name" arity fn) table, in a
%% `*X-prolog*' half, or in the strcmp chain a C++ target dispatches on --
%% shapes 1, 2 and 3 of the blocklist -- so "does this module really define
%% the name its header documents" is answered by the code that already
%% answers it for the linter. tool.sh consults build.pl beside this file for
%% exactly that, and the alternative was a fourth scanner over the same
%% three shapes.

ix_module_rows(Rows) :-
    ix_module_dirs(Dirs0),
    sort(Dirs0, Dirs),
    findall(Row,
            ( member(Name, Dirs),
              ix_module_file(Name, Rel, Abs),
              ix_module_row(Name, Rel, Abs, Row)
            ),
            Rows).

%% modules/NAME/*.cicili, MINUS sdk.cicili -- which is a symlink into lib/,
%% the API every module is written against and not one of them. A directory
%% with no .cicili of its own is skipped rather than reported: `modules/' is
%% a place a checkout may leave a stray directory.
ix_module_file(Name, Rel, Abs) :-
    atomic_list_concat(['modules/', Name], Dir),
    ix_path(Dir, Full),
    atomic_list_concat([Full, '/*.cicili'], Pattern),
    expand_file_name(Pattern, Es0),
    sort(Es0, Es),
    findall(A, ( member(A, Es), ix_basename(A, B), B \== 'sdk.cicili' ), [Abs|_]),
    ix_basename(Abs, Base),
    atomic_list_concat([Dir, '/', Base], Rel).

ix_module_row(Name, Rel, Abs, json(Row)) :-
    read_file_to_codes(Abs, Src),
    ix_cc_header(Src, Header),
    length(Header, HB),
    ix_module_heads(Abs, Heads),
    length(Heads, NH),
    ix_documented(Src, ";;", Heads, Doc),
    atomic_list_concat([':- use_module(library(', Name, ')).'], Import),
    atom_codes(HeaderA, Header),
    Row = [ path-Rel, module-Name, tier-2, kind-so, import-Import,
            header-HeaderA, header_bytes-HB, documented-Doc, heads-NH ].

%% The leading run of `;;' lines, after any blank ones above it -- one file
%% starts with an empty line -- and it STOPS AT A BLANK. A .pl header's own
%% blank lines are `%%' lines and stay inside the block; a .cicili's are
%% empty, and the first of them is the end of the intro and the beginning of
%% the section banners.
ix_cc_header(Src, Header) :-
    ix_lines(Src, Lines),
    ix_skip_blank_lines(Lines, Rest),
    ix_cc_take(Rest, [], Kept),
    ix_unlines_nolast(Kept, Header).

ix_skip_blank_lines([L|T], R) :- ix_blank(L), !, ix_skip_blank_lines(T, R).
ix_skip_blank_lines(L, L).

ix_cc_take([], Acc, Out) :- !, reverse(Acc, Out).
ix_cc_take([L|Ls], Acc, Out) :-
    (   append(";;", _, L)
    ->  ix_cc_take(Ls, [L|Acc], Out)
    ;   reverse(Acc, Out)
    ).

%% SHAPES 1, 2 AND 3 OVER THE ONE FILE, which is what a module is. Three and
%% not two: a C++ target dispatches on a strcmp chain rather than a
%% ("name" arity fn) table -- torch, tensorflow and bigint all do -- and with
%% shape 3 left out those three answered zero heads, which would have read as
%% "documents nothing" when the truth is "counted nothing". A shape-3 name
%% carries no arity and is keyed `name/*', so it will not match a doc line
%% that names one; that is a limit of the chain, not of the header, and it is
%% why torch's own count is the low one.
ix_module_heads(Abs, Keys) :-
    (   catch(( bd_shape1([Abs], P1),
                bd_shape2([Abs], P2),
                bd_shape3([Abs], P3) ), _, fail)
    ->  findall(K, ( member(K-_, P1) ; member(K-_, P2) ; member(K-_, P3) ), Ks),
        sort(Ks, Keys)
    ;   Keys = []
    ).

%% ---- the exemplars, by capability tag ------------------------------------
%%
%% Seven rows, from DESIGN.md section 9.1. A row with no span is the WHOLE
%% file: for a template, half a file is worse than none, because what is being
%% taught is the shape.

ix_exemplar('self-checking program', 'tutorials/basics/01-facts-and-rules.pl',
  'the template for most requests: header, sections, main walking claims, the two helpers repeated at the foot').
ix_exemplar('assert/retract', 'tutorials/basics/07-assert-and-retract.pl',
  'the correct retract recursion, and it COUNTS the removals -- the failure-driven loop it shows first removes exactly one clause').
ix_exemplar(grammar, 'tutorials/basics/10-grammars.pl',
  'a DCG over codes, 0\'0 character literals, { } placement').
ix_exemplar('tier-2 library', 'library/astar.pl',
  'the shortest complete library in the tree -- the full header template plus the callback idiom. Shipped WITH its own two defects named (a no-op tier-1 use_module at line 41, and two unprefixed helpers): showing a real file and what is wrong with it beats a sanitised one').
ix_exemplar('parser: dispatch', 'library/json.pl',
  'ordered-clause DCG dispatch, the var/1 guard first, the type_error catch-all last, and the bound-code-list-is-a-call rule that nothing in an SWI corpus teaches').
ix_exemplar('cross-process', 'tutorials/library/34-kbs.pl',
  'goals as terms, marker-line verdicts, the honest-skip idiom').
ix_exemplar('bulk KB write', 'coworker/balancer/worker.pl',
  'chunk, then the completion mark, in one turn; every clause ends in a cut because consult appends').
ix_exemplar('tensor program', 'tutorials/library/39-tensor-expr.pl',
  'the whole of how a tensor program is written here: the two op/3 directives the file must declare ITSELF because a library cannot lend its operators upward, `:=\' running an expression as the list of goals it stands for, `::=\' for a function of the program\'s own, and a procedure as a DCG rule whose output list is what it made. Every network under tutorials/tensor is this shape').

ix_span('parser: dispatch',
        'json_emit(V, _, _) --> { var(V) }',
        'json_raw([C|Cs]) --> [C], json_raw(Cs).').

ix_exemplars(Run, Rows, Bad) :-
    findall(R-B, ix_exemplar_row(Run, R, B), Pairs),
    findall(R, ( member(R-_, Pairs), R \== none ), Rows),
    findall(B, ( member(_-Bs, Pairs), member(B, Bs) ), Bad).

ix_exemplar_row(Run, Row, Bad) :-
    ix_exemplar(Tag, Rel, Why),
    ix_path(Rel, Abs),
    (   \+ exists_file(Abs)
    ->  format(atom(B), "~w: does not exist", [Rel]),
        Row = none, Bad = [B]
    ;   read_file_to_codes(Abs, Src),
        ix_resolve(Tag, Src, Rel, I, J, Bad),
        (   I == none
        ->  Row = none
        ;   Bytes is J - I,
            (   ix_span(Tag, A, E)
            ->  Whole = @(false),
                Head = [tag-Tag, path-Rel, start_anchor-A, end_anchor-E, why-Why]
            ;   Whole = @(true),
                Head = [tag-Tag, path-Rel, why-Why]
            ),
            (   Run == yes
            ->  ix_record_stdout(Rel, Got, Absent),
                append(Head, [bytes-Bytes, whole_file-Whole,
                              recorded_stdout-Got, recorded_stdout_absent-Absent], Ps)
            ;   append(Head, [bytes-Bytes, whole_file-Whole], Ps)
            ),
            Row = json(Ps)
        )
    ).

%% Anchors to offsets. EXACTLY ONCE or the build fails -- an anchor that
%% matches twice is a span nobody chose, and one that matches none is a span
%% that has moved.
ix_resolve(Tag, Src, Rel, I, J, Bad) :-
    (   \+ ix_span(Tag, _, _)
    ->  I = 0, length(Src, J), Bad = []
    ;   ix_span(Tag, A, E),
        atom_codes(A, ACs), atom_codes(E, ECs),
        ix_count(Src, ACs, NA),
        ix_count(Src, ECs, NE),
        findall(B,
                ( member(W-N-Anc, ['start_anchor'-NA-A, 'end_anchor'-NE-E]),
                  N =\= 1,
                  format(atom(B), "~w: ~w matches ~w times, needs exactly 1: '~w'",
                         [Rel, W, N, Anc])
                ),
                Bad0),
        (   Bad0 \== []
        ->  I = none, J = none, Bad = Bad0
        ;   ix_index(Src, ACs, I0),
            ix_index(Src, ECs, J0),
            length(ECs, EL),
            J1 is J0 + EL,
            (   J1 =< I0
            ->  format(atom(B2), "~w: end_anchor is before start_anchor", [Rel]),
                I = none, J = none, Bad = [B2]
            ;   I = I0, J = J1, Bad = []
            )
        )
    ).

ix_count(Hay, Needle, N) :- ix_count_(Hay, Needle, 0, N).

ix_count_(Hay, Needle, A, N) :-
    (   append(Needle, Rest, Hay)
    ->  A1 is A + 1, ix_count_(Rest, Needle, A1, N)
    ;   Hay = [_|T]
    ->  ix_count_(T, Needle, A, N)
    ;   N = A
    ).

ix_index(Hay, Needle, I) :- ix_index_(Hay, Needle, 0, I).

ix_index_(Hay, Needle, A, I) :-
    (   append(Needle, _, Hay) -> I = A
    ;   Hay = [_|T] -> A1 is A + 1, ix_index_(T, Needle, A1, I)
    ).

%% What `cocolog --local run FILE main' prints. `null' when the file has no
%% main/0 -- a library is exercised by its tutorial, not by itself.
%%
%% STDOUT ONLY, which is what capture_output + r.stdout gave: the shell
%% redirection sends stderr away rather than letting proc_run/4 merge it, so
%% a warning on stderr cannot end up recorded as the program's output.
ix_record_stdout(Rel, Got, Absent) :-
    ix_path(Rel, Abs),
    ix_heads(Abs, Heads),
    (   \+ memberchk('main/0', Heads)
    ->  Got = @(null),
        Absent = 'no main/0: a library is run by its tutorial, not by itself'
    ;   ix_bin(Bin),
        \+ exists_file(Bin)
    ->  Got = @(null), Absent = 'no binary'
    ;   ix_bin(Bin2),
        ix_root(Root),
        atomic_list_concat(['cd ', Root, ' && COCOLOG_LIBRARY=', Root,
                            '/library ', Bin2, ' --local run ', Abs,
                            ' main 2>/dev/null'], Cmd),
        (   catch(proc_run(Cmd, 120000, Out, Exit), _, fail)
        ->  (   Exit =:= 0
            ->  atom_codes(GotA, Out), Got = GotA, Absent = @(null)
            ;   Got = @(null),
                format(atom(Absent), "exit ~w", [Exit])
            )
        ;   Got = @(null), Absent = 'did not run'
        )
    ).

%% ---- the topic table -----------------------------------------------------
%%
%% HAND-WRITTEN AND VALIDATED, which is the whole of section 9.2's argument
%% against embeddings: what retrieval would serve here is an exact-match
%% problem over a few dozen documents with one hand-labelled topic each, not a
%% similarity problem. Twenty-three rows fit on a page and every path is
%% checked -- and ix_unrouted below says which library no row reaches, which
%% is the half a hand-written table cannot check about itself.

ix_capability('JSON', [json, serialise, serialize, 'api payload'],
              [json], ['parser: dispatch'], local).
ix_capability('XML or HTML', [xml, html, markup, scrape, css, stylesheet],
              [xml, html], ['parser: dispatch'], local).
ix_capability('an HTTP client', [fetch, 'http request', download, rest, curl],
              [http, curl], ['tier-2 library'], local).
ix_capability('an HTTP server', [serve, 'web server', endpoint, route, page],
              [httpd, html], ['tier-2 library'], local).
ix_capability('TLS or certificates', [tls, https, certificate, ca, x509, sign],
              [x509, ca, tls, der, sha], ['tier-2 library'], local).
ix_capability('hashing or ciphers', [sha, hash, hmac, aes, encrypt],
              [sha, aes], ['tier-2 library'], local).
ix_capability(sockets, [socket, tcp, listen, connect, port],
              [tcp], ['tier-2 library'], local).
ix_capability(threads, [thread, concurrent, worker, parallel, channel],
              [thread], ['bulk KB write'], local).
ix_capability(processes, [subprocess, spawn, exec, 'shell out'],
              [process], ['tier-2 library'], local).
ix_capability('the knowledge base',
              ['knowledge base', database, persist, store, 'across processes', shared],
              [kbs], ['cross-process', 'bulk KB write'], kb).
ix_capability('an embedded store', [embedded, 'single file', 'no server', 'local store'],
              [], ['bulk KB write'], embed).
ix_capability('a grammar or parser', [parse, grammar, dcg, tokenize, lexer],
              [], [grammar, 'parser: dispatch'], local).
ix_capability('search or pathfinding', ['shortest path', 'a*', astar, route, search, graph],
              [astar], ['tier-2 library'], local).
ix_capability('hex grids', [hex, hexagonal, tile, map],
              [hex], ['tier-2 library'], local).
ix_capability('big integers', [bignum, 'big integer', 'arbitrary precision', rsa],
              [bigint], ['tier-2 library'], local).
ix_capability('tensors or a model',
              [tensor, neural, train, torch, model, tensorflow, gpu, cuda,
               gradient, network, 'tensor expression'],
              [torch, tensor_expr, tensorflow], ['tensor program'], local).
ix_capability('a language model', [llm, chat, prompt, completion, openai, anthropic],
              [llm, curl, json], ['tier-2 library'], local).
ix_capability('files and paths', [file, directory, path, 'read a file'],
              [], ['self-checking program'], local).
ix_capability('text and atoms', [string, text, atom, split, join, case],
              [text], ['self-checking program'], local).
ix_capability('the operating system', [platform, 'which os', cpus, 'temp dir', environment],
              [os], ['self-checking program'], local).
ix_capability('assert and retract', [assert, retract, remember, counter, mutable],
              [], ['assert/retract'], local).
ix_capability('a command line', [argv, 'command line', flag, option, usage, script],
              [main], ['self-checking program'], local).
ix_capability('a window or a game', [draw, game, window, sprite, raylib, graphics,
                                     '2d', '3d', keyboard, mouse],
              [ray], ['self-checking program'], local).

ix_capabilities(Rows) :-
    findall(json([topic-T, words-W, libraries-L, exemplars-E, arrangement-A]),
            ix_capability(T, W, L, E, A),
            Rows).

%% Every library named must have a surface row; every exemplar tag must exist.
%% A topic table that names a library nobody ships is a prompt that tells the
%% model to import something that is not there.
ix_check_capabilities(Surf, Exs, Bad) :-
    findall(M, ( member(json(R), Surf), memberchk(module-M, R) ), Mods0),
    ix_module_dirs(Dirs),
    append(Mods0, Dirs, Mods),
    findall(T, ( member(json(E), Exs), memberchk(tag-T, E) ), Tags),
    findall(B, ix_cap_complaint(Mods, Tags, B), Bad).

ix_module_dirs(Dirs) :-
    ix_path(modules, Full),
    (   exists_directory(Full)
    ->  atomic_list_concat([Full, '/*'], P),
        expand_file_name(P, Es),
        findall(N, ( member(E, Es), exists_directory(E), ix_basename(E, N) ), Dirs)
    ;   Dirs = []
    ).

ix_cap_complaint(Mods, Tags, B) :-
    ix_capability(Topic, _, Libs, Exs, Arr),
    (   member(M, Libs), \+ memberchk(M, Mods),
        format(atom(B), "capabilities: '~w' names library(~w), which does not ship",
               [Topic, M])
    ;   member(T, Exs), \+ memberchk(T, Tags),
        format(atom(B), "capabilities: '~w' names exemplar tag '~w', which is not one",
               [Topic, T])
    ;   \+ memberchk(Arr, [local, kb, embed, http]),
        format(atom(B), "capabilities: '~w' names arrangement '~w'", [Topic, Arr])
    ).

%% Tier-2 libraries whose header documents almost nothing.
%%
%% NOT A BUILD FAILURE, A REPORT. CLAUDE.md's house style asks a header for
%% "the public surface as an indented signature list", and where one is
%% missing the index cannot invent it -- so the honest thing is to say which
%% library will be under-served rather than to quietly serve one name.
ix_thin(Surf, Thin) :-
    findall(m(Mod, ND, NH),
            ( member(json(R), Surf),
              memberchk(tier-2, R),
              memberchk(documented-D, R), length(D, ND), ND =< 1,
              memberchk(module-Mod, R),
              memberchk(heads-NH, R)
            ),
            Thin).

%% ---- lines ---------------------------------------------------------------

ix_lines([], []) :- !.
ix_lines(Cs, [L|Ls]) :-
    (   append(L, [0'\n|Rest], Cs) -> true ; L = Cs, Rest = [] ),
    !,
    ( Rest == [], L == [] -> Ls = [] ; ix_lines(Rest, Ls) ).

%% Joined with newlines BETWEEN, not after -- "\n".join(out).
ix_unlines_nolast([], []) :- !.
ix_unlines_nolast([L], L) :- !.
ix_unlines_nolast([L|Ls], Out) :-
    ix_unlines_nolast(Ls, R),
    append(L, [0'\n|R], Out).

ix_ws([C|T], R) :- ix_space(C), !, ix_ws(T, R).
ix_ws(L, L).

ix_ws1([C|T], R) :- ix_space(C), ix_ws(T, R).

ix_digits1([C|T], [C|Ds], R) :- ix_digit(C), ix_digits(T, Ds, R).
ix_digits([C|T], [C|Ds], R) :- ix_digit(C), !, ix_digits(T, Ds, R).
ix_digits(L, [], L).
ix_digit(C) :- C >= 0'0, C =< 0'9.

ix_rstrip(L, Out) :- reverse(L, R0), ix_ws(R0, R1), reverse(R1, Out).

%% ---- writing --------------------------------------------------------------

ix_write_jsonl(Path, Rows) :-
    findall(Cs, ( member(R, Rows), json_codes(R, C0), append(C0, "\n", Cs) ), Parts),
    ix_concat(Parts, Text),
    ix_write_atomic(Path, Text).

ix_concat([], []).
ix_concat([P|Ps], Out) :- ix_concat(Ps, R), append(P, R, Out).

ix_write_atomic(Path, Codes) :-
    atom_concat(Path, '.tmp', Tmp),
    write_file_from_codes(Tmp, Codes),
    rename_file(Tmp, Path).

%% ---- the entry point -------------------------------------------------------

ix_main :-
    current_prolog_flag(argv, [_|Args]),
    ( memberchk('--no-run', Args) -> Run = no ; Run = yes ),
    ix_surface(Surf),
    ix_exemplars(Run, Exs, Bad0),
    ix_check_capabilities(Surf, Exs, Bad1),
    append(Bad0, Bad1, Bad),
    forall(member(B, Bad), format("index: ~w~n", [B])),
    (   Bad \== []
    ->  fail
    ;   (   memberchk('--check', Args)
        ->  true
        ;   ix_here('surface.jsonl', SP),   ix_write_jsonl(SP, Surf),
            ix_here('exemplars.jsonl', EP), ix_write_jsonl(EP, Exs),
            ix_capabilities(Caps),
            json_codes(Caps, CC, [indent(1)]),
            ix_here('capabilities.json', CP),
            ix_write_atomic(CP, CC)
        ),
        ix_report(Surf, Exs)
    ).

ix_report(Surf, Exs) :-
    findall(R, ( member(json(R), Surf), memberchk(tier-2, R) ), T2),
    length(T2, NT2),
    findall(R, ( member(R, T2), memberchk(kind-so, R) ), Mods),
    length(Mods, NMod),
    NPl is NT2 - NMod,
    length(Surf, NAll),
    NT1 is NAll - NT2,
    ix_sum(T2, header_bytes, HB),
    ix_sum(T2, heads, HD),
    findall(1, ( member(R, T2), memberchk(documented-D, R), member(_, D) ), Ds),
    length(Ds, NDoc),
    KB is HB // 1024,
    findall(1, ( member(json(E), Exs), memberchk(recorded_stdout-S, E), S \== @(null) ), Rs),
    length(Rs, NRan),
    length(Exs, NEx),
    findall(1, ix_capability(_, _, _, _, _), Cs), length(Cs, NCap),
    format("surface : ~w tier-2 libraries and ~w loadable modules, ~w KB of header, ~w documented of ~w heads~n",
           [NPl, NMod, KB, NDoc, HD]),
    format("          ~w tier-1 vendored libraries~n", [NT1]),
    format("exemplar: ~w rows, ~w with recorded stdout, all anchors matched once~n",
           [NEx, NRan]),
    format("capabil.: ~w topics, every library and tag checked~n", [NCap]),
    ix_thin(Surf, Thin),
    forall(member(m(Mod, ND, NH), Thin),
           format("thin    : library(~w) documents ~w of ~w heads -- its header has no signature list, so the index cannot offer a surface for it~n",
                  [Mod, ND, NH])),
    ix_unrouted(Surf, Un),
    forall(member(U, Un),
           format("unrouted: library(~w) ships and no capability row names it -- nothing a reader asks for can route to it~n",
                  [U])).

%% A tier-2 library the topic table does not name.
%%
%% NOT A BUILD FAILURE, A REPORT, for ix_thin's reason and one of its own: a
%% row is a judgement about ENGLISH -- which words should reach this library
%% -- and a builder cannot make one up. What it can do is notice.
%%
%% FOUR WERE UNROUTED WHEN THIS WAS WRITTEN and not one was a decision.
%% library(tensor_expr) and library(tensorflow) arrived after the table did;
%% library(main) and library(ray) were simply missed on the day it was
%% written, which is why this is a standing check and not a sweep.
ix_unrouted(Surf, Names) :-
    findall(M, ( member(json(R), Surf),
                 memberchk(tier-2, R), memberchk(module-M, R) ), Mods),
    findall(L, ( ix_capability(_, _, Ls, _, _), member(L, Ls) ), Named),
    findall(M, ( member(M, Mods), \+ memberchk(M, Named) ), Names).

ix_sum(Rows, Key, Sum) :-
    findall(V, ( member(R, Rows), memberchk(Key-V, R) ), Vs),
    ix_add(Vs, 0, Sum).

ix_add([], A, A).
ix_add([V|Vs], A, S) :- A1 is A + V, ix_add(Vs, A1, S).
