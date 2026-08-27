%% library(ca) -- a certificate authority, as rules.
%%
%%     :- use_module(library(ca)).
%%
%% TIER 2, clauses only. It stands on `library(x509)' for the bytes and
%% adds the half that belongs in Prolog: a workflow with names instead of
%% five file paths, a set of trusted roots that is a PREDICATE, and
%% authorisation as a rule you can read.
%%
%% THE ARGUMENT FOR THIS FILE EXISTING. `library(x509)' is a faithful
%% binding: every entry point ZiguratIP's `ca' tool has, one predicate
%% each, taking the paths that tool takes. That is the right shape for a
%% back end and the wrong one for a program, because the interesting
%% questions are not "issue this CSR" but "is this certificate one of
%% ours" and "may this holder do that" -- and those are RULES over facts
%% read out of a signed document. Which is what this interpreter is for.
%%
%%     ca_root(+Name, +PubKeyPath)      trust a root, as a fact
%%     ca_trusted(?Name, ?PubKeyPath)   the roots, on backtracking
%%     ca_chains(+CertPath, -Root)      which root signed it, if any
%%     ca_valid(+CertPath)              some trusted root signed it
%%
%%     ca_enrol(+Dir, +Name, +SubjectConf, +Opts)   key, csr, certificate
%%     ca_files(+Dir, +Name, -Key, -Pub, -Csr, -Cert)
%%
%%     ca_load(+CertPath)               a certificate, as clauses
%%     ca_holder(?Subject, ?CertPath)
%%     ca_grants(?Subject, ?Permission)
%%     ca_may(+Subject, +Action)        THE RULE
%%     ca_forget(+CertPath)
%%
%% A CERTIFICATE BECOMES CLAUSES, and that is the point of the file. Once
%% `ca_load/1' has run, who somebody is and what they may do are ordinary
%% facts in the knowledge base -- which means they are ROWS, which means
%% another process can ask. A gateway loads the certificates it trusts at
%% start-up and every later `ca_may/2' is a query against the store, not a
%% signature check against a file.
%%
%% AUTHORISATION IS A PREFIX MATCH, deliberately. A permission written
%% `ledger' allows `ledger.write' and `ledger.read.balance'; one written
%% `ledger.read' does not allow `ledger.write'. That is the rule
%% ZiguratIP matches an object's qualified name with, and putting it here
%% -- three clauses, in Prolog -- is what makes it arguable. A permission
%% system nobody can read is a permission system nobody can audit.
%%
%% NOTHING HERE HOLDS A PRIVATE KEY. `library(x509)' takes keys as paths
%% and never lets their bytes become a term, for the reason its header
%% gives at length: a term reaches the trail, a channel copy and the
%% knowledge base. This file inherits that and asserts only what a
%% certificate says in public -- a subject, a path, and the permissions
%% its issuer wrote into it.

:- use_module(library(x509)).

:- dynamic ca_trusted/2.
:- dynamic ca_holder/2.
:- dynamic ca_grants/2.

%% ---- trusted roots ---------------------------------------------------
%%
%% A ROOT IS A FACT, so the set of them is a predicate: assert one,
%% retract one, list them, or -- against a server -- have another process
%% assert one and this one see it. There is no configuration file and no
%% registry; the knowledge base is both.

ca_root(Name, PubKeyPath) :-
    (   exists_file(PubKeyPath)
    ->  true
    ;   throw(error(existence_error(source_sink, PubKeyPath), ca_root/2))
    ),
    retractall(ca_trusted(Name, _)),
    assertz(ca_trusted(Name, PubKeyPath)).

%% `ca_chains/2' ANSWERS WHICH ROOT, not merely whether. Two roots during
%% a key rotation is the ordinary case, and "it is valid" is a worse
%% answer than "it is valid under the old one" when the old one is being
%% retired this week.
ca_chains(CertPath, Root) :-
    ca_trusted(Root, Pub),
    x509_validate(Pub, CertPath).

ca_valid(CertPath) :-
    ca_chains(CertPath, _),
    !.

%% ---- enrolment -------------------------------------------------------
%%
%% ONE NAME INSTEAD OF FOUR PATHS. Every file a holder needs is derived
%% from a directory and a name, so a caller writes `alice' and not
%% `/var/pki/alice.key', `/var/pki/alice.pub', `/var/pki/alice.csr' and
%% `/var/pki/alice.crt' -- four chances to get one of them wrong, three of
%% which fail late.

ca_files(Dir, Name, Key, Pub, Csr, Cert) :-
    atomic_list_concat([Dir, '/', Name, '.key'], Key),
    atomic_list_concat([Dir, '/', Name, '.pub'], Pub),
    atomic_list_concat([Dir, '/', Name, '.csr'], Csr),
    atomic_list_concat([Dir, '/', Name, '.crt'], Cert).

%% ca_enrol(+Dir, +Name, +SubjectConf, +Opts)
%%
%% Opts carries `issuer(ConfPath)' and `issuer_key(KeyPath)' -- the two
%% that have no sensible default because they are the authority's own --
%% and anything `x509_keygen/4' or `x509_issue/5' understands, which is
%% passed straight through. `permission(P)' as often as the issuer likes.
%%
%% THE ISSUER OPTION IS A NAME CONFIGURATION, NOT A CERTIFICATE. That is
%% `library(x509)''s finding and this file does not soften it: what
%% `x509_issue/5' writes into the certificate is the issuer's
%% DISTINGUISHED NAME, and the key beside it does the signing.
ca_enrol(Dir, Name, SubjectConf, Opts) :-
    memberchk(issuer(IssuerConf), Opts),
    memberchk(issuer_key(IssuerKey), Opts),
    ca_files(Dir, Name, Key, Pub, Csr, Cert),
    x509_keygen(Opts, Key, Pub, _),
    x509_csr(SubjectConf, Key, Opts, Csr),
    x509_issue(Opts, IssuerConf, IssuerKey, Csr, Cert).

%% ---- a certificate, as clauses ---------------------------------------

ca_load(CertPath) :-
    x509_subject(CertPath, Subject),
    x509_permissions(CertPath, Permissions),
    retractall(ca_holder(Subject, CertPath)),
    assertz(ca_holder(Subject, CertPath)),
    ca_assert_grants(Subject, Permissions).

ca_assert_grants(_, []) :- !.
ca_assert_grants(Subject, [P|Ps]) :-
    (   ca_grants(Subject, P)
    ->  true
    ;   assertz(ca_grants(Subject, P))
    ),
    ca_assert_grants(Subject, Ps).

ca_forget(CertPath) :-
    (   ca_holder(Subject, CertPath)
    ->  retractall(ca_holder(Subject, CertPath)),
        (   ca_holder(Subject, _)
        ->  true                    % another certificate still names them
        ;   retractall(ca_grants(Subject, _))
        )
    ;   true
    ).

%% ---- THE RULE --------------------------------------------------------
%%
%% `ca_may(Subject, Action)' is four lines and every one of them is
%% arguable, which is the whole reason it is here rather than inside a C
%% function. A grant of `ledger' covers `ledger.write'; a grant of
%% `ledger.read' does not cover `ledger.write'; and a holder with no
%% certificate loaded may do nothing at all -- an empty knowledge base
%% denies rather than permits, which is the direction a permission system
%% has to fail in.

ca_may(Subject, Action) :-
    ca_grants(Subject, Grant),
    ca_covers(Grant, Action),
    !.

%% `ca_covers/2' IS SEPARATE so it can be tested on its own, and so a
%% program that wants a different policy can read this one before writing
%% it. Exact, or a dotted prefix -- and the dot has to be there: `ledger'
%% must not cover `ledgerx'.
ca_covers(Grant, Action) :-
    Grant == Action,
    !.
ca_covers(Grant, Action) :-
    atom_concat(Grant, '.', Prefix),
    atom_concat(Prefix, _, Action).
