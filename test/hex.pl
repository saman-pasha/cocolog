%% library(hex) -- hexagonal-grid arithmetic, held to its IDENTITIES.
%%
%% Hex math is the rare surface whose correctness is a set of closed
%% formulas: a ring at radius R has exactly 6R hexes, a disk exactly
%% 1+3R(R+1), a line exactly distance+1, every neighbor is at distance
%% one, six left-rotations are the identity, and offset and pixel
%% conversions ROUND-TRIP. So this file checks the formulas over whole
%% neighborhoods rather than spot values -- a spot value can be right by
%% accident; forall over a 7x7 window cannot.
%%
%%     cocolog -s test/hex.pl        from the checkout root
%%
%% ONE PROCESS FOR NINETEEN CHECKS, where test/hex.sh spawned one per
%% check (3.7 s on this machine).

:- use_module('test/prelude.pl').
:- use_module(library(hex)).

main :-
    directions, distance, rings, lines, rotation, offsets, pixels,
    checks_done.

directions :-
    section('directions and neighbors'),
    written(( findall(D1, hex_direction(D1, _), L1), length(L1, N1) ), N1, G1),
    check('six directions, nondeterministically', G1, '6'),
    written(( findall(N2, ( hex_neighbor(hex(2, -1), _, N2), hex_distance(hex(2, -1), N2, 1) ), L2),
              length(L2, X2) ), X2, G2),
    check('every neighbor is at distance one', G2, '6'),
    written(( hex_neighbor(hex(4, 4), 0, N3a), hex_neighbor(N3a, 3, N3) ), N3, G3),
    check('opposite directions cancel', G3, 'hex(4,4)').

distance :-
    section('distance is a metric'),
    written(hex_distance(hex(0, 0), hex(3, -2), D1), D1, G1),
    check('the worked example', G1, '3'),
    written(( findall(x, ( between(-2, 2, Q2), between(-2, 2, R2),
                           hex_distance(hex(0, 1), hex(Q2, R2), D2a),
                           hex_distance(hex(Q2, R2), hex(0, 1), D2b), D2a =\= D2b ), Bad2),
              length(Bad2, N2) ), N2, G2),
    check('and symmetric over a window', G2, '0').

rings :-
    section('rings and disks obey their formulas'),
    written(( hex_ring(hex(0, 0), 1, L1a), length(L1a, A1),
              hex_ring(hex(5, -3), 3, L1b), length(L1b, B1) ), A1-B1, G1),
    check('ring 1 has 6, ring 3 has 18', G1, '6-18'),
    written(( hex_ring(hex(1, 1), 3, L2),
              findall(x, ( member(H2, L2), \+ hex_distance(hex(1, 1), H2, 3) ), Bad2),
              length(Bad2, N2) ), N2, G2),
    check('every ring hex is at exactly its radius', G2, '0'),
    written(( hex_disk(hex(0, 0), 2, L3a), length(L3a, A3),
              hex_disk(hex(-4, 7), 3, L3b), length(L3b, B3) ), A3-B3, G3),
    check('disk 2 has 19, disk 3 has 37', G3, '19-37'),
    written(( hex_disk(hex(0, 0), 3, D4), length(D4, N4),
              hex_ring(hex(0, 0), 0, R40), hex_ring(hex(0, 0), 1, R41),
              hex_ring(hex(0, 0), 2, R42), hex_ring(hex(0, 0), 3, R43),
              length(R40, A4), length(R41, B4), length(R42, C4), length(R43, E4),
              M4 is A4 + B4 + C4 + E4,
              ( N4 =:= M4 -> X4 = agree ; X4 = differ(N4, M4) ) ), X4, G4),
    check('a disk is its rings, counted', G4, agree).

lines :-
    section('lines'),
    written(( hex_line(hex(0, 0), hex(3, -2), L1), length(L1, N1),
              L1 = [First1|_], last(L1, Last1) ), N1-First1-Last1, G1),
    check('a line is distance+1 hexes, endpoints included', G1, '4-hex(0,0)-hex(3,-2)'),
    written(( hex_line(hex(-2, 1), hex(4, -3), L2),
              findall(x, ( append(_, [A2, B2|_], L2), \+ hex_distance(A2, B2, 1) ), Bad2),
              length(Bad2, N2) ), N2, G2),
    check('every step of a line moves distance one', G2, '0').

rotation :-
    section('rotation'),
    written(( hex_rotate(left, hex(3, -1), A1), hex_rotate(left, A1, B1),
              hex_rotate(left, B1, C1), hex_rotate(left, C1, D1),
              hex_rotate(left, D1, E1), hex_rotate(left, E1, F1) ), F1, G1),
    check('six left turns are the identity', G1, 'hex(3,-1)'),
    written(( hex_rotate(left, hex(-2, 5), A2), hex_rotate(right, A2, B2) ), B2, G2),
    check('a right turn undoes a left', G2, 'hex(-2,5)').

offsets :-
    section('offsets round-trip, all four layouts, negatives included'),
    forall(member(Layout, [oddr, evenr, oddq, evenq]), offset_round_trip(Layout)).

offset_round_trip(Layout) :-
    written(( findall(x, ( between(-3, 3, Q), between(-3, 3, R),
                           hex_offset(Layout, hex(Q, R), Col, Row),
                           offset_hex(Layout, Col, Row, H2), H2 \== hex(Q, R) ), Bad),
              length(Bad, N) ), N, G),
    atom_concat(Layout, ' over a 7x7 window', Label),
    check(Label, G, '0').

pixels :-
    section('pixels round-trip, both orientations'),
    forall(member(Orient, [pointy, flat]), pixel_round_trip(Orient)).

pixel_round_trip(Orient) :-
    written(( findall(x, ( between(-3, 3, Q), between(-3, 3, R),
                           hex_pixel(Orient, 32, hex(Q, R), X, Y),
                           pixel_hex(Orient, 32, X, Y, H2), H2 \== hex(Q, R) ), Bad),
              length(Bad, N) ), N, G),
    atom_concat(Orient, ' at size 32', Label),
    check(Label, G, '0').
