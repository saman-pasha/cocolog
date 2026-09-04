%% LIBRARY 40 -- library(numpy): numpy arrays as clauses, and two ways to keep one
%%
%%     ./cocolog run tutorials/library/40-numpy.pl main
%%
%% TIER 2: `use_module(library(numpy))', a `.so' from `modules/numpy'. It
%% needs a python3 with numpy and a shared libpython: `sh
%% modules/numpy/build.sh' (its header says what it asks the interpreter).
%%
%% WHAT THE MODULE IS. An ndarray is a HANDLE -- an integer naming a slot
%% in the module's table, as a tensor is in library(torch) -- and every
%% predicate is one call of numpy's C API on the arrays behind the
%% handles. Nothing calls a Python function: what numpy offers only as
%% Python -- its `.npy' format, loadtxt, the random draws, the elementwise
%% math -- the module writes in C over the same arrays. The interpreter
%% underneath is there because numpy's C API is a table a running CPython
%% fills in; it runs no Python of anybody's.
%%
%% THE SURFACE, in the order this file walks it:
%%
%%     np_from_list(+L, -A)  np_array(+L, +Dtype, -A)  np_to_list(+A, -L)
%%     np_shape/2  np_ndim/2  np_size/2  np_dtype/2
%%     np_zeros/2  np_ones/2  np_full/3  np_eye/2  np_arange/4  np_linspace/4
%%     np_rand/2  np_randn/2  np_seed/1
%%     np_get(+A, +Index, -V)  np_set(+A, +Index, +V)
%%     np_unary(+Op, +A, -B)  np_binary(+Op, +A, +B, -C)  np_scalar(+Op, +A, +N, -C)
%%     np_where/4  np_reduce/3  np_reduce/4  np_cumsum/2
%%     np_reshape/3  np_transpose/2  np_flatten/2  np_concat/3
%%     np_rows/4  np_cols/4  np_copy/2  np_astype/3  np_sort/2  np_argsort/2
%%     np_dot/3  np_norm/2  np_add/3 ... np_matmul/3  np_sum/2 ... np_argmin/2
%%     np_save(+Path, +A)  np_load(+Path, -A)  np_save_csv/2  np_load_csv/2
%%     np_store(+Name, +A)  np_fetch(+Name, -A)  np_forget/1  np_stored/1
%%     np_free/1  np_handles/1
%%
%% TWO WAYS TO KEEP AN ARRAY, and the lesson is that they are different
%% things. np_save writes numpy's own `.npy': a FILE, one a notebook opens
%% with numpy.load, and the way an array leaves this process for another
%% program. np_store puts the array in the KNOWLEDGE BASE, the way a
%% trained model goes there: rows of doubles where the arrangement has a
%% tensors table, clause chunks where it has not, and one clause
%% np_meta/3 for the shape and dtype -- so a second cocolog process
%% sharing the base fetches it, dtype and all. Under `run' with no store
%% this file's np_store lands in the local session; test/numpy.pl is
%% where the across-processes claim is pinned, on the embedded store and
%% on the wire.
%%
%% A HANDLE IS AN INTEGER, which is why np_binary/4 takes two arrays and
%% np_scalar/4 an array and a number: the module cannot tell 5 the handle
%% from 5 the number, so the caller says which. And why every array this
%% file makes is freed at the end: np_handles/1 answering 0 is the proof.

:- use_module(library(numpy)).

main :-
    write('1. a list of lists is a matrix, with the shape and dtype it says'), nl,
    np_from_list([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], A),
    np_shape(A, Shape), np_dtype(A, T), np_size(A, N),
    must('the shape', Shape, [2, 3]),
    must('the dtype, float64 by default', T, float64),
    must('the size', N, 6),
    np_to_list(A, Back),
    must('and it reads back as it went in', Back, [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]),

    write('2. reductions are numbers; operations are arrays'), nl,
    np_sum(A, S), np_mean(A, M), np_argmax(A, I),
    must('sum', S, 21.0),
    must('mean', M, 3.5),
    must('argmax, over the flattened array', I, 5),
    np_reduce(sum, A, 0, ColSums), np_to_list(ColSums, LCol),
    must('the column sums, an array along axis 0', LCol, [5.0, 7.0, 9.0]),
    np_transpose(A, AT), np_matmul(A, AT, G), np_to_list(G, LG),
    must('A matmul transpose(A), the Gram matrix', LG, [[14.0, 32.0], [32.0, 77.0]]),
    np_scalar(mul, A, 2, A2), np_get(A2, [1, 2], V),
    must('A times the number 2, element [1,2]', V, 12.0),

    write('3. the dtype is the array''s, and it can be asked to change'), nl,
    np_array([1, 2, 3], int32, Ints), np_dtype(Ints, TI),
    must('np_array keeps int32', TI, int32),
    np_astype(Ints, float32, Fl), np_dtype(Fl, TF), np_to_list(Fl, LF),
    must('np_astype makes float32', TF, float32),
    must('with the same numbers', LF, [1.0, 2.0, 3.0]),

    write('4. a comparison is a bool array, and where picks by it'), nl,
    np_from_list([1.0, 5.0, 3.0], X), np_full([3], 2.0, Two),
    np_binary(gt, X, Two, Mask), np_dtype(Mask, TM), np_to_list(Mask, LM),
    must('X > 2, a bool array', TM-LM, bool-[false, true, true]),
    np_where(Mask, X, Two, W), np_to_list(W, LW),
    must('where(X > 2, X, 2): the small ones become 2', LW, [2.0, 5.0, 3.0]),

    write('5. the elementwise math is C over libm, on a float64 copy'), nl,
    np_from_list([-4.0, 0.0, 9.0], R0),
    np_unary(relu, R0, R1), np_to_list(R1, LR),
    must('relu', LR, [0.0, 0.0, 9.0]),
    np_from_list([4.0, 9.0], Q0), np_sqrt(Q0, Q1), np_to_list(Q1, LQ),
    must('sqrt', LQ, [2.0, 3.0]),
    np_norm(Q0, Norm),
    must('the L2 norm of [4, 9]: sqrt(97)', Norm, 9.848857801796104),

    write('6. shapes: reshape, rows, cols, concat, sort'), nl,
    np_arange(0.0, 6.0, 1.0, Ar), np_reshape(Ar, [2, 3], Mx),
    np_rows(Mx, 1, 2, Row), np_to_list(Row, LRow),
    must('row 1 of the 2 by 3', LRow, [[3.0, 4.0, 5.0]]),
    np_cols(Mx, 1, 3, Cols), np_shape(Cols, SC),
    must('columns 1..2, a 2 by 2', SC, [2, 2]),
    np_eye(2, E), np_concat([E, E], 0, Cat), np_shape(Cat, SCat),
    must('two eyes stacked, 4 by 2', SCat, [4, 2]),
    np_from_list([3.0, 1.0, 2.0], U), np_sort(U, So), np_to_list(So, LSo),
    must('sorted, a copy', LSo, [1.0, 2.0, 3.0]),
    np_argsort(U, Ix), np_to_list(Ix, LIx),
    must('and where each came from', LIx, [1, 2, 0]),

    write('7. the .npy file: numpy''s format, written and read in C'), nl,
    tmp_path(Path),
    np_save(Path, Ints), np_load(Path, Loaded),
    np_dtype(Loaded, TL), np_to_list(Loaded, LL),
    must('what was saved is what loads, dtype kept', TL-LL, int32-[1, 2, 3]),

    write('8. the knowledge base: np_store, then np_fetch under the name'), nl,
    np_store(demo, A),
    findall(Name, np_stored(Name), Names),
    must('np_stored answers the name', Names, [demo]),
    np_fetch(demo, Fetched), np_to_list(Fetched, LFetched), np_dtype(Fetched, TFetched),
    must('the fetch is the array, dtype and all', TFetched-LFetched, float64-[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]),
    np_forget(demo),
    ( np_stored(demo) -> Gone = still_there ; Gone = gone ),
    must('and np_forget leaves nothing under the name', Gone, gone),

    write('9. every handle is freed, and the count says so'), nl,
    forall(member(H, [A, ColSums, AT, G, A2, Ints, Fl, X, Two, Mask, W, R0, R1, Q0, Q1,
                      Ar, Mx, Row, Cols, E, Cat, U, So, Ix, Loaded, Fetched]),
           np_free(H)),
    np_handles(Live),
    must('live handles at the end', Live, 0),
    write(done), nl.

%% a scratch path for the .npy, under $TMPDIR or /tmp
tmp_path(Path) :-
    ( getenv('TMPDIR', D0) -> true ; D0 = '/tmp' ),
    ( atom_concat(D, '/', D0) -> true ; D = D0 ),
    atom_concat(D, '/cocolog-tutorial-40.npy', Path).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
