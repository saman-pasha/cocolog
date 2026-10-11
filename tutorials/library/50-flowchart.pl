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
%%     flow_chart(+Spec, +Base, +Options)   source(File), title(T), libraries(reach|all|none),
%%                                          depth(D), only(Preds), builtins(fold|show) --
%%                                          these three for the picture
%%     flow_graph(+Spec, -Graph, +Options)  the analysis as a term
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
%% A BIG PROGRAM IS DRAWN IN PART and analysed in full: past 150 panels the
%% picture stops at the depth that fits, depth(D) and only(Preds) choose
%% another part, and a panel left out is a stub that says how much hangs
%% from it. THE FLOW GOES THROUGH YOUR CODE: a run of builtin work --
%% tests, unifications, builtins, library calls -- is one box, a dot where
%% it can neither fail nor leave a choice, and builtins(show) draws every
%% goal. The XML always has everything.

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
    flow_graph(count('+', '-'), graph(Title, _, Panels, _, _), [source(Prog)]),
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
    %% So count/2 is semidet, which its comment does not say: a character
    %% that is neither a letter nor a blank ends the parse with no answer.
    %% The chart said so before anything ran; running it agrees.
    use_module(Prog),
    ( count("two words", N1) -> true ; N1 = none ),
    must('count("two words", N)', N1, 2),
    ( count("a 1", _) -> F1 = yes ; F1 = no ),
    must('count("a 1", N) has an answer', F1, no),

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

    format("~n-- the flow goes through your code; builtins(show) draws the rest~n"),
    %% word//1 is word([C|Cs]) --> [C], { code_type(C, alpha) }, word_rest(Cs):
    %% its body is the test, the list passed on (S1 = S0), and the call
    svg_title(S, 'p4.c1.g1', T5),
    ( atom_concat('2 builtin goals, folded', _, T5) -> Fold5 = yes ; Fold5 = no ),
    must('word//1''s code_type/2 test and the list passed on are one folded box', Fold5, yes),
    atom_concat(Dir, '/count2', Base2),
    flow_chart(count('+', '-'), Base2, [source(Prog), builtins(show)]),
    atom_concat(Base2, '.svg', Svg2),
    read_file_to_codes(Svg2, SC2),
    xml_parse(SC2, S2),
    svg_title(S2, 'p4.c1.g1', T6),
    must('builtins(show) draws the test in a box of its own', T6,
         'code_type(C, alpha)  --  builtin, C in the engine, semidet'),

    format("~ndone~n").

%% the program this lesson charts: a word count, by a grammar
program([
    '%% words.pl -- what lesson 50 charts',
    '',
    '%% count(+Text, -N): how many words Text has',
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
