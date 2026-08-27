%% LIBRARY 28 -- library(tls): a connection that knows who is on it
%%
%%     ZIGURATIP=/path/to/ZiguratIP COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/28-tls.pl main
%%
%% TIER 2: `sh modules/tls/build.sh'. It is `Zigurat::tlsstream' from
%% SocketIO -- real OpenSSL underneath, TLS 1.2 at the lowest, and a
%% cipher list that is ECDHE and AEAD and nothing else.
%%
%%     tls_listen(+Port, -Server)         tls_listen(+Port, +Opts, -Server)
%%     tls_accept(+Server, +Ms, +Creds, -Conn, -Peer)
%%     tls_connect(+Host, +Service, +Creds, -Conn)
%%     tls_read(+Conn, +MaxBytes, +Ms, -Codes)   tls_write(+Conn, +Codes)
%%     tls_close(+Conn)                   tls_connections(-N)
%%     tls_peer_subject(+Conn, -Subject)  tls_peer_permissions(+Conn, -List)
%%     tls_peer(+Conn, -Address)          tls_why(-Reason)
%%
%% THIS LESSON OPENS NO PORT. A handshake needs two ends and a tutorial
%% is one process; `sh test/tls.sh' raises a server and runs three
%% different clients at it -- enrolled, impostor, browser. Here the
%% checks are the ones a single process can make honestly, and the rest
%% is the argument.

:- use_module(library(tls)).

main :-
    format("~n-- A HANDLE IS A SLOT, which is library(tcp)'s rule~n"),
    tls_connections(N0),
    must('no connections yet', N0, 0),
    ( tls_read(9999, 16, 10, _) -> R1 = read ; R1 = failed ),
    must('an integer this module did not hand out', R1, failed),
    ( tls_peer_subject(-1, _) -> R2 = answered ; R2 = failed ),
    must('...and a negative one', R2, failed),
    tls_close(9999),
    format("   Prolog does arithmetic, so ANY integer can arrive at any~n"),
    format("   of these predicates. A slot this module did not fill is~n"),
    format("   not a connection, and saying so is the difference between~n"),
    format("   a failed call and a closed stdout.~n"),

    format("~n-- \"cocolog HAS NO STREAM LAYER\" WAS THE WRONG OBJECTION~n"),
    format("   `Zigurat::tlsstream' is a C++ iostream and there is~n"),
    format("   genuinely nothing in cocolog to hand one to. But nothing~n"),
    format("   has to be: the stream stays inside the module for its~n"),
    format("   whole life and what crosses into Prolog is an INDEX. That~n"),
    format("   is exactly what library(tcp) does with a descriptor, and a~n"),
    format("   TLS connection is no more a term than a socket is.~n"),

    format("~n-- CREDENTIALS ARE AN OPTION LIST, and the paths are PATHS~n"),
    format("~n"),
    format("     Creds = [ certificate('node.crt'),~n"),
    format("               key('node.key'),~n"),
    format("               key_cipher(Pass),~n"),
    format("               authority('ca.crt'),~n"),
    format("               client_auth(required) ].~n"),
    format("~n"),
    format("   That they are file names is OpenSSL's decision, not this~n"),
    format("   module's -- but it is the rule library(x509) already~n"),
    format("   follows and for the same reason: a private key that~n"),
    format("   became a cocolog term would be on the heap, in the trail,~n"),
    format("   in every copy a channel made of the term holding it, and~n"),
    format("   in the knowledge base the moment anything asserted it.~n"),

    format("~n-- MUTUAL AUTHENTICATION IS THE DEFAULT~n"),
    format("   `client_auth(required)' is what you get by saying~n"),
    format("   nothing: a peer is who the authority says it is, or it~n"),
    format("   does not get in. A browser has no such certificate and~n"),
    format("   never will, so a port meant for one says~n"),
    format("   `client_auth(none)'.~n"),
    format("~n"),
    format("   `optional' is NOT \"trust anything\": a certificate that~n"),
    format("   IS offered is still checked and a bad one still fails~n"),
    format("   the handshake. Nobody gets in as a stranger by sending~n"),
    format("   something broken.~n"),

    format("~n-- WHAT THE HANDSHAKE ANSWERS, which is the interesting part~n"),
    format("~n"),
    format("     serve(Conn) :-~n"),
    format("         tls_peer_subject(Conn, Who),~n"),
    format("         tls_peer_permissions(Conn, Granted),~n"),
    format("         ( member(G, Granted), ca_covers(G, 'ledger.write')~n"),
    format("         -> apply_the_write(Conn)~n"),
    format("         ;  refuse(Conn, Who) ).~n"),
    format("~n"),
    format("   BOTH ARE SETTLED DURING THE HANDSHAKE, against the~n"),
    format("   authority, before a byte moves. So a server does not~n"),
    format("   authenticate its peer -- that already happened -- and~n"),
    format("   what is left is AUTHORISATION, which is a rule over facts.~n"),
    format("   The permissions came out of a certificate an issuer~n"),
    format("   signed; `library(ca)' is the half that decides what they~n"),
    format("   mean. test/tls.sh shows alice arriving with~n"),
    format("   [read, 'ledger.write'] and being allowed to write.~n"),

    format("~n-- A REFUSED HANDSHAKE IS NOT AN ERROR~n"),
    format("   `tls_accept/5' FAILS for a stranger, for a certificate~n"),
    format("   this authority did not sign, and for nobody arriving~n"),
    format("   inside the timeout alike. `tls_why/1' says which:~n"),
    format("~n"),
    format("     tlsv1 alert unknown ca        -- an impostor knocked~n"),
    format("     certificate verify failed     -- from the other end~n"),
    format("~n"),
    format("   A server that RAISED on any of those would stop serving~n"),
    format("   everybody else because one impostor tried, which is~n"),
    format("   exactly what mutual TLS is meant to prevent.~n"),
    format("~n"),
    format("   BUT `tls_connect/4' SUCCEEDING IS NOT PROOF YOU GOT IN,~n"),
    format("   and that is TLS 1.3 rather than anything this module~n"),
    format("   does: under 1.3 the server does not look at a client's~n"),
    format("   certificate until after the client has sent its Finished~n"),
    format("   and thinks the handshake is over. A stranger therefore~n"),
    format("   gets SUCCESS out of connect and hears the refusal~n"),
    format("   afterwards, as an alert on a connection it believes it~n"),
    format("   already has. What is true either way is that a refused~n"),
    format("   peer gets no answer -- so check the ANSWER. The server~n"),
    format("   side is unaffected: it is the end that decided.~n"),
    tls_why(W),
    ( W == '' -> Why = nothing_yet ; Why = W ),
    must('nothing has been refused in this process', Why, nothing_yet),

    format("~n-- FORWARD SECRECY OR NOTHING, and not decided here~n"),
    format("   The default cipher list is ECDHE key agreement and AEAD~n"),
    format("   ciphers with !kRSA -- static RSA key transport cannot be~n"),
    format("   negotiated at all -- TLS 1.2 at the lowest, and no record~n"),
    format("   compression. That is SocketIO/tlsbuf.cpp, and this module~n"),
    format("   offers no way to weaken it beyond passing your own~n"),
    format("   `ciphers(...)'.~n"),

    format("~n-- AND WHAT IS NOT HERE: HTTPS~n"),
    format("   `library(httpd)' speaks tcp_accept/read/write/close, and~n"),
    format("   swapping those four for the tls_ ones is what an HTTPS~n"),
    format("   server whose pages are clauses would take. It is a~n"),
    format("   transport indirection through fourteen call sites, not a~n"),
    format("   new mechanism -- and it is not done yet.~n"),
    format("~n"),
    format("   `sh test/tls.sh' is the real demonstration: a server and~n"),
    format("   three clients as SEPARATE PROCESSES, because a handshake~n"),
    format("   is between two ends that do not share memory and a test~n"),
    format("   proving one process can talk to itself would have proved~n"),
    format("   the least interesting half.~n~n"),
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
