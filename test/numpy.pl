%% library(numpy): numpy arrays as cocolog predicates, over numpy's C API.
%%
%% WHAT IS BEING PINNED, in the order the module's header lists it:
%%
%%   THE ARRAY IS numpy's. A list of lists becomes a matrix with the shape,
%%   dtype and elements it says; a reduction answers a number, an operation
%%   an array; the dtypes survive np_array and np_astype.
%%
%%   THE FILE IS numpy's FORMAT, written and read here in C. An array saved
%%   by np_save loads back equal; where a python3 with numpy is on the
%%   path, numpy.load reads what np_save wrote and np_load reads what
%%   numpy.save wrote -- an int64 array, and one in Fortran order. The CSV
%%   round trip holds to the digit.
%%
%%   THE KNOWLEDGE BASE KEEPS IT ACROSS PROCESSES, dtype and shape and all:
%%   np_store in one process, np_fetch in another, against the embedded
%%   store -- and against a Zigurat server when one answers, where the
%%   numbers travel as rows of the tensors table and no chunk clause is
%%   written. A second store under the same name replaces the first;
%%   np_forget leaves nothing behind.
%%
%%   NOTHING LEAKS: every handle a section makes is freed, and np_handles
%%   answers 0 at the end.
%%
%%     cocolog -s test/numpy.pl        from the checkout root
%%
%% ONE PROCESS FOR THE ARRAY AND FILE HALVES, where test/numpy.sh started a
%% Python interpreter inside a fresh cocolog for every check (13.4 s on
%% this machine). The knowledge-base half is STILL child processes, because
%% "stored in one process, fetched in another" is the claim.
%%
%% SKIPs without library/numpy.so (sh modules/numpy/build.sh says what it
%% needs: a python3 with numpy and a shared libpython).

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(numpy)), _, fail)
    ->  true
    ;   skip('(no library/numpy.so -- sh modules/numpy/build.sh)')
    ),
    (   catch(( np_zeros([1], A0), np_free(A0) ), _, fail)
    ->  true
    ;   skip('(library(numpy) does not start: is the python3 it was built against still here?)')
    ),
    scratch(D),
    the_array, the_file(D), across_processes(D), leaks,
    shl(['rm -rf ', D]),
    checks_done.

the_array :-
    section('the array is numpy''s'),
    written(( np_from_list([[1.0,2.0,3.0],[4.0,5.0,6.0]], A1), np_shape(A1, S1), np_dtype(A1, T1),
              np_size(A1, N1), np_free(A1) ), S1-T1-N1, G1),
    check('a list of lists is a 2 by 3 float64 matrix', G1, '[2,3]-float64-6'),
    written(( np_from_list([[1.0,2.0],[3.0,4.0]], A2), np_to_list(A2, L2), np_free(A2) ), L2, G2),
    check('and reads back as the list it came from', G2, '[[1.0,2.0],[3.0,4.0]]'),
    written(( np_array([1,2,3], int32, A3), np_dtype(A3, T3a), np_astype(A3, float32, B3),
              np_dtype(B3, T3b), np_to_list(B3, L3), np_free(A3), np_free(B3) ), T3a-T3b-L3, G3),
    check('np_array keeps the dtype it is given, np_astype changes it', G3, 'int32-float32-[1.0,2.0,3.0]'),
    written(( np_from_list([[1.0,5.0],[3.0,4.0]], A4), np_sum(A4, S4), np_mean(A4, M4),
              np_max(A4, X4), np_argmax(A4, I4), np_free(A4) ), S4-M4-X4-I4, G4),
    check('sum, mean, max and argmax are numbers', G4, '13.0-3.25-5.0-1'),
    written(( np_from_list([[1.0,2.0],[3.0,4.0]], A5), np_reduce(sum, A5, 0, C5), np_to_list(C5, L5),
              np_free(A5), np_free(C5) ), L5, G5),
    check('a reduction along an axis is an array', G5, '[4.0,6.0]'),
    written(( np_from_list([[1.0,2.0],[3.0,4.0]], A6), np_matmul(A6, A6, B6), np_to_list(B6, LB6),
              np_scalar(mul, A6, 10, C6), np_get(C6, [1,0], G6v), np_free(A6), np_free(B6), np_free(C6) ),
            LB6-G6v, G6),
    check('matmul, and a scalar on the right', G6, '[[7.0,10.0],[15.0,22.0]]-30.0'),
    written(( np_from_list([-4.0,0.0,9.0], A7), np_unary(relu, A7, R7), np_to_list(R7, LR7),
              np_from_list([4.0,9.0], B7), np_sqrt(B7, Q7), np_to_list(Q7, LQ7),
              np_free(A7), np_free(R7), np_free(B7), np_free(Q7) ), LR7-LQ7, G7),
    check('the elementwise math over libm: sqrt, and relu', G7, '[0.0,0.0,9.0]-[2.0,3.0]'),
    written(( np_eye(2, E8), np_arange(0.0, 6.0, 1.0, R8), np_reshape(R8, [2,3], M8), np_transpose(M8, T8),
              np_shape(T8, ST8), np_rows(M8, 1, 2, Row8), np_to_list(Row8, LRow8), np_cols(M8, 1, 3, Col8),
              np_shape(Col8, SC8), np_concat([E8, E8], 0, Cat8), np_shape(Cat8, SCat8),
              np_from_list([3.0,1.0,2.0], U8), np_sort(U8, So8), np_to_list(So8, LSo8),
              np_free(E8), np_free(R8), np_free(M8), np_free(T8), np_free(Row8), np_free(Col8),
              np_free(Cat8), np_free(U8), np_free(So8) ), ST8-LRow8-SC8-SCat8-LSo8, G8),
    check('eye, transpose, reshape, rows, cols, concat, sort', G8, '[3,2]-[[3.0,4.0,5.0]]-[2,2]-[4,2]-[1.0,2.0,3.0]'),
    written(( np_from_list([1.0,5.0,3.0], A9), np_from_list([2.0,2.0,2.0], B9), np_binary(gt, A9, B9, C9),
              np_dtype(C9, T9), np_where(C9, A9, B9, W9), np_to_list(W9, L9),
              np_free(A9), np_free(B9), np_free(C9), np_free(W9) ), T9-L9, G9),
    check('a comparison is a bool array, and where chooses by it', G9, 'bool-[2.0,5.0,3.0]'),
    written(( np_zeros([2,2], A10), np_set(A10, [0,1], 7.5), np_get(A10, [0,1], V10),
              np_seed(11), np_rand([3], R10a), np_to_list(R10a, L10a),
              np_seed(11), np_rand([3], R10b), np_to_list(R10b, L10b),
              ( L10a == L10b -> Same10 = same ; Same10 = differ ),
              np_free(A10), np_free(R10a), np_free(R10b) ), V10-Same10, G10),
    check('np_set is the one mutation, and np_seed repeats the draws', G10, '7.5-same'),
    written(( np_zeros([2], A11), catch(np_get(A11, [5], _), error(E11, _), true), np_free(A11),
              functor(E11, F11, _) ), F11, G11),
    check('an index off the array is an error, not a crash', G11, cocolog_error).

the_file(D) :-
    section('the file is numpy''s format, in C'),
    atom_concat(D, '/a.npy', Npy),
    written(( np_array([[1,2,3],[4,5,6]], int64, A1), np_save(Npy, A1), np_load(Npy, B1),
              np_dtype(B1, T1), np_to_list(B1, L1), np_free(A1), np_free(B1) ), T1-L1, G1),
    check('.npy: save, load, equal, int64 kept', G1, 'int64-[[1,2,3],[4,5,6]]'),
    atom_concat(D, '/a.csv', Csv),
    written(( np_from_list([[0.1,0.2],[1.0e-9,12345.678]], A2), np_save_csv(Csv, A2), np_load_csv(Csv, B2),
              np_to_list(A2, LA2), np_to_list(B2, LB2), ( LA2 == LB2 -> R2 = same ; R2 = LA2-LB2 ),
              np_free(A2), np_free(B2) ), R2, G2),
    check('.csv: save and load to the digit, %.17g both ways', G2, same),
    (   sh_exit('command -v python3 >/dev/null 2>&1 && python3 -c ''import numpy'' >/dev/null 2>&1', 0)
    ->  shl_atom(['python3 -c "import numpy; a = numpy.load(''', Npy, '''); print(str(a.dtype) + ''-'' + str(a.tolist()).replace('' '', ''''))"'], G3),
        check('numpy.load reads what np_save wrote', G3, 'int64-[[1,2,3],[4,5,6]]'),
        atom_concat(D, '/t.npy', TNpy), atom_concat(D, '/f.npy', FNpy),
        shl(['python3 -c "import numpy; numpy.save(''', TNpy, ''', numpy.arange(6, dtype=''float32'').reshape(2,3)); numpy.save(''', FNpy, ''', numpy.asfortranarray(numpy.arange(6.0).reshape(2,3)))"']),
        written(( np_load(TNpy, A4), np_dtype(A4, T4), np_to_list(A4, L4), np_load(FNpy, F4), np_to_list(F4, LF4),
                  np_free(A4), np_free(F4) ), T4-L4-LF4, G4),
        check('np_load reads what numpy.save wrote: float32, and Fortran order', G4,
              'float32-[[0.0,1.0,2.0],[3.0,4.0,5.0]]-[[0.0,1.0,2.0],[3.0,4.0,5.0]]')
    ;   format("     (skipped: no python3 with numpy on the path -- the cross-check with numpy.load not run)~n", [])
    ).

%% a child against the embedded store: `--kb numpy_case --embed STORE run p.pl GOAL'
embedded(D, Goal, Got) :-
    atom_concat(D, '/p.pl', P), atom_concat(D, '/store', Store),
    sh_join(['--kb numpy_case --embed ', Store, ' run ', P, ' "', Goal, '"'], Args),
    cocolog_answer(Args, Got).

across_processes(D) :-
    section('the knowledge base keeps it across processes'),
    atom_concat(D, '/p.pl', P),
    fixture(P, [':- use_module(library(numpy)).']),
    embedded(D, 'np_array([[1,2,3],[4,5,6]], int32, A), np_store(m, A), np_stored(N), np_free(A), write(answer(N)), nl', G1),
    check('embed: stored in one process', G1, answer(m)),
    embedded(D, 'np_fetch(m, B), np_dtype(B, T), np_shape(B, S), np_to_list(B, L), np_free(B), write(answer(T-S-L)), nl', G2),
    check('embed: fetched in another, dtype and shape and all', G2, answer(int32-[2,3]-[[1,2,3],[4,5,6]])),
    embedded(D, 'np_linspace(0.0, 1.0, 5, A), np_store(m, A), np_fetch(m, B), np_to_list(B, L), np_forget(m), ( np_stored(_) -> R = still ; R = gone ), np_free(A), np_free(B), write(answer(L-R)), nl', G3),
    check('embed: a second store under the name replaces it; forget leaves nothing', G3, answer([0.0,0.25,0.5,0.75,1.0]-gone)),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --host ', Host, ' --tcp ', Port, ' --timeout 10 --kb numpy_case list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  sh_join([C, ' --kb numpy_case --host ', Host, ' --tcp ', Port, ' --timeout 60 forget >/dev/null 2>&1'], Forget),
        sh_exit(Forget, _),
        %% the first twelve characters of the two sums, as the .sh compared
        %% them: a sum of 2100 normals is a float whose last digits are the
        %% summation order's, not the store's
        wire(Host, Port, 'np_seed(3), np_randn([3,700], A), np_store(big, A), np_sum(A, S), np_free(A), write(answer(S)), nl', W4a),
        wire(Host, Port, 'np_seed(3), np_randn([3,700], A), np_sum(A, S), np_free(A), write(answer(S)), nl', W4b),
        prefix12(W4a, P4a), prefix12(W4b, P4b),
        check('wire: 2100 numbers stored as rows, their sum in this process', P4a, P4b),
        wire(Host, Port, 'np_fetch(big, B), np_shape(B, Sh), np_sum(B, S), findall(Q, np_chunk(big, Q, _), Qs), length(Qs, NC), np_free(B), write(answer(Sh-NC)), nl', W5),
        check('wire: the same sum from another process, and no chunk clause', W5, 'answer([3,700]-0)'),
        sh_exit(Forget, _)
    ;   format("     (skipped: no Zigurat server at ~w:~w -- the wire half not run)~n", [Host, Port])
    ).

wire(Host, Port, Goal, Got) :-
    sh_join(['--kb numpy_case --host ', Host, ' --tcp ', Port, ' --timeout 60 query "use_module(library(numpy)), ', Goal, '"'], Args),
    cocolog_out(Args, Out),
    (   re_first_atom('answer\\([^\n]*\\)', Out, Got) -> true ; Got = none ).

prefix12(A, P) :- atom_length(A, Len), Take is min(Len, 12), sub_atom(A, 0, Take, _, P).

leaks :-
    section('nothing leaks'),
    written(( np_zeros([3,3], A1), np_ones([3,3], B1), np_add(A1, B1, C1), np_free(A1), np_free(B1), np_free(C1),
              np_handles(N1) ), N1, G1),
    check('every handle above was freed: the case ends at 0 after a round', G1, '0').
