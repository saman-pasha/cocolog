%  An unknown procedure's message names the predicates whose names are near
%  its own (cocolog 3.3.0), held to swipl 9.0.4. Run by BOTH SWI-Prolog
%  and cocolog, output compared byte for byte.
%
%  swipl's rule (boot/dwim.pl, pl-dwim.c): the name is a goal's head, and
%  its own predicate alone where that is defined -- Name/0 for an atom --;
%  else every defined predicate of any arity whose name is one
%  character off, two swapped, one in or out, separated differently or two
%  of its words swapped -- the system's first, then the program's, each by
%  arity and then by name, never a `$' name, and no name under three
%  characters but itself. Five names say something of their own instead.
%  The lines follow the message wherever it is printed: print_message/2,
%  a directive's report and an initialization goal's.
%
%  Everything is written to user_error, which both systems flush as each
%  message ends: the runner reads the two streams through one pipe.

foo(1).
foo(1, 2).
done.
done(1).
bar_baz(1).
qux_quux_corge(1).
waldofred_plugh(1).
formax(1, 2).
zap(1, 2).
zaq(1).
abcdefghi(1).
'$hidden'(1).
%% named as cocolog names a procedure's name that is no atom: offered for
%% none, as swipl offers it for none
'<bad-atom>'(1).
:- dynamic dyn_pred/1.
:- discontiguous disc_only/1.

%% a directive's report: the lines under its location, indented as it is
:- fooo(x).
%% an initialization goal's, one prefix a line
:- initialization(fooo(y)).
%% the engine's own text of the five names, and of the shapes a ball's
%% procedure may have: under a module, with modules in its name -- which
%% say none of the five --, a compound name -- its own predicate alone where
%% it is defined, else its name's near ones --, an arity that is no
%% integer, a name that is neither, and no Name/Arity at all
:- initialization(a^true).
:- initialization((a :- b)).
:- initialization((a => b)).
:- initialization((:- a)).
:- initialization((?- a)).
:- initialization(throw(error(existence_error(procedure, user:(^)/2), _))).
:- initialization(throw(error(existence_error(procedure, lists:(:-)/2), _))).
:- initialization(throw(error(existence_error(procedure, (user:fooo)/1), _))).
:- initialization(throw(error(existence_error(procedure, (user:(:-))/2), _))).
:- initialization(throw(error(existence_error(procedure, (user:(^))/2), _))).
:- initialization(throw(error(existence_error(procedure, (a:(b:fooo))/1), _))).
:- initialization(throw(error(existence_error(procedure, foo(x)/1), _))).
:- initialization(throw(error(existence_error(procedure, zap(x)/1), _))).
:- initialization(throw(error(existence_error(procedure, (:-(a))/1), _))).
:- initialization(throw(error(existence_error(procedure, (a^b)/2), _))).
:- initialization(throw(error(existence_error(procedure, fooo/a), _))).
:- initialization(throw(error(existence_error(procedure, 3/1), _))).
:- initialization(throw(error(existence_error(procedure, fooo), _))).

main :-
    unknown(fooo(x)),            % foo/1 and foo/2, the program's
    unknown(foooo(x)),           % one more: still near foo
    unknown(fo(x)),              % too short to be near anything
    unknown(done(1, 2)),         % done/0 defined: it alone
    unknown(nl(a, b, c)),        % nl/0 the system's: it alone
    unknown(barBaz(x)),          % separated differently
    unknown(quxquuxcorge(x)),    % ...with no sub-word in common
    unknown(waldoFredPlugh(x)),  % ...and a capital read small
    unknown(bar_bazz(x)),        % one inserted
    unknown(baz_bar(x)),         % two words swapped
    unknown(atom_lenght(a, N)),  % the system's, two swapped
    unknown(findal(x, y, z)),    % findall/3 and findall/4
    unknown(halts(x)),           % halt/0 and halt/1, by arity
    unknown(formay(x, y)),       % the system's format/1,2,3, then formax/2
    unknown(zar(a, b, c)),       % zaq/1 before zap/2: arity, then name
    unknown(ab_c_d_e_f_g_h_i(x)),% abcdefghi/1 is too far: lengths 5 apart
    unknown(awaitt(x)),          % cocolog's own library's await/1,2: none
    unknown(dyn_pre(x)),         % a dynamic predicate with no clause
    unknown(disc_onl(x)),        % a discontiguous one with none
    unknown('$hiddn'(x)),        % a `$' name is never offered
    unknown(qwertyuiop(x)),      % nothing near: no lines
    unknown(call((a :- b))),     % the five names that say their own
    unknown(call((a => b))),
    unknown(call((:- a))),
    unknown(call((?- a))),
    unknown(call(N^true)),
    proc_message(fooo/1),        % the message of a ball, its shapes
    proc_message(user:fooo/1),
    proc_message((user:fooo)/1),
    proc_message(fooo/a),
    proc_message(fooo),
    proc_message(3/1),
    proc_message(user:(^)/2),
    proc_message(lists:(:-)/2),
    proc_message((user:(:-))/2),
    proc_message((user:(^))/2),
    proc_message(foo(x)/1),
    proc_message(user:foo(x)/1),
    proc_message((a:(b:fooo))/1),
    message_text.

unknown(G) :-
    catch(G, E, true),
    (   var(E)
    ->  format(user_error, 'no error: ~q~n', [G])
    ;   print_message(error, E)
    ).

proc_message(P) :-
    print_message(error, error(existence_error(procedure, P), _)).

%% the lines are the message's own: message_to_string/2's text has them too
message_text :-
    catch(fooo(z), E, true),
    message_to_string(E, S),
    format(user_error, '[~w]~n', [S]).
