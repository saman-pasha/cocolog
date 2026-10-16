%  A prefix operator written before its operand: where the writer puts a
%  space, with write/1 and writeq/1, and that the text reads back as the
%  same term. Run by BOTH systems, output compared byte for byte.
%
%  A DIGIT after `-' takes a space, because `-1' is the integer and not
%  `-' applied to 1; after every other symbolic prefix operator a number
%  follows with none (`+1', `\1', `\+1', `?-1'), as swipl writes them, and
%  reads back as the operator applied to it. Through cocolog 2.2.2 each of
%  those took a space too: `+ 1'. A symbol character after the operator
%  takes one by the ordinary rule (`- -1', `+ +1'), and so does an opening
%  parenthesis (`- (1+2)', `+ (+)'). Left out: write_canonical/1, which
%  keeps operators here and drops them in swipl (the dialect card's W1),
%  print/1, which does not quote here, and "1", a code list here and a
%  string there.

t(-(1)).        t(-(1.0)).      t(-(-1)).       t(-(-1.0)).     t(-(a)).
t(-(-(1))).     t(-(-(a))).     t(-(1+2)).      t(-(0.5)).      t(-(1^2)).
t(+(1)).        t(+(1.0)).      t(+(-1)).       t(+(a)).        t(+(+(1))).
t(+(1.0Inf)).   t(+(1.5NaN)).   t(+(-(1))).     t(+(-1.0Inf)).  t(+(1^2)).
t(+(+(+(1)))).  t(+([])).       t(+('1')).      t(+(f(1))).     t(+([1])).
t(\(1)).        t(\(-1)).       t(\(a)).        t(\(\(1))).     t(\(+(1))).
t(\(-(1))).     t(\+(1)).       t(\+(a)).       t(\+(-1)).      t(\+(\+(1))).
t(?-(1)).       t(:-(1)).       t(dynamic(1)).  t(discontiguous(a)).
t(f(-(1))).     t(f(+(1))).     t([-(1), +(1), \(1)]).
t(1 - (-(1))).  t(1 - (+(1))).  t(1 + (+(1))).  t(a = +(1)).    t(+(1) = a).
t(-(1.0e10)).   t(+(1.0e-5)).   t(+(123456789012345678)).
t(-(9223372036854775807)).      t(+(0'a)).
t((+(1))^2).    t((-(1))^2).    t((\(1))^2).
t(+(+)).        t(-(-)).        t(\(\)).        t(+(-)).        t(-(+)).

s(T) :-
    write(T), write('  '), writeq(T), write('  '),
    term_to_atom(T, A), term_to_atom(T2, A),
    ( T2 == T -> write(same) ; write(differs(T2)) ), nl.

main :- forall(t(T), s(T)).
