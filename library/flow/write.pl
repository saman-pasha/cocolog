%% library(flow/chart), part: a document written to its file a piece at a
%% time.
%%
%% library(xml) makes a document as ONE code list, which is right for a
%% page and wrong for a chart of a big program: the translator's XML is 45
%% million codes, 52 s and 251 M inferences to make, and its SVG ran the
%% process out of memory before a byte was written. This writes the same
%% bytes -- library(xml)'s header, its escaping, and its rule that only
%% element-only content is indented -- straight to the stream, an
%% attribute at a time, and escapes a value with a split per character in
%% C rather than a step per code. test/flowchart.pl reads both documents
%% back through library(xml), and checks the small ones against it byte
%% for byte.

:- use_module(library(stream)).

flow_write_doc(File, Doc, Opts) :-
    (   memberchk(indent(Step), Opts) -> true ; Step = 0 ),
    open(File, write, S),
    catch(( format(S, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~n", []),
            flow_w_node(S, Step, 0, Doc) ),
          E, ( close(S), throw(E) )),
    close(S).

flow_w_node(S, Step, D, element(N, As, Ks)) :- !,
    format(S, "<~a", [N]),
    flow_w_attrs(As, S),
    (   Ks == []
    ->  format(S, "/>", [])
    ;   format(S, ">", []),
        (   Step > 0, flow_w_elements(Ks)
        ->  D1 is D + 1,
            flow_w_lines(Ks, S, Step, D1),
            flow_w_break(S, Step, D)
        ;   flow_w_kids(Ks, S, Step, D)
        ),
        format(S, "</~a>", [N])
    ).
flow_w_node(S, _, _, str(Cs)) :- !,
    atom_codes(A, Cs),
    flow_w_text(S, A).
flow_w_node(S, _, _, A) :- atom(A), !,
    flow_w_text(S, A).
flow_w_node(S, _, _, N) :- number(N), !,
    format(S, "~w", [N]).
flow_w_node(_, _, _, X) :-
    throw(error(type_error(xml_node, X), flow_write_doc/3)).

flow_w_kids([], _, _, _).
flow_w_kids([K|Ks], S, Step, D) :-
    flow_w_node(S, Step, D, K),
    flow_w_kids(Ks, S, Step, D).

flow_w_lines([], _, _, _).
flow_w_lines([K|Ks], S, Step, D) :-
    flow_w_break(S, Step, D),
    flow_w_node(S, Step, D, K),
    flow_w_lines(Ks, S, Step, D).

%% element-only content, as library(xml) decides it: every child an element
flow_w_elements([]).
flow_w_elements([K|Ks]) :- nonvar(K), K = element(_, _, _), flow_w_elements(Ks).

flow_w_break(S, Step, D) :-
    W is Step * D,
    format(S, "~n~*c", [W, 0' ]).

%% an attribute is ONE format/3 when its value is a number or a short atom
%% with nothing to escape, which is nearly every one: the eight splits
%% of an escape, run on every value, made the translator's XML 211 M
%% inferences to write
flow_w_attrs([], _).
flow_w_attrs([A|As], S) :-
    (   A = (N = V) -> true
    ;   A = (N - V) -> true
    ;   throw(error(type_error(xml_attribute, A), flow_write_doc/3))
    ),
    (   number(V)
    ->  format(S, " ~a=\"~w\"", [N, V])
    ;   flow_w_value(V, V1),
        flow_w_esc_attr(V1, E),
        atom_length(E, L),
        (   L < 2000
        ->  format(S, " ~a=\"~a\"", [N, E])
        ;   format(S, " ~a=\"", [N]),
            flow_w_atom(S, E),
            format(S, "\"", [])
        )
    ),
    flow_w_attrs(As, S).

flow_w_value(V, V) :- atom(V), !.
flow_w_value(str(Cs), A) :- !, atom_codes(A, Cs).
flow_w_value(V, _) :- throw(error(type_error(xml_text, V), flow_write_doc/3)).

flow_w_text(S, A) :-
    flow_w_esc_text(A, E),
    flow_w_atom(S, E).

%% library(xml)'s escapes, `&' first so no later one is escaped again; one
%% split_string/4 first says whether there is anything to escape at all
flow_w_esc_text(A, E) :-
    (   split_string(A, "&<>", "", [_])
    ->  E = A
    ;   flow_w_repl(A, '&', '&amp;', A1),
        flow_w_repl(A1, '<', '&lt;', A2),
        flow_w_repl(A2, '>', '&gt;', E)
    ).

flow_w_esc_attr(A, E) :-
    (   split_string(A, "&<>\"'\n\r\t", "", [_])
    ->  E = A
    ;   flow_w_repl(A, '&', '&amp;', A1),
        flow_w_repl(A1, '<', '&lt;', A2),
        flow_w_repl(A2, '>', '&gt;', A3),
        flow_w_repl(A3, '"', '&quot;', A4),
        flow_w_repl(A4, '''', '&#39;', A5),
        flow_w_repl(A5, '\n', '&#10;', A6),
        flow_w_repl(A6, '\r', '&#13;', A7),
        flow_w_repl(A7, '\t', '&#9;', E)
    ).

flow_w_repl(A, From, To, B) :-
    atomic_list_concat(Ps, From, A),
    (   Ps = [_] -> B = A ; atomic_list_concat(Ps, To, B) ).

%% an atom of any length, in one format/3: through 1.10.5 `~a' copied its
%% text through an 8192-byte buffer, and this wrote a long one as codes in
%% pieces of 2000 (DESIGN-flow.md, section 11)
flow_w_atom(S, A) :-
    format(S, "~a", [A]).
