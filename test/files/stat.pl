%  The Files library: size, time, links and temporaries. Run under BOTH
%  SWI-Prolog and cocolog in the same fresh directory, output compared.
%
%  NOTHING HERE PRINTS A VALUE THAT VARIES BETWEEN RUNS. A modification time
%  and a temporary file name differ every time and between the two systems, so
%  what is written is what can be checked about them -- their type, and how
%  they compare with each other -- rather than the values themselves.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    %  A file of a known size, made without any writing predicate: a directory
    %  is not a file, so the size has to come from somewhere both systems can
    %  make. `expand_file_name' on a pattern that matches nothing is the only
    %  side-effect-free thing here, so the file is made by the harness instead
    %  and this program only measures it.
    yn(exists_file('five.txt'), fixture_present),
    size_file('five.txt', N1), s(size, N1),
    yn(integer(N1), size_is_integer),

    size_file('empty.txt', N2), s(empty_size, N2),

    time_file('five.txt', T1),
    yn(float(T1), time_is_float),
    yn(T1 > 0.0, time_is_positive),

    %  a symbolic link, also made by the harness
    yn(exists_file('link.txt'), link_looks_like_a_file),
    yn(same_file('five.txt', 'link.txt'), link_is_the_same_file),
    yn(same_file('five.txt', 'empty.txt'), different_files),
    read_link('link.txt', L1, _T2), s(link_target, L1),

    %  deleting
    delete_file('empty.txt'),
    yn(exists_file('empty.txt'), deleted),

    %  a temporary name is an atom, is absolute, and is not the same twice
    tmp_file(probe, F1), tmp_file(probe, F2),
    yn(atom(F1), tmp_is_atom),
    yn(is_absolute_file_name(F1), tmp_is_absolute),
    yn(F1 == F2, tmp_repeats),
    %  and it is a NAME: nothing has been created there
    yn(exists_file(F1), tmp_exists_already),
    true.
