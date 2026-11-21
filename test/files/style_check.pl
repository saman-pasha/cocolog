%  style_check/1 (cocolog 3.67.0), swipl 9.0.4's: boot/syspred.pl's
%  clauses over '$style_check'/2, the word of style checks -- 202 at the
%  start, singleton (66: the reader's 2 and the compiler's 64),
%  discontiguous (8) and no_effect (128) on, charset (32) and var_branches
%  (256) off --, its errors, and what a load says under each style: the
%  word is the file's, put back when its read ends, and an included
%  file's is its includer's. And the three collectors swipl has, each
%  true. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; the fixtures are test/files.pl's `sc/2'. A name past ASCII
%  (charset) is test/directives.pl's, its text the locale's in swipl.

q(G) :- catch((G -> R = yes ; R = no), error(F, _), R = ex(F)), print(R), nl.

word(Tag) :- '$style_check'(W, W), print(Tag-W), nl.

main :-
    word(start),
    %% ?(Style) walks the styles on, `atom' saying it has no effect as the
    %% walk passes it
    forall(style_check(?(S)), ( print(on(S)), nl )),
    q(style_check(?(singleton))), q(style_check(?(var_branches))),
    q(style_check(?(nope))), q(style_check(?(atom))),
    %% the errors: an unbound spec, one no flag, a name no style
    q(style_check(_)), q(style_check(foo)), q(style_check(+foo)),
    q(style_check(-(1))), q(style_check(charset)),
    q(style_check([+singleton, bar])), q(style_check([?(nope)])),
    %% a list each in turn; its ?(Name) that fails is the list's type error
    q(style_check([+var_branches, ?(var_branches)])), word(vb_on),
    q(style_check([-var_branches, -singleton])), word(off),
    q(style_check([?(singleton)])), word(still_off),
    q(style_check(+singleton)), word(back),
    q(style_check(+atom)), word(atom), q(style_check(-atom)), word(no_atom),
    %% the word itself: an integer a C int holds, or nothing set
    q('$style_check'(_, foo)), q('$style_check'(_, 4294967296)), q('$style_check'(_, 1.0)),
    q('$style_check'(5, 5)), q('$style_check'(_, -1)), word(all), q('$style_check'(_, 202)),
    %% a load says what its style leaves on, and puts the word back after
    consult(sc_w), word(after_w),
    consult(sc_inc), word(after_inc),
    consult(sc_nest), word(after_nest),
    %% a load begins in the style a goal left
    q(style_check(-singleton)), consult(sc_inc), word(begun_off), q(style_check(+singleton)),
    %% the collectors
    q(garbage_collect_atoms), q(garbage_collect_clauses), q(trim_stacks).
