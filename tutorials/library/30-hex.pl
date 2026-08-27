%% LIBRARY 30 -- library(hex): hexagonal-grid arithmetic
%%
%%     ./cocolog run tutorials/library/30-hex.pl main
%%
%% TIER 2: `use_module(library(hex))', clauses only -- no build step, no
%% C. Every hex game needs this math and none of it is about any game;
%% it is the standard axial treatment of hex grids (Red Blob Games'
%% "Hexagonal Grids" is the canonical exposition), and it exists here
%% because CivV's map rung asked for it.
%%
%% A HEX IS hex(Q, R) -- axial coordinates. The third cube coordinate is
%% implicit (S = -Q-R). Because the library is clauses, the enumerating
%% predicates are properly NONDETERMINISTIC: hex_neighbor/3 with an
%% unbound direction backtracks through all six, which is what a
%% movement rule wants to sit on top of.
%%
%% THE SURFACE:
%%
%%     hex_add/3  hex_sub/3  hex_scale/3
%%     hex_direction(?D, ?V)            hex_neighbor(+H, ?D, -N)
%%     hex_neighbors(+H, -Six)          hex_distance(+A, +B, -D)
%%     hex_ring(+C, +R, -L)             hex_disk(+C, +R, -L)
%%     hex_line(+A, +B, -L)             hex_round(+FQ, +FR, -H)
%%     hex_rotate(left|right, +H, -H2)
%%     hex_offset(Layout, +H, -Col, -Row)   Layout: oddr|evenr|oddq|evenq
%%     offset_hex(Layout, +Col, +Row, -H)
%%     hex_pixel(pointy|flat, +Size, +H, -X, -Y)
%%     pixel_hex(pointy|flat, +Size, +X, +Y, -H)

:- use_module(library(hex)).

main :-
    format("~n-- neighbors are an enumeration, distance a formula~n"),
    hex_neighbors(hex(0, 0), Six),
    length(Six, N6),
    must('six neighbors', N6, 6),
    hex_distance(hex(0, 0), hex(3, -2), D),
    must('distance (0,0) to (3,-2)', D, 3),
    hex_neighbor(hex(2, 2), 0, East),
    must('east of (2,2)', East, hex(3, 2)),

    format("~n-- rings, disks and lines obey closed formulas~n"),
    hex_ring(hex(0, 0), 2, Ring),
    length(Ring, NR),
    must('a ring at radius 2 has 6*2', NR, 12),
    hex_disk(hex(0, 0), 2, Disk),
    length(Disk, ND),
    must('a disk at radius 2 has 1+3*2*3', ND, 19),
    hex_line(hex(0, 0), hex(3, -2), Line),
    length(Line, NL),
    must('a line is distance+1 hexes', NL, 4),
    show('the line', Line),

    format("~n-- offset coordinates, for maps stored row by row~n"),
    hex_offset(oddr, hex(-1, 3), Col, Row),
    must('odd-r offset of hex(-1,3)', Col-Row, 0-3),
    offset_hex(oddr, 0, 3, Back),
    must('and back', Back, hex(-1, 3)),

    format("~n-- pixels, for library(ray) to draw at~n"),
    hex_pixel(pointy, 10, hex(1, 0), X, Y),
    XI is round(X), YI is round(Y),
    must('center of hex(1,0) at size 10, rounded', XI-YI, 17-0),
    pixel_hex(pointy, 10, X, Y, Under),
    must('and the hex under that point', Under, hex(1, 0)),

    format("~ndone~n").

show(What, Value) :- format("     ~w: ~w~n", [What, Value]).

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~w~n", [What, Got])
    ;   format("     FAILED: ~w~n        got  ~w~n        want ~w~n", [What, Got, Want]),
        halt(1)
    ).
