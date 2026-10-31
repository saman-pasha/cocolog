%  The operator table, as swipl 9.0.4 has it (cocolog 3.2.0). Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  Every operator either system defines at the start, sorted by name, then
%  priority, then type -- all but one: swipl's `.' at 100 yfx, the dicts'
%  operator, which cocolog has no dicts for. Through 3.1.0 cocolog lacked
%  `|' (1105 xfy), `:=' (800 xfx), `as', `:<' and `>:<' (700 xfx), `$' (1
%  fx) and seven of swipl's eleven declarations at 1150 fx, and had `xor' at
%  500 where swipl has it at 400.

main :-
    findall(N-P-T, ( current_op(P, T, N), N \== '.' ), L0),
    msort(L0, L),
    forall(member(N-P-T, L), ( writeq(op(P, T, N)), nl )).
