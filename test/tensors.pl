%% Tensors as a table of one vector field: model parameters in
%% cocolog::tensors -- doubles in Vector<Double> rows, each row's id
%% columns (kb, name) saying WHICH tensor and `seq' which piece -- with
%% clause chunks kept as the fallback for the arrangements that have no
%% tensor storage.
%%
%% WHAT IT IS CHECKING:
%%
%%   THE WIRE ARRANGEMENT USES THE TABLE. After model_save over the
%%   binary protocol, torch_params/3 answers false -- the parameters are
%%   rows, not clauses -- while torch_model/2 (the spec, the name the
%%   accumulator-style pollers ask for) is still a clause. model_load in
%%   a SECOND process gets the model back whole: 100% on the corners.
%%
%%   AND THE TUTORIAL IT DRIVES NO LONGER CALLS model_save/2, which is
%%   why the two claims above are made about a model of this case's own.
%%   Every tensor lesson from 1 to 30 was rewritten in
%%   library(tensor_expr), so 07-xor saves with params_save/2 -- and
%%   that is arrangement-independent by design: it writes
%%   '$te_param'(Name, I, Shape) and '$te_chunk'(Name, I, Seq, Chunk) as
%%   ordinary clauses and never reaches for the tensors table. So the
%%   tutorial proves the ROUND TRIP, in every arrangement, and a
%%   model_save/2 beside it proves the TABLE. Asked about the tutorial's
%%   name instead, torch_model/2 was empty -- a red -- and torch_params/3
%%   answered false for the wrong reason, which is the worse of the two.
%%
%%   HTTP READS IT PAGED. The tensor page takes `from' and `limit', so a
%%   tensor of any number of rows streams a piece per request -- the way
%%   anything over HTTP should face a table that can hold a huge number
%%   of rows -- and the elements travel as the IEEE bits of the double,
%%   because the default decimal rendering keeps six digits and a model
%%   weight does not survive that. A 1994-parameter model makes four
%%   512-double pieces and loads back over --http exactly.
%%
%%   THE EMBEDDED ARRANGEMENT FALLS BACK. Its engine's columns are int64
%%   and text, so the tensor hooks stay null there and model_save keeps
%%   parameters in clause chunks -- torch_params answers -- and
%%   model_load still works. --local is the same fallback and the
%%   tutorials hold it.
%%
%%     cocolog -s test/tensors.pl        from the checkout root
%%
%% Every check IS a child: the claim is what a SECOND process reads.

:- use_module('test/prelude.pl').

main :-
    %% "no torch here" and "the backend is wrong" are different findings --
    %% the same rule the database suites follow. Every check below drives the
    %% xor tutorial through library(torch), so without the module the case
    %% has no subject.
    (   exists_file('library/torch.so')
    ->  true
    ;   skip('(no library/torch.so -- sh modules/torch/build.sh against libtorch)')
    ),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    ( getenv('ZEYTUN_PORT', Zeytun) -> true ; Zeytun = 2190 ),
    KB = tensors_test,
    sh_join(['--kb ', KB, ' --host ', Host, ' --tcp ', Port, ' --timeout 30'], W),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' ', W, ' list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  true
    ;   sh_join(['no Zigurat server at ', Host, ':', Port], Why), skip(Why)
    ),
    scratch(D),
    sh_join([W, ' forget >/dev/null 2>&1'], Forget),
    cocolog_run(Forget, _, _),
    T = 'use_module(library(torch))',
    wire(D, W, T, KB), http(Host, Zeytun, T, KB), embed(D, T, KB),
    cocolog_run(Forget, _, _),
    shl(['rm -rf ', D]),
    checks_done.

%% the last line of a child's stdout
last_line(Args, Last) :-
    sh_join([Args, ' 2>/dev/null'], A), cocolog_run(A, Text, _, 600000),
    atom_codes(Text, Cs),
    (   codes_lines(Cs, Ls), Ls \== [], last(Ls, L) -> atom_codes(Last, L) ; Last = '' ).

%% how many lines of a child's stdout match an anchored pattern
lines_matching(Args, Pat, N) :-
    sh_join([Args, ' 2>/dev/null'], A), cocolog_run(A, Text, _, 600000),
    atom_codes(Text, Cs), re_lines(Pat, Cs, Ls), length(Ls, N).

wire(D, W, T, _) :-
    section('wire: the tutorial''s clauses, and the table'),
    sh_join([W, ' run tutorials/tensor/07-xor.pl train'], Train),
    lines_matching(Train, '^saved$', N1),
    check('a model trains and saves over the wire', N1, 1),
    %% FOUR ROWS BECAUSE THE XOR MODEL IS TWO DENSE LAYERS, a weight and a
    %% bias each; params_save/2 writes one '$te_param'(Name, I, Shape) per
    %% tensor and chunks the values into '$te_chunk'/4 beside it. Pinned
    %% rather than "some": a shape row that stopped appearing would leave
    %% params_load/2 throwing existence_error, and "more than none" would
    %% not notice three of the four going missing.
    sh_join([W, ' query "', T, ', ''\\$te_param''(t07_xor, _, _)"'], Q2),
    last_line(Q2, G2),
    check('the tutorial''s parameters are params_save/2''s clauses', G2, '4 answer(s).'),
    sh_join([W, ' run tutorials/tensor/07-xor.pl test'], Test),
    last_line(Test, G3),
    check('a second process loads it back whole', G3, ok),
    %% THE TABLE, ASKED ABOUT THE PREDICATE THAT USES IT. `big' is also what
    %% the --http checks below page through, so it is made once, here.
    sh_join([W, ' query "', T, ', torch_seed(1), model_new([input(20), dense(64, relu), dense(10, log_softmax)], M), model_save(big, M)" >/dev/null 2>&1'], Make),
    cocolog_run(Make, _, _),
    sh_join([W, ' query "', T, ', torch_params(big, _, _)"'], Q4),
    last_line(Q4, G4),
    check('the parameters are rows, not chunk clauses', G4, 'false.'),
    sh_join([W, ' --answers 1 query "', T, ', torch_model(big, _)"'], Q5),
    lines_matching(Q5, '^  1\\.', N5),
    check('the spec is still the clause pollers ask for', N5, 1).

http(Host, Zeytun, T, KB) :-
    section('http: paged, and exact'),
    sh_join(['--kb ', KB, ' --host ', Host, ' --http ', Zeytun], H),
    sh_join([H, ' run tutorials/tensor/07-xor.pl test'], Test),
    last_line(Test, G1),
    check('model_load works over --http', G1, ok),
    sh_join([H, ' query "', T, ', model_load(big, M), model_params(M, P), length(P, N), N == 1994"'], Q2),
    lines_matching(Q2, '^  1\\.', N2),
    check('a four-piece tensor loads over --http, all 1994', N2, 1),
    (   sh_exit('command -v curl >/dev/null 2>&1', 0)
    ->  sh_join(['curl -s "http://', Host, ':', Zeytun, '/cocolog/tensor.zt?kb=', KB, '&name=big&from=0&limit=1"'], Curl),
        shell(Curl, Page, _),
        atom_codes(Page, Cs), codes_lines(Cs, Lines),
        ( nth1(2, Lines, L2) -> atom_codes(Line2, L2) ; Line2 = '' ),
        check('the page is paged: T says four pieces', Line2, 'T 4'),
        ( nth1(3, Lines, L3) -> atom_codes(Line3, L3) ; Line3 = '' ),
        check('and limit=1 carries only the piece asked for', Line3, 'V 0 512')
    ;   format("     (skipped: curl -- page shape unchecked)~n", [])
    ).

embed(D, T, KB) :-
    section('embed: the same rows, in-process'),
    %% The engine's VECTOR column kind carries the tensors table inside the
    %% one binary, so the embedded arrangement stores parameters exactly as
    %% the server does: rows, not clause chunks. The same split as over the
    %% wire -- the tutorial's params_save/2 clauses, then a model_save/2 of
    %% this case's own for the table.
    sh_join(['--embed ', D, '/store --kb ', KB], E),
    sh_join([E, ' run tutorials/tensor/07-xor.pl train >/dev/null 2>&1'], Train),
    cocolog_run(Train, _, _),
    sh_join([E, ' query "', T, ', ''\\$te_param''(t07_xor, _, _)"'], Q1),
    last_line(Q1, G1),
    check('embedded: the same four shape rows', G1, '4 answer(s).'),
    sh_join([E, ' run tutorials/tensor/07-xor.pl test'], Test),
    last_line(Test, G2),
    check('and a second process loads them back whole', G2, ok),
    sh_join([E, ' query "', T, ', torch_seed(1), model_new([input(4), dense(8, relu), dense(2, log_softmax)], M), model_save(esmall, M)" >/dev/null 2>&1'], Make),
    cocolog_run(Make, _, _),
    sh_join([E, ' query "', T, ', torch_params(esmall, _, _)"'], Q3),
    last_line(Q3, G3),
    check('embedded: the parameters are rows, not clauses', G3, 'false.'),
    sh_join([E, ' --answers 1 query "', T, ', torch_model(esmall, _)"'], Q4),
    lines_matching(Q4, '^  1\\.', N4),
    check('embedded: and the spec is still a clause', N4, 1).
