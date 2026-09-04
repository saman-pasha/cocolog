%% The whole story in one test: a Prolog program locates a dataset with
%% the Files module, loads and trains on it with the Torch module, and
%% stores the trained model in Zigurat through an assert -- then a
%% SECOND process loads the model back out of the store and reproduces
%% the first one's predictions exactly.
%%
%% It SKIPS when the binary lacks the torch module, because "no libtorch
%% here" and "the module is wrong" are different findings.
%%
%%     cocolog -s test/torch.pl        from the checkout root
%%
%% Every check IS a child: the claim is what a SECOND process loads. The
%% datasets the .sh made with awk are made here with the sin-hash noise
%% the other tensor cases use -- the same shape of data, deterministic.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/torch.so') -> true ; skip('(no library/torch.so -- sh modules/torch/build.sh)') ),
    scratch(D),
    atom_concat(D, '/store', Store),
    datasets(D),
    the_model(D, Store), the_operations(D), the_conv_net(D, Store), the_device(D),
    shl(['rm -rf ', D]),
    checks_done.

%% deterministic noise in (-1, 1): the classic sin-hash
noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, F is S - truncate(S), R is 2 * F - 1.

datasets(D) :-
    %% the dataset: y = 3*x1 - 2*x2 + 0.5*x3 + 1, with a little noise
    atom_concat(D, '/data.csv', Csv),
    findall(Line, ( between(0, 239, I),
                    noise(I, X1), noise(I + 1000, X2), noise(I + 2000, X3), noise(I + 3000, E),
                    Y is 3*X1 - 2*X2 + 0.5*X3 + 1 + E * 0.025,
                    format(atom(Line), "~6f,~6f,~6f,~6f", [X1, X2, X3, Y]) ), Lines),
    fixture(Csv, Lines),
    %% bars: class 0 a row of ones at Pos, class 1 a column of ones at Pos
    atom_concat(D, '/bars.csv', Bars),
    findall(Line, ( between(0, 119, I), Cls is I mod 2, Pos is 1 + (I // 2) mod 6,
                    findall(V, ( between(0, 63, P), R is P // 8, C is P mod 8,
                                 ( Cls =:= 0, R =:= Pos -> V = '1.0' ; Cls =:= 1, C =:= Pos -> V = '1.0' ; V = '0.0' ) ), Vs),
                    atomic_list_concat(Vs, ',', Px), sh_join([Px, ',', Cls], Line) ), BarLines),
    fixture(Bars, BarLines).

%% a child against the embedded store, its stdout and stderr, indented into
%% the transcript the way the .sh showed it
against(Store, File, Goal, Text) :-
    sh_join(['--kb torch_test --embed ', Store, ' run ', File, ' ', Goal, ' 2>&1'], Args),
    cocolog_run(Args, Text, _),
    atom_codes(Text, Cs), codes_lines(Cs, Ls),
    forall(member(L, Ls), ( atom_codes(A, L), format("     ~w~n", [A]) )).

count(Pat, Text, N) :- atom_codes(Text, Cs), re_lines(Pat, Cs, Ls), length(Ls, N).

the_model(D, Store) :-
    section('training, and storing the model in Zigurat'),
    atom_concat(D, '/data.csv', Csv),
    atom_concat(D, '/train.pl', Train),
    sh_join(['getenv_path(''', Csv, ''').'], PathClause),
    fixture(Train,
            [ ':- use_module(library(torch)).',
              'train_main :-',
              '    % the Files module finds and vouches for the dataset',
              '    getenv_path(CSV),',
              '    ( exists_file(CSV) -> true ; write(no_csv), nl, halt(1) ),',
              '    % the Torch module loads it: [240 rows, 4 cols], features then target',
              '    tensor_load_csv(CSV, All),',
              '    tensor_shape(All, [N, 4]),',
              '    tensor_cols(All, 0, 3, X0),',
              '    tensor_cols(All, 3, 4, Y),',
              '    NTrain is (N * 4) // 5,',
              '    tensor_standardise(X0, NTrain, X),',
              '    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),',
              '    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),',
              '    % train',
              '    torch_seed(11),',
              '    model_new([input(3), dense(24, relu), dense(1)], M),',
              '    model_train(M, XTr, YTr, [epochs(150), batch(24), lr(0.01),',
              '                              shuffle(true), final_loss(L)]),',
              '    format("train mse ~4f~n", [L]),',
              '    model_evaluate(M, XTe, YTe, rmse, R),',
              '    format("test rmse ~4f~n", [R]),',
              '    ( R < 0.2 -> true ; write(did_not_learn), nl, halt(1) ),',
              '    % a probe row and its prediction, stored beside the model',
              '    tensor_rows(XTe, 0, 5, Probe),',
              '    tensor_to_list(Probe, ProbeRows),',
              '    model_predict(M, Probe, P),',
              '    tensor_to_list(P, Pred),',
              '    % THE MODEL GOES INTO ZIGURAT: spec and parameters as terms, asserted',
              '    model_save(net1, M),',
              '    assertz(torch_probe(net1, ProbeRows, Pred)),',
              '    write(saved), nl.',
              PathClause ]),
    against(Store, Train, train_main, TrainOut),
    count('^saved$', TrainOut, N1),
    check('the program trained and saved', N1, 1),
    section('a fresh process loads it back'),
    atom_concat(D, '/load.pl', Load),
    fixture(Load,
            [ ':- use_module(library(torch)).',
              'close_enough([], []).',
              'close_enough([[A]|As], [[B]|Bs]) :-',
              '    D is abs(A - B), D < 1.0e-4,',
              '    close_enough(As, Bs).',
              'load_main :-',
              '    % a FRESH PROCESS: the model exists only in the store',
              '    model_load(net1, M),',
              '    torch_probe(net1, ProbeRows, Saved),',
              '    model_spec(M, Spec),',
              '    format("loaded ~w~n", [Spec]),',
              '    % the reloaded model must predict what the trained one predicted',
              '    tensor_from_list(ProbeRows, Probe),',
              '    model_predict(M, Probe, P),',
              '    tensor_to_list(P, Again),',
              '    ( close_enough(Saved, Again)',
              '    ->  write(predictions_agree), nl',
              '    ;   write(predictions_differ), nl, halt(1) ),',
              '    write(reloaded), nl.' ]),
    against(Store, Load, load_main, LoadOut),
    count('^reloaded$', LoadOut, N2),
    check('the model came back out of the store', N2, 1),
    count('input\\(3\\),dense\\(24,relu\\),dense\\(1', LoadOut, N3),
    check('with its architecture intact', N3, 1),
    count('^predictions_agree$', LoadOut, N4),
    check('and the stored weights predict identically', N4, 1).

the_operations(D) :-
    section('the tensor operations'),
    atom_concat(D, '/ops.pl', Ops),
    fixture(Ops,
            [ ':- use_module(library(torch)).',
              'ops_main :-',
              '    tensor_from_list([[1.0,2.0],[3.0,4.0]], A),',
              '    tensor_from_list([[5.0,6.0],[7.0,8.0]], B),',
              '    tensor_matmul(A, B, M), tensor_to_list(M, [[19.0,22.0],[43.0,50.0]]),',
              '    tensor_scalar(pow, A, 2, Sq), tensor_sum(Sq, 30.0),',
              '    tensor_transpose(A, T), tensor_to_list(T, [[1.0,3.0],[2.0,4.0]]),',
              '    tensor_reshape(A, [4], R), tensor_shape(R, [4]),',
              '    tensor_eye(3, E), tensor_sum(E, 3.0),',
              '    tensor_cat([A, B], 1, C), tensor_shape(C, [2,4]),',
              '    tensor_argmax(A, 1, Am), tensor_to_list(Am, [1.0,1.0]),',
              '    write(ops_agree), nl.' ]),
    sh_join(['--local run ', Ops, ' ops_main 2>&1'], A), cocolog_run(A, Out, _),
    count('^ops_agree$', Out, N),
    check('every operation family answers as libtorch does', N, 1).

the_conv_net(D, Store) :-
    section('a conv net with batch norm, through the store'),
    atom_concat(D, '/bars.csv', Bars),
    atom_concat(D, '/conv.pl', Conv),
    sh_join(['    tensor_load_csv(''', Bars, ''', All),'], LoadLine),
    fixture(Conv,
            [ ':- use_module(library(torch)).',
              'conv_main :-',
              LoadLine,
              '    tensor_shape(All, [N, 65]),',
              '    tensor_cols(All, 0, 64, X), tensor_cols(All, 64, 65, Y),',
              '    NTrain is (N * 4) // 5,',
              '    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),',
              '    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),',
              '    torch_seed(5),',
              '    model_new([image(1,8,8), conv(4,3,relu,pad(1)), norm, pool(2),',
              '               flatten, dropout(0.1), dense(16, relu),',
              '               dense(2, log_softmax)], M),',
              '    model_train(M, XTr, YTr, [epochs(25), batch(12), lr(0.005), loss(nll),',
              '                              shuffle(true), schedule(step, 10, 0.5)]),',
              '    model_evaluate(M, XTe, YTe, accuracy, A),',
              '    ( A >= 0.95 -> true ; write(conv_did_not_learn), nl, halt(1) ),',
              '    model_save(bars, M),',
              '    write(conv_saved), nl.',
              'conv_again :-',
              '    model_load(bars, M2),',
              LoadLine,
              '    tensor_shape(All, [N, 65]),',
              '    tensor_cols(All, 0, 64, X), tensor_cols(All, 64, 65, Y),',
              '    NTrain is (N * 4) // 5,',
              '    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),',
              '    model_evaluate(M2, XTe, YTe, accuracy, A),',
              '    ( A >= 0.95 -> write(conv_reloaded) ; write(conv_buffers_lost) ), nl.' ]),
    against(Store, Conv, conv_main, Out1),
    count('^conv_saved$', Out1, N1),
    check('the conv net learned and saved', N1, 1),
    against(Store, Conv, conv_again, Out2),
    count('^conv_reloaded$', Out2, N2),
    check('and its buffers came back out of Zigurat', N2, 1).

the_device(D) :-
    section('the device tier'),
    %% On a CUDA box the model trains on the GPU; on a CPU-only box asking
    %% for cuda is refused with a domain_error rather than silently falling
    %% back. Either way training after torch_device(auto) must still learn.
    atom_concat(D, '/device.pl', Dev),
    fixture(Dev,
            [ ':- use_module(library(torch)).',
              'device_main :-',
              '    torch_cuda_available(Avail),',
              '    torch_cuda_count(Count),',
              '    write(cuda(Avail, Count)), nl,',
              '    torch_device(cpu), torch_current_device(cpu),',
              '    ( Avail == true ->',
              '        torch_device(cuda), torch_current_device(cuda(_)),',
              '        catch(torch_device(cuda(Count)),',
              '              error(domain_error(cuda_available, _), _), true)',
              '    ;   catch((torch_device(cuda), write(fell_back_silently), nl, halt(1)),',
              '              error(domain_error(cuda_available, _), _), true),',
              '        catch((torch_device(cuda(0)), write(fell_back_silently), nl, halt(1)),',
              '              error(domain_error(cuda_available, _), _), true)',
              '    ),',
              '    torch_device(auto), torch_current_device(D),',
              '    write(auto_is(D)), nl,',
              '    torch_seed(7),',
              '    model_new([input(2), dense(8, relu), dense(1)], M),',
              '    tensor_from_list([[0.0,0.0],[0.0,1.0],[1.0,0.0],[1.0,1.0]], X),',
              '    tensor_from_list([[0.0],[1.0],[1.0],[2.0]], Y),',
              '    model_train(M, X, Y, [epochs(400), lr(0.05), final_loss(L)]),',
              '    ( L < 0.05 -> write(device_trained) ; write(device_did_not_learn(L)) ), nl,',
              '    model_predict(M, X, P), tensor_shape(P, [4, 1]),',
              '    model_free(M).' ]),
    sh_join(['--local run ', Dev, ' device_main 2>&1'], A), cocolog_run(A, Out, _),
    atom_codes(Out, Cs), codes_lines(Cs, Ls),
    forall(member(L, Ls), ( atom_codes(At, L), format("     ~w~n", [At]) )),
    count('^auto_is\\(', Out, N1),
    check('cuda is used when present, refused when absent', N1, 1),
    count('^device_trained$', Out, N2),
    check('and training on the chosen device learned', N2, 1).
