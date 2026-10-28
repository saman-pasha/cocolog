%  consult/1, load_files/2 and [File] as goals. Run by BOTH SWI-Prolog and
%  cocolog, output compared byte for byte; test/files.pl writes a.pl, b.pl,
%  d.pl and e.pl into the sandbox first.
%
%  Through 2.12 none of the three was a goal in cocolog: a program that
%  loaded a file at run time stopped at existence_error(procedure,
%  consult/1) (reported from cicili-lang, 2026-10-28).
%
%  WHAT IS LEFT OUT, because the two answer differently by design (STATUS.md,
%  2.13.0): a syntax error, after which swipl reads on and cocolog's consult
%  ends; must_be_module(true) of a file with no module header, which cocolog
%  has no headers to ask; and a file of a list that will not load, which both
%  report on stderr -- in its own order against stdout in each.

p(Name, G) :- catch((G -> R = yes ; R = no), error(F, _), R = raised(F)), format("~w: ~q~n", [Name, R]).

main :-
    p(missing, consult(nofile)),
    p(twice, (consult(a), consult(a), findall(X1, a(X1), L1), L1 == [1,2])),
    p(two_names, (consult('a.pl'), findall(X2, a(X2), L2), L2 == [1,2])),
    p(list, (consult([a,b]), b(x))),
    p(empty, consult([])),
    p(bracket, call([b])),
    p(bracket_list, call([a,b])),
    p(lf_plain, load_files(a, [])),
    p(lf_list, load_files([a,b], [])),
    p(lf_unknown_option, load_files(a, [bogus(1)])),
    p(lf_not_a_list, load_files(a, if(true))),
    p(lf_unbound_options, load_files(a, _)),
    p(lf_partial_options, load_files(a, [if(true)|_])),
    p(lf_improper_options, load_files(a, [if(true)|x])),
    p(unbound, consult(_)),
    p(number, consult(3)),
    p(compound, consult(foo(bar))),
    p(empty_atom, consult('')),
    p(directory, consult('.')),
    p(improper_files, consult([a|b])),
    p(lib, consult(library(lists))),
    p(lib_missing, consult(library(nosuch))),
    p(lf_exists_missing, load_files(nofile, [if(exists)])),
    p(lf_exists_compound, load_files(foo(bar), [if(exists)])),
    p(lf_exists_lib, load_files(library(nosuch), [if(exists)])),
    p(lf_not_loaded_missing, load_files(nofile, [if(not_loaded)])),
    p(lf_changed_missing, load_files(nofile, [if(changed)])),
    %  a file's directives run where they stand and its initialization/1
    %  after it is read, each time it is read; a load that skips it runs
    %  neither
    p(directives, consult(d)),
    p(directives_again, consult(d)),
    p(lf_not_loaded_d, load_files(d, [if(not_loaded)])),
    p(lf_changed_d, load_files(d, [if(changed)])),
    p(ensure_d, ensure_loaded(d)),
    %  [File] as a directive in a file loaded at run time
    p(directive_bracket, (consult(e), b(x))),
    %  a string is a file's name: "a" in swipl, and the code list cocolog's
    %  `codes' default reads it as
    p(string, consult("a")).
