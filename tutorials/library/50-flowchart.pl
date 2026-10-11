%% LIBRARY 50 -- library(flowchart): a predicate drawn from the query down to
%% the C it reaches, and back, as an SVG for a person and an XML for an agent
%%
%%     ./cocolog run tutorials/library/50-flowchart.pl main
%%
%% TIER 2: `use_module(library(flowchart))', clauses in library/flowchart.pl
%% and library/flow/, over library(stream) (`sh modules/stream/build.sh').
%% Its tables -- which C function answers each name, with what modes -- are
%% written by `make modules' (sh tools/flow/build.sh).
%%
%%     flow_chart(+Spec, +Base)             Base.svg and Base.xml
%%     flow_chart(+Spec, +Base, +Options)   source(File), title(T), libraries(none|reach|all),
%%                                          depth(D), only(Preds) -- these two for the picture
%%     flow_graph(+Spec, -Graph, +Options)  the analysis as a term
%%     flow_findings(+Graph, -Findings)     what is wrong, and where
%%     flow_svg(+Graph, -Svg)   flow_xml(+Graph, -Xml)      the documents as terms
%%
%% Spec is a call pattern -- count(+, -) -- or Name/Arity, or Name//Arity for
%% a nonterminal called to parse. It is NOT A DEBUGGER: nothing is run. The
%% program is READ, with its variable names and where each goal stands, and
%% analysed for the call pattern: which variables each goal finds bound (the
%% MODES, + - ? on every argument), how each predicate can end (det, semidet,
%% nondet, or never succeeds), and where every failure goes. A predicate met
%% with two call patterns gets a panel for each. A grammar rule is drawn as
%% the predicate it stands for, through the engine's own translator. A C
%% function is the end of the chart -- a portal, named with its module, its C
%% function and its table row -- and never looked inside.
%%
%% THE XML SAYS WHAT THE PICTURE DOES, for a program: every goal with its
%% file, line and column, its modes, can_fail and choice, the panel it calls
%% and on_fail -- the id of the goal tried again, next_clause, or fail -- and
%% each one's id is the id of its box in the SVG. tools/flow/chart.pl is the
%% same from a shell: `cocolog -s tools/flow/chart.pl -- SPEC FILE BASE'.
%%
%% IT FINDS WHAT IS WRONG, AND WHERE: a call nothing answers, a call the
%% engine refuses with an argument unbound on every path to it, a predicate
%% that calls itself again first with nothing gained, a clause never tried,
%% a `%! p(...) is det' the code does not keep -- each a numbered red disc
%% on its box, a line under the chart, a <finding> at the head of the XML,
%% and a line from tools/flow/chart.pl as a compiler writes one.
%%
%% EVERY GOAL IS DRAWN, builtins too: a test, a unification, a builtin and
%% a library call are each a box with its own text on its clause's line,
%% and the chart never goes inside one -- a builtin is C in the engine, and
%% a library predicate is opened into a panel only when libraries(reach)
%% or libraries(all) asks. A BIG PROGRAM IS DRAWN IN PART and analysed in
%% full: past 150 panels the picture stops at the depth that fits,
%% depth(D) and only(Preds) choose another part, and a panel left out is a
%% stub that says how much hangs from it. The XML always has everything.

:- use_module(library(flowchart)).
:- use_module(library(stream)).
:- use_module(library(xml)).

main :-
    Dir = '/tmp/cocolog-flowchart-lesson',
    ( exists_directory(Dir) -> true ; make_directory(Dir) ),
    atom_concat(Dir, '/words.pl', Prog),
    atom_concat(Dir, '/count', Base),
    program(Lines),
    open(Prog, write, W),
    forall(member(L, Lines), format(W, "~w~n", [L])),
    close(W),

    format("~n-- one call, two files~n"),
    flow_chart(count('+', '-'), Base, [source(Prog)]),
    atom_concat(Base, '.svg', Svg), atom_concat(Base, '.xml', Xml),
    ( exists_file(Svg), exists_file(Xml) -> Both = yes ; Both = no ),
    must('the picture and the XML are both written', Both, yes),

    format("~n-- what each predicate is, as count(+, -) meets it~n"),
    flow_graph(count('+', '-'), Graph, [source(Prog)]),
    Graph = graph(Title, _, Panels, _, _),
    must('the title is the moded head, named as the comment names it', Title, 'count(+Text, -N)'),
    findall(K-CM-D, ( member(panel(I, K, _, CM, _, _, D, _), Panels), I > 0 ), Ps),
    must('each panel: what it is, its call pattern, how it can end', Ps,
         [count/2-['+', '-']-semidet,
          ws/3-['-', '+', '+']-semidet,
          blanks/2-['+', '-']-det,
          word/3-['-', '+', '-']-semidet,
          blanks/2-['+', '+']-semidet,
          word_rest/3-['-', '+', '-']-det]),
    %% blanks//0 has two panels: ws//1's first clause calls it to read
    %% what blanks there are (+, -: it cannot fail), its second to read the
    %% REST of the text as blanks (+, +: phrase/2 left [] for what is left).
    %% So count/2 is semidet, which its comment promises it is not -- `is
    %% det' -- and a character that is neither a letter nor a blank ends
    %% the parse with no answer. The chart said so before anything ran;
    %% running it agrees.
    use_module(Prog),
    ( count("two words", N1) -> true ; N1 = none ),
    must('count("two words", N)', N1, 2),
    ( count("a 1", _) -> F1 = yes ; F1 = no ),
    must('count("a 1", N) has an answer', F1, no),

    format("~n-- what the chart finds: a promise the code does not keep~n"),
    %% a finding names its kind, the place it is about (p1, count/2's
    %% panel) and what is wrong, in a sentence: here the `is det' of the
    %% comment against the analysis, and the goal that breaks it
    flow_findings(Graph, Fs),
    findall(K-At, member(finding(_, K, _, At, _, _, _, _), Fs), KAs),
    must('one finding: count/2 breaks the det its comment promises', KAs, [det_promise-p1]),
    Fs = [finding(_, _, _, _, _, _, FText, _)],
    must('and what breaks it', FText,
         'count/2 is documented as det (line 3) but can fail: when phrase(ws(Ws), Text) fails, so does the whole call'),

    format("~n-- the XML, which is what an agent reads~n"),
    read_file_to_codes(Xml, XC),
    xml_parse(XC, X),
    goal_attr(X, 'p1.c1.g1', text, T1),
    goal_attr(X, 'p1.c1.g1', line, L1),
    must('count/2''s first goal, and the line it is on', T1-L1, 'phrase(ws(Ws), Text)'-'5'),
    goal_attr(X, 'p4.c1.g1', on_fail, F2),
    must('when word//1''s { code_type } test fails, the call fails: nothing before it can redo', F2, fail),
    goal_attr(X, 'p2.c1.g2', on_fail, F3),
    must('when ws//1''s word fails, its next clause is tried: blanks//0 left no choice', F3, next_clause),
    goal_attr(X, 'p2.c1.g5', on_fail, F4),
    must('past the cut, a failure fails the whole call', F4, fail),
    goal_attr(X, 'p2.c1.g2', dcg, D3),
    must('a goal from a grammar body says what it was there', D3, 'nonterminal word//1'),

    format("~n-- and the SVG names the same goal the same way~n"),
    read_file_to_codes(Svg, SC),
    xml_parse(SC, S),
    ( has_id(S, 'p2.c1.g2') -> Boxed = yes ; Boxed = no ),
    must('the box for p2.c1.g2 is in the picture', Boxed, yes),

    format("~n-- the picture can be cut short; the XML cannot~n"),
    atom_concat(Dir, '/count1', Base1),
    flow_chart(count('+', '-'), Base1, [source(Prog), depth(1)]),
    atom_concat(Base1, '.xml', Xml1),
    read_file_to_codes(Xml1, XC1),
    ( XC1 == XC -> SameX = yes ; SameX = no ),
    must('depth(1) leaves the XML as it was', SameX, yes),
    atom_concat(Base1, '.svg', Svg1),
    read_file_to_codes(Svg1, SC1),
    xml_parse(SC1, S1),
    ( has_text(S1, 'not drawn: deeper than depth(1)') -> Stub = yes ; Stub = no ),
    must('ws//1, which count/2 calls, is a stub in the picture', Stub, yes),

    format("~n-- every goal is drawn, and the chart does not go inside a builtin~n"),
    %% word//1 is word([C|Cs]) --> [C], { code_type(C, alpha) }, word_rest(Cs):
    %% its body is the test, the list passed on (S1 = S0), and the call
    svg_title(S, 'p4.c1.g1', T5),
    must('word//1''s code_type/2 test is a box of its own', T5,
         'code_type(C, alpha)  --  builtin, C in the engine, semidet'),
    svg_title(S, 'p4.c1.g2', T6),
    must('and so is the list the grammar passes on', T6, 'S1 = S0  --  unification, det'),
    svg_title(S, 'p1.c1.g2', T7),
    must('length/2 is a box in count/2''s clause, and no panel of its own', T7,
         'length(Ws, N)  --  library(lists), det'),

    format("~ndone~n").

%% the program this lesson charts: a word count, by a grammar
program([
    '%% words.pl -- what lesson 50 charts',
    '',
    '%! count(+Text, -N) is det: how many words Text has',
    'count(Text, N) :-',
    '    phrase(ws(Ws), Text),',
    '    length(Ws, N).',
    '',
    '%% ws(-Words)//',
    'ws([W|Ws]) --> blanks, word(W), !, ws(Ws).',
    'ws([]) --> blanks.',
    '',
    'blanks --> [C], { code_type(C, space) }, !, blanks.',
    'blanks --> [].',
    '',
    '%% word(-W)//',
    'word([C|Cs]) --> [C], { code_type(C, alpha) }, word_rest(Cs).',
    '',
    'word_rest([C|Cs]) --> [C], { code_type(C, alpha) }, !, word_rest(Cs).',
    'word_rest([]) --> [].'
]).

goal_attr(X, Id, Name, V) :-
    (   find_id(X, Id, element(_, As, _)), memberchk(Name=V0, As) -> V = V0 ; V = none ).

find_id(element(N, As, Cs), Id, E) :-
    (   memberchk(id=Id, As) -> E = element(N, As, Cs)
    ;   member(C, Cs), C = element(_, _, _), find_id(C, Id, E)
    ), !.

has_id(T, Id) :- find_id(T, Id, _).

svg_title(T, Id, Title) :-
    (   find_id(T, Id, element(_, _, Cs)), memberchk(element(title, _, [Title0]), Cs)
    ->  Title = Title0
    ;   Title = none
    ).

has_text(element(_, _, Cs), T) :-
    member(C, Cs),
    (   C == T -> true
    ;   C = element(_, _, _), has_text(C, T)
    ), !.

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
