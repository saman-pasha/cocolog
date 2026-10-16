%  The float flags, swipl's four -- float_overflow, float_zero_div,
%  float_undefined and float_underflow -- set by set_prolog_flag/2 as a goal
%  and read back by current_prolog_flag/2: at their defaults, each alone, and
%  all four together, over one set of expressions. Checked against SWI: run
%  by BOTH systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable, and its
%  expression is written in the body, as a program writes it. An error is
%  printed as its formal term alone, the context being each system's own.
%  A NaN is SWI's one NaN wherever the flags let one stand, which `==' tells
%  from another by its bits; the setter's other flags as goals come last.
%  Left out: an integer past 64 bits, which SWI makes a bignum of; the
%  setter's answer for a flag nobody defined, which SWI makes and cocolog
%  refuses; and float_rounding, which cocolog does not have.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
r(Set, Label) :-
    atomic_list_concat([Set, ':', Label], Tag),
    catch(( c(Label, V) -> s(Tag, V) ; s(Tag, no) ), error(E, _), s(Tag, E)).

ev(E, X) :- X is E.
eve(E, X) :- atom(x), ( atom(y) -> X is E ; X = none ).
divh(A, B, X) :- X is A / B.
powh(A, B, X) :- X is A ** B.

%  ---- an infinite result, or an infinite operand where swi promotes one ----
c(x001, X) :- X is 10.0 ** 400.
c(x002, X) :- X is -(10.0 ** 400).
c(x003, X) :- X is exp(1000).
c(x004, X) :- X is 1.0e308 * 10.
c(x005, X) :- X is 1.0e308 + 1.0e308.
c(x006, X) :- X is -1.0e308 - 1.0e308.
c(x007, X) :- X is 2 ** 10000.0.
c(x008, X) :- X is 2.0 ** 1024.
c(x009, X) :- X is max(1.0Inf, 1.0Inf).
c(x010, X) :- X is min(-1.0Inf, -1.0Inf).
c(x011, X) :- X is 1.0Inf + 1.
c(x012, X) :- X is 1 + 1.0Inf.
c(x013, X) :- X is 1.0Inf - 1.
c(x014, X) :- X is 1.0Inf * 2.
c(x015, X) :- X is 1.0Inf / 2.
c(x016, X) :- X is 1.0Inf ** -1.
c(x017, X) :- X is 1.0Inf ** 2.
c(x018, X) :- X is sqrt(1.0Inf).
c(x019, X) :- X is exp(1.0Inf).
c(x020, X) :- X is log(1.0Inf).
c(x021, X) :- X is sin(1.0Inf).
c(x022, X) :- X is float(1.0Inf).
c(x023, X) :- X is integer(1.0Inf).
c(x024, X) :- X is truncate(-1.0Inf).
c(x025, X) :- X is round(1.0Inf).
c(x026, X) :- X is 1.0Inf ** 0.
c(x027, X) :- X is 1 ** 1.0Inf.
c(x028, X) :- X is log(0).
c(x029, X) :- X is log(0.0).
c(x030, X) :- X is log(-0.0).
c(x031, X) :- X is abs(-1.0Inf).
c(x032, X) :- X is -(1.0Inf).
c(x033, X) :- X is sign(-1.0Inf).
c(x034, X) :- X is max(1.0Inf, 2).
c(x035, X) :- X is min(1.0Inf, 2).

%  ---- a division by zero ----
c(x036, X) :- X is 1 / 0.0.
c(x037, X) :- X is -1 / 0.0.
c(x038, X) :- X is 1 / -0.0.
c(x039, X) :- X is -1 / -0.0.
c(x040, X) :- X is 1 / 0.
c(x041, X) :- X is -1 / 0.
c(x042, X) :- X is 0 / 0.
c(x043, X) :- X is 0.0 / 0.0.
c(x044, X) :- X is 0 / 0.0.
c(x045, X) :- X is 0.0 / 0.
c(x046, X) :- X is 1.0 / 0.
c(x047, X) :- X is 2.5 / 0.0.
c(x048, X) :- X is 1.0Inf / 0.0.
c(x049, X) :- X is -1.0Inf / -0.0.
c(x050, X) :- X is 1.5NaN / 0.0.
c(x051, X) :- X is 0 ** -1.
c(x052, X) :- X is 0 ** -2.
c(x053, X) :- X is 0.0 ** -1.
c(x054, X) :- X is -0.0 ** -1.
c(x055, X) :- X is -0.0 ** -2.
c(x056, X) :- X is -0.0 ** -1.0.
c(x057, X) :- X is 0 ** -1.5.
c(x058, X) :- X is 0.0 ** -0.5.
c(x059, X) :- X is 0 ^ -1.
c(x060, X) :- X is 0.0 ^ -1.
c(x061, X) :- X is 1 // 0.
c(x062, X) :- X is 1 mod 0.
c(x063, X) :- X is 1 rem 0.
c(x064, X) :- X is 1 div 0.
c(x065, X) :- X is (1 / 0.0) + 1.
c(x066, X) :- X is 1 / (1 / 0.0).

%  ---- no number at all ----
c(x067, X) :- X is sqrt(-1).
c(x068, X) :- X is sqrt(-1.0).
c(x069, X) :- X is log(-1).
c(x070, X) :- X is asin(2).
c(x071, X) :- X is acos(2.0).
c(x072, X) :- X is 1.0Inf - 1.0Inf.
c(x073, X) :- X is 0.0 * 1.0Inf.
c(x074, X) :- X is 1.0Inf * 0.
c(x075, X) :- X is 1.5NaN + 1.
c(x076, X) :- X is 1 + 1.5NaN.
c(x077, X) :- X is 1.5NaN * 0.
c(x078, X) :- X is 1.5NaN / 1.5NaN.
c(x079, X) :- X is 1.0Inf / 1.0Inf.
c(x080, X) :- X is 1 / 1.0Inf.
c(x081, X) :- X is 1.5NaN ** 0.
c(x082, X) :- X is 1.5NaN ** 1.
c(x083, X) :- X is 1 ** 1.5NaN.
c(x084, X) :- X is 2 ** 1.5NaN.
c(x085, X) :- X is integer(1.5NaN).
c(x086, X) :- X is max(1.5NaN, 1).
c(x087, X) :- X is max(1, 1.5NaN).
c(x088, X) :- X is min(1.5NaN, 1.5NaN).
c(x089, X) :- X is abs(1.5NaN).
c(x090, X) :- X is -(1.5NaN).
c(x091, X) :- X is sin(1.5NaN).
c(x092, X) :- X is cos(1.0Inf).
c(x093, X) :- X is -(0.0 / 0.0).
c(x094, X) :- X is float(1.5NaN).

%  ---- a subnormal result, or a subnormal operand where swi promotes one ----
c(x095, X) :- X is 1.0e-300 * 1.0e-10.
c(x096, X) :- X is 1.0e-320 + 0.
c(x097, X) :- X is 5.0e-324 * 1.
c(x098, X) :- X is 2.0e-308 / 4.
c(x099, X) :- X is 2.0e-308 / 4.0.
c(x100, X) :- X is 1.0e-310.
c(x101, X) :- X is 1.0e-310 + 1.0.
c(x102, X) :- X is 1.0e-310 + 1.
c(x103, X) :- X is 1.0e-310 * 2.
c(x104, X) :- X is sqrt(1.0e-310).
c(x105, X) :- X is 1.0e-310 / 2.0.
c(x106, X) :- X is 1.0e-310 ** 1.
c(x107, X) :- X is exp(-1000).
c(x108, X) :- X is exp(-708.5).
c(x109, X) :- X is max(1.0e-310, 0).
c(x110, X) :- X is -(1.0e-310).
c(x111, X) :- X is abs(-1.0e-310).
c(x112, X) :- X is 1.0e-310 - 1.0e-310.
c(x113, X) :- X is float(1.0e-310).
c(x114, X) :- X is 2.2250738585072014e-308 / 2.

%  ---- the constants ----
c(x115, X) :- X is inf.
c(x116, X) :- X is -inf.
c(x117, X) :- X is nan.
c(x118, X) :- X is epsilon.
c(x119, X) :- X is inf + 0.
c(x120, X) :- X is nan + 0.
c(x121, X) :- X is 1.0 + epsilon.

%  ---- the list and aggregate predicates, a clause's head, an environment's
%  branch, and two NaNs that are one ----
c(x122, S) :- sum_list([1.0Inf, -1.0Inf], S).
c(x123, S) :- sum_list([1.0e308, 1.0e308], S).
c(x124, S) :- sum_list([1.5NaN, 1], S).
c(x125, S) :- sum_list([1.0e-310, 0], S).
c(x126, S) :- max_list([1.0Inf, 1.0Inf], S).
c(x127, S) :- min_list([-1.0Inf, -1.0Inf], S).
c(x128, S) :- max_list([1.5NaN, 1], S).
c(x129, S) :- aggregate_all(sum(X), member(X, [1.0e308, 1.0e308]), S).
c(x130, S) :- aggregate_all(sum(X), member(X, [1.5NaN, 1]), S).
c(x131, S) :- aggregate_all(max(X), member(X, [1.0Inf, 1.0Inf]), S).
c(x132, S) :- aggregate_all(min(X), member(X, [0, -1.0Inf, -1.0Inf]), S).
c(x133, S) :- divh(1, 0.0, S).
c(x134, S) :- divh(0, 0, S).
c(x135, S) :- powh(0, -1, S).
c(x136, S) :- eve(1 / 0, S).
c(x137, S) :- eve(0.0 / 0.0, S).
c(x138, S) :- ev(10.0 ** 400, S).
c(x139, S) :- ( A is nan, B is 0.0 / 0.0, ( A == B -> S = same ; S = differ ) ).
c(x140, S) :- ( A is nan, ( A == 1.5NaN -> S = same ; S = differ ) ).
c(x141, S) :- ( A is -nan, B is nan, ( A == B -> S = same ; S = differ ) ).
c(x142, S) :- ( A is 1.0Inf - 1.0Inf, B is nan, ( A == B -> S = same ; S = differ ) ).
c(x143, S) :- ( sum_list([1.0Inf, -1.0Inf], A), B is nan, ( A == B -> S = same ; S = differ ) ).
c(x144, X) :- X is max(1.0e-310, 1.0e-310).
c(x145, S) :- max_list([1.0e-310, 1.0e-310], S).
c(x146, S) :- aggregate_all(max(X), member(X, [1.0e-310]), S).
c(x147, X) :- X is 2.0 ** -1050.

%  ---- the setter's refusals, and the flags read back ----
v(Label, G) :- catch(( G -> s(Label, yes) ; s(Label, no) ), error(E, _), s(Label, E)).
setter :-
    v(dom, set_prolog_flag(float_overflow, nan)),
    v(dom2, set_prolog_flag(float_undefined, infinity)),
    v(dom3, set_prolog_flag(float_underflow, nan)),
    v(dom4, set_prolog_flag(double_quotes, foo)),
    v(type, set_prolog_flag(float_zero_div, 1)),
    v(type2, set_prolog_flag(1, error)),
    v(type3, set_prolog_flag(f(x), error)),
    v(inst, set_prolog_flag(_, error)),
    v(inst2, set_prolog_flag(float_overflow, _)),
    v(perm, set_prolog_flag(float_max, 1.0)),
    v(perm2, set_prolog_flag(bounded, false)),
    v(perm3, set_prolog_flag(executable, x)),
    v(same, set_prolog_flag(float_overflow, error)),
    v(dq, ( set_prolog_flag(double_quotes, chars), term_to_atom(T, 'f("ab")'),
            set_prolog_flag(double_quotes, codes), T == f([a, b]) )),
    v(gdi, set_prolog_flag(generate_debug_info, false)),
    v(gdi2, set_prolog_flag(generate_debug_info, maybe)),
    forall(member(F, [float_min, float_max, float_max_integer]),
           ( current_prolog_flag(F, V) -> s(F, V) ; s(F, none) )).

flags([float_overflow, float_zero_div, float_undefined, float_underflow]).
default(float_overflow, error).
default(float_zero_div, error).
default(float_undefined, error).
default(float_underflow, ignore).

setting(defaults, []).
setting(overflow, [float_overflow-infinity]).
setting(zero_div, [float_zero_div-infinity]).
setting(undefined, [float_undefined-nan]).
setting(underflow, [float_underflow-error]).
setting(all, [float_overflow-infinity, float_zero_div-infinity, float_undefined-nan,
              float_underflow-error]).

run(Set) :-
    setting(Set, Pairs),
    forall(member(F-V, Pairs), set_prolog_flag(F, V)),
    flags(Fs),
    forall(member(F, Fs), ( current_prolog_flag(F, V) -> s(Set:F, V) ; s(Set:F, none) )),
    labels(Ls), forall(member(L, Ls), r(Set, L)),
    forall(member(F, Fs), ( default(F, D), set_prolog_flag(F, D) )).

labels([x001, x002, x003, x004, x005, x006, x007, x008, x009, x010, x011, x012, x013,
        x014, x015, x016, x017, x018, x019, x020, x021, x022, x023, x024, x025, x026,
        x027, x028, x029, x030, x031, x032, x033, x034, x035, x036, x037, x038, x039,
        x040, x041, x042, x043, x044, x045, x046, x047, x048, x049, x050, x051, x052,
        x053, x054, x055, x056, x057, x058, x059, x060, x061, x062, x063, x064, x065,
        x066, x067, x068, x069, x070, x071, x072, x073, x074, x075, x076, x077, x078,
        x079, x080, x081, x082, x083, x084, x085, x086, x087, x088, x089, x090, x091,
        x092, x093, x094, x095, x096, x097, x098, x099, x100, x101, x102, x103, x104,
        x105, x106, x107, x108, x109, x110, x111, x112, x113, x114, x115, x116, x117,
        x118, x119, x120, x121, x122, x123, x124, x125, x126, x127, x128, x129, x130,
        x131, x132, x133, x134, x135, x136, x137, x138, x139, x140, x141, x142, x143,
        x144, x145, x146, x147]).

main :- setter, forall(setting(S, _), run(S)).
