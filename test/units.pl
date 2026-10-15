%% text_units: text counted in CHARACTERS, as SWI counts it (1.13.0).
%%
%% cocolog's text is UTF-8 bytes, and through 1.12 its builtins counted the
%% bytes: atom_length('dár', 4), atom_codes/2 the bytes 100,195,161,114, a
%% sub_atom/5 cut through the middle of á. `:- set_prolog_flag(text_units,
%% characters).' -- or COCOLOG_TEXT_UNITS=characters for a whole run --
%% makes a code a CODE POINT and a char a CHARACTER of however many bytes,
%% for every builtin that hands text out as codes or chars or counts it.
%% BYTES STAY THE DEFAULT through 1.x, so a program written against them
%% runs as it did; the flip is 2.0.0's.
%%
%%     cocolog -s test/units.pl        from the checkout root
%%
%% THIS CASE RUNS IN CHARACTERS: the directive below sets the flag for the
%% rest of the file and for the machine that runs main. Bytes, the default,
%% is asked of child processes, as are the environment variable, a file's
%% own directive and a frozen machine. Every expected answer here is swipl
%% 9.0.4's (LANG=C.UTF-8, double_quotes codes) unless a comment says where
%% cocolog differs and why.

:- use_module('test/prelude.pl').
:- use_module(library(stream)).
:- set_prolog_flag(text_units, characters).

main :-
    scratch(D),
    flag(D), atoms, cases, strings, reader(D), formats, types, undecodable(D),
    documents, streams(D), threads(D), frozen(D),
    shl(['rm -rf ', D]),
    checks_done.

%% ---- the flag ------------------------------------------------------------

%% the same program, under whatever its process counts
probe_program(['main :- current_prolog_flag(text_units, U), atom_length(\'dár\', N),',
               '    atom_codes(\'dár\', Cs), write(answer(U-N-Cs)), nl.']).

flag(D) :-
    section('the flag: characters here, bytes by default'),
    answer(current_prolog_flag(text_units, U1), U1, G1),
    check('this case counts characters', G1, characters),
    probe_program(P),
    atom_concat(D, '/plain.pl', F2),
    fixture(F2, P),
    atom_concat('run ', F2, A2),
    answer_text(A2, T2),
    check('a program that says nothing counts bytes, the default through 1.x', T2,
          'bytes-4-[100,195,161,114]'),
    cocolog(C),
    sh_join(['COCOLOG_TEXT_UNITS=characters ', C, ' run ', F2, ' 2>/dev/null'], Cmd3),
    shell(Cmd3, Out3, _),
    check('COCOLOG_TEXT_UNITS=characters counts characters for a whole run', Out3,
          'answer(characters-3-[100,225,114])'),
    atom_concat(D, '/chars.pl', F4),
    fixture(F4, [':- set_prolog_flag(text_units, characters).'|P]),
    atom_concat('run ', F4, A4),
    answer_text(A4, T4),
    check('so does a file\'s own directive', T4, 'characters-3-[100,225,114]'),
    atom_concat(D, '/back.pl', F5),
    fixture(F5, [':- set_prolog_flag(text_units, characters).',
                 ':- set_prolog_flag(text_units, bytes).'|P]),
    atom_concat('run ', F5, A5),
    answer_text(A5, T5),
    check('and a second directive puts bytes back', T5, 'bytes-4-[100,195,161,114]'),
    atom_concat(D, '/bad.pl', F6),
    fixture(F6, [':- set_prolog_flag(text_units, words).', 'main.']),
    atom_concat('run ', F6, A6),
    cocolog_out(A6, Out6),
    ( re_match('text_units takes bytes or characters', Out6) -> R6 = refused ; R6 = Out6 ),
    check('a value that is neither is refused by name', R6, refused).

%% ---- atoms -----------------------------------------------------------------

atoms :-
    section('atoms: lengths, codes, chars and pieces in characters'),
    answer(atom_length('dár', N1), N1, G1),
    check('atom_length(\'dár\', 3)', G1, 3),
    answer(atom_codes('dár', C2), C2, G2),
    check('atom_codes gives code points', G2, [100,225,114]),
    answer(atom_codes(A3, [100,225,114]), A3, G3),
    check('and takes them back', G3, 'dár'),
    answer(atom_chars('dár', C4), C4, G4),
    check('atom_chars gives characters', G4, [d,'á',r]),
    answer(atom_chars(A5, [d,'á',r]), A5, G5),
    check('and takes one of two bytes back (1.11.8 crashed on it in bytes)', G5, 'dár'),
    answer(char_code('á', K6), K6, G6),
    check('char_code(\'á\', 225)', G6, 225),
    answer(char_code(Ch7, 8364), Ch7, G7),
    check('char_code(C, 8364) is the euro sign', G7, '€'),
    answer(sub_atom('dár', 1, 1, A8, S8), A8-S8, G8),
    check('sub_atom(\'dár\', 1, 1, A, S) is 1 and á, not half of it', G8, 1-'á'),
    answer(findall(B9-L9-S9, sub_atom('dár', B9, L9, _, S9), Ps9), Ps9, G9),
    check('sub_atom/5 enumerates the ten pieces swipl does',
          G9, [0-0-'', 0-1-d, 0-2-'dá', 0-3-'dár', 1-0-'', 1-1-'á', 1-2-'ár',
               2-0-'', 2-1-r, 3-0-'']),
    answer(findall(B10, sub_atom('ñandú', B10, _, _, 'ú'), Bs10), Bs10, G10),
    check('and finds a known piece by its character offset', G10, [4]),
    answer(( atom_length('🙂x', N11), atom_codes('🙂x', C11) ), N11-C11, G11),
    check('four bytes are one character', G11, 2-[128578,120]),
    answer(number_codes(N12, [0'4, 0'2]), N12, G12),
    check('number_codes is unchanged', G12, 42),
    answer(atomic_list_concat(Ps13, 'á', 'xáyáz'), Ps13, G13),
    check('atomic_list_concat/3 splits on a character of two bytes', G13, [x,y,z]).

%% ---- case ------------------------------------------------------------------

cases :-
    section('case: the letters past ASCII change too'),
    answer(upcase_atom('dár', U1), U1, G1),
    check('upcase_atom(\'dár\', \'DÁR\')', G1, 'DÁR'),
    answer(downcase_atom('ÉLAN ÑU', L2), L2, G2),
    check('downcase_atom', G2, 'élan ñu'),
    answer(upcase_atom('straße', U3), U3, G3),
    check('ß has no capital of its own, as in swipl', G3, 'STRAßE'),
    answer(upcase_atom('αβγ жук', U4), U4, G4),
    check('Greek and Cyrillic', G4, 'ΑΒΓ ЖУК'),
    answer(downcase_atom('İI', L5), L5, G5),
    check('dotted capital I goes to i, as glibc pairs it', G5, ii),
    answer(( length(Cs6, 5000), maplist(=(0'á), Cs6), atom_codes(A6, Cs6),
             upcase_atom(A6, U6), atom_length(U6, N6), sub_atom(U6, 0, 1, _, F6) ), N6-F6, G6),
    check('an atom past 4096 bytes (it went through a buffer of 4096 and was a type error)',
          G6, 5000-'Á').

%% ---- strings ---------------------------------------------------------------

strings :-
    section('strings: the same units'),
    answer(( string_codes(S1, [100,225,114]), string_length(S1, N1) ), N1, G1),
    check('string_length', G1, 3),
    answer(( atom_string('dár', S2), string_chars(S2, C2) ), C2, G2),
    check('string_chars', G2, [d,'á',r]),
    answer(( atom_string('dár', S3), string_upper(S3, U3), atom_string(A3, U3) ), A3, G3),
    check('string_upper', G3, 'DÁR'),
    answer(( atom_string('dár', S4), split_string(S4, "á", "", P4),
             maplist(atom_string, A4, P4) ), A4, G4),
    check('split_string on a separator of two bytes: two fields, not three', G4, [d,r]),
    answer(( atom_string('¡¡ñandú!!', S5), split_string(S5, "", "¡!", P5),
             maplist(atom_string, A5, P5) ), A5, G5),
    check('and a pad of characters off both ends', G5, ['ñandú']),
    answer(( atom_string('éaáb', S7), split_string(S7, "á", "é", P7),
             maplist(atom_string, A7, P7) ), A7, G7),
    check('a pad whose first byte a separator shares is another character (bytes: [a,'''',b])', G7, [a,b]),
    answer(( atom_string('dár', S6), sub_string(S6, 1, 1, A6, Sub6), atom_string(At6, Sub6) ),
           A6-At6, G6),
    check('sub_string counts characters', G6, 1-'á').

%% ---- the reader ------------------------------------------------------------

reader(D) :-
    section('the reader: "..." and 0\'c are characters'),
    X1 = "dár",
    check('"dár" reads as three codes', X1, [100,225,114]),
    X2 = 0'á,
    check('0\'á is 225, where bytes stopped at its second byte', X2, 225),
    X3 = 0'€,
    check('0\'€ is 8364', X3, 8364),
    %% a flag set in a file is that file's from there on, so the chars of a
    %% "..." under double_quotes = chars take a file of their own
    atom_concat(D, '/dq.pl', F4),
    fixture(F4, [':- set_prolog_flag(text_units, characters).',
                 ':- set_prolog_flag(double_quotes, chars).',
                 'main :- X = "dár", write(answer(X)), nl.']),
    atom_concat('run ', F4, A4),
    answer_text(A4, T4),
    check('"dár" under double_quotes = chars is three chars', T4, '[d,á,r]').

%% ---- format ----------------------------------------------------------------

formats :-
    section('format/2,3 and with_output_to/2'),
    answer(format(atom(A1), "~c~c", [225, 8364]), A1, G1),
    check('~c writes a code point', G1, 'á€'),
    answer(format(atom(A2), "~s", [[100,225,114]]), A2, G2),
    check('~s takes code points', G2, 'dár'),
    answer(format(codes(C3), "d~ar", ['á']), C3, G3),
    check('a codes sink answers code points', G3, [100,225,114]),
    answer(format(chars(C4), "d~ar", ['á']), C4, G4),
    check('a chars sink answers characters', G4, [d,'á',r]),
    answer(format(codes(C5, T5), "á", []), C5-T5, G5),
    check('and a difference list keeps its tail', G5, [225|T5]-T5),
    answer(with_output_to(codes(C6), write('dár')), C6, G6),
    check('with_output_to(codes(C), ...)', G6, [100,225,114]),
    answer(format(atom(A7), "~w", ["dár"]), A7, G7),
    check('a code list written by ~w is its numbers', G7, '[100,225,114]').

%% ---- char_type/2 and code_type/2 --------------------------------------------

%% swipl's answers on Linux, glibc's C.UTF-8 classes, for the categories
%% cocolog has; captured with code_type/2 over each code point
ct_cats([alpha, alnum, csym, csymf, upper, lower, space, white, punct, graph, print,
         cntrl, digit(_), prolog_var_start, prolog_atom_start,
         prolog_identifier_continue, prolog_symbol, upper(_), lower(_),
         to_lower(_), to_upper(_)]).

ct(225, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(193),to_lower(193),to_upper(225)]).
ct(193, [alpha,alnum,csym,csymf,upper,graph,print,prolog_var_start,prolog_identifier_continue,upper(225),to_lower(193),to_upper(225)]).
ct(223, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(223),to_lower(223),to_upper(223)]).
ct(7838, [alpha,alnum,csym,csymf,upper,graph,print,prolog_var_start,prolog_identifier_continue,upper(223),to_lower(7838),to_upper(223)]).
ct(8364, [punct,graph,print,prolog_symbol,to_lower(8364),to_upper(8364)]).
ct(160, [punct,graph,print,to_lower(160),to_upper(160)]).
ct(12288, [space,print,to_lower(12288),to_upper(12288)]).
ct(1632, [alpha,alnum,csym,csymf,graph,print,prolog_identifier_continue,to_lower(1632),to_upper(1632)]).
ct(20013, [alpha,alnum,csym,csymf,graph,print,prolog_atom_start,prolog_identifier_continue,to_lower(20013),to_upper(20013)]).
ct(945, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(913),to_lower(913),to_upper(945)]).
ct(1078, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(1046),to_lower(1046),to_upper(1078)]).
ct(170, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(170),to_lower(170),to_upper(170)]).
ct(215, [punct,graph,print,prolog_symbol,to_lower(215),to_upper(215)]).
ct(8195, [space,print,to_lower(8195),to_upper(8195)]).
ct(133, [cntrl,to_lower(133),to_upper(133)]).
ct(8217, [punct,graph,print,prolog_symbol,to_lower(8217),to_upper(8217)]).
ct(4304, [alpha,alnum,csym,csymf,lower,graph,print,prolog_atom_start,prolog_identifier_continue,lower(7312),to_lower(7312),to_upper(4304)]).

ct_answers(K, Rs) :-
    ct_cats(Cs),
    findall(R, ( member(C0, Cs), copy_term(C0, R), catch(code_type(K, R), _, fail) ), Rs).

types :-
    section('char_type/2 and code_type/2 past ASCII, as swipl answers on Linux'),
    findall(K-Got, ( ct(K, _), ct_answers(K, Got) ), Gots),
    findall(K-Want, ct(K, Want), Wants),
    check('seventeen code points through twenty-one categories', Gots, Wants),
    answer(char_type('á', upper(U2)), U2, G2),
    check('char_type(\'á\', upper(U)) fails: it is the small letter', G2, failed),
    answer(char_type('Á', upper(L3)), L3, G3),
    check('char_type(\'Á\', upper(L)) answers its small letter as a char', G3, 'á'),
    yes_no(char_type('€', punct), G4),
    check('a character of three bytes is a character', G4, yes),
    %% swipl also answers period and quote for a code point whose low byte
    %% is a NUL or one of those marks -- U+0100 and U+AC00 are periods there,
    %% its strchr over a truncated character -- which is not copied
    answer(findall(K5, ( member(K5, [256, 44032, 1575]), ( code_type(K5, period) ; code_type(K5, quote) ) ), Ks5),
           Ks5, G5),
    check('period and quote are ASCII\'s alone', G5, []).

%% ---- bytes that are no UTF-8 --------------------------------------------------

undecodable(D) :-
    section('a byte that is no UTF-8 is U+DC00 plus the byte, and goes back as it came'),
    answer(( atom_codes(A1, [0xDCC3]), atom_length(A1, N1), atom_codes(A1, C1) ), N1-C1, G1),
    check('an atom of the one byte 0xC3: one character, its code 0xDCC3', G1, 1-[0xDCC3]),
    atom_concat(D, '/raw.bin', F2),
    answer(( write_file_from_codes(F2, [104, 0xDCFF, 0xDCC3, 105, 225]),
             size_file(F2, Z2), read_file_to_codes(F2, C2) ), Z2-C2, G2),
    check('written as its bytes and read back the same: h, 0xFF, 0xC3, i, á',
          G2, 6-[104, 0xDCFF, 0xDCC3, 105, 225]),
    atom_concat(D, '/text.txt', F3),
    answer(( write_file_from_codes(F3, "dár €"), size_file(F3, Z3), read_file_to_codes(F3, C3),
             atom_codes(A3, C3) ), Z3-A3, G3),
    check('a text file: eight bytes, five characters back', G3, 8-'dár €'),
    %% swipl takes one into an atom; UTF-8 has no bytes for it
    answer(catch(( atom_codes(_, [0xD800]), E4 = none ), error(E4, _), true), E4, G4),
    check('a lone surrogate is no character: the codes are no text', G4, instantiation_error).

%% ---- the document libraries ------------------------------------------------

documents :-
    section('library(json), library(xml), library(html): a reference is one code'),
    use_module(library(json)),
    use_module(library(xml)),
    use_module(library(html)),
    answer(( json_parse('"\\u00e1\\u20ac"', T1), atom_codes(T1, C1) ), C1, G1),
    check('a \\u escape is the code point, not its UTF-8', G1, [225, 8364]),
    answer(( json_parse('"\\ud83d\\ude00"', T2), atom_codes(T2, C2) ), C2, G2),
    check('a surrogate pair is one character', G2, [128512]),
    answer(xml_parse('<p>&#225;&#x20AC;</p>', T3), T3, G3),
    check('an XML character reference', G3, element(p, [], ['á€'])),
    answer(html_parse('<p>&#225;</p>', T4), T4, G4),
    check('an HTML character reference', G4, [element(p, [], ['á'])]).

%% ---- library(stream): a text stream's codes are the program's ------------

streams(D) :-
    section('library(stream): get_code, peek_code, put_code and lines in characters'),
    (   catch(use_module(library(stream)), _, fail)
    ->  atom_concat(D, '/s.txt', F),
        answer(( open(F, write, W1), put_code(W1, 225), put_code(W1, 8364), put_char(W1, 'x'),
                 close(W1), size_file(F, Z1) ), Z1, G1),
        check('put_code writes a code point as its UTF-8: á and € and x are six bytes', G1, 6),
        answer(( open(F, read, R2), peek_code(R2, P2), get_code(R2, A2), get_code(R2, B2),
                 get_code(R2, C2), get_code(R2, E2), close(R2) ), [P2, A2, B2, C2, E2], G2),
        check('get_code and peek_code read them back, -1 at the end', G2, [225, 225, 8364, 0'x, -1]),
        answer(( open(F, read, R3), stream_read_line(R3, L3), close(R3) ), L3, G3),
        check('a line is code points', G3, [225, 8364, 0'x]),
        answer(( open(F, read, R4, [type(binary)]), stream_read_all(R4, L4), close(R4) ), L4, G4),
        check('a binary stream is bytes whatever the program counts', G4,
              [195, 161, 226, 130, 172, 120])
    ;   format("   (library(stream) is not built: sh modules/stream/build.sh)~n", [])
    ).

%% ---- threads ---------------------------------------------------------------

%% Under -s this file is a module, and a thread's machine reads a module's
%% directives again on its first goal, so the first check holds of the
%% directive alone; a consulted program's thread has only the process
%% default the directive set (`coco_text_default'), which the child asks.
threads(D) :-
    section('a thread made after the directive counts as the program does'),
    (   catch(use_module(library(thread)), _, fail)
    ->  answer(( channel_new(Ch), thread_create(( atom_length('dár', N), channel_send(Ch, N) ), I),
                 thread_join(I, _), channel_recv(Ch, M) ), M, G1),
        check('atom_length(\'dár\', 3) in a thread of its own', G1, 3),
        atom_concat(D, '/thread.pl', F2),
        fixture(F2, [':- set_prolog_flag(text_units, characters).',
                     ':- use_module(library(thread)).',
                     'main :- channel_new(Ch), thread_create(( atom_length(\'dár\', N), channel_send(Ch, N) ), I),',
                     '    thread_join(I, _), channel_recv(Ch, M), write(answer(M)), nl.']),
        atom_concat('run ', F2, A2),
        answer_text(A2, T2),
        check('and in a consulted program, whose thread has only the process default', T2, '3')
    ;   format("   (library(thread) is not built: sh modules/thread/build.sh)~n", [])
    ).

%% ---- a frozen machine ------------------------------------------------------

frozen(D) :-
    section('a frozen machine keeps its units'),
    atom_concat(D, '/kb', KB),
    make_directory(KB),
    atom_concat(D, '/len.pl', F),
    fixture(F, ['go :- atom_length(\'dár\', N), write(answer(N)), nl.']),
    cocolog(C),
    sh_join(['timeout 60 ', C, ' --embed ', KB, ' consult ', F, ' >/dev/null 2>&1 && ',
             'COCOLOG_TEXT_UNITS=characters timeout 60 ', C, ' --embed ', KB,
             ' start chars go >/dev/null 2>&1 && ',
             'timeout 60 ', C, ' --embed ', KB, ' start bytes go >/dev/null 2>&1'], Setup),
    (   sh_exit(Setup, 0)
    ->  sh_join(['timeout 60 ', C, ' --embed ', KB, ' step chars 2>/dev/null'], S1),
        shell(S1, O1, _),
        ( re_first_atom('answer\\([0-9]+\\)', O1, A1) -> true ; A1 = O1 ),
        check('started under characters, stepped in a process that says nothing: 3', A1, 'answer(3)'),
        sh_join(['COCOLOG_TEXT_UNITS=characters timeout 60 ', C, ' --embed ', KB, ' step bytes 2>/dev/null'], S2),
        shell(S2, O2, _),
        ( re_first_atom('answer\\([0-9]+\\)', O2, A2) -> true ; A2 = O2 ),
        check('started under bytes, stepped under characters: 4', A2, 'answer(4)')
    ;   check('could set up a machine in a scratch store', failed, done)
    ).
