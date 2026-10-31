%  A body's bar holds goals, as swipl 9.0.4's load holds it to (cocolog
%  3.2.0). Run by BOTH SWI-Prolog and cocolog, output (stdout and stderr)
%  compared byte for byte.
%
%  `p :- (a | 1).' is refused where it stands -- `Type error: `callable'
%  expected, found `a|1' (a compound)', the whole body named -- and the load
%  goes on, as for a body whose `;' holds a number (3.1.0). The bar is the
%  disjunction under `,', `;', `->', `*->', `\+' and another bar, so a
%  number anywhere along that spine is no goal. Through 3.1.0's reader the
%  bar was `;' and refused as one; 3.2.0's first cut read '|'/2 and let the
%  walk take it for a goal, storing `bad1 :- (a ; 1)'.

bad1 :- (a | 1).
bad2 :- \+ (b | 2).
bad3 :- (x , y | 3).
bad4 :- (fail ; (c | 4)).
good :- (fail | true).

main :-
    forall(member(P, [bad1/0, bad2/0, bad3/0, bad4/0, good/0]),
           (   current_predicate(P) -> writeq(P-defined), nl
           ;   writeq(P-none), nl
           )),
    ( good -> writeln(good_runs) ; writeln(good_fails) ).
