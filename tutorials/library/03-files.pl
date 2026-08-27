%% LIBRARY 03 -- library(files)
%%
%%     ./cocolog run tutorials/library/03-files.pl main
%%
%% RUN IT FROM THE REPOSITORY ROOT: it reads its own source, and finds it
%% by a relative path.
%%
%% TIER 1: no import.
%%
%% SWI'S FILES LIBRARY, AND MOSTLY C -- seventeen predicates in the C half
%% and five in Prolog, because a file system is a syscall away and there
%% is nothing a clause can do about that. It is the opposite balance from
%% `library(lists)', and the two together are why the module seam exists.
%%
%% IT IS CHECKED AGAINST SWI BYTE FOR BYTE. `test/files/' runs the same
%% Prolog program under `swipl' and under `cocolog' in the same fresh
%% directory and compares the output line by line -- the only kind of
%% compatibility claim that cannot be fooled by its author.
%%
%% ---- THERE IS NO STREAM LAYER, AND THAT IS THE FIRST THING TO KNOW ----
%%
%% `open/3', `close/1', `read_term/3', `nl/1' -- none of them exists here,
%% and `open/3' raises `existence_error(procedure, open/3)' rather than
%% pretending. cocolog writes to the literal stdout in some seventy places
%% rather than to a stream it passes around, so a stream API would be a
%% facade over one destination.
%%
%% SO WHAT DOES A PROGRAM DO INSTEAD?
%%
%%     TO READ a file      `read_file_to_codes/2', in one call
%%     TO CAPTURE output   `with_output_to(atom(A), Goal)' or `codes(C)'
%%     TO WRITE something  put it in the KNOWLEDGE BASE, which is the
%%                         durable store this interpreter actually has --
%%                         see tutorials/basics/11 -- or shell out, or
%%                         write a module for it
%%
%% That is a real limitation and it is deliberate rather than unfinished.
%% cocolog's answer to "where does state live" is a database, not a file,
%% and half a stream layer would blur the one decision the whole design
%% follows from.
%%
%% WHAT IS HERE IS EVERYTHING ELSE: existence, size, times, permissions,
%% listing a directory, making and removing them, renaming, globbing,
%% absolute names, temporary names, and taking a PATH apart.

main :-
    format("~n-- names are taken apart and put together, not spliced~n"),
    file_base_name('/a/b/notes.txt', Base),
    must('file_base_name/2', Base, 'notes.txt'),
    file_directory_name('/a/b/notes.txt', Dir),
    must('file_directory_name/2', Dir, '/a/b'),
    file_name_extension(Stem, Ext, 'notes.txt'),
    must('file_name_extension/3 splits', Stem-Ext, notes-txt),
    file_name_extension(report, csv, Joined),
    must('...and JOINS, with the same predicate', Joined, 'report.csv'),
    format("   One definition, both directions -- see basics 03 on why~n"),
    format("   that is the normal state of affairs here.~n"),

    format("~n-- reading a whole file, in one call~n"),
    Self = 'tutorials/library/03-files.pl',
    ( exists_file(Self) -> Here = found ; Here = run_me_from_the_repo_root ),
    must('this tutorial can see its own source', Here, found),
    read_file_to_codes(Self, Codes),
    length(Codes, ByteCount),
    size_file(Self, Size),
    must('read_file_to_codes/2 read every byte', ByteCount, Size),
    atom_codes(Text, Codes),
    ( sub_atom(Text, 0, 12, _, '%% LIBRARY 0') -> Top = right_file ; Top = Text ),
    must('and it is this file', Top, right_file),

    format("~n-- metadata~n"),
    ( exists_file(Self) -> E = yes ; E = no ),
    must('exists_file/1', E, yes),
    ( exists_directory('tutorials') -> D = yes ; D = no ),
    must('exists_directory/1', D, yes),
    ( access_file(Self, read) -> A = readable ; A = no ),
    must('access_file/2', A, readable),
    time_file(Self, When),
    ( number(When) -> T = a_number ; T = When ),
    must('time_file/2 is a POSIX timestamp', T, a_number),

    format("~n-- ...and a question about a missing file is an ordinary NO~n"),
    ( exists_file('/no/such/file/anywhere') -> M = yes ; M = no ),
    must('exists_file on nothing', M, no),
    format("   It FAILS rather than raising, because `is it there' is a~n"),
    format("   question with an ordinary answer.~n"),
    (   catch(delete_file('/no/such/file/anywhere'), _, fail)
    ->  Del = succeeded
    ;   Del = failed
    ),
    must('and so does delete_file/1 on a missing file', Del, failed),
    format("   SWI RAISES THERE and cocolog fails, which is a difference~n"),
    format("   worth knowing before you port code: a `delete_file' whose~n"),
    format("   failure you did not check looks like success in SWI and~n"),
    format("   like a failed goal here. Wrap it in `ignore/1' if you mean~n"),
    format("   `remove it if it is there'.~n"),

    format("~n-- absolute names, and the working directory~n"),
    ( is_absolute_file_name('/a/b') -> Abs = yes ; Abs = no ),
    must('is_absolute_file_name/1', Abs, yes),
    ( is_absolute_file_name('a/b') -> Rel = yes ; Rel = no ),
    must('...and a relative one', Rel, no),
    absolute_file_name(Self, Full),
    ( is_absolute_file_name(Full) -> AF = absolute ; AF = Full ),
    must('absolute_file_name/2', AF, absolute),
    working_directory(Cwd, Cwd),
    ( is_absolute_file_name(Cwd) -> C = absolute ; C = relative ),
    must('working_directory/2 answers an absolute path', C, absolute),

    format("~n-- listing a directory, and globbing~n"),
    directory_files('tutorials', Entries0),
    sort(Entries0, Entries),
    ( memberchk('basics', Entries) -> HasB = yes ; HasB = no ),
    must('directory_files/2 sees tutorials/basics', HasB, yes),
    ( memberchk('.', Entries) -> HasDot = yes ; HasDot = no ),
    must('...and includes . and .., like readdir does', HasDot, yes),
    expand_file_name('tutorials/basics/0*.pl', Globbed),
    length(Globbed, GlobCount),
    ( GlobCount >= 9 -> G = several ; G = GlobCount ),
    must('expand_file_name/2 globs', G, several),

    format("~n-- making and removing a directory, which DOES work~n"),
    tmp_file(tutorial, Tmp),
    atom_concat(Tmp, '-dir', ScratchDir),
    make_directory(ScratchDir),
    ( exists_directory(ScratchDir) -> Made = yes ; Made = no ),
    must('make_directory/1', Made, yes),
    delete_directory(ScratchDir),
    ( exists_directory(ScratchDir) -> Gone = still_there ; Gone = removed ),
    must('delete_directory/1', Gone, removed),

    format("~n-- and capturing output, which is what replaces a write stream~n"),
    with_output_to(atom(Captured), (write(hello), write(' '), write(world))),
    must('with_output_to(atom(A), Goal)', Captured, 'hello world'),
    with_output_to(codes(Cs), write(hi)),
    must('...or codes(C)', Cs, [104, 105]),
    format("   It redirects file descriptor 1 for the duration, and its~n"),
    format("   goal runs in a nested engine -- so, like findall/3, it~n"),
    format("   cannot be suspended mid-proof.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
