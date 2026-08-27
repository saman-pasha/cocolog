%% cocolog -- library(hex): hexagonal-grid arithmetic, as clauses.
%%
%% EVERY HEX GAME NEEDS THIS AND NONE OF IT IS ABOUT ANY GAME, which is
%% why it lives here and not in the project that asked for it (CivV's
%% rung 2). The math is the standard axial/cube treatment -- the one
%% Red Blob Games' "Hexagonal Grids" page made canonical -- written as
%% clauses, so the enumerating predicates (a direction, a neighbor) are
%% NONDETERMINISTIC the way Prolog wants them: the engine provides the
%% choice points, and a frozen machine mid-enumeration thaws.
%%
%% A HEX IS hex(Q, R) -- axial coordinates, pointy-top axes. The third
%% cube coordinate is implicit (S = -Q-R) and never stored; predicates
%% that need it derive it. Rows of constant R run east-west.
%%
%%   hex_add(A, B, C)              hex_sub(A, B, C)     hex_scale(A, K, C)
%%   hex_direction(D, V)           D in 0..5, east first, counterclockwise
%%   hex_neighbor(H, D, N)         nondet over D when D is unbound
%%   hex_neighbors(H, L)           the six, as a list
%%   hex_distance(A, B, D)         cube distance, an integer
%%   hex_ring(C, R, L)             the 6*R hexes at exactly distance R
%%   hex_disk(C, R, L)             the 1+3*R*(R+1) hexes within R
%%   hex_line(A, B, L)             distance+1 hexes, A first, B last
%%   hex_round(FQ, FR, H)          fractional axial to the nearest hex
%%   hex_rotate(left|right, H, H2) sixty degrees about the origin
%%
%%   hex_offset(Layout, H, Col, Row)     axial to offset; Layout is one of
%%   offset_hex(Layout, Col, Row, H)     oddr | evenr | oddq | evenq
%%
%%   hex_pixel(Orient, Size, H, X, Y)    center of H; Orient is pointy|flat
%%   pixel_hex(Orient, Size, X, Y, H)    the hex under a point
%%
%% WHAT THE LAYOUT NAMES MEAN, because everybody forgets: offset
%% coordinates shove alternate lines inward, and the name says WHICH
%% lines. oddr/evenr shove odd/even ROWS (pointy-top maps -- Civ V is
%% odd-r shaped); oddq/evenq shove odd/even COLUMNS (flat-top). The
%% conversions use floored mod, so negative rows and columns round-trip
%% -- test/hex.sh holds all four layouts to exactly that.
%%
%% THE LINE IS NUDGED. hex_line lerps in cube space and rounds, and a
%% line between hex centers can pass exactly through an edge midpoint,
%% where rounding is a coin toss two runs could call differently. The
%% standard epsilon nudge toward one side makes every tie break the same
%% way, so the same line is always the same hexes -- determinism is not
%% optional in this family.
%%
%% NO WRAPAROUND HERE. A cylinder map (Civ's east-west wrap) is one mod
%% on the column at the game's edge of the seam, and which edge wraps is
%% the game's decision, not geometry's.

%% ---- the six directions, and arithmetic -------------------------------

hex_direction(0, hex(1, 0)).      % east
hex_direction(1, hex(1, -1)).     % northeast
hex_direction(2, hex(0, -1)).     % northwest
hex_direction(3, hex(-1, 0)).     % west
hex_direction(4, hex(-1, 1)).     % southwest
hex_direction(5, hex(0, 1)).      % southeast

hex_add(hex(Q1, R1), hex(Q2, R2), hex(Q, R)) :-
    Q is Q1 + Q2,
    R is R1 + R2.

hex_sub(hex(Q1, R1), hex(Q2, R2), hex(Q, R)) :-
    Q is Q1 - Q2,
    R is R1 - R2.

hex_scale(hex(Q1, R1), K, hex(Q, R)) :-
    Q is Q1 * K,
    R is R1 * K.

hex_neighbor(H, D, N) :-
    hex_direction(D, V),
    hex_add(H, V, N).

hex_neighbors(H, L) :-
    findall(N, hex_neighbor(H, _, N), L).

%% ---- distance ---------------------------------------------------------
%%
%% Half the cube L1 norm; the S term is derived, not stored.
hex_distance(hex(Q1, R1), hex(Q2, R2), D) :-
    DQ is Q1 - Q2,
    DR is R1 - R2,
    D is (abs(DQ) + abs(DR) + abs(DQ + DR)) // 2.

%% ---- rings, disks -----------------------------------------------------
%%
%% THE RING IS WALKED, not filtered: start 4*R southwest of nothing --
%% at center + direction(4) scaled by R -- then R steps in each of the
%% six directions, turning as you go. 6*R hexes, in drawing order, which
%% a filter would not give.
hex_ring(C, 0, [C]) :- !.
hex_ring(C, Radius, Hexes) :-
    Radius > 0,
    hex_direction(4, V),
    hex_scale(V, Radius, Off),
    hex_add(C, Off, Start),
    hex_ring_walk(0, Radius, Start, Hexes).

hex_ring_walk(6, _, _, []) :- !.
hex_ring_walk(Side, Radius, At, Hexes) :-
    hex_ring_side(Radius, Side, At, Here, Next),
    Side1 is Side + 1,
    hex_ring_walk(Side1, Radius, Next, More),
    append(Here, More, Hexes).

hex_ring_side(0, _, At, [], At) :- !.
hex_ring_side(N, Side, At, [At|More], Next) :-
    N > 0,
    hex_neighbor(At, Side, Step),
    N1 is N - 1,
    hex_ring_side(N1, Side, Step, More, Next).

%% The disk is a comprehension over the axial bounds -- the standard
%% max/min window that makes it 1 + 3*R*(R+1) hexes exactly.
hex_disk(hex(CQ, CR), Radius, Hexes) :-
    Radius >= 0,
    NR is -Radius,
    findall(hex(Q, R),
            ( between(NR, Radius, DQ),
              Lo is max(NR, -DQ - Radius),
              Hi is min(Radius, -DQ + Radius),
              between(Lo, Hi, DR),
              Q is CQ + DQ,
              R is CR + DR ),
            Hexes).

%% ---- lines ------------------------------------------------------------

hex_line(A, A, [A]) :- !.
hex_line(A, B, Hexes) :-
    hex_distance(A, B, N),
    findall(H,
            ( between(0, N, I),
              hex_lerp(A, B, I, N, FQ, FR),
              hex_round(FQ, FR, H) ),
            Hexes).

%% The nudge: 1e-6 on one endpoint's Q and R (so S moves -2e-6), which
%% pushes every edge-midpoint tie off the fence, always the same way.
hex_lerp(hex(Q1, R1), hex(Q2, R2), I, N, FQ, FR) :-
    T is I / N,
    FQ is (Q1 + 1.0e-6) + ((Q2 - Q1) * T),
    FR is (R1 + 1.0e-6) + ((R2 - R1) * T).

%% Cube rounding: round all three, then repair the one that moved
%% farthest, because the three must still sum to zero.
hex_round(FQ, FR, hex(Q, R)) :-
    FS is -FQ - FR,
    Q0 is round(FQ),
    R0 is round(FR),
    S0 is round(FS),
    DQ is abs(Q0 - FQ),
    DR is abs(R0 - FR),
    DS is abs(S0 - FS),
    (   DQ > DR, DQ > DS
    ->  Q is -R0 - S0, R = R0
    ;   DR > DS
    ->  Q = Q0, R is -Q0 - S0
    ;   Q = Q0, R = R0
    ).

%% ---- rotation, sixty degrees about the origin -------------------------
%%
%% In cube: left is (q,r,s) -> (-s,-q,-r), right is (q,r,s) -> (-r,-s,-q).
hex_rotate(left, hex(Q, R), hex(Q2, R2)) :-
    Q2 is Q + R,
    R2 is -Q.
hex_rotate(right, hex(Q, R), hex(Q2, R2)) :-
    Q2 is -R,
    R2 is Q + R.

%% ---- offset coordinates, all four layouts -----------------------------
%%
%% Floored mod keeps the parity bit 0/1 for NEGATIVE rows and columns
%% too, which is the whole trick; a truncating mod breaks the round trip
%% one step west of the origin.

hex_offset(oddr,  hex(Q, R), Col, R) :- Col is Q + (R - (R mod 2)) // 2.
hex_offset(evenr, hex(Q, R), Col, R) :- Col is Q + (R + (R mod 2)) // 2.
hex_offset(oddq,  hex(Q, R), Q, Row) :- Row is R + (Q - (Q mod 2)) // 2.
hex_offset(evenq, hex(Q, R), Q, Row) :- Row is R + (Q + (Q mod 2)) // 2.

offset_hex(oddr,  Col, Row, hex(Q, Row)) :- Q is Col - (Row - (Row mod 2)) // 2.
offset_hex(evenr, Col, Row, hex(Q, Row)) :- Q is Col - (Row + (Row mod 2)) // 2.
offset_hex(oddq,  Col, Row, hex(Col, R)) :- R is Row - (Col - (Col mod 2)) // 2.
offset_hex(evenq, Col, Row, hex(Col, R)) :- R is Row - (Col + (Col mod 2)) // 2.

%% ---- pixels, both orientations ----------------------------------------
%%
%% X, Y is the CENTER of the hex, in the same units as Size (the corner
%% radius). What a renderer needs and nothing more: library(ray) draws
%% at these centers, and pixel_hex answers what the mouse is over.

hex_pixel(pointy, Size, hex(Q, R), X, Y) :-
    S3 is sqrt(3),
    X is Size * (S3 * Q + S3 / 2 * R),
    Y is Size * (3 / 2 * R).
hex_pixel(flat, Size, hex(Q, R), X, Y) :-
    S3 is sqrt(3),
    X is Size * (3 / 2 * Q),
    Y is Size * (S3 / 2 * Q + S3 * R).

pixel_hex(pointy, Size, X, Y, H) :-
    S3 is sqrt(3),
    FQ is (S3 / 3 * X - 1 / 3 * Y) / Size,
    FR is (2 / 3 * Y) / Size,
    hex_round(FQ, FR, H).
pixel_hex(flat, Size, X, Y, H) :-
    S3 is sqrt(3),
    FQ is (2 / 3 * X) / Size,
    FR is (-1 / 3 * X + S3 / 3 * Y) / Size,
    hex_round(FQ, FR, H).
