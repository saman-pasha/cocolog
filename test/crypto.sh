#!/bin/sh
# ZiguratIP's cryptography and its CA, as cocolog predicates: library(sha),
# library(aes), library(der), library(x509) and library(ca).
#
# HELD TO PUBLISHED VECTORS WHERE THERE ARE ANY -- FIPS 180 for the
# digests, RFC 4231 for HMAC, NIST SP 800-38A F.2.1 for AES-CBC, and DER's
# own worked examples for the integer encoding. A binding that answers
# confidently and wrongly is worse than one that does not build, and the
# only defence is an answer somebody else published first.
#
# AND TO A ROUND TRIP WHERE THERE ARE NOT. `library(der)' writes a term,
# reads it back and writes it again, and the two texts are compared --
# the same discipline test/serialize.sh holds json, xml and html to, for
# the same reason: a reader and a writer that disagree about the same
# certificate are worse than either alone.
#
# THE CA IS EXERCISED FOR REAL, not mocked: a key is generated, a signing
# request made from it, a certificate issued against ZiguratIP's own
# sample authority, and the result validated, read, signed with and
# checked. That takes a few seconds of RSA key generation and is worth it
# -- everything cheaper proves the module loads and nothing else.
#
# SKIPS when the .so's are not there, because "no ZiguratIP built here"
# and "the binding is wrong" are different findings.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
. "$HERE/library-path.sh"

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built"
  exit 0
fi
for m in sha aes der x509; do
  if [ ! -f "$ROOT/library/$m.so" ]; then
    echo "SKIP no library/$m.so -- sh modules/$m/build.sh (needs a built ZiguratIP)"
    exit 0
  fi
done

# The sample authority ZiguratIP ships. Its private key is in that
# repository and in every clone of it, which is the point: it is not a
# secret and a test may use it.
CERT="${ZIGURATIP:-$HOME/ZiguratIP}/home/etc/cert"
if [ ! -f "$CERT/issuer.conf" ]; then
  echo "SKIP no $CERT/issuer.conf -- set ZIGURATIP to a built checkout"
  exit 0
fi

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-crypto-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

cat > "$OUT/subject.conf" <<'CONF'
COUNTRY: IR
ORGANIZATION: Coco
ORGANIZATIONAL_UNIT: 
DISTINGUISHED_NAME_QUALIFIER: 
STATE_OR_PROVINCE_NAME: 
COMMON_NAME: alice
SERIAL_NUMBER: 
LOCALITY: 
TITLE: 
NAME: 
SURNAME: 
GIVEN_NAME: 
INITIALS: 
PSEUDONYM: 
GENERATION_QUALIFIER: 
DOMAIN_COMPONENT: 
EMAIL_ADDRESS: alice@example.org
CONF

cat > "$OUT/case.pl" <<PL
:- use_module(library(sha)).
:- use_module(library(aes)).
:- use_module(library(der)).
:- use_module(library(x509)).
:- use_module(library(ca)).

cert_dir('$CERT').
work('$OUT').
PL

cat >> "$OUT/case.pl" <<'PL'

main :-
    nb_zero,
    digests, macs, ciphers, encodings, certificates, authority,
    checks(N), fails(F),
    format("~w check(s)~n", [N]),
    (   F =:= 0
    ->  format("GREEN: 0 failure(s)~n")
    ;   format("RED: ~w failure(s)~n", [F])
    ).

%% ---- the harness, four clauses ---------------------------------------
:- dynamic count/2.
nb_zero :- retractall(count(_, _)), assertz(count(checks, 0)), assertz(count(fails, 0)).
checks(N) :- count(checks, N).
fails(N) :- count(fails, N).
bump(K) :- retract(count(K, N)), N1 is N + 1, assertz(count(K, N1)).

ok(Label, Got, Want) :-
    bump(checks),
    (   Got == Want
    ->  true
    ;   bump(fails),
        format("FAIL ~w~n  got  ~q~n  want ~q~n", [Label, Got, Want])
    ).

yes(Label, Goal) :-
    bump(checks),
    (   call(Goal) -> true ; bump(fails), format("FAIL ~w (did not hold)~n", [Label]) ).

no(Label, Goal) :-
    bump(checks),
    (   call(Goal) -> bump(fails), format("FAIL ~w (held, and must not)~n", [Label]) ; true ).

%% ---- library(sha): FIPS 180 and RFC 4231 -----------------------------
digests :-
    sha_hash(sha256, abc, A),
    ok('sha256("abc")', A, ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad),
    sha_hash(sha1, '', B),
    ok('sha1("")', B, da39a3ee5e6b4b0d3255bfef95601890afd80709),
    sha_hash(sha224, abc, C),
    ok('sha224("abc")', C, '23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7'),
    sha_hash(sha384, abc, D),
    ok('sha384("abc")', D, 'cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7'),
    sha_hash(sha512, abc, E),
    ok('sha512("abc")', E, 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f'),
    sha_size(sha256, S256), ok('sha_size(sha256)', S256, 32),
    sha_size(sha512, S512), ok('sha_size(sha512)', S512, 64),
    findall(Alg, sha_algorithm(Alg), Algs),
    ok('the five algorithms', Algs, [sha1, sha224, sha256, sha384, sha512]),
    %% HEX IN IS THE SAME BYTES AS TEXT IN, which is the check that the
    %% two entry points cannot drift: 616263 is "abc".
    sha_hash_hex(sha256, '616263', F),
    ok('sha_hash_hex over the same bytes', F, A),
    no('an unknown algorithm is refused',
       catch(sha_hash(md5, abc, _), _, fail)).

macs :-
    %% RFC 4231 test case 1: a 20-byte key of 0x0b, "Hi There".
    sha_hmac_hex(sha256, '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b', '4869205468657265', A),
    ok('RFC 4231 case 1, sha256', A,
       b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7),
    sha_hmac_hex(sha512, '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b', '4869205468657265', B),
    ok('RFC 4231 case 1, sha512', B,
       '87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854'),
    %% THE KEY COMES FIRST, and the check is that swapping them changes
    %% the answer -- HMAC(k,m) is not HMAC(m,k) and a binding that had
    %% them the wrong way round would pass every round trip.
    sha_hmac(sha256, key, message, C),
    sha_hmac(sha256, message, key, D),
    no('HMAC is not symmetric in its arguments', C == D).

%% ---- library(aes): NIST SP 800-38A -----------------------------------
ciphers :-
    K = '2b7e151628aed2a6abf7158809cf4f3c',
    IV = '000102030405060708090a0b0c0d0e0f',
    P = '6bc1bee22e409f96e93d7e117393172a',
    aes_encrypt(K, IV, P, C),
    ok('SP 800-38A F.2.1 AES-128-CBC', C, '7649abac8119b246cee98e9b12e9197d'),
    aes_decrypt(K, IV, C, P2),
    ok('...and back', P2, P),
    aes_key_bits(K, B128), ok('aes_key_bits, 16 bytes', B128, 128),
    atom_concat(K, K, K256),
    aes_key_bits(K256, B256), ok('aes_key_bits, 32 bytes', B256, 256),
    aes_block_size(BS), ok('aes_block_size', BS, 16),
    %% PKCS #7 ADDS A WHOLE BLOCK WHEN THE INPUT IS ALREADY ALIGNED,
    %% which is the property that makes the last byte always a length.
    aes_pad(P, Padded), atom_length(Padded, PL),
    ok('an aligned input still gains a block', PL, 64),
    aes_unpad(Padded, P3), ok('and unpad takes it off', P3, P),
    aes_pad('0102', Short),
    ok('PKCS #7 pads with the count', Short, '01020e0e0e0e0e0e0e0e0e0e0e0e0e0e'),
    no('padding that is not well formed is refused',
       aes_unpad('00000000000000000000000000000000', _)),
    no('a key of the wrong length is refused',
       catch(aes_encrypt('0102', IV, P, _), _, fail)),
    no('an iv of the wrong length is refused',
       catch(aes_encrypt(K, '00', P, _), _, fail)),
    no('a part block is refused',
       catch(aes_encrypt(K, IV, '01', _), _, fail)).

%% ---- library(der) ----------------------------------------------------
encodings :-
    %% TWO'S COMPLEMENT, SHORTEST FORM. 127 fits in a byte; 128 needs a
    %% leading zero or it reads as -128; -1 is 0xFF. This is where a
    %% hand-rolled encoder is wrong and stays wrong for years.
    der_encode(integer('127'), A), ok('DER INTEGER 127', A, '02017f'),
    der_encode(integer('128'), B), ok('DER INTEGER 128', B, '02020080'),
    der_encode(integer('-1'), C), ok('DER INTEGER -1', C, '0201ff'),
    der_encode(integer('-129'), D), ok('DER INTEGER -129', D, '0202ff7f'),
    der_encode(integer('0'), Z), ok('DER INTEGER 0', Z, '020100'),
    der_encode(oid('1.2.840.113549.1.1.1'), E),
    ok('rsaEncryption', E, '06092a864886f70d010101'),
    der_encode(null, N), ok('DER NULL', N, '0500'),
    der_encode(printable(hi), PS), ok('PRINTABLE STRING', PS, '13026869'),
    der_encode(sequence([integer('1'), null]), SQ),
    ok('a SEQUENCE', SQ, '30050201010500'),
    der_encode(bit_string('0a0b'), BS),
    ok('a BIT STRING has a zero unused-bit octet', BS, '0303000a0b'),
    der_tlv('3003020101', T, V, R),
    ok('der_tlv splits one value off the front', T-V-R, 48-'020101'-''),
    %% A MODULUS DOES NOT FIT IN SIXTY-FOUR BITS, which is why an integer
    %% here is a decimal atom. cocolog's own would wrap in silence.
    Big = '26959946667150639794667015087019630673557916260026308143510066298881',
    der_encode(integer(Big), BH), der_decode(BH, BT),
    ok('a 2048-bit-class integer survives', BT, integer(Big)),
    %% AN UNKNOWN TAG ROUND-TRIPS RATHER THAN FAILING, which is what lets
    %% a parser read a certificate carrying an extension it never met.
    der_decode('1f0141', UT), ok('an unknown tag', UT, unknown(31, '41')),
    roundtrip(sequence([context(0, integer('2')), integer('-129'),
                        set([printable(a), ia5(b)]), unknown(31, '41'),
                        oid('2.5.4.3'), utc_time('1700000000')])),
    roundtrip(sequence([sequence([oid('1.2.840.113549.1.1.1'), null]),
                        bit_string('3003020101')])).

%% THE ROUND TRIP IS THE REAL TEST. Write, read, write again, compare the
%% BYTES -- and the term too, because a reader that lost a field and a
%% writer that invented one would agree with each other.
roundtrip(Term) :-
    der_encode(Term, Once),
    der_decode(Once, Back),
    der_encode(Back, Twice),
    ok('round trip, bytes', Once, Twice),
    ok('round trip, term', Back, Term).

%% ---- library(x509): a real certificate -------------------------------
certificates :-
    cert_dir(C), work(W),
    atom_concat(C, '/dont-use-certificate.crt', CaCrt),
    atom_concat(C, '/dont-use-public.key', CaPub),
    x509_subject(CaCrt, S),
    ok('the sample CA names itself', S,
       'C=US, dnQualifier=The Zigurat Informational Platform Project, ST=Chicago, CN=ZiguratIP, DC=ziguratip.com, emailAddress=info@ziguratip.com'),
    yes('a self-signed CA validates against its own key', x509_validate(CaPub, CaCrt)),
    x509_permissions(CaCrt, NoPerms),
    ok('a v1 certificate grants nothing', NoPerms, []),
    %% A DN AS ONE FILE NAME, and back -- everything outside a plain set
    %% percent encoded, so it can never name anything outside its
    %% directory.
    x509_subject_file_name('CN=alice, O=Acme', FN),
    ok('a DN as a file name', FN, 'CN=alice%2C%20O=Acme'),
    x509_file_name_subject(FN, DN),
    ok('...and back', DN, 'CN=alice, O=Acme'),
    %% THE TWO LIBRARIES MEET HERE: a public key that came out of C++,
    %% taken apart in Prolog.
    x509_public_key(CaCrt, K),
    der_wrap(48, K, Spki),
    der_decode(Spki, sequence([Alg, bit_string(Bits)])),
    ok('the algorithm is rsaEncryption', Alg,
       sequence([oid('1.2.840.113549.1.1.1'), null])),
    der_decode(Bits, sequence([integer(Mod), integer(Exp)])),
    ok('the public exponent', Exp, '65537'),
    atom_length(Mod, ModDigits),
    ok('a 2048-bit modulus is 617 decimal digits', ModDigits, 617),
    %% ---- and now issue one, for real
    atom_concat(C, '/issuer.conf', IssuerConf),
    atom_concat(C, '/dont-use-private.key', IssuerKey),
    atom_concat(W, '/subject.conf', Subject),
    atom_concat(W, '/alice.key', Key),
    atom_concat(W, '/alice.pub', Pub),
    atom_concat(W, '/alice.csr', Csr),
    atom_concat(W, '/alice.crt', Crt),
    x509_keygen([], Key, Pub, Tries),
    yes('key generation reports its tries', integer(Tries)),
    x509_csr(Subject, Key, [], Csr),
    yes('the request exists', exists_file(Csr)),
    x509_issue([serial(7), permission(read), permission('ledger.write')],
               IssuerConf, IssuerKey, Csr, Crt),
    x509_subject(Crt, ASub),
    ok('the certificate names its holder', ASub,
       'C=IR, O=Coco, CN=alice, emailAddress=alice@example.org'),
    x509_permissions(Crt, Perms),
    ok('and carries what the issuer granted', Perms, [read, 'ledger.write']),
    yes('it chains to the authority', x509_validate(CaPub, Crt)),
    no('and not to the holder key', x509_validate(Pub, Crt)),
    yes('the refusal says why', (x509_why(Why), Why \== '')),
    %% ---- the RSA operations a certificate makes possible
    sha_hash(sha256, 'the message', Digest),
    x509_sign(Key, '', 'SHA-256', Digest, Sig),
    yes('a 2048-bit signature is 256 bytes', (atom_length(Sig, 512))),
    yes('and it verifies', x509_verify(Crt, 'SHA-256', Digest, Sig)),
    sha_hash(sha256, 'the mess age', Other),
    no('a different message does not', x509_verify(Crt, 'SHA-256', Other, Sig)),
    x509_encrypt(Crt, '48656c6c6f', Enc),
    x509_decrypt(Key, '', Enc, Dec),
    ok('encrypt to a certificate, decrypt with the key', Dec, '48656c6c6f').

%% ---- library(ca): the rules ------------------------------------------
authority :-
    cert_dir(C), work(W),
    atom_concat(C, '/dont-use-public.key', CaPub),
    atom_concat(W, '/alice.crt', Crt),
    ca_root(zigurat, CaPub),
    yes('a root is a fact', ca_trusted(zigurat, CaPub)),
    ca_chains(Crt, Root),
    ok('ca_chains names WHICH root', Root, zigurat),
    yes('and ca_valid agrees', ca_valid(Crt)),
    ca_load(Crt),
    ca_holder(Subject, Crt),
    ok('a certificate became clauses', Subject,
       'C=IR, O=Coco, CN=alice, emailAddress=alice@example.org'),
    findall(P, ca_grants(Subject, P), Ps),
    ok('and its grants are facts', Ps, [read, 'ledger.write']),
    %% THE RULE, and the four things it has to get right.
    yes('an exact grant permits', ca_may(Subject, 'ledger.write')),
    yes('a prefix grant permits below it', ca_may(Subject, 'read.balance')),
    no('a grant does not permit its own prefix', ca_may(Subject, ledger)),
    no('and does not permit a sibling', ca_may(Subject, 'ledger.read')),
    no('`read" does not cover `readx"', ca_may(Subject, readx)),
    no('a stranger may do nothing at all', ca_may('CN=mallory', read)),
    ca_forget(Crt),
    no('forgetting takes the holder away', ca_holder(Subject, _)),
    no('and the grants with them', ca_grants(Subject, _)).
PL

"$COCOLOG" run "$OUT/case.pl" main 2>&1
