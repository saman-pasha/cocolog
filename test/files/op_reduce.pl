%  The reader's operators, shifted and reduced as swipl 9.0.4's (cocolog
%  3.62.0). Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  swipl's complex_term() keeps two stacks, the operators met and the
%  operands read. An INFIX operator first reduces every operator before it
%  whose priority is no more than its left argument's and whose own operands
%  fit, and is then pushed. A PREFIX operator is pushed whatever its
%  priority. Whether an operand is too big for its operator is asked when
%  the term ends. So:
%
%    - at one priority xfy against yfx reduces the first, `a => b <= c' is
%      (a => b) <= c, and yfx against xfy is a clash;
%    - a chain no priority lets read (`a = b = c') is operator_clash, its
%      place the operator the reduction stops at: its start where its left
%      operand is too big, its end where its right one is;
%    - an operator left with an operand missing when the term ends is
%      operator_balance -- punct(Op, End) where the one left is a comma or a
%      semicolon alone, operator_clash where one below it does not fit;
%    - A PREFIX OPERATOR'S ATOM BEFORE AN INFIX OPERATOR is the atom only
%      where the infix operator's left argument is above the prefix
%      operator's own argument: `- = a' and `x == - -> y' read, 200 under
%      699 and 1049. Where it is not, the infix operator's NAME is the
%      prefix operator's operand: `\+ =' is \+(=), and `x == dynamic -> y'
%      has `->' for dynamic's operand, so the y after it is
%      operator_expected. It wants its brackets, `x == (dynamic) -> y'.
%      A comma there is quoted_punctuation. Through 3.61.0 cocolog read a
%      prefix operator's atom as a right operand whatever followed;
%    - a token that will not read where it stands is reported before any
%      clash to its left;
%    - a prefix operator still waiting for its operand when the clause ends
%      inside a bracket has the full stop for its operand, which is no
%      term: end_of_clause (`( ff', `f(a = \+'). Outside a bracket the
%      full stop ends the term, and the operator is its atom.
%
%  Each text is read by term_to_atom/2: the term written canonically, ok_var
%  for one with a variable, or the error whole -- its id, the raw text read
%  and the place. Then the clauses of o1.pl (test/files.pl's fixture) are
%  consulted, a load's place for each error and what reads asked for, and
%  read again from a stream, each term with its subterm positions.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

:- op(700, xfy, =>).
:- op(700, yfx, <=).
:- op(200, xfy, ^^).
:- op(200, yfx, vv).
:- op(200, xfx, xx).
:- op(700, fy, ff).
:- op(700, fx, gg).
:- op(200, fy, pp).
:- op(400, fy, qq).
:- op(400, fx, rr).
:- op(1150, fx, zz).
:- op(1000, yfx, ww).
:- op(1100, yfx, uu).
:- op(1200, yfx, yy).

r(T) :-
    catch(( term_to_atom(X, T), ( ground(X) -> E = ok(X) ; E = ok_var ) ), E, true),
    write_canonical(r(T, E)), nl.

%  ---- one priority, both ways round ----
texts(one_priority, [
    'a => b <= c', 'a <= b => c', 'a => b => c <= d', 'a <= b <= c => d', 'a => b <= c => d',
    'a => b <= c <= d', 'a <= b => c <= d', 'a => b => c', 'a <= b <= c', 'a - b => c <= d + e',
    '1 ^^ 2 vv 3', '1 vv 2 ^^ 3', '1 ^^ 2 ^^ 3 vv 4', '1 vv 2 vv 3 ^^ 4', '1 xx 2 vv 3', '1 vv 2 xx 3',
    '1 xx 2 ^^ 3', '1 ^^ 2 xx 3', '1 xx 2 xx 3', '1 ^^ 2 vv 3 ^^ 4 vv 5', 'a ww b , c', 'a , b ww c',
    'a ww b ww c , d', 'a , b , c ww d', 'a uu b ; c', 'a ; b uu c', 'a ; b ; c uu d',
    'a uu b uu c ; d', 'f(a ww b , c)', '[a ww b , c]', '(a , b ww c)', '{a , b ww c}',
    'a :- b , c ww d', 'a :- b ww c , d' ]).

%  ---- a prefix operator and an infix one at its priority ----
texts(prefix_at_priority, [
    'pp a vv b', 'pp a ^^ b', 'pp a xx b', 'pp pp a vv b', 'pp a vv b vv c', 'pp a vv pp b',
    'ff a <= b', 'ff a => b', 'ff a = b', 'gg a <= b', 'gg a => b', 'gg a = b', 'ff ff a <= b',
    'ff gg a', 'gg ff a', 'gg gg a', 'gg a <= gg b', 'qq a * b', 'qq a + b', 'qq a ^ b', 'rr a * b',
    'rr a + b', 'rr rr a', 'qq rr a', 'rr qq a', '- a vv b', '- a ^^ b', '- a xx b', '\\ a vv b' ]).

%  ---- a prefix operator over the priority here ----
texts(prefix_over, [
    'a = \\+ b', 'a = \\+ b = c', 'a :- :- b', '- \\+ a', 'a = \\+ b c', 'a = zz b', 'f(a = \\+ b)',
    'a = \\+ b, c', 'a = \\+ b = c = d', 'a + \\+ b', 'a * - b', 'a ^ - b', 'a ** - b', '- - a',
    '- \\+ a = b', 'a = ff b', 'a = gg b', 'a <= ff b', 'a => ff b', 'ff a = ff b', '1 + qq 2',
    '1 * qq 2', '1 * rr 2', '1 ^ qq 2', 'qq 1 ^ 2', 'a = zz b = c', 'zz a = b', 'zz zz a', 'zz a zz b',
    'a , zz b', 'zz a , b', '[zz a, b]', 'f(zz a, b)', 'a :- zz b', ':- zz a', 'zz :- a',
    'a = \\+ \\+ b', 'a = \\+ b = \\+ c' ]).

%  ---- a prefix operator's atom ----
texts(prefix_atom, [
    '\\+ = a', 'zz ; a', ':- = a', '- = a', '\\+ =', '\\+ = = a', 'a , \\+ = b', '- , a', '\\+ , a',
    ':- , a', 'a = -', 'a = - .', '[-]', '[- , a]', 'f(-)', 'f(- , a)', 'f(:- , a)', '- -', '\\+',
    '- = - ', '- - = a', 'a = \\+', 'a = zz', '- zz', 'zz -', '\\+ - = a', 'ff = a', 'gg = a',
    'pp vv a', 'pp ^^ a', 'qq * a', 'f(- = a)', '[- = a]', '(- = a)', '{\\+ = a}', '- = a = b',
    '\\+ = a = b', 'a = - = b', 'a + - * b', 'a * - + b', 'a ** - , b', 'a ^ - , b', 'a = zz , b',
    'a = - , b', 'a = \\+ , b', '- * a', '- * a + b' ]).

%  ---- brackets and what ends each ----
texts(brackets, [
    '(a = b = c) = d', 'a = (b = c = d)', '[a = b = c]', '[a|b = c = d]', '[a = b = c|d]',
    '{a = b = c}', 'f(a = b = c, d)', 'f(a, b = c = d)', '(a = b = c]', '{a = b = c)', 'f(a = b = c]',
    '[a = b = c)', '[a = b = c}', '(a = b = c}', 'f(a = b = c}', '[x|a = b = c, d]', '[x|a, b]',
    '[x|a = b = c | d]', '[a = b = c, d = e = f]', 'f(a = b = c) = d = e', 'f((a = b = c))',
    'f([a = b = c])', '[f(a = b = c)]', 'a = b = f(c = d = e)', 'a = f(b = c = d) = e', '(a = b = c',
    'f(a = b = c', '[a = b = c', '{a = b = c', '(a = b) = (c = d) = e', 'a = (b) = c', '- (a = b = c)',
    '\\+ (a = b = c)', 'f(a = b = c , )' ]).

%  ---- a trailing operator ----
texts(trailing, [
    'a + b, c *', 'a * b +', 'a - b * ', 'a = b + ', '- a +', '\\+ a =', 'a , \\+ b =', 'a :- b, c *',
    'a :- b :- c ,', 'a = b , c = d =', 'a , b = c =', 'a = b = c ,', 'a ; b = c = d ;', 'f(a = b =)',
    '[a = b =]', '(a = b =)', '{a , b ;}', 'f(a , b +)', '[a , b + ]', '[a | b +]', 'a + b * c -',
    'a * b + c *', 'a + b + c *', 'a , b , c *', 'a * b , c , ', 'a = b * c +', 'a + b = c *',
    '- a * b +', 'a :- b ,', 'a :- b ;', 'a --> b ,', ':- a ,', '\\+ a , b ;', 'a => b <=',
    'a <= b =>', 'a ww b ,', 'a , b ww', 'pp a vv', 'a ^^ b vv', 'a vv b ^^', 'a => b , c <=',
    'zz a ,', 'zz a = b ,', 'a = zz b ,' ]).

%  ---- a token that will not read comes first ----
texts(token_first, [
    'a = b = c (', 'a = b = c "x', 'a = b = c 1', 'a = b = c X', 'a = b = c [', 'a = b = c {',
    'a = b = c d', 'a = b = (c d)', 'a = b = f(c d)', 'a = b = [c d]', 'a = b = c = (d',
    'a = b = c , d e', 'a = \\+ b (c)', 'f(a = b = c d)', '[a = b = c d]', 'a = b = c = 0\'',
    'a = b = c = "x', 'a = b = c , ]', 'a = b = c )', 'a = b = c ]', 'a = b = c }',
    'f(a = b = c , d e)', 'a = b = c . d', 'a = b = \'c', 'a = b = 1 2' ]).

%  ---- chains of other shapes ----
texts(chains, [
    'a :- b :- c', 'a = b :- c :- d', 'a = b = c :- d', 'a :- b = c = d', 'a = b :- c = d = e',
    'a :- b :- c = d = e', 'a --> b --> c', 'a = b --> c = d = e', 'a = b = c --> d', 'a < b = c > d',
    'a is b = c', 'a = b is c', 'a = b = c is d is e', 'a = b , c = d = e , f = g = h',
    'a = b ; c = d = e', 'a = b -> c = d = e ; f', 'a = b = c -> d ; e', '(a = b = c -> d ; e)',
    'a = b = c | d', 'a | b = c = d', 'a ** b ** c', 'a ^ b ** c', 'a ** b ^ c', 'a ** b ^ c ^ d',
    'a ^ b ^ c ** d', '- a ** b', 'a ** - b ** c', '1 - 2 = 3 - 4 = 5', '1 = 2 - 3 = 4 - 5',
    'a : b = c : d = e', 'a = b : c = d', '\\+ a = b = c', '\\+ \\+ a = b = c', '- a = b = c',
    'a = - b = c', 'a = b = - c', '- - a = - b = c', 'a = b = c = d = e' ]).

%  ---- what reads, as it did ----
texts(reads, [
    'a :- b , c ; d -> e', '1 + 2 * 3 - 4', '\\+ \\+ a', '- a ^ b', '- 1 ^ 2', 'a ^ b ^ c',
    'a - b - c', 'a = b , c = d', 'f(a :- b)', '[a :- b, c]', '- (a)', '-(a, b)', '\\ a', '1 - -1',
    'a- -b', 'a - - b', 'a :- \\+ b , c', ':- dynamic a/1, b/2', ':- a , b', '?- a',
    'a --> b , {c} , d', 'X is 1 + 2 * 3', 'a = b * c + d * e - f', 'a ; b -> c ; d', '(a , b)',
    'a | b', '(a | b)', '[a | b]', '- - - a', '\\ - a', '1 - 2 - 3', 'a : b : c', 'a : b : c = d',
    'f(a , b)', 'f(a ; b)', '[a , b | c]', 'a * (b + c)', '(a + b) * c', 'a rdiv b', 'a rem b mod c',
    'a // b / c', 'a >> b << c', '- a + b', '- a * b', '- (a * b)', '\\+ a , b', 'a , \\+ b , c',
    '\\+ a = b', 'a = b + c * d ^ e', 'a ^ b * c + d = e', 'a :- b -> c ; d', 'a :- b *-> c ; d',
    'a , b ; c , d', 'a ; b , c ; d', 'a -> b , c -> d', 'x = (a :- b)', 'x = (a , b)', 'x = [a , b]',
    'x = {a , b}', 'x = \'=\'(a , b)', 'f(- 1)', 'f(-1)', 'f(- a)', 'f(-(1))', '-(-(1))', '- (1)',
    '-(1)', '1 - 1', '1 -1', '1 - - 1', 'a - -1', 'dynamic a , b', 'zz (a , b)', ':- zz a , b' ]).

%  ---- chains of one operator, and a comma with nothing after it ----
texts(chains_commas, [
    'a :- b :- c :- d', 'a :- b :- c :- d :- e', 'a :- b :- c :- d :- e :- f', 'a = b = c',
    'a = b = c = d', 'a = b = c = d = e = f', 'a < b < c < d', 'a = b < c = d', 'a < b = c < d = e',
    'a :- b = c = d = e', 'a = b = c :- d :- e', 'f(a = b = c = d)', '[a = b = c = d]',
    '(a = b = c = d)', '{a = b = c = d}', 'f(x, a = b = c = d)', '[x|a = b = c = d]',
    '- a = b = c = d', 'a = b = c + d', 'a = b = c + d = e', 'a + b = c = d = e',
    'a =.. b =.. c =.. d', '\\+ a = b = c = d', 'a == b == c == d == e == f', '1 = 2 = 3 = 4',
    'a = (b = c) = d = e', 'a is b is c is d', 'a --> b --> c --> d', 'a :- b --> c :- d',
    'a --> b :- c --> d', 'a = b, c = d = e, f', 'a = b = c, d', 'a, b = c = d', 'a, b = c = d = e',
    'a = b ; c = d = e = f', 'a = b -> c = d = e', 'a = b = c = d.', 'a = b = c = d .',
    'a  =  b  =  c  =  d', 'x :- a = b = c', 'x :- a = b = c = d', 'x :- y :- a = b = c = d',
    'a ?- b ?- c', ':- a :- b', ':- a :- b :- c', ':- :- a', 'dynamic a dynamic b',
    'dynamic dynamic a', 'a = b = c = d = ', 'a = b = c = d )', 'a = b = c = d e', 'a = b = c d = e',
    'a < b < c', 'a < b < c < d < e', 'a @< b @< c @< d', 'a >= b >= c >= d', 'a \\= b \\= c \\= d',
    'a : b : c : d', 'a ^ b ^ c ^ d', 'a - b - c - d', 'a mod b mod c', 'a ** b ** c ** d',
    'a -> b -> c', 'a = b -> c = d -> e = f = g', 'a rem b = c = d = e', 'a, b,', 'a,', 'a, b, c,',
    'a, b, c, d,', 'f(a, b,)', 'f(a,)', '[a, b,]', '[a,]', '(a, b,)', '(a,)', '{a, b,}', '{a,}',
    'a, b, ', 'a , b , . ', 'a :- b, c,', 'a :- b,', 'a ; b,', 'a -> b,', 'a, b ;', 'a, b |', 'a | b,',
    'a, b, c ,d,', 'a, b,.', 'a, b ,.', 'a,.', 'a, b, )', 'a, b, ]', 'f((a, b,))', 'a, b, c', 'a, , b',
    'a, b, , c', ', a, b', 'a ,, b', 'a, b,, ', 'a; b;', 'a; b; c;', 'a | b |', 'a -> b ->',
    'a :- b :-', 'a = b =', 'a = b = c =', 'a + b +', 'a + b + c +', 'a - b -', 'a * b *', 'a, b +',
    'a + b ,', 'a + b, c +', 'a, b, c + ', '- a,', '\\+ a,', '\\+ a, b,', 'a, \\+', 'a, b, \\+',
    'a, b, -', 'a, b, - ,', 'a, b, f(', 'a, b, [', 'a:b:c,', 'a,b:c,', 'f(a) :- b, c, d,' ]).

%  ---- mixed again ----
texts(mixed, [
    'a = b , c <= d => e' ]).

%  ---- a prefix operator's atom before an infix operator that does not take it ----
texts(prefix_atom_looser, [
    'a == dynamic -> b ; c', '( a == dynamic -> b ; c )', 'a == dynamic , b',
    '( Kind == dynamic -> SP = any, Det = nondet ; x )', 'a == (dynamic) -> b ; c',
    'a == (=), b =:= 2 -> c', '( N == (=), A =:= 2 -> Kind = unify ; x )', 'x == dynamic',
    'x = dynamic -> y', 'x == - -> y', 'x == \\+ -> y', 'f(dynamic -> y)', 'dynamic -> y',
    'dynamic = y', '- = y', '\\+ = y', 'x == dynamic = y', 'x , dynamic -> y', 'x , dynamic , y',
    'x == dynamic ; y', 'x == dynamic | y', '[dynamic|y]', '[dynamic,y]', 'x == table -> y',
    'x == discontiguous -> y ; z', 'x = zz -> y', 'x = zz :- y', 'x = \\+ :- y', 'x :- dynamic :- y',
    'x = \\+ , y', 'x = \\+ -> y', 'x = \\+ ; y', 'x = \\+ = y', 'x = \\+ < y', 'x = \\+ + y',
    'x = - + y', 'x = - * y', 'x = - ^ y', 'x = - : y', 'x = $ , y', 'x = $ = y', 'x = $ : y',
    'f(dynamic, y)', 'f(dynamic = y)', 'f(x = dynamic, y)', '[x = dynamic, y]', '[x = dynamic | y]',
    '{x = dynamic , y}', '{x = dynamic}', '(x = dynamic)', '(x = dynamic) , y', 'x = dynamic',
    'x = (dynamic) , y', 'x = \'dynamic\' , y', 'x :- y = dynamic', 'x :- y = dynamic , z', 'dynamic',
    'dynamic ,', '- ,', 'x = - ,', 'x = dynamic ,', 'x = dynamic =', 'x = - =', 'x = dynamic dynamic',
    'x = dynamic - ', 'x = dynamic -', 'x = - dynamic', 'x = - dynamic , y', 'dynamic dynamic , y',
    '\\+ dynamic , y', '\\+ \\+ , y', '\\+ - , y', '- \\+ , y', '- - , y', '- - = y', '\\+ \\+ = y',
    'x = y = dynamic', 'x = y = dynamic , z', 'x = y = - , z',
    'dynamic ; a', 'a = b = dynamic ; c', 'x :- y == multifile -> a ; b' ]).

%  ---- an operator at the top priority, a prefix operator's clash further in, and operators left over one ----
texts(more, [
    'a yy b', 'a yy b yy c', 'a :- b yy c', 'a yy b :- c', 'x yy y , z', '(a yy b) yy c', 'f(a yy b yy c)',
    'gg <= a', 'gg => a', 'rr * a', 'rr ** a', 'a + - \\+ b', 'f(- \\+ a)', 'x = - \\+ a', '[- \\+ a]',
    'a , gg b =', 'a , gg b <=', 'a , zz b =', 'a ; gg b =', 'a , b = c <=', 'a , gg b = c', 'a , rr b *',
    'a , \\+ b =', 'a , - b ^', 'gg a = b =', 'a = b , c = d = e', 'a = b , c = d =', 'a , b = c = d ,' ]).

%  a clash at the operator the text ends on: placed at that operator, with
%  a space after it and without, never at the full stop the reader adds
texts(ends_on_operator, [
    'a , rr b * ', 'f(a , rr b *)', 'a , rr b *c', 'a , gg b =>', 'a , gg b xx', 'a , rr b xx',
    'a = b <=', 'a = b <= c', 'gg a = b', 'a = gg b', 'a = gg b =', 'x , a = gg b =',
    'a xx b xx', 'a xx b xx c', '- - a xx b xx', 'a , b xx c xx', 'a , b = c =', 'a , b = c = d',
    'a = b =', 'a , b * c <=', 'a , b * c <= ', '[a , rr b *]', '{a , rr b *}', '(a , rr b *)',
    'a :- b , rr c *', 'a , ff b =>', 'a , ff b <=', 'a , - b vv', 'a , - b ^^', 'a , qq b *',
    'a , qq b * ', 'a , rr b * .', 'a , rr b *.',
    'x , a = gg b xx', 'a <= b , c <=', 'a = b , c =', 'a => b , c =>', 'a <= b <= c <=',
    'a , b <= c <= d <=', 'x = a , gg b xx', 'gg a xx b ,', 'a , gg ff b =', 'a ; b , c = d =' ]).

%  a prefix operator still waiting for its operand when the clause ends
%  inside a bracket: the full stop ends no bracket's term, so it is the
%  operand, and no term -- end_of_clause. Outside a bracket the full stop
%  ends the term and the operator is its atom
texts(clause_ends_in_bracket, [
    '( ff', 'f(a = \\+', '[ -', '{ dynamic', '( a , \\+', 'f(dynamic', '[a|\\+', '( - -', '( ff =',
    '( ff )', '( gg', 'f(-', '[\\+', '{ \\+', '( a = ff', '(ff', 'f((- )', 'f((-)', '( a', 'f(a', '[a', '{a',
    '( a =', 'f(a =', '[a =', '{a =', 'ff', 'a = ff', 'dynamic', '- -', '( rr uu { :-', '$ ( ff $',
    '( \\ table -', '[ $ - +', 'f(f(; xx ?- +', '{ { = - \\+ -', '( a , - b , \\+', '[a, b | -',
    'f(a, - )', '[a, - ]', '{ - }', '( - )', 'f(- , a)', '[- , a]', '[- | a]', '( - , a )' ]).

main :-
    forall(texts(_, L), forall(member(T, L), r(T))),
    loads('o1.pl', [o1a(_), o1p, o1r, o1zz(_)]),
    shows([o1t(_), o1u(_), o1w(_), o1y(_, _)]),
    reads('o1.pl').

%  a load: the place of each error, and the clauses either side of them
loads(F, Goals) :-
    catch(consult(F), E, ( print(raised(E)), nl )),
    flush_output,
    findall(G, ( member(G, Goals), catch(clause(G, _), _, fail) ), L),
    print(F-L), nl, flush_output.

shows(Heads) :-
    forall(member(H, Heads),
           forall(catch(clause(H, B), _, fail), ( write_canonical((H :- B)), nl ))).

%  the same clauses from a stream: every term and every error
reads(F) :-
    open(F, read, S),
    read_all(S),
    close(S).

read_all(S) :-
    catch(read_term(S, T, [subterm_positions(P)]), E, T = '$error'(E)),
    (   T == end_of_file -> true
    ;   T = '$error'(E0) -> write_canonical(raised(E0)), nl, read_all(S)
    ;   ( ground(T) -> write_canonical(T) ; write(var) ), nl,
        write_canonical(P), nl, read_all(S)
    ).
