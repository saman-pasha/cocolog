%% LIBRARY 26 -- library(x509): certificates, and the CA that issues them
%%
%%     ZIGURATIP=/path/to/ZiguratIP COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/26-x509.pl main
%%
%% TIER 2: `sh modules/x509/build.sh'. It is the whole of ZiguratIP's
%% `ca' tool -- keygen, signing requests, issuance, validation -- plus
%% the RSA operations a certificate makes possible.
%%
%%     x509_keygen(+Opts, +PrivPath, +PubPath, -Tries)
%%     x509_csr(+SubjectConf, +PrivPath, +Opts, +CsrPath)
%%     x509_issue(+Opts, +IssuerConf, +IssuerKey, +CsrPath, +CertPath)
%%     x509_validate(+PubPath, +CertPath)
%%     x509_validate_by_key(+PrivPath, +Cipher, +CertPath)
%%     x509_subject/2  x509_public_key/2  x509_permissions/2  x509_why/1
%%     x509_sign/5  x509_verify/4  x509_encrypt/3  x509_decrypt/4
%%     x509_subject_file_name/2  x509_file_name_subject/2
%%
%% THIS LESSON READS ONLY. Issuing needs an RSA key pair, which is a few
%% seconds of prime search, and `test/crypto.pl' does that end to end --
%% key, request, certificate, signature, the lot. Here the material is
%% the sample authority ZiguratIP ships, whose private key is in that
%% repository and in every clone of it: it is not a secret and was never
%% meant to be one, which is exactly why a tutorial may use it.

:- use_module(library(x509)).
:- use_module(library(der)).
:- use_module(library(files)).

%% WHERE THE SAMPLE AUTHORITY IS. `getenv/2' rather than a constant,
%% because a checkout is not always in the same place -- and because
%% environment is the one channel into a cocolog program that does not
%% pass through the knowledge base, which is the same reason a pass
%% phrase arrives that way.
cert_dir(D) :-
    (   getenv('ZIGURATIP', Z) -> true ; Z = '/home/user/ZiguratIP' ),
    atom_concat(Z, '/home/etc/cert', D).

file(Name, Path) :- cert_dir(D), atomic_list_concat([D, '/', Name], Path).

main :-
    file('dont-use-certificate.crt', Crt),
    file('dont-use-public.key', Pub),
    (   exists_file(Crt)
    ->  true
    ;   format("~nNo sample certificate at ~w.~n", [Crt]),
        format("Set ZIGURATIP to a built checkout and run again.~n"),
        fail
    ),

    format("~n-- a certificate says who it is~n"),
    x509_subject(Crt, S),
    must('the sample CA names itself', S,
         'C=US, dnQualifier=The Zigurat Informational Platform Project, ST=Chicago, CN=ZiguratIP, DC=ziguratip.com, emailAddress=info@ziguratip.com'),

    format("~n-- and whether YOU signed it~n"),
    (   x509_validate(Pub, Crt) -> V = valid ; V = no ),
    must('self-signed, so its own key checks it', V, valid),
    format("   VALIDATION FAILS, it does not raise. The C++ throws; this~n"),
    format("   binding turns that into `false', because \"this~n"),
    format("   certificate was not signed by you\" is an ordinary answer~n"),
    format("   to an ordinary question and a caller wants to branch on~n"),
    format("   it. The sentence is kept -- `x509_why/1' hands it back,~n"),
    format("   because a wrong key and a corrupt file are different~n"),
    format("   findings and a bare `false' cannot tell them apart.~n"),

    format("~n-- THE TWO LIBRARIES MEET HERE~n"),
    x509_public_key(Crt, K),
    %% THE CONTENTS OF A SubjectPublicKeyInfo, not the whole structure --
    %% the AlgorithmIdentifier and the BIT STRING with no SEQUENCE around
    %% them. `x509.hpp' says it is "the same shape the .pub files hold"
    %% and it measurably is not: 289 bytes here against the 293 of
    %% `dont-use-public.key', which is exactly a `30 82 01 21' header.
    atom_length(K, KL), must('the SPKI contents, in hex', KL, 578),
    der_wrap(48, K, Spki),
    der_decode(Spki, sequence([Alg, bit_string(Bits)])),
    must('the algorithm is rsaEncryption', Alg,
         sequence([oid('1.2.840.113549.1.1.1'), null])),
    der_decode(Bits, sequence([integer(Mod), integer(Exp)])),
    must('the public exponent', Exp, '65537'),
    atom_length(Mod, Digits),
    must('and a 2048-bit modulus in decimal', Digits, 617),
    sub_atom(Mod, 0, 16, _, Mod16),
    show('the first sixteen digits of it', Mod16),
    format("   The certificate came out of C++ and the modulus was read~n"),
    format("   in Prolog. That is the argument for having both libraries~n"),
    format("   at once, made concrete.~n"),

    format("~n-- PERMISSIONS: what makes this more than a key store~n"),
    x509_permissions(Crt, P),
    must('a v1 certificate grants nothing', P, []),
    format("   An issuer may write a list of strings into a certificate,~n"),
    format("   under ZiguratIP's own OID arc 1.3.6.1.4.1.55447.1.1, and~n"),
    format("   they mean NOTHING to the certificate: they are matched by~n"),
    format("   whoever cares. Which is exactly the shape a Prolog program~n"),
    format("   wants -- \"may this holder do that\" becomes a RULE over~n"),
    format("   facts read out of a signed document. Library 27 is that.~n"),

    format("~n-- a distinguished name as one file name~n"),
    x509_subject_file_name('CN=alice, O=Acme', N),
    must('percent encoded', N, 'CN=alice%2C%20O=Acme'),
    x509_file_name_subject(N, Back),
    must('and back', Back, 'CN=alice, O=Acme'),
    format("   A DN carries commas, spaces and equals signs, and nothing~n"),
    format("   stops it carrying a slash or a dot. Encoding everything~n"),
    format("   outside a plain set is what makes the result unable to~n"),
    format("   name anything outside its own directory.~n"),

    format("~n-- WHAT IS NOT HERE, and why~n"),
    format("   KEYS ARE FILES, NOT TERMS. A private key read into an atom~n"),
    format("   would be on the heap, in the trail, in every copy a channel~n"),
    format("   made of the term holding it, and in the knowledge base the~n"),
    format("   moment anything asserted it. cocolog's whole claim is that~n"),
    format("   a clause is a row somebody else can read; a signing key is~n"),
    format("   the one thing that must never become one.~n"),
    format("~n"),
    format("   AND NOT THE TLS HANDSHAKE. ZiguratIP has one, as a C++~n"),
    format("   iostream over a socket, and cocolog has no stream layer to~n"),
    format("   hang it on -- library(tcp) hands out handles into a table,~n"),
    format("   not descriptors. The certificates this module makes are~n"),
    format("   the same ones that server reads, which is the part that~n"),
    format("   had to be true.~n"),
    format("~n"),
    format("   `sh test/crypto.pl' issues one for real: 74 checks, key~n"),
    format("   generation included.~n~n"),
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
