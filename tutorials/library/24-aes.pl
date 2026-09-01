%% LIBRARY 24 -- library(aes): a block cipher, and what it does not do
%%
%%     COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/24-aes.pl main
%%
%% TIER 2: `sh modules/aes/build.sh', against a BUILT ZiguratIP. It is
%% `Zigurat::AES' -- the one X.509 encrypts private key files with.
%%
%%     aes_encrypt(+KeyHex, +IvHex, +PlainHex, -CipherHex)   CBC
%%     aes_decrypt(+KeyHex, +IvHex, +CipherHex, -PlainHex)
%%     aes_encrypt_ecb(+KeyHex, +PlainHex, -CipherHex)
%%     aes_decrypt_ecb(+KeyHex, +CipherHex, -PlainHex)
%%     aes_pad(+Hex, -PaddedHex)      aes_unpad(+PaddedHex, -Hex)
%%     aes_key_bits(+KeyHex, -Bits)   aes_block_size(-Bytes)
%%
%% EVERYTHING IS HEX. A key, an IV and a block of cipher text are
%% arbitrary bytes, and the shape a program reaches for them with -- an
%% atom, or a code list -- stops at a zero byte. (A string does not, but
%% these entry points predate it and hex is the interface they froze on.)
%%
%% READ THE LAST SECTION BEFORE USING THIS. AES-CBC hides content and
%% does NOT detect tampering, and that is not a footnote.

:- use_module(library(aes)).
:- use_module(library(sha)).

key('2b7e151628aed2a6abf7158809cf4f3c').
iv('000102030405060708090a0b0c0d0e0f').

main :-
    key(K), iv(IV),
    format("~n-- against NIST SP 800-38A, F.2.1~n"),
    aes_encrypt(K, IV, '6bc1bee22e409f96e93d7e117393172a', C),
    must('AES-128-CBC', C, '7649abac8119b246cee98e9b12e9197d'),
    aes_decrypt(K, IV, C, P),
    must('...and back', P, '6bc1bee22e409f96e93d7e117393172a'),

    format("~n-- THE KEY LENGTH CHOOSES THE CIPHER~n"),
    aes_key_bits(K, B1), must('16 bytes', B1, 128),
    atom_concat(K, K, K32),
    aes_key_bits(K32, B2), must('32 bytes', B2, 256),
    aes_block_size(BS), must('and a block is always', BS, 16),
    format("   There is no `strength' argument, because there is nothing~n"),
    format("   for one to be out of step WITH: 16, 24 and 32 bytes are~n"),
    format("   AES-128, -192 and -256, and any other length is refused.~n"),
    (   catch(aes_encrypt('0102', IV, C, _), error(domain_error(D, _), _), true)
    ->  R = D ; R = accepted ),
    must('a two-byte key', R, aes_key_or_iv_length),

    format("~n-- PADDING IS SEPARATE, and it is PKCS #7~n"),
    aes_pad('0102', Pad),
    must('two bytes become a block', Pad, '01020e0e0e0e0e0e0e0e0e0e0e0e0e0e'),
    aes_unpad(Pad, Back), must('and unpad takes it off', Back, '0102'),
    aes_pad('6bc1bee22e409f96e93d7e117393172a', Full), atom_length(Full, FL),
    must('an ALIGNED input still gains a whole block', FL, 64),
    format("   Which is the point of the scheme: the last byte always~n"),
    format("   says how much to remove, so there is never a case where a~n"),
    format("   data byte could be read as a length.~n"),
    (   aes_unpad('00000000000000000000000000000000', _)
    ->  U = accepted ; U = refused ),
    must('padding that is not well formed', U, refused),
    format("   EVERY padding byte is checked, not just the last. Trusting~n"),
    format("   the last one turns a decryption with the WRONG KEY into a~n"),
    format("   plausible shorter message instead of an error.~n"),

    format("~n-- ECB is the fire escape, and the shape shows through~n"),
    aes_encrypt_ecb(K, '6bc1bee22e409f96e93d7e117393172a6bc1bee22e409f96e93d7e117393172a', E),
    sub_atom(E, 0, 32, _, First), sub_atom(E, 32, 32, _, Second),
    must('two equal blocks give two EQUAL cipher blocks', First, Second),
    format("   That is the famous picture of a penguin that is still a~n"),
    format("   penguin after encryption. `aes_encrypt_ecb/3' is here~n"),
    format("   because X.509 private key files were written that way and~n"),
    format("   have to keep opening. Anything new should chain.~n"),
    aes_encrypt(K, IV, '6bc1bee22e409f96e93d7e117393172a6bc1bee22e409f96e93d7e117393172a', Chained),
    sub_atom(Chained, 0, 32, _, CFirst), sub_atom(Chained, 32, 32, _, CSecond),
    (   CFirst == CSecond -> Same = equal ; Same = different ),
    must('...under CBC they are', Same, different),

    format("~n-- WHAT THIS IS NOT: authenticated encryption~n"),
    format("   AES-CBC hides content and does not detect tampering. A~n"),
    format("   cipher text edited in flight decrypts to SOMETHING,~n"),
    format("   quietly. Cover it with an HMAC over the IV and the cipher~n"),
    format("   text, and check that BEFORE you decrypt:~n"),
    aes_encrypt(K, IV, '6bc1bee22e409f96e93d7e117393172a', Ct),
    atom_concat(IV, Ct, Covered),
    sha_hmac_hex(sha256, K, Covered, Tag),
    atom_length(Tag, TL), must('a tag over iv || ciphertext', TL, 64),
    format("   ...and note the ORDER: check the tag, then decrypt. The~n"),
    format("   other way round is a padding oracle, which is a real~n"),
    format("   attack on exactly this construction.~n~n"),
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
