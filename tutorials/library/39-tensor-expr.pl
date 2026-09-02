%% LIBRARY 39 -- library(tensor_expr): tensor expressions over library(torch)
%%
%%     COCOLOG_LIBRARY=$PWD/library \
%%       ./cocolog run tutorials/library/39-tensor-expr.pl main
%%
%% TIER 2, a .pl on the library path, and it wants library(torch) loaded
%% first. A tensor predicate names a value; this library lets a program
%% write the value as an EXPRESSION and turns the expression into the list
%% of tensor goals it stands for -- a DCG, expr//2, does the turning, and
%% `:=' runs the list. The lesson here is the mechanism, in four claims:
%% an expression is a list of goals; the list is a program; a float is a
%% number and an integer is a handle; and the operators are declared where
%% they are read. The networks built with it are tutorials/tensor/31 on.
%%
%% THE OPERATORS ARE DECLARED HERE, in the file that uses them: cocolog's
%% reader applies op/3 to the file it is reading, and a library's clauses
%% are consulted after the file naming it has been read, so a library cannot
%% lend its operators to the file above it. Two lines, before the first
%% clause that writes an expression.

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% two functions of this file's own: one DEFINED, one a clause of the grammar itself
square_error(A, B) ::= (A - B) ^ 2.0.
expr(double(A), T) --> expr(A * 2.0, T).

%% and a PROCEDURE: a DCG rule of bindings, its output list the handles it made
normalise(A, Z) -->
    Mu = row_mean(A),
    C = A - Mu,
    Sd = sqrt(row_mean(C ^ 2.0)),
    Z = C / Sd.

%% and one that uses the module's predicates as nonterminals, no braces: the
%% seed, a model, and a prediction -- which model_predict emits, so exec frees it
through_a_model(X, Ps) -->
    torch_seed(1),
    model_new([input(2), dense(1)], M),
    model_set_params(M, [1.0, 1.0, 0.0]),
    model_predict(M, X, P),
    Ps = list(P),
    model_free(M).

main :-
    write('1. an expression is a list of goals, one per node, in dependency order'), nl,
    tensor_from_list([[1.0, 2.0], [3.0, 4.0]], X),
    tensor_from_list([[1.0], [-1.0]], W),
    phrase(expr(mean((X matmul W) ^ 2.0), _), Goals),
    length(Goals, NGoals),
    must('goals for mean((X matmul W) ^ 2.0)', NGoals, 3),
    Goals = [G1, G2, G3],
    G1 =.. [F1, Op1 | _], must('the first', F1-Op1, tensor_binary-matmul),
    G2 =.. [F2, Op2 | _], must('the second', F2-Op2, tensor_scalar-pow),
    G3 =.. [F3, Op3 | _], must('the third', F3-Op3, tensor_agg-mean),

    write('2. `:='' runs the list and answers the last result; the rest are freed'), nl,
    L := mean((X matmul W) ^ 2.0),
    tensor_item(L, Lv),
    must('mean of (-1)^2 and (-1)^2', Lv, 1.0),
    tensor_shape(L, LS), must('a one-element TENSOR, so it can be differentiated', LS, []),

    write('3. a float is a number, an integer is a handle'), nl,
    T := X * 2.0, tensor_to_list(T, TL),
    must('X * 2.0 doubles', TL, [[2.0, 4.0], [6.0, 8.0]]),
    C := 2.0 + 3.0,
    must('two numbers stay a number', C, 5.0),
    catch(( _ := 2.0 ^ X, Refused = no ), error(domain_error(tensor_expression, _), _), Refused = yes),
    must('a number on the left of ^ is refused by the grammar', Refused, yes),

    write('4. the list is the same program under both execution paths'), nl,
    tensor_execution(B0, M0), must('the backend and the mode, asked', B0-M0, torch-eager),
    tensor_execution(torch, eager), E := relu(X - 2.5) matmul W, tensor_to_list(E, EL),
    tensor_execution(torch, graph), G := relu(X - 2.5) matmul W, tensor_to_list(G, GL),
    tensor_execution(torch, eager),
    must('eager and graph, the same numbers', GL, EL),

    write('5. the composites are ordinary forms'), nl,
    P := softmax([[1.0, 1.0, 1.0, 1.0]]), tensor_to_list(P, [PL]),
    must('softmax of a flat row', PL, [0.25, 0.25, 0.25, 0.25]),
    one_hot([1, 0], 2, Y),
    CE := cross_entropy([[0.0, 5.0], [5.0, 0.0]], Y), tensor_item(CE, CEv), ( CEv < 0.01 -> Small = yes ; Small = no ),
    must('cross_entropy of two confident right answers is under 0.01', Small, yes),

    write('6. an optimiser step answers NEW parameters'), nl,
    A := parameter([1.0]), Loss := mean((A - 3.0) ^ 2.0),
    tensor_grad(Loss, [A], [GA]), sgd_step([A], [GA], 0.5, [A2]),
    tensor_to_list(A2, A2L),
    must('one SGD step of 0.5 on (a - 3)^2 from 1', A2L, [3.0]),

    write('7. the answers: what asks about a tensor stands outermost, and is a term'), nl,
    V := item(mean(X * 2.0)), must('item(mean(X * 2.0))', V, 5.0),
    Sh := shape(X matmul W), must('shape(X matmul W)', Sh, [2, 1]),
    Ls := list(X - 1.0), must('list(X - 1.0)', Ls, [[0.0, 1.0], [2.0, 3.0]]),
    Rd := reduce(max, X), must('reduce(max, X), a number', Rd, 4.0),
    B := parameter([[1.0], [1.0]]), [GB] := grad(sum(X matmul B), [B]), GBL := list(GB),
    must('grad(sum(X matmul B), [B]) is the column sums', GBL, [[4.0], [6.0]]),
    Tr-Te := split(X, 1), TrL := list(Tr), TeL := list(Te), must('split(X, 1)', TrL-TeL, [[1.0, 2.0]]-[[3.0, 4.0]]),
    params_save(lesson, [X, B]), [X2, _] := params(lesson), X2L := list(X2),
    must('params(lesson): what params_save put there, back as parameters', X2L, [[1.0, 2.0], [3.0, 4.0]]),
    catch(( _ := item(X) + 1.0, Inside = accepted ), error(domain_error(tensor_expression, _), _), Inside = refused),
    must('an answer form inside an expression is refused', Inside, refused),

    write('8. a function the program defines, and a clause it adds to the grammar'), nl,
    SE := list(square_error(X, 1.0)), must('square_error(X, 1.0), defined with ::=', SE, [[0.0, 1.0], [4.0, 9.0]]),
    Db := list(double(X) + 1.0), must('double(X) + 1.0, a clause of expr//2 in this file', Db, [[3.0, 5.0], [7.0, 9.0]]),
    catch(( _ := nosuch(X), Unknown = accepted ), error(domain_error(tensor_expression, _), _), Unknown = refused),
    must('a form nothing defines is refused', Unknown, refused),

    write('9. a procedure: a DCG rule, its bindings V = E, its list what it made'), nl,
    phrase(normalise(X, Z0), Made), length(Made, NMade),
    must('normalise made four tensors: Mu, C, Sd and Z', NMade, 4),
    exec(normalise(X, Z)), ZL := list(Z),
    must('exec(normalise(X, Z)) answers Z and frees the other three', ZL, [[-1.0, 1.0], [-1.0, 1.0]]),

    write('10. the module''s predicates are nonterminals in a rule, and the tensor one emits'), nl,
    phrase(through_a_model(X, Ps1), Made2), length(Made2, NMade2),
    must('through_a_model: the row sums of X through a dense(1) of ones', Ps1, [[3.0], [7.0]]),
    must('and it made one tensor, the prediction, which model_predict emitted', NMade2, 1),
    exec(through_a_model(X, _)),
    write(done), nl.

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
