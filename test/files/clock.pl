%% stamp_date_time/3, date_time_stamp/2 and format_time/3,4 (cocolog
%% 3.77.0), held to swipl 9.0.4's pl-tai.c line for line.
%%
%% THE ZONE IS PINNED: test/files.pl runs this case under
%% TZ=CET-1CEST,M3.5.0,M10.5.0/3 and LC_ALL=C.UTF-8 for both systems
%% (`case_env/2'), a POSIX rule the C library reads without a zoneinfo
%% file, so `local' is an hour east of UTC in winter and two in summer,
%% CET and CEST, on any box. The C.UTF-8 locale writes strftime(3)'s
%% directives as cocolog's C locale does.
%%
%% x86-64's answers: an infinity, a NaN and a stamp past a long are the
%% least long's date (cvttsd2si), which swipl's C leaves to the machine and
%% cocolog writes out.

t(N, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    \+ \+ ( numbervars(N-R, 0, _), print(N-R), nl ).

%% a time formatted into an atom
f(N, F, T) :- t(N, format_time(atom(_), F, T)).
p(N, F, T) :- t(N, format_time(atom(_), F, T, posix)).

main :-
    stamps,
    stamps_odd,
    local_stamps,
    dates,
    dates_local,
    directives,
    directives_odd,
    names,
    sinks,
    errors,
    zone_kept.

stamps :-
    t(s1, stamp_date_time(0, _, 'UTC')),
    t(s2, stamp_date_time(0, _, 0)),
    t(s3, stamp_date_time(0, _, 3600)),
    t(s4, stamp_date_time(0, _, -3600)),
    t(s5, stamp_date_time(0.5, _, 'UTC')),
    t(s6, stamp_date_time(1700000000.123456, _, 'UTC')),
    t(s7, stamp_date_time(-1, _, 'UTC')),
    t(s8, stamp_date_time(-86400.25, _, 'UTC')),
    t(s9, stamp_date_time(1.0e12, _, 'UTC')),
    t(s10, stamp_date_time(253402300800, _, 'UTC')),
    t(s11, stamp_date_time(-62135596800, _, 'UTC')),
    t(s12, stamp_date_time(-62135596801, _, 'UTC')),
    t(s13, stamp_date_time(1r3, _, 'UTC')),
    t(s14, stamp_date_time(10, _, 86400)),
    t(s15, stamp_date_time(10, _, 100000)),
    t(s16, stamp_date_time(0.999999999, _, 'UTC')),
    t(s17, stamp_date_time(59.9999999, _, 'UTC')),
    t(s18, stamp_date_time(951782400, _, 'UTC')),
    t(s19, stamp_date_time(951868800, _, 'UTC')),
    t(s20, stamp_date_time(4107542400, _, 'UTC')),
    t(s21, stamp_date_time(0, _, -86400000)),
    t(s22, stamp_date_time(-0.0, _, 'UTC')),
    t(s23, stamp_date_time(-0.5, _, 'UTC')),
    t(s24, stamp_date_time(-1.0e-10, _, 'UTC')),
    t(s25, stamp_date_time(1.0e-10, _, 'UTC')),
    t(s26, stamp_date_time(0, date(1970,1,1,0,0,0.0,0,'UTC',-), 'UTC')),
    t(s27, stamp_date_time(0, date(1970,1,1,0,0,0,0,'UTC',-), 'UTC')),
    t(s28, stamp_date_time(0, x, 'UTC')),
    t(s29, stamp_date_time(2147483648, _, 'UTC')).

%% past a long, and what x86-64 makes of a NaN
stamps_odd :-
    t(o1, stamp_date_time(1.0Inf, _, 'UTC')),
    t(o2, stamp_date_time(-1.0Inf, _, 'UTC')),
    t(o3, stamp_date_time(1.5NaN, _, 'UTC')),
    t(o4, stamp_date_time(1.0e19, _, 'UTC')),
    t(o5, stamp_date_time(9223372036854775807, _, 'UTC')),
    t(o6, stamp_date_time(-9223372036854775808, _, 'UTC')),
    t(o7, stamp_date_time(4.6e18, _, 'UTC')),
    t(o8, stamp_date_time(-4.7e18, _, 'UTC')),
    t(o9, stamp_date_time(1.0e300, _, 3600)).

local_stamps :-
    t(l1, stamp_date_time(0, _, local)),
    t(l2, stamp_date_time(1700000000.5, _, local)),
    t(l3, stamp_date_time(1688000000, _, local)),
    t(l4, stamp_date_time(-0.5, _, local)),
    t(l5, stamp_date_time(1679792400, _, local)),
    t(l6, stamp_date_time(1679795999, _, local)),
    t(l7, stamp_date_time(1698541200, _, local)),
    t(l8, stamp_date_time(-1.0e10, _, local)),
    t(l9, stamp_date_time(1.0e15, _, local)).

dates :-
    t(d1, date_time_stamp(date(1970,1,1,0,0,0,0,-,-), _)),
    t(d2, date_time_stamp(date(1970,1,1,0,0,0.0,0,'UTC',-), _)),
    t(d3, date_time_stamp(date(2023,11,14,22,13,20.123456,0,-,-), _)),
    t(d4, date_time_stamp(date(1970,1,1,0,0,0,3600,-,-), _)),
    t(d5, date_time_stamp(date(1970,13,1,0,0,0,0,-,-), _)),
    t(d6, date_time_stamp(date(1970,1,32,0,0,0,0,-,-), _)),
    t(d7, date_time_stamp(date(1970,1,1,25,0,0,0,-,-), _)),
    t(d8, date_time_stamp(date(1970,1,1,0,61,0,0,-,-), _)),
    t(d9, date_time_stamp(date(1970,1,1,0,0,61,0,-,-), _)),
    t(d10, date_time_stamp(date(1970,0,1,0,0,0,0,-,-), _)),
    t(d11, date_time_stamp(date(1970,1,0,0,0,0,0,-,-), _)),
    t(d12, date_time_stamp(date(1970,-1,1,0,0,0,0,-,-), _)),
    t(d13, date_time_stamp(date(1970,1,1,-1,0,0,0,-,-), _)),
    t(d14, date_time_stamp(date(1970,1,1,0,0,-0.5,0,-,-), _)),
    t(d15, date_time_stamp(date(1,1,1,0,0,0,0,-,-), _)),
    t(d16, date_time_stamp(date(0,1,1,0,0,0,0,-,-), _)),
    t(d17, date_time_stamp(date(-1,1,1,0,0,0,0,-,-), _)),
    t(d18, date_time_stamp(date(10000,1,1,0,0,0,0,-,-), _)),
    t(d19, date_time_stamp(date(1970,1,1,0,0,0,0,foo,true), _)),
    t(d20, date_time_stamp(date(1970,1,1,0,0,0,0,-,-), 0.0)),
    t(d21, date_time_stamp(date(1970,1,1,0,0,0,0,-,-), 0)),
    t(d22, date_time_stamp(date(1970,1,1,0,0,1r3,0,-,-), _)),
    t(d23, date_time_stamp(date(2023,2,29,0,0,0,0,-,-), _)),
    t(d24, date_time_stamp(date(1970,1,1,0,0,1.0e20,0,-,-), _)),
    t(d25, date_time_stamp(date(1970,1,1,0,0,1.0Inf,0,-,-), _)),
    t(d26, date_time_stamp(date(1970,1,1,0,0,9999999999,0,-,-), _)),
    t(d27, date_time_stamp(date(1970,99999,1,0,0,0,0,-,-), _)),
    t(d28, date_time_stamp(date(1970,1,99999,0,0,0,0,-,-), _)),
    t(d29, date_time_stamp(date(1970,1,1,0,0,0,0,[],-), _)),
    t(d30, date_time_stamp(date(2023,7,1,12,0,0,0,-,on), _)),
    t(d31, date_time_stamp(date(2023,7,1,12,0,0,0,-,off), _)),
    t(d32, date_time_stamp(date(2023,7,1,12,0,0,0,-,1), _)),
    t(d33, date_time_stamp(date(2023,7,1,12,0,0,0,-,0), _)).

%% no offset given: mktime(3) in CET, and the offset, the daylight word and
%% the zone bound where they are unbound -- or, with the daylight word
%% given, no offset at all (swipl's NO_UTC_OFFSET, 2147483647 seconds)
dates_local :-
    t(m1, date_time_stamp(date(1970,1,1,0,0,0,_,_,_), _)),
    t(m2, date_time_stamp(date(1970,1,1), _)),
    t(m3, date_time_stamp(date(2000,2,30), _)),
    t(m4, date_time_stamp(date(2023,7,1,12,0,0,_,_,_), _)),
    t(m5, date_time_stamp(date(2023,1,1,12,0,0,_,_,_), _)),
    t(m6, date_time_stamp(date(2023,3,26,2,30,0,_,_,_), _)),
    t(m7, date_time_stamp(date(2023,10,29,2,30,0,_,_,_), _)),
    t(m8, date_time_stamp(date(2023,7,1,12,0,0,_,_,true), _)),
    t(m9, date_time_stamp(date(2023,7,1,12,0,0,_,_,false), _)),
    t(m10, date_time_stamp(date(2023,7,1,12,0,0,_,_,-), _)),
    t(m11, date_time_stamp(date(2023,7,1,12,0,0,_,zz,_), _)),
    t(m12, date_time_stamp(date(2023,7,1,12,0,0,0,_,_), _)),
    t(m13, date_time_stamp(date(1970,1,1,0,59,59,_,_,_), _)),
    t(m14, date_time_stamp(date(1970,1,1,0,0,61.5,_,_,_), _)),
    t(m15, date_time_stamp(date(2023,13,40,0,0,0,_,_,_), _)),
    t(m16, date_time_stamp(date(2023,7,1,12,0,0,1,_,_), _)),
    t(m17, date_time_stamp(date(2023,7,1,12,0,0,_,_,_), 1688205600.0)),
    t(m18, date_time_stamp(date(2023,7,1,12,0,0,7,_,_), 1688205600.0)).

directives :-
    f(f1, '%Y-%m-%d %H:%M:%S', 0),
    f(f2, '%a %A %b %B %h', 1700000000),
    f(f3, '%c|%p|%P|%x|%X', 1700000000),
    f(f4, '%C %d %D %e %F', 1700000000),
    f(f5, '%G %g %V %j %u %U %w %W', 1700000000),
    f(f6, '%H %I %k %l %m %M %S %y %Y', 1700000000),
    f(f7, '%n%t%%', 0),
    f(f8, '%r %R %T', 1700000000),
    f(f9, '%f %3f %0f %9f %12f', 1700000000.123456),
    f(f10, '%s', 1700000000.7),
    f(f11, '%z %:z %Oz %Z', 1700000000),
    f(f12, '%z %:z %Oz %Z', 1688000000),
    f(f13, '%+', 1700000000),
    f(f14, '%5Y|%3d|%10%', 0),
    f(f15, [0'%, 0'Y], 0),
    f(f16, [a, b], 0),
    f(f17, [], 0),
    f(f18, '%Y', date(2023,7,1)),
    f(f19, '%Y-%m-%d %H:%M:%S %z %Z', date(2023,7,1,12,0,0,3600,-,-)),
    f(f20, '%Y-%m-%d %H:%M:%S %z %Z|%a', date(2023,7,1,12,0,0.5,-7200,'CEST',true)),
    f(f21, '%j %U %W %V %G', date(2021,1,1)),
    f(f22, '%j %U %W %V %G', date(2020,12,31)),
    f(f23, '%j %U %W %V %G', date(2024,12,30)),
    f(f24, '%s %f', date(2023,7,1,12,0,1.25,0,-,-)),
    f(f25, '%d %e', date(2023,7,5)),
    f(f26, '%I %l %p', date(2023,7,5,0,30,0,0,-,-)),
    f(f27, '%I %l %p', date(2023,7,5,13,30,0,0,-,-)),
    f(f28, '%s', -0.5),
    f(f29, '%f', -0.5),
    f(f30, '%S %f', 59.9999999),
    f(f31, '%2f|%1f', 0.987654),
    f(f32, '%u|%w|%U|%W', date(2023,1,1,0,0,0,0,-,-)),
    f(f33, '%Z|%z', date(2023,7,1,12,0,0,0,[],-)),
    f(f34, '%Z|%z', date(2023,7,1,12,0,0,_,_,true)),
    f(f35, '%Z|%z', date(2023,7,1,12,0,0,_,_,-)),
    f(f36, '%Z|%z', date(2023,7,1)),
    f(f37, '%Z|%z|%s', date(2023,1,1,0,0,0,_,_,_)),
    f(f38, '%s', 1r3).

%% what swipl's C does with a field out of its range, and with a stamp
%% past a long
directives_odd :-
    f(x1, '%a %b', date(2023,13,40)),
    f(x2, '%s', date(1970,1,1,0,0,61,0,-,-)),
    f(x3, '%a%s', date(1970,1,1,0,0,61,0,-,-)),
    f(x4, '%b|%B|%a', date(2023,13,1,0,0,0,0,-,-)),
    f(x5, '%y|%d|%e', date(-105,-3,-7,0,0,0,0,-,-)),
    f(x6, '%H|%I|%k|%l|%M|%S', date(2023,1,1,-5,-7,-9,0,-,-)),
    f(x7, '%+', date(10000,7,1,12,0,0,0,-,-)),
    f(x8, '%+', date(-1,7,1,12,0,0,0,-,-)),
    f(x9, '%+', date(999,7,1,12,0,0,0,-,-)),
    f(x10, '%s|%f', 1.5NaN),
    f(x11, '%s|%f', 1.0Inf),
    f(x12, '%s|%3f', 1.0e300),
    f(x13, '%s|%f', date(1970,1,1,0,0,1.5NaN,0,-,-)),
    f(x14, '%s|%f', date(1970,1,1,0,0,1.0Inf,0,-,-)),
    f(x15, '%s|%f', date(1970,1,1,0,0,-1.0Inf,0,-,-)),
    f(x16, '%a', -1.0e20),
    f(x17, '%Y %m %d %H:%M:%S %Z %z', 1.0e20).

names :-
    p(n1, '%a %A %b %B', 0),
    p(n2, '%A %B', 1700000000),
    p(n3, '%a %b %h', date(2023,7,1,12,0,0,0,-,-)),
    p(n4, '%Y-%m-%d %c', 1688000000),
    t(n5, format_time(atom(_), '%a', 0, foo)),
    t(n6, format_time(atom(_), '%a', 0, _)),
    t(n7, format_time(atom(_), '%a', 0, 1)),
    t(n8, format_time(atom(_), '%a', 0, [])),
    t(n9, format_time(atom(_), '%Y', foo, foo)),
    t(n10, format_time(atom(_), 12, 0, posix)).

sinks :-
    t(k1, format_time(string(_), '%Y', 0)),
    t(k2, format_time(codes(_), '%Y', 0)),
    t(k3, format_time(chars(_), '%Y', 0)),
    t(k4, format_time(codes(_, T), '%Y', 0)), ( var(T) -> writeln(k4_tail_open) ; print(T), nl ),
    t(k5, format_time(chars(_, []), '%y', 0)),
    t(k6, format_time(atom(x), '%Y', 0)),
    t(k7, format_time(atom('1970'), '%Y', 0)),
    format_time(user_output, 'out:%Y%n', 0),
    t(k8, format_time(user_output, 'part:%Y%q', 0)), nl,
    t(k9, format_time(codes(C9), '\xE9\%Y\x20AC\', 0)), print(C9), nl.

%% each predicate's errors, in the order swipl checks the arguments
errors :-
    t(e1, stamp_date_time(_, _, 'UTC')),
    t(e2, stamp_date_time(a, _, 'UTC')),
    t(e3, stamp_date_time(0, _, _)),
    t(e4, stamp_date_time(0, _, foo)),
    t(e5, stamp_date_time(0, _, 1.5)),
    t(e6, stamp_date_time(0, _, utc)),
    t(e7, stamp_date_time(0, _, 2147483648)),
    t(e8, stamp_date_time(0, _, 9223372036854775807)),
    t(e9, stamp_date_time(0, _, [])),
    t(e10, stamp_date_time(0, _, 0.0)),
    t(e11, stamp_date_time(f(x), _, 'UTC')),
    t(e12, stamp_date_time(a, _, foo)),
    t(e13, stamp_date_time(_, _, local)),
    t(e14, date_time_stamp(date(1970,1,1,0,0,0,0,foo,bar), _)),
    t(e15, date_time_stamp(date(_,1,1,0,0,0,0,-,-), _)),
    t(e16, date_time_stamp(date(1970,_,1,0,0,0,0,-,-), _)),
    t(e17, date_time_stamp(date(1970,1,1,_,0,0,0,-,-), _)),
    t(e18, date_time_stamp(date(1970,1,1,0,0,_,0,-,-), _)),
    t(e19, date_time_stamp(date(a,1,1,0,0,0,0,-,-), _)),
    t(e20, date_time_stamp(date(1970,1,1,0,0,a,0,-,-), _)),
    t(e21, date_time_stamp(_, _)),
    t(e22, date_time_stamp(foo, _)),
    t(e23, date_time_stamp(date(1970,1,1,0,0,0,1.5,-,-), _)),
    t(e24, date_time_stamp(date(1970,1,1,0,0,0,0), _)),
    t(e25, date_time_stamp(date(1970,1.5,1,0,0,0,0,-,-), _)),
    t(e26, date_time_stamp(date(1970,1,1,0,0,0,2147483648,-,-), _)),
    t(e27, date_time_stamp(date(9223372036854775807,1,1,0,0,0,0,-,-), _)),
    t(e28, date_time_stamp(date(1970,1,1,0,99999999999,0,0,-,-), _)),
    t(e29, date_time_stamp(date(2023,7,1,12,0,0,0,1,-), _)),
    t(e30, date_time_stamp(date(2023,7,1,12,0,0,0,f(x),-), _)),
    t(e31, date_time_stamp(date(a,b,c,d,e,f,g,h,i), _)),
    t(e32, date_time_stamp(date(2023,7,1,12,0,0,0,-,fail), _)),
    t(e33, date_time_stamp(date(2023,7,1,12,0,0,0,-,2), _)),
    t(e34, date_time_stamp(date(2023,7,1,12,0,0,0,-,1.0), _)),
    t(e35, date_time_stamp(date(2023,7,1,12,0,0,0,-,[]), _)),
    f(e36, '%E', 0),
    f(e37, '%O', 0),
    f(e38, '%q', 0),
    f(e39, '%', 0),
    f(e40, 'abc%', 0),
    f(e41, '%:', 0),
    f(e42, 'x%Ex', 0),
    f(e43, '%C', date(10000,1,1)),
    f(e44, '%C', date(-1,1,1)),
    f(e45, '%Y %y %C %G %g', date(-1,1,1)),
    f(e46, 12, 0),
    f(e47, _, 0),
    f(e48, '%Y', _),
    f(e49, '%Y', foo),
    f(e50, '%Y-%m-%d %H:%M:%S %z %Z', date(2023,7,1,12,0,0,'CET',-,-)),
    t(e51, format_time(foo, '%Y', 0)),
    t(e52, format_time(_, '%Y', 0)),
    t(e53, format_time(atom(_), 12, foo)),
    t(e54, format_time(nosuch, '%Y', foo)),
    t(e55, format_time(nosuch, 12, 0)),
    t(e56, format_time(user_input, '%Y', 0)),
    t(e57, format_time(atom(_), '%Y', [0'0])),
    key(e58, '%\xE9\'),
    key(e59, '%\x20AC\'),
    key(e60, 'x%\x100\').

%% THE ZONE CHANGED UNDER THE PROGRAM, last: mktime(3) reads TZ again, so
%% the offset follows it and so does the C library's own name (%Z of a
%% date/3), while the names swipl keeps (tz_name_as_atom()) are those of
%% the zone first asked, CET's
zone_kept :-
    setenv('TZ', 'UTC0'),
    t(z1, date_time_stamp(date(2023,1,1,12,0,0,_,_,_), _)),
    f(z2, '%Z %z', date(2023,1,1)),
    t(z3, stamp_date_time(0, _, local)),
    f(z4, '%Z %z', 0).

%% a directive's key, past ASCII: swipl's key[] is a char, so the atom is
%% the code's low byte
key(N, F) :-
    catch(( format_time(atom(_), F, 0) -> R = yes ; R = no ),
          error(existence_error(format, K), _), ( atom_codes(K, Cs), R = key(Cs) )),
    print(N-R), nl.
