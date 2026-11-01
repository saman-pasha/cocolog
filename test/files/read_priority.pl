%  The reader's priorities, as swipl 9.0.4's (cocolog 3.2.0). Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  AN ARGUMENT, A LIST ELEMENT AND A CURLY TERM ARE READ TO 1200, stopping at
%  their comma -- and a list element at its bar too: swipl's reader, not
%  ISO's 999. So f(a :- b) and [a :- b] read, and a prefix operator applies
%  inside an argument as it does anywhere, f(dynamic - 1) being
%  f(dynamic(-1)).
%
%  A PREFIX OPERATOR'S ATOM, read as a plain atom because what follows it
%  begins no term, is a LEFT operand only where its priority fits: `- = a'
%  reads (200 under 699), `\+ = a' and `dynamic ; a' do not (900 and 1150),
%  and `\+ -> a' does (under 1049). Quoted or bracketed it is priority 0,
%  and a right operand, an argument or an element takes any atom. Before an
%  infix bar it is refused whatever its priority, as swipl's is.
%
%  Each text is read by term_to_atom/2 and written canonically, or `refused'
%  for a syntax error: the error's class is not compared (swipl names some
%  of these operator_clash or quoted_punctuation where cocolog says
%  operator_expected).

t(S) :-
    write(S), write('  =>  '),
    catch(( term_to_atom(T, S), write_canonical(T) ),
          error(syntax_error(_), _), write(refused)),
    nl.

main :- forall(text(S), t(S)).

%  ---- arguments, elements and curly terms to 1200 ----
text('f(a :- b)').
text('f(a :- b, c)').
text('f(a, b :- c)').
text('f((a :- b))').
text('[a :- b]').
text('[a :- b, c :- d]').
text('[a :- b | c]').
text('[a, b :- c | d]').
text('{a :- b}').
text('f({a :- b})').
text('f({a , b})').
text('[{a | b}]').
text('f(:- a)').
text('[:- a]').
text('f(?- a)').
text('f(a , b)').
text('f((a , b))').
text('[(a , b)]').
text('{a , b}').
text('f(a ; b)').
text('f(a -> b ; c)').
text('f(a = b, c)').
text('[a | b]').
text('[a, b | c]').
text('f(a | b)').
text('[(a | b)]').
text('{a | b}').
text('[a | b | c]').
text('[a | b, c]').
text('f(a :- b :- c)').

%  ---- a prefix operator inside an argument ----
text('f(dynamic a)').
text('f(dynamic - 1)').
text('f(dynamic-1-nondet)').
text('[dynamic - 1]').
text('f(- 1)').
text('f(- (1))').
text('f(- a)').
text('- (a , b)').
text('f(\\+ a, b)').

%  ---- a prefix operator's atom as a left operand ----
text('- = a').
text('+ = a').
text('$ = a').
text('- * 2').
text('- mod a').
text('- - = a').
text('\\+ = a').
text('(\\+) = a').
text('\'\\\\+\' = a').
text('\\+ -> a').
text('\\+ ; a').
text('\\+ * 2').
text('\\+ , a').
text('a :- \\+, b').
text('dynamic = a').
text('(dynamic) = a').
text('\'dynamic\' = a').
text('f(dynamic = a)').
text('[dynamic = a]').
text('{dynamic = a}').
text('dynamic -> a').
text('dynamic ; a').
text('dynamic , a').
text('a :- dynamic, b').
text('table = a').
text('public , a').
text(':- = a').
text('?- = a').
text('dynamic is 1').
text('f(a, \\+ = b)').

%  ---- an infix operator's atom, and a right operand: no priority ----
text('mod = a').
text('is = a').
text('= = a').
text('a = \\+').
text('a = dynamic').
text('a = -').
text('f(a :- dynamic)').
text('a = dynamic = b').

%  ---- an argument and an element take any atom ----
text('f(dynamic)').
text('f(dynamic, a)').
text('f(\\+)').
text('f(- , a)').
text('[\\+ , a]').
text('[dynamic|a]').
text('[a|dynamic]').
text('{dynamic}').
text('- dynamic').
text('dynamic dynamic').

%  ---- and before an infix bar, at any priority ----
text('- | a').
text('f(- | a)').
text('x(\\+ | a)').
text('f(dynamic | a)').
text('[- | a]').
text('[\\+ | a]').
text('(a | b)').
