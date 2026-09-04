%% LIBRARY 22 -- library(torch): Prolog that trains
%%
%%     COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/22-torch.pl main
%%
%% TIER 2, and the heaviest one here: `use_module(library(torch))' loads
%% `library/torch.so', built by `sh modules/torch/build.sh' against
%% libtorch. A cocolog with no libtorch still builds and still runs --
%% which is the whole reason this is a module and not a builtin.
%%
%% THIS FILE IS THE INTRODUCTION. The real collection is
%% `tutorials/tensor/' -- twenty-four networks, each a PyTorch-tutorial
%% classic rewritten as a standalone Prolog program, each with three goals
%% meant to run as their OWN PROCESSES against the same store:
%%
%%     ./cocolog --embed /tmp/t run tutorials/tensor/07-xor.pl train
%%     ./cocolog --embed /tmp/t run tutorials/tensor/07-xor.pl test
%%     ./cocolog --embed /tmp/t run tutorials/tensor/07-xor.pl predict
%%
%% WHY THREE PROCESSES AND NOT THREE GOALS. Because the trained model does
%% not live in memory: `model_save/2' puts its parameters in the KNOWLEDGE
%% BASE, as rows, and `model_load/2' gets them back. So `test' is a
%% process that consulted nothing, loaded a model somebody else trained,
%% and judged it -- which is the claim this whole interpreter exists to
%% make, applied to a neural network.
%%
%% WHICH IS ALSO WHY THE MODEL IS PORTABLE. Train on a Colab GPU, save
%% into a knowledge base, and query it from a laptop over the wire -- see
%% `colab/COLAB.md'. Nothing is exported and nothing is a file format:
%% the parameters are `cocolog::tensors' rows, and the SPEC is a clause.
%%
%% THE SHAPE OF THE SURFACE:
%%
%%     tensor_from_list/2  tensor_to_list/2  tensor_shape/2   data in, out
%%     tensor_new/3 (zeros|ones|randn|rand)  tensor_eye/2     making them
%%     tensor_unary/3  tensor_binary/4  tensor_scalar/4       four generics
%%     tensor_reduce/3                                        ...and sugar
%%     model_new/2  model_train/4  model_predict/3            fitting one
%%     model_evaluate/5  model_spec/2                         judging one
%%     model_save/2  model_load/2                             to and from the KB
%%     torch_seed/1  torch_device/1  torch_cuda_available/1   determinism, GPU

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand

main :-
    format("~n-- the module loads, and says whether there is a GPU~n"),
    %% `current_predicate/1' IS THE WRONG QUESTION, and 20-curl explains
    %% why at length: it answers about the KNOWLEDGE BASE, and a module's
    %% predicates are not clauses in it. Call the thing instead.
    torch_cuda_available(Cuda),
    ( ( Cuda == true ; Cuda == false ) -> C = a_boolean ; C = Cuda ),
    must('torch_cuda_available/1', C, a_boolean),
    show('a CUDA device', Cuda),
    torch_current_device(Dev),
    show('and the device in force', Dev),
    format("   `torch_device(cuda)' on a machine without one THROWS.~n"),
    format("   Never a silent fall back to the CPU: \"trained on the GPU\"~n"),
    format("   and \"quietly trained on the CPU\" are different results,~n"),
    format("   and only one of them is the one you asked for.~n"),

    format("~n-- a tensor is a HANDLE, and its shape is a term~n"),
    torch_seed(42),
    tensor_from_list([[1.0, 2.0], [3.0, 4.0]], T1),
    tensor_shape(T1, Shape),
    must('a list of ROWS makes a matrix', Shape, [2, 2]),
    tensor_to_list(T1, L1),
    must('tensor_to_list/2 gives the rows back', L1, [[1.0, 2.0], [3.0, 4.0]]),
    tensor_from_list([1.0, 2.0, 3.0], V), tensor_shape(V, VShape),
    must('a flat list makes a vector', VShape, [3]),
    format("   THE SHAPE IS NOT A SEPARATE ARGUMENT. `tensor_from_list/2'~n"),
    format("   reads it off the nesting, so a ragged list is an error at~n"),
    format("   the seam rather than a wrong answer three layers in.~n"),

    format("~n-- the other ways to make one~n"),
    tensor_new([2, 2], zeros, Z), tensor_to_list(Z, ZL),
    must('tensor_new(Shape, zeros, T)', ZL, [[0.0, 0.0], [0.0, 0.0]]),
    tensor_zeros([2], Z2), tensor_to_list(Z2, Z2L),
    must('...and tensor_zeros/2 is the sugar', Z2L, [0.0, 0.0]),
    tensor_eye(2, I), tensor_to_list(I, IL),
    must('tensor_eye/2', IL, [[1.0, 0.0], [0.0, 1.0]]),
    format("   `zeros', `ones', `randn' and `rand' are the four kinds,~n"),
    format("   and each has a two-argument name spelled over it.~n"),

    format("~n-- FOUR GENERICS CARRY EVERY OPERATION~n"),
    tensor_from_list([1.0, 2.0], A),
    tensor_from_list([10.0, 20.0], B),
    tensor_binary(add, A, B, Sum), tensor_to_list(Sum, SumL),
    must('tensor_binary(add, ...)', SumL, [11.0, 22.0]),
    tensor_add(A, B, Sum2), tensor_to_list(Sum2, Sum2L),
    must('...which is what tensor_add/3 is', Sum2L, [11.0, 22.0]),
    tensor_mul(A, B, Prod), tensor_to_list(Prod, ProdL),
    must('tensor_mul/3 is ELEMENTWISE', ProdL, [10.0, 40.0]),
    tensor_matmul(I, T1, MM), tensor_to_list(MM, MML),
    must('tensor_matmul/3 is the matrix one', MML, [[1.0, 2.0], [3.0, 4.0]]),
    tensor_scalar(mul, A, 3.0, Scaled), tensor_to_list(Scaled, ScaledL),
    must('tensor_scalar(mul, T, 3.0, T2)', ScaledL, [3.0, 6.0]),
    tensor_reduce(sum, T1, S1), must('tensor_reduce(sum, ...)', S1, 10.0),
    tensor_sum(T1, S2), must('...and tensor_sum/2 over it', S2, 10.0),
    format("   unary, binary, scalar, reduce -- and the friendly names~n"),
    format("   are ONE CLAUSE EACH in the module's Prolog half. Which is~n"),
    format("   the shape to copy: a small C surface, and the vocabulary~n"),
    format("   written in Prolog on top of it where it can be read.~n"),

    format("~n-- ...and the nonlinearity that makes a hidden layer worth~n"),
    format("   having~n"),
    tensor_from_list([-2.0, -1.0, 1.0, 2.0], R0),
    tensor_relu(R0, R1), tensor_to_list(R1, RL),
    must('tensor_relu/2', RL, [0.0, 0.0, 1.0, 2.0]),

    format("~n-- reshaping, slicing, and the one that prevents a leak~n"),
    tensor_reshape(T1, [4], Flat), tensor_to_list(Flat, FlatL),
    must('tensor_reshape/3', FlatL, [1.0, 2.0, 3.0, 4.0]),
    tensor_rows(T1, 0, 1, Row0), tensor_to_list(Row0, Row0L),
    must('tensor_rows(T, From, To, T2) -- half open', Row0L, [[1.0, 2.0]]),
    tensor_cols(T1, 1, 2, Col1), tensor_to_list(Col1, Col1L),
    must('tensor_cols/4', Col1L, [[2.0], [4.0]]),
    format("   `tensor_standardise(T, NTrain, T2)' takes its mean and~n"),
    format("   deviation FROM THE FIRST NTrain ROWS ONLY. That argument~n"),
    format("   is the whole point of the predicate: standardising over~n"),
    format("   the full table lets the test rows inform the scaling, and~n"),
    format("   the score you get back is then better than the truth.~n"),

    format("~n-- A MODEL IS A TERM, which is the part that matters here~n"),
    model_new([input(2), dense(4, relu), dense(1)], M),
    model_spec(M, Spec),
    %% NORMALISED, not echoed: `dense(1)' comes back `dense(1,none)'.
    %% The spec you get is the one the network was actually built from,
    %% with every default filled in -- which is what makes it safe to
    %% save, because a default that changes later would otherwise change
    %% the architecture of a model already trained.
    must('model_spec/2 gives the architecture back',
         Spec, [input(2), dense(4, relu), dense(1, none)]),
    model_params(M, Ps), length(Ps, NP),
    must('model_params/2 -- (2*4+4) + (4*1+1) floats', NP, 17),
    format("   THE SHAPE FLOWS DOWN THE LIST: each layer's input is the~n"),
    format("   previous layer's output, worked out at `model_new', so a~n"),
    format("   mismatch is a refusal and not a runtime surprise.~n"),

    format("~n-- and it TRAINS, in four lines~n"),
    tensor_from_list([[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]], X),
    tensor_from_list([[0.0], [1.0], [1.0], [0.0]], Y),
    model_train(M, X, Y, [epochs(400), lr(0.1), optimiser(adam),
                          loss(mse), final_loss(Loss)]),
    ( number(Loss) -> LK = a_number ; LK = Loss ),
    must('model_train/4 answers its final loss', LK, a_number),
    show('the loss it got to', Loss),
    model_predict(M, X, Pred), tensor_shape(Pred, PShape),
    must('model_predict/3 -- one row out per row in', PShape, [4, 1]),
    model_evaluate(M, X, Y, rmse, RMSE),
    ( RMSE < 0.4 -> Learned = yes ; Learned = no ),
    must('...and XOR is learnable with a hidden layer', Learned, yes),
    show('rmse', RMSE),
    model_free(M),
    format("   `loss(nll)' wants a `log_softmax' last layer and~n"),
    format("   `loss(cross_entropy)' takes raw logits; both take INTEGER~n"),
    format("   class labels and convert them themselves, because a float~n"),
    format("   target failing deep inside libtorch is the classic trap.~n"),

    format("~n-- THE KNOWLEDGE BASE IS THE MODEL FILE~n"),
    format("~n"),
    format("     train :- model_new(Spec, M), model_train(M, X, Y, Opts),~n"),
    format("              model_save(xor, M).~n"),
    format("     test  :- model_load(xor, M),~n"),
    format("              model_evaluate(M, X, Y, accuracy, A).~n"),
    format("~n"),
    format("   `model_save/2' asserts `torch_model(Name, Spec)' and puts~n"),
    format("   the parameters in `cocolog::tensors' -- a table of one~n"),
    format("   Vector<Double> field, and 120 to a clause where there is no~n"),
    format("   such table, because a row must fit in a page. `model_load/2'~n"),
    format("   is `model_new' over the spec and `model_set_params' over~n"),
    format("   the floats. No file format, and nothing exported.~n"),

    format("~n-- GO AND RUN ONE, which is the real lesson~n"),
    format("~n"),
    format("     ./cocolog --embed /tmp/t run tutorials/tensor/07-xor.pl train~n"),
    format("     ./cocolog --embed /tmp/t run tutorials/tensor/07-xor.pl test~n"),
    format("~n"),
    format("   07-xor is the one to start with: it is the smallest~n"),
    format("   network that cannot be done without a hidden layer, so~n"),
    format("   the file is short and the reason for every line is~n"),
    format("   visible. Then 09-four-blobs for multiclass, 17-cnn-bars~n"),
    format("   for convolution, and 21-lstm-sum for sequences.~n"),
    format("~n"),
    format("   `sh test/tutorials.pl' runs all twenty-four, three~n"),
    format("   processes each, and checks every one against a threshold~n"),
    format("   -- so the collection is a suite as well as a course.~n~n"),
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
