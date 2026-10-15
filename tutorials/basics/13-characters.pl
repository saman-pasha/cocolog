%% BASICS 13 -- text in characters: the `text_units' flag
%%
%%     ./cocolog run tutorials/basics/13-characters.pl main
%%
%% cocolog keeps text as UTF-8 BYTES, and by default its builtins count
%% the bytes (lesson 08): `atom_length' of an a-acute is 2, `atom_codes'
%% hands out the two bytes, a `sub_atom' can cut the letter in half. That
%% is still the default through 1.x, so a program written against bytes
%% runs as it always did.
%%
%% A PROGRAM CAN ASK FOR CHARACTERS INSTEAD, which is what SWI-Prolog
%% counts:
%%
%%     :- set_prolog_flag(text_units, characters).
%%
%% at the head of a file, or COCOLOG_TEXT_UNITS=characters in the
%% environment for a whole run. From there on a CODE is a code point and a
%% CHAR is one character of however many bytes, in every builtin that
%% hands text out or counts it: atom_length/2, atom_codes/2, atom_chars/2,
%% char_code/2, sub_atom/5, upcase_atom/2, the string_* family,
%% split_string/4, char_type/2, format's ~c and its codes and chars sinks,
%% read_file_to_codes/2 -- and the reader, so "..." and 0'c in the rest
%% of the file are characters too. This file sets it, so every claim below
%% is in characters. `current_prolog_flag(text_units, U)' says which.
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

:- set_prolog_flag(text_units, characters).

main :-
    current_prolog_flag(text_units, U),
    must('this file counts', U, characters),

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
    format("~ndone~n").

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
