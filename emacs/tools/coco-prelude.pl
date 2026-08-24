%% coco-prelude.pl -- what the engine's library has and cocolog's vendored
%% dcg/basics does not, copied VERBATIM from `cocolog-library-source' in
%% cocolog-engine.el so that `make coco' asks cocolog the same rules the
%% engine runs.  Nothing else belongs here: a rule both sides already
%% carry would shadow cocolog's own on consult.

csym(Name, Head, Tail) :- nonvar(Name), !, atom_codes(Name, Cs), append(Cs, Tail, Head).
csym(Name) --> [F], { csymf_code(F) }, csyms(Rest), { atom_codes(Name, [F|Rest]) }.
csyms([C|T]) --> [C], { csym_code(C) }, !, csyms(T).
csyms([]) --> [].
csymf_code(C) :- C >= 97, C =< 122.
csymf_code(C) :- C >= 65, C =< 90.
csymf_code(95).
csym_code(C) :- csymf_code(C).
csym_code(C) :- C >= 48, C =< 57.
