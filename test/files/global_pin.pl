%  A ground global as swipl 9.0.4 keeps it: one term, older than every
%  choice point made after its nb_setval/2, which nb_setarg/3 writes for
%  good and setarg/3 until backtracking. Run by BOTH systems, output
%  compared byte for byte.
%
%  cocolog hands out a ground global as a copy the machine keeps (1.12.1,
%  `coco_b_global_term'), made where the global is first read -- so
%  backtracking can take it, and a read after that copies again -- and an
%  nb_setarg/3 into a copy pins every copy the machine holds, out of
%  backtracking's reach. Through 3.78.15 the pin took the copies
%  backtracking had already taken too: a global read before a failure, and
%  read again after a switch's nb_setarg/3, was whatever term stood where
%  its copy had been -- the switch's own copy, an environment's goal
%  (written `<?>'), a continuation frame (the reasoning session's report:
%  `memberchk(class, <?>)'). And a collection dropped the undo of a
%  setarg/3 into a copy, or of a b_setval/2 box made, after a choice point,
%  which a freeze after the collection kept past that choice point: the
%  write outlived the failure it should have ended with. garbage_collect/0
%  makes the collection here; test/engine.pl runs the file under a
%  collector that runs every 2000 cells too.

pr(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

init :- nb_setval(cls, [a, b, class, c]), nb_setval(sw, s(off)), nb_setval(rec, r(1, [x], z)).
cls(Tag) :- nb_getval(cls, L),
    ( catch(memberchk(class, L), _, fail) -> pr(Tag-yes(L)) ; pr(Tag-no(L)) ).
switch(V) :- nb_getval(sw, S), nb_setarg(1, S, V).

%% THE PIN TAKES ONLY A COPY THAT STANDS: the class list read and taken
%% by a failure, a \+, findall/3's end, a throw and forall/2's search
t(p1) :- init, ( nb_getval(cls, L0), memberchk(class, L0), fail ; true ),
    switch(on), cls(p1), nb_getval(sw, S), pr(p1-S).
t(p2) :- init, \+ \+ nb_getval(cls, _), switch(on), cls(p2).
t(p3) :- init, findall(x, nb_getval(cls, _), _), switch(on), cls(p3).
t(p4) :- init, catch((nb_getval(cls, _), throw(x)), x, true), switch(on), cls(p4).
t(p5) :- init, forall(member(_, [1, 2]), nb_getval(cls, _)), switch(on), cls(p5).
%% a copy that stands is pinned beside one that does not
t(p6) :- init, nb_getval(rec, R0), pr(p6-R0),
    ( nb_getval(cls, _), fail ; true ),
    switch(on), cls(p6), nb_getval(rec, R), pr(p6-R), nb_getval(sw, S), pr(p6-S).
%% a reasoner's turns: the list read and the switch set in each
t(p7) :- init,
    ( between(1, 3, I), nb_getval(cls, L), memberchk(class, L),
      switch(on), nb_getval(sw, S), pr(p7-I-S), fail
    ; true ),
    cls(p7), nb_getval(sw, S2), pr(p7-S2).
%% the switch's own copy taken, then written
t(p8) :- init, ( nb_getval(sw, _), fail ; true ),
    switch(on), nb_getval(sw, S), pr(p8-S), cls(p8).
%% the switch written twice
t(p9) :- init, ( nb_getval(cls, _), fail ; true ),
    switch(on), switch(off), cls(p9), nb_getval(sw, S), pr(p9-S).
%% a fresh term built where a taken copy stood: no copy of a global
t(p10) :- init, ( nb_getval(cls, _), fail ; true ),
    functor(T, f, 2), nb_setarg(1, T, x), pr(p10-T), cls(p10).

%% A WRITE INTO A GLOBAL'S STAND-IN IS UNDONE ACROSS A COLLECTION: a
%% setarg/3 into a copy, and a b_setval/2's box, made after the \+'s
%% choice point, a collection, then a freeze -- the switch's pin, or an
%% nb_setarg/3 on an older term
t(c1) :- init, \+ \+ ( nb_getval(rec, R), setarg(1, R, 2), garbage_collect, switch(on) ),
    nb_getval(rec, R2), pr(c1-R2), nb_getval(sw, S), pr(c1-S).
t(c2) :- init, \+ \+ ( b_setval(bk2, v1), garbage_collect, switch(on) ),
    ( nb_current(bk2, V) -> pr(c2-V) ; pr(c2-none) ).
t(c3) :- functor(T, f, 1), nb_setarg(1, T, x),
    \+ \+ ( b_setval(bk3, v1), garbage_collect, nb_setarg(1, T, y) ),
    ( nb_current(bk3, V) -> pr(c3-V) ; pr(c3-none) ), pr(c3-T).
%% a box made before the choice point, written inside it
t(c4) :- init, b_setval(bk4, v0), \+ \+ ( b_setval(bk4, v1), garbage_collect, switch(on) ),
    b_getval(bk4, V), pr(c4-V).
%% the pin before the write
t(c5) :- init, \+ \+ ( switch(on), nb_getval(rec, R), setarg(1, R, 2), garbage_collect ),
    nb_getval(rec, R2), pr(c5-R2).
%% two writes, a choice point between them, each undone at its own
t(c6) :- init,
    \+ \+ ( nb_getval(rec, R), setarg(1, R, 2),
            \+ \+ ( setarg(1, R, 3), garbage_collect, switch(on),
                    nb_getval(rec, R3), pr(c6-R3) ),
            nb_getval(rec, R4), pr(c6-R4) ),
    nb_getval(rec, R5), pr(c6-R5).
%% the class list written, collected and pinned: its read after
t(c7) :- init, \+ \+ ( nb_getval(cls, L), setarg(1, L, q), garbage_collect, switch(on) ),
    cls(c7).

main :-
    forall(member(N, [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, c1, c2, c3, c4, c5, c6, c7]),
           ( catch(t(N), E, (pr(N-raised(E)), fail)) -> true ; pr(N-failed) )).
