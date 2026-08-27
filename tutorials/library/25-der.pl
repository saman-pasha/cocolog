%% LIBRARY 25 -- library(der): the encoding everything X.509 is made of
%%
%%     COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/25-der.pl main
%%
%% TIER 2: `sh modules/der/build.sh'. It links libEncoding, libCore and
%% libStreamIO and NOT libCryptography -- `Zigurat::DER' is an encoding,
%% not a secret, so everything a certificate is made of can be taken
%% apart with no cipher and no OpenSSL anywhere near the process.
%%
%%     der_encode(+Term, -Hex)          der_decode(+Hex, -Term)
%%     der_tlv(+Hex, -Tag, -Value, -Rest)   der_wrap(+Tag, +Hex, -Hex)
%%     der_prim(+Kind, +Value, -Hex)    der_unprim(+Kind, +Hex, -Value)
%%     der_tag(?Kind, ?Tag)
%%
%% THE VOCABULARY:
%%     boolean(B)  integer(DecimalAtom)  null
%%     bit_string(Hex)  octet_string(Hex)  oid('1.2.840...')
%%     utf8(A)  printable(A)  ia5(A)
%%     utc_time(Unix)  generalized_time(Unix)
%%     sequence([...])  set([...])  context(N, T)  unknown(Tag, Hex)

:- use_module(library(der)).

main :-
    format("~n-- TWO'S COMPLEMENT, SHORTEST FORM, which is where a~n"),
    format("   hand-rolled encoder is wrong and stays wrong for years~n"),
    der_encode(integer('127'), A), must('127', A, '02017f'),
    der_encode(integer('128'), B), must('128 -- a leading zero appears', B, '02020080'),
    der_encode(integer('-1'), C), must('-1', C, '0201ff'),
    der_encode(integer('-129'), D), must('-129', D, '0202ff7f'),
    der_encode(integer('0'), Z), must('0 is one byte, not none', Z, '020100'),
    format("   128 needs the 00 or its top bit reads as a SIGN. Negative~n"),
    format("   numbers are the complement plus one under the same rule,~n"),
    format("   and a redundant leading byte is forbidden rather than~n"),
    format("   optional -- DER means there is exactly one encoding.~n"),

    format("~n-- AN INTEGER IS A DECIMAL ATOM, and it has to be~n"),
    Modulus = '26959946667150639794667015087019630673557916260026308143510066298881',
    der_encode(integer(Modulus), MH), der_decode(MH, MT),
    must('a number past 64 bits survives', MT, integer(Modulus)),
    X is 1000000000000000000 * 997,
    must('...because a cocolog integer WRAPS IN SILENCE', X, 875820019684212736),
    format("   That second line is a wrong answer returned confidently.~n"),
    format("   An RSA modulus is two thousand bits; read into a cocolog~n"),
    format("   integer it would be nonsense with no error attached. A~n"),
    format("   decimal atom is also what `library(bigint)' speaks, so the~n"),
    format("   two compose with no conversion nobody would remember.~n"),

    format("~n-- the other primitives~n"),
    der_encode(oid('1.2.840.113549.1.1.1'), O),
    must('rsaEncryption', O, '06092a864886f70d010101'),
    der_encode(null, N), must('NULL', N, '0500'),
    der_encode(printable(hi), P), must('PRINTABLE STRING', P, '13026869'),
    der_encode(bit_string('0a0b'), BS),
    must('a BIT STRING gains a zero unused-bit octet', BS, '0303000a0b'),
    der_tag(oid, T6), must('der_tag/2 runs both ways', T6, 6),
    der_tag(K19, 19), must('...backwards too', K19, printable),

    format("~n-- STRUCTURE IS PROLOG AND BYTES ARE C++~n"),
    der_tlv('3003020101', Tag, V, R),
    must('der_tlv/4 takes ONE value off the front', Tag-V-R, 48-'020101'-''),
    format("   That is the whole of what the C++ half owes the Prolog~n"),
    format("   half about structure. A sequence is a tag whose content is~n"),
    format("   more TLVs, and walking that is a two-clause recursion --~n"),
    format("   better said in Prolog than as a loop with a cursor in it.~n"),
    der_decode('3003020101', S), must('so der_decode/2 recurses', S, sequence([integer('1')])),

    format("~n-- AN UNKNOWN TAG IS NOT A FAILURE~n"),
    der_decode('1f0141', U), must('a tag with no name', U, unknown(31, '41')),
    der_encode(U, U2), must('...and it writes back exactly', U2, '1f0141'),
    format("   A parser that refused every tag it did not recognise could~n"),
    format("   not read a certificate carrying an extension somebody else~n"),
    format("   invented -- which is most real certificates.~n"),

    format("~n-- THE ROUND TRIP, which is the real check~n"),
    Doc = sequence([sequence([oid('1.2.840.113549.1.1.1'), null]),
                    bit_string('3003020101'),
                    context(0, integer('2')),
                    set([printable(a), ia5(b)]),
                    utc_time('1700000000')]),
    der_encode(Doc, Once),
    der_decode(Once, Read),
    der_encode(Read, Twice),
    must('write, read, write again', Once, Twice),
    must('...and the term survives too', Read, Doc),
    format("   The same discipline test/serialize.sh holds json, xml and~n"),
    format("   html to. A reader and a writer that disagree about the~n"),
    format("   same certificate are worse than either alone, and no~n"),
    format("   amount of expectations on each half separately finds it.~n"),

    format("~n-- and the shape a public key really has~n"),
    der_encode(sequence([sequence([oid('1.2.840.113549.1.1.1'), null]),
                         bit_string('3006020101020103')]), Spki),
    der_decode(Spki, sequence([Alg, bit_string(Bits)])),
    must('the algorithm', Alg, sequence([oid('1.2.840.113549.1.1.1'), null])),
    der_decode(Bits, sequence([integer(Mod), integer(Exp)])),
    must('a (tiny) modulus', Mod, '1'),
    must('and its exponent', Exp, '3'),
    format("   Library 26 does that to a REAL certificate, and gets a~n"),
    format("   617-digit modulus and 65537 out of it.~n~n"),
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
