%  The Files library: names only -- nothing here touches the file system.
%
%  THIS FILE IS RUN BY BOTH SWI-PROLOG AND COCOLOG AND THEIR OUTPUT COMPARED,
%  so it may use only what both have. That rules out findall/3, member/2,
%  format/2 and the rest of SWI's library, and it rules out printing a compound
%  term: cocolog's writer spaces operators differently from SWI's, so `A-B'
%  would differ on formatting alone and say nothing about the library.
%  Every value is therefore written on a line of its own.

s(Label, Value) :- write(Label), write(=), write(Value), nl.

yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    file_base_name('/a/b/c.txt', A1), s(base_slash, A1),
    file_base_name('/a/b/', A2), s(base_trailing, A2),
    file_base_name('/', A3), s(base_root, A3),
    file_base_name(abc, A4), s(base_bare, A4),
    file_base_name('a/b', A5), s(base_relative, A5),

    file_directory_name('/a/b/c', B1), s(dir_absolute, B1),
    file_directory_name(abc, B2), s(dir_bare, B2),
    file_directory_name('/abc', B3), s(dir_root, B3),
    file_directory_name('/a/b/', B4), s(dir_trailing, B4),
    file_directory_name('a/b/c', B5), s(dir_relative, B5),

    %  splitting
    file_name_extension(C1, C2, 'a/b.txt'), s(split_base, C1), s(split_ext, C2),
    file_name_extension(D1, D2, 'a.b.c'), s(multi_base, D1), s(multi_ext, D2),
    file_name_extension(E1, E2, noext), s(none_base, E1), s(none_ext, E2),
    %  a dot in a DIRECTORY component is not an extension
    file_name_extension(F1, F2, '/a/b.d/c'), s(dirdot_base, F1), s(dirdot_ext, F2),
    %  a leading dot IS an extension separator in SWI, which is not what
    %  anyone guesses -- this line is why the tests are run against both
    file_name_extension(G1, G2, '.bashrc'), s(dotfile_base, G1), s(dotfile_ext, G2),
    file_name_extension(G3, G4, '/a/.bashrc'), s(dotpath_base, G3), s(dotpath_ext, G4),
    file_name_extension(G5, G6, 'a.'), s(trailingdot_base, G5), s(trailingdot_ext, G6),

    %  joining
    file_name_extension(a, txt, H1), s(join_plain, H1),
    file_name_extension(x, '.md', H2), s(join_dotted, H2),
    file_name_extension('/a/b', tar, H3), s(join_path, H3),

    yn(is_absolute_file_name('/a/b'), absolute_yes),
    yn(is_absolute_file_name('a/b'), absolute_no),
    yn(is_absolute_file_name('.'), absolute_dot),

    prolog_to_os_filename(I1, '/a/b'), s(to_os, I1),
    prolog_to_os_filename('/c/d', I2), s(from_os, I2),
    true.
