%  The Files library: the file system. Run under BOTH SWI-Prolog and cocolog
%  in the same freshly made empty directory, and their output compared.
%
%  EVERY PATH HERE IS RELATIVE and every value written is one atom or one
%  number. Absolute paths would carry the sandbox's name into the output, and
%  a compound term would be spaced differently by the two writers -- neither
%  would say anything about the library.
%
%  Only what both systems have: no findall/3, no member/2, no format/2, no
%  library(lists). The helpers below are spelt with a `t_' prefix so that they
%  cannot collide with anything either system autoloads.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

t_member(X, [X|_]).
t_member(X, [_|T]) :- t_member(X, T).

t_length([], 0).
t_length([_|T], N) :- t_length(T, M), N is M + 1.

main :-
    %  ---- making and finding ----
    make_directory(sub),
    yn(exists_directory(sub), dir_exists),
    yn(exists_file(sub), dir_is_not_a_file),
    yn(exists_file(nothing_here), missing_file),
    yn(exists_directory(nothing_here), missing_dir),

    %  ---- a file to work on, made with the only writer both agree on ----
    make_directory('sub/deep'),
    yn(exists_directory('sub/deep'), nested_dir),

    %  ---- access ----
    yn(access_file(sub, read), access_read),
    yn(access_file(sub, search), access_search),
    yn(access_file(nothing_here, exist), access_exist_missing),
    %  `none' asks for no access and gets it, even on a file that is not there
    yn(access_file(nothing_here, none), access_none_missing),

    %  ---- renaming and removing ----
    rename_file(sub, moved),
    yn(exists_directory(moved), renamed_present),
    yn(exists_directory(sub), renamed_gone),
    delete_directory('moved/deep'),
    yn(exists_directory('moved/deep'), deleted_nested),

    %  ---- listing ----
    directory_files(moved, L1),
    yn(t_member('.', L1), listing_has_dot),
    yn(t_member('..', L1), listing_has_dotdot),
    t_length(L1, N1), s(listing_count, N1),

    %  ---- mkdir -p, which is the module's Coco half calling its C half ----
    make_directory_path('a/b/c'),
    yn(exists_directory('a/b/c'), mkdir_p_leaf),
    yn(exists_directory('a/b'), mkdir_p_middle),
    yn(exists_directory(a), mkdir_p_root),
    %  and it is idempotent
    yn(make_directory_path('a/b/c'), mkdir_p_again),

    %  ---- globbing ----
    make_directory('a/b/c/x1'), make_directory('a/b/c/x2'),
    expand_file_name('a/b/c/x*', L2),
    t_length(L2, N2), s(glob_count, N2),
    yn(t_member('a/b/c/x1', L2), glob_first),
    yn(t_member('a/b/c/x2', L2), glob_second),
    %  no match is the EMPTY LIST and not a failure
    expand_file_name('a/b/c/nomatch*', L3),
    t_length(L3, N3), s(glob_empty_count, N3),

    %  ---- identity ----
    yn(same_file('a/b', 'a/b'), same_yes),
    yn(same_file('a/b', 'a'), same_no),

    %  ---- the working directory answers with a trailing slash ----
    working_directory(W, W),
    file_base_name(W, WB), s(cwd_base_is_atom, WB),

    %  ---- absolute_file_name normalises without requiring existence ----
    absolute_file_name('a/b/c', AB1),
    absolute_file_name('a/b/./c', AB2),
    absolute_file_name('a/b/x/../c', AB3),
    yn(AB1 == AB2, abs_dot_normalised),
    yn(AB1 == AB3, abs_dotdot_normalised),
    absolute_file_name('a/nope', AB4),
    yn(atom(AB4), abs_missing_is_atom),
    yn(exists_directory(AB1), abs_is_the_same_place),
    true.
