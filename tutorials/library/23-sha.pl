%% LIBRARY 23 -- library(sha): digests and HMAC
%%
%%     COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/23-sha.pl main
%%
%% TIER 2: `use_module(library(sha))', a `.so' from `modules/sha' built by
%% `sh modules/sha/build.sh' against a BUILT ZiguratIP. There is no hash
%% code in the module -- it is `Zigurat::SHA', the one RSA signs with and
%% X.509 fingerprints with, said in Prolog.
%%
%%     sha_hash(+Alg, +Text, -Hex)      sha_hash_hex(+Alg, +HexIn, -Hex)
%%     sha_file(+Alg, +Path, -Hex)      sha_size(+Alg, -Bytes)
%%     sha_hmac(+Alg, +Key, +Text, -Hex)
%%     sha_hmac_hex(+Alg, +KeyHex, +TextHex, -Hex)
%%     sha_algorithm(?Alg)
%%
%% ALG IS ONE OF `sha1 sha224 sha256 sha384 sha512', and anything else is
%% a `domain_error' rather than a default -- a program that meant SHA-512
%% and silently got SHA-1 has a security property it does not have.
%%
%% THERE IS NO BARE `sha256/2' HERE, on purpose. cocolog has ONE namespace
%% and The Coco already ships a `sha256/2' from its own crypto module;
%% two modules registering that name would be resolved by load order,
%% which is not a way to choose a hash function.

:- use_module(library(sha)).

main :-
    format("~n-- the digests, against the vectors in FIPS 180~n"),
    sha_hash(sha256, abc, A),
    must('sha256("abc")', A,
         ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad),
    sha_hash(sha1, '', B),
    must('sha1("") -- the empty one everybody knows', B,
         da39a3ee5e6b4b0d3255bfef95601890afd80709),
    sha_hash(sha512, abc, C), atom_length(C, CL),
    must('sha512 is 128 hex characters', CL, 128),
    format("   HELD TO SOMEBODY ELSE'S ANSWER, which is the only way to~n"),
    format("   check a hash. A binding that computes confidently and~n"),
    format("   wrongly looks exactly like one that works.~n"),

    format("~n-- the algorithm is an ARGUMENT, and it is checked~n"),
    findall(Alg, sha_algorithm(Alg), Algs),
    must('sha_algorithm/1 enumerates', Algs,
         [sha1, sha224, sha256, sha384, sha512]),
    sha_size(sha256, S), must('sha_size(sha256)', S, 32),
    (   catch(sha_hash(md5, abc, _), error(domain_error(D, _), _), true)
    ->  R = D
    ;   R = accepted
    ),
    must('md5 is not one of ours', R, sha_algorithm),

    format("~n-- TEXT OR HEX, and why there are two entry points~n"),
    sha_hash_hex(sha256, '616263', H),
    must('sha_hash_hex over 61 62 63 is the same', H, A),
    format("   A DIGEST IS ARBITRARY BYTES, zero bytes included, and~n"),
    format("   \"abc\" IS [97,98,99] under the default flag, and a code~n"),
    format("   list cannot carry a zero. So data that is bytes~n"),
    format("   rather than text goes in as hex, and comes out as hex.~n"),

    format("~n-- a file, without reading it in~n"),
    sha_file(sha256, 'LICENSE', F), atom_length(F, FL),
    must('sha_file/3 answers a digest', FL, 64),
    format("   `read_file_to_codes/2' then `sha_hash/3' would cost a copy~n"),
    format("   of the whole file on the heap AND could not carry a zero~n"),
    format("   byte. This walks the file.~n"),

    format("~n-- HMAC, and the argument order that has bitten people~n"),
    sha_hmac_hex(sha256, '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b',
                 '4869205468657265', M),
    must('RFC 4231 test case 1', M,
         b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7),
    sha_hmac(sha256, key, message, K1),
    sha_hmac(sha256, message, key, K2),
    (   K1 == K2 -> Sym = symmetric ; Sym = different ),
    must('HMAC(k, m) is not HMAC(m, k)', Sym, different),
    format("   THE KEY COMES FIRST. That is RFC 2104's order and this~n"),
    format("   module's, and ZiguratIP's own header records that its C~n"),
    format("   interface once took them the other way round -- so callers~n"),
    format("   reading `hmac(SHA256, secret, ...)' passed the key where~n"),
    format("   the message goes and computed something else entirely.~n"),
    format("   A round trip would not have caught it: both sides agreed.~n~n"),
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
