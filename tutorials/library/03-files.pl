%% LIBRARY 03 -- library(files)
%%
%%     ./cocolog run tutorials/library/03-files.pl main
%%
%% RUN IT FROM THE REPOSITORY ROOT: it reads its own source, and finds it
%% by a relative path.
%%
%% TIER 1: no import.
%%
%% SWI'S FILES LIBRARY, AND MOSTLY C -- twenty-one predicates in the C half
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
%% WHAT A PROGRAM DOES INSTEAD IS ONE CALL PER FILE:
%%
%%     TO READ a file      `read_file_to_codes/2'
%%     TO WRITE one        `write_file_from_codes/2' -- the whole content,
%%                         whatever the file held before
%%     TO ADD to one       `append_file_from_codes/2'
%%     TO CAPTURE output   `with_output_to(atom(A), Goal)' or `codes(C)' --
%%                         which is also how the text for a write is built,
%%                         since there is no `format/2' onto a file
%%
%% A file is read whole and written whole, and that is deliberate rather
%% than unfinished. cocolog's answer to "where does state live" is a
%% database, not a file it holds open -- see tutorials/basics/11 -- and
%% half a stream layer would blur the one decision the whole design
%% follows from. What the one-call shape gives up is exactly holding a
%% file open and interleaving with it.
%%
%% PORTING NOTE: SWI spells writing `open/3' + `format/2' + `close/1' and
%% has no `write_file_from_codes'. File I/O rewrites at the edges when
%% code moves either way -- and only at the edges.
%%
%% WHAT IS HERE BESIDES is everything about the file as an object:
%% existence, size, times, permissions, listing a directory, making and
%% removing them, renaming, globbing, absolute names, temporary names, and
%% taking a PATH apart.

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

    format("~n-- writing a file: the whole content, one call~n"),
    tmp_file(lesson, T0),
    atom_concat(T0, '-w', F),
    write_file_from_codes(F, 'hello, file\n'),
    read_file_to_codes(F, W1),
    atom_codes(Wrote, W1),
    must('write_file_from_codes/2 takes an atom', Wrote, 'hello, file\n'),
    write_file_from_codes(F, [104, 105, 10]),
    read_file_to_codes(F, W2),
    must('...or a list of codes', W2, [104, 105, 10]),
    format("   The pair `tcp_write/2' takes, for the same reason: a caller~n"),
    format("   with a literal should not have to convert it, and a caller~n"),
    format("   holding bytes should not have to lose them.~n"),
    with_output_to(atom(Line), format("~w+~w=~w~n", [2, 2, 4])),
    write_file_from_codes(F, Line),
    read_file_to_codes(F, W3),
    atom_codes(Formatted, W3),
    must('formatted text is BUILT first, then written', Formatted, '2+2=4\n'),

    format("~n-- and it ROUND-TRIPS: bytes out are bytes back~n"),
    write_file_from_codes(F, Codes),
    read_file_to_codes(F, Copied),
    ( Copied == Codes -> RT = identical ; RT = different ),
    must('a copy of this lesson is byte-for-byte this lesson', RT, identical),
    format("   Codes are masked to 0..255 on the way out, so whatever~n"),
    format("   `read_file_to_codes/2' hands back writes back exactly:~n"),
    format("   copying a binary is these two predicates and nothing between~n"),
    format("   them. Proven once on the cocolog binary itself, cmp-identical.~n"),

    format("~n-- appending~n"),
    write_file_from_codes(F, first),
    append_file_from_codes(F, '-second'),
    read_file_to_codes(F, A1),
    atom_codes(Appended, A1),
    must('append_file_from_codes/2 adds to the end', Appended, 'first-second'),

    format("~n-- the empty list TRUNCATES, and [] is the case to know~n"),
    write_file_from_codes(F, []),
    size_file(F, Z),
    must('write_file_from_codes(F, []) leaves zero bytes', Z, 0),
    format("   `[]' is an ATOM here as well as a list -- atom([]) and~n"),
    format("   is_list([]) are both true -- and a draft that asked atom~n"),
    format("   FIRST wrote the two characters `[' `]' into the file, which~n"),
    format("   read back as a perfectly good list of two codes. The list~n"),
    format("   branch is asked first, so the shell's `: > f' means here~n"),
    format("   what it means there: a zero-byte file is a file.~n"),

    format("~n-- a bad code raises, NAMING the term~n"),
    catch( write_file_from_codes(F, [foo]),
           error(type_error(Kind, Culprit), _),
           true ),
    must('the error carries the type it wanted', Kind, integer),
    must('...and the term that was not one', Culprit, foo),
    delete_file(F),

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

    format("~n-- and capturing output, which is where a write's text comes from~n"),
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
