%% BASICS 13 -- text in characters, and bytes on request: `text_units'
%%
%%     ./cocolog run tutorials/basics/13-characters.pl main
%%
%% cocolog keeps text as UTF-8, and since 2.0.0 its builtins count it in
%% CHARACTERS, which is what SWI-Prolog counts. A CODE is a code point and
%% a CHAR is one character of however many bytes, in every builtin that
%% hands text out or counts it: atom_length/2, atom_codes/2, atom_chars/2,
%% char_code/2, sub_atom/5, upcase_atom/2, the string_* family,
%% split_string/4, char_type/2, format's ~c and its codes and chars sinks,
%% read_file_to_codes/2 -- and the reader, so "..." and 0'c are characters
%% too. A file that says nothing counts characters, as `main' below does;
%% `current_prolog_flag(text_units, U)' says which.
%%
%% THROUGH 1.x THE DEFAULT WAS BYTES: `atom_length' of an a-acute was 2,
%% `atom_codes' handed out its two bytes, a `sub_atom' could cut the letter
%% in half. A program written against bytes asks for them,
%%
%%     :- set_prolog_flag(text_units, bytes).
%%
%% at the head of a file, or COCOLOG_TEXT_UNITS=bytes in the environment
%% for a whole run. The flag holds for the REST of the file and for the
%% machine that runs it, and the last part of this lesson is read and run
%% between two such directives: it counts bytes while `main' counts
%% characters.
%%
%% WHAT DOES NOT CHANGE: an atom is the same bytes either way (only how it
%% is counted and taken apart moves), atom_concat/3, atomic_list_concat/3
%% and sorting work as they did, and a binary stream or a socket is bytes.
%% library(http) and its kin count bytes on the wire whatever the program
%% does, so text with letters past ASCII goes to them as bytes.
%%
%% A BYTE THAT IS NO UTF-8 IS NOT LOST: it reads as the code 0xDC00 plus
%% the byte -- what Python calls surrogateescape -- and is written back as
%% that byte, so a file that is not UTF-8 goes round unchanged.
%%
%% AND THE BYTES ARE ONE CALL AWAY, whatever the units: SWI's
%% `string_bytes(Text, Bytes, utf8)' (2.0.0) answers a text's UTF-8, and
%% given bytes, the string they make. It is how library(http) and its kin
%% cross between the program's text and the wire, which is bytes.

main :-
    current_prolog_flag(text_units, U),
    must('a file that says nothing counts', U, characters),

    format("~n-- an atom is characters long~n"),
    atom_length('dár', N),
    must('atom_length(\'dár\', N)', N, 3),
    atom_codes('dár', Cs),
    must('atom_codes gives code points', Cs, [100, 225, 114]),
    atom_chars('dár', Chs),
    must('atom_chars gives characters', Chs, [d, 'á', r]),
    char_code(Euro, 8364),
    must('char_code(C, 8364)', Euro, '€'),

    format("~n-- pieces are cut between characters~n"),
    sub_atom('dár', 1, 1, After, Piece),
    must('sub_atom(\'dár\', 1, 1, A, S): the piece', Piece, 'á'),
    must('  and what comes after it', After, 1),
    split_string("ñandú, sí", ",", " ", Parts),
    maplist(atom_string, PartAtoms, Parts),
    must('split_string over two words', PartAtoms, ['ñandú', 'sí']),

    format("~n-- case changes past ASCII~n"),
    upcase_atom('dár', Up),
    must('upcase_atom', Up, 'DÁR'),
    downcase_atom('ΑΒΓ', Down),
    must('Greek too', Down, 'αβγ'),
    ( char_type('Ñ', upper(Lower)) -> true ; Lower = none ),
    must('char_type(\'Ñ\', upper(L)): its small letter', Lower, 'ñ'),
    ( char_type('ß', alpha) -> Alpha = yes ; Alpha = no ),
    must('and a letter past ASCII is alpha', Alpha, yes),

    format("~n-- the reader reads characters too~n"),
    Quoted = "dár",
    must('"dár" in this file', Quoted, [100, 225, 114]),
    Code = 0'á,
    must('0\'á', Code, 225),
    format(atom(Written), "~c~c~c", [100, 225, 114]),
    must('format ~c writes a code point', Written, 'dár'),

    format("~n-- a byte that is no UTF-8 goes round unchanged~n"),
    atom_codes(Odd, [0xDCFF]),
    atom_length(Odd, OddLen),
    must('the byte 0xFF alone is one character', OddLen, 1),
    atom_codes(Odd, OddCodes),
    must('  whose code is 0xDC00 plus the byte', OddCodes, [0xDCFF]),

    format("~n-- the bytes, whatever the units: string_bytes/3~n"),
    string_bytes('dár', Bytes, utf8),
    must('string_bytes(\'dár\', B, utf8): its UTF-8', Bytes, [100, 195, 161, 114]),
    string_bytes(Str, [100, 195, 161, 114], utf8),
    atom_string(Back, Str),
    must('  and the bytes back, a string atom_string/2 makes an atom', Back, 'dár'),

    format("~n-- bytes, where a file asks for them (the part after main)~n"),
    ( catch(nb_getval(lesson13_bytes, Got), _, fail) -> true ; Got = not_run ),
    ( Got = BU-BN-BCs-BQ -> true ; BU = Got, BN = none, BCs = none, BQ = none ),
    must('after the directive, the flag', BU, bytes),
    must('  atom_length(\'dár\', N): the a-acute is two bytes', BN, 4),
    must('  atom_codes gives the UTF-8 bytes', BCs, [100, 195, 161, 114]),
    must('  and "dár" read there is the bytes too', BQ, [100, 195, 161, 114]),
    current_prolog_flag(text_units, U2),
    must('and the directive after it put characters back for main', U2, characters),
    format("~ndone~n").

%% ---- bytes, asked for ---------------------------------------------------
%% A directive is a goal run where it stands. The first one below sets the
%% flag for the rest of the file and for the machine, so `in_bytes' is READ
%% in bytes (its "dár") and RUN in bytes, by `initialization(_, now)' at
%% that point of the load; the last puts characters back before `main'
%% runs. `in_bytes' leaves what it saw in a global for `main' to check,
%% because a directive that fails is reported and the load goes on. A
%% program that wants bytes throughout says the first line at its head.

:- set_prolog_flag(text_units, bytes).

in_bytes :-
    current_prolog_flag(text_units, U),
    atom_length('dár', N),
    atom_codes('dár', Cs),
    Quoted = "dár",
    nb_setval(lesson13_bytes, U-N-Cs-Quoted).

:- initialization(in_bytes, now).
:- set_prolog_flag(text_units, characters).

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
