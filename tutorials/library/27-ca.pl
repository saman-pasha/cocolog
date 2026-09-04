%% LIBRARY 27 -- library(ca): a certificate authority, as rules
%%
%%     ZIGURATIP=/path/to/ZiguratIP COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/27-ca.pl main
%%
%% TIER 2, CLAUSES ONLY -- `library/ca.pl'. It stands on `library(x509)'
%% for the bytes and adds the half that belongs in Prolog.
%%
%%     ca_root(+Name, +PubKeyPath)     ca_trusted(?Name, ?Path)
%%     ca_chains(+CertPath, -Root)     ca_valid(+CertPath)
%%     ca_enrol(+Dir, +Name, +SubjectConf, +Opts)
%%     ca_files(+Dir, +Name, -Key, -Pub, -Csr, -Cert)
%%     ca_load(+CertPath)              ca_forget(+CertPath)
%%     ca_holder(?Subject, ?CertPath)  ca_grants(?Subject, ?Permission)
%%     ca_may(+Subject, +Action)       ca_covers(+Grant, +Action)
%%
%% WHY THIS FILE EXISTS. `library(x509)' is a faithful binding: every
%% entry point ZiguratIP's `ca' tool has, taking the paths that tool
%% takes. That is the right shape for a back end and the wrong one for a
%% program, because the interesting questions are not "issue this CSR"
%% but "is this certificate one of ours" and "may this holder do that" --
%% and those are RULES over facts read out of a signed document.

:- use_module(library(ca)).
:- use_module(library(files)).

cert_dir(D) :-
    (   getenv('ZIGURATIP', Z) -> true ; Z = '/home/user/ZiguratIP' ),
    atom_concat(Z, '/home/etc/cert', D).

file(Name, Path) :- cert_dir(D), atomic_list_concat([D, '/', Name], Path).

main :-
    file('dont-use-public.key', CaPub),
    file('dont-use-certificate.crt', CaCrt),
    (   exists_file(CaPub)
    ->  true
    ;   format("~nNo sample authority at ~w.~n", [CaPub]),
        format("Set ZIGURATIP to a built checkout and run again.~n"),
        fail
    ),

    format("~n-- A TRUSTED ROOT IS A FACT~n"),
    ca_root(zigurat, CaPub),
    (   ca_trusted(zigurat, CaPub) -> T = there ; T = missing ),
    must('ca_root/2 asserts it', T, there),
    format("   So the set of roots is a PREDICATE: assert one, retract~n"),
    format("   one, list them -- or, against a server, have another~n"),
    format("   process assert one and this one see it. There is no~n"),
    format("   configuration file and no registry; the store is both.~n"),

    format("~n-- and validation names WHICH root~n"),
    ca_chains(CaCrt, R),
    must('ca_chains/2', R, zigurat),
    format("   Not merely whether. Two roots during a key rotation is the~n"),
    format("   ordinary case, and \"it is valid\" is a worse answer than~n"),
    format("   \"valid under the old one\" when the old one retires this~n"),
    format("   week.~n"),

    format("~n-- A CERTIFICATE BECOMES CLAUSES, which is the point~n"),
    ca_load(CaCrt),
    ca_holder(Subject, CaCrt),
    must('who it names is now a fact', Subject,
         'C=US, dnQualifier=The Zigurat Informational Platform Project, ST=Chicago, CN=ZiguratIP, DC=ziguratip.com, emailAddress=info@ziguratip.com'),
    findall(P, ca_grants(Subject, P), Ps),
    must('a v1 certificate grants nothing', Ps, []),
    format("   Once `ca_load/1' has run, who somebody is and what they~n"),
    format("   may do are ordinary facts -- which means they are ROWS,~n"),
    format("   which means another process can ask. A gateway loads the~n"),
    format("   certificates it trusts at start-up, and every later~n"),
    format("   `ca_may/2' is a query against the store rather than a~n"),
    format("   signature check against a file.~n"),

    format("~n-- THE RULE, and the four things it has to get right~n"),
    Alice = 'CN=alice',
    assertz(ca_grants(Alice, read)),
    assertz(ca_grants(Alice, 'ledger.write')),
    (   ca_may(Alice, 'ledger.write') -> A1 = yes ; A1 = no ),
    must('an exact grant permits', A1, yes),
    (   ca_may(Alice, 'read.balance') -> A2 = yes ; A2 = no ),
    must('a grant permits BELOW itself', A2, yes),
    (   ca_may(Alice, ledger) -> A3 = yes ; A3 = no ),
    must('but not its own prefix', A3, no),
    (   ca_may(Alice, 'ledger.read') -> A4 = yes ; A4 = no ),
    must('and not a sibling', A4, no),
    (   ca_may(Alice, readx) -> A5 = yes ; A5 = no ),
    must('`read" does not cover `readx"', A5, no),
    (   ca_may('CN=mallory', read) -> A6 = yes ; A6 = no ),
    must('a stranger may do NOTHING', A6, no),
    format("   That last one is the direction a permission system has to~n"),
    format("   fail in: an empty knowledge base denies. And the whole~n"),
    format("   policy is three clauses you can read --~n"),
    format("~n"),
    format("     ca_covers(G, A) :- G == A, !.~n"),
    format("     ca_covers(G, A) :- atom_concat(G, '.', P),~n"),
    format("                        atom_concat(P, _, A).~n"),
    format("~n"),
    format("   -- which is the argument for having it here rather than~n"),
    format("   inside a C function. A permission system nobody can read~n"),
    format("   is a permission system nobody can audit.~n"),

    format("~n-- and it can be taken back~n"),
    ca_forget(CaCrt),
    (   ca_holder(Subject, _) -> F = still_there ; F = gone ),
    must('ca_forget/1', F, gone),

    format("~n-- ENROLMENT: one name instead of four paths~n"),
    ca_files('/var/pki', bob, K, Pub, Csr, Crt),
    must('the key', K, '/var/pki/bob.key'),
    must('its public half', Pub, '/var/pki/bob.pub'),
    must('the request', Csr, '/var/pki/bob.csr'),
    must('and the certificate', Crt, '/var/pki/bob.crt'),
    format("~n"),
    format("     ca_enrol('/var/pki', bob, 'bob.conf',~n"),
    format("              [ issuer('issuer.conf'),~n"),
    format("                issuer_key('ca.key'),~n"),
    format("                permission('ledger.read') ]).~n"),
    format("~n"),
    format("   THE ISSUER OPTION IS A NAME CONFIGURATION, NOT A~n"),
    format("   CERTIFICATE, and that cost an afternoon: what gets written~n"),
    format("   into the certificate is the issuer's distinguished NAME,~n"),
    format("   and the key beside it does the signing. Handing it the~n"),
    format("   issuer's .crt fails deep inside a configuration parser~n"),
    format("   with a message about line 1 and some DER bytes.~n"),
    format("~n"),
    format("   `sh test/crypto.pl' runs the whole thing for real -- key,~n"),
    format("   request, certificate, signature, verification, and these~n"),
    format("   rules over a certificate that was issued a second earlier.~n~n"),
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
