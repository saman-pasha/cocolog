%% generate.pl -- the model call, and only the model call.
%%
%% Everything around it is deterministic and lives in tools/cocolint/*.pl;
%% this is the one place a key is needed. Run by agent.sh:
%%
%%     cocolog --local run generate.pl coco_generate SYS.txt USER.txt OUT.json
%%
%% THROUGH library(llm) RATHER THAN library(curl), because that is the tier-2
%% library this repository ships for exactly this: the provider table, the
%% 600-second default timeout (curl's 30 is wrong for a generation and would
%% cut one off mid-file), and the single Content-Type header that took writing
%% a tutorial to find.
%%
%% THE OUTPUT SCHEMA IS DESIGN.md SECTION 8's GENERATOR SCHEMA, asked for by
%% llm_json/4 -- which appends the instruction as a system message and throws
%% with the text that was there when the reply is not JSON, rather than
%% failing. A failure here would be indistinguishable from a predicate with no
%% clauses, which is the distinction this whole design is about.
%%
%% IT DOES NOT VERIFY. verify.sh does, in a separate process, on the file this
%% writes -- so a generation that hangs cannot take the gates down with it, and
%% a repair iteration is the same two commands as the first attempt.

:- use_module(library(llm)).
:- use_module(library(json)).

%% coco_generate is the entry point agent.sh names on the CLI. The three
%% paths arrive through current_prolog_flag(argv, _)? No -- cocolog has
%% exactly ONE flag and it is `executable', so the paths come from the
%% environment, which is the arrangement that works in every one of the four
%% knowledge-base arrangements.
coco_generate :-
    getenv('COCO_AGENT_SYSTEM', SysPath),
    getenv('COCO_AGENT_USER', UserPath),
    getenv('COCO_AGENT_OUT', OutPath),
    read_file_to_codes(SysPath, SysCodes),
    read_file_to_codes(UserPath, UserCodes),
    atom_codes(System, SysCodes),
    atom_codes(User, UserCodes),
    coco_generate_schema(Instruction),
    llm_json([msg(system, System), msg(user, User)], Instruction,
             [max_tokens(8192), timeout(600)], Term),
    json_codes(Term, OutCodes),
    coco_write_file(OutPath, OutCodes),
    write(done), nl.

%% THE SCHEMA IS ONE ATOM AND IS JOINED WITH SPACES, not written across
%% lines: a string literal in this dialect is a code list and a Prolog atom
%% cannot carry a newline without an escape the reader does not have.
coco_generate_schema(I) :-
    atomic_list_concat([
        'Answer with an object of exactly these keys:',
        'verdict (one of "code", "impossible", "needs-a-layer"),',
        'files (a list of objects with path, role and content),',
        'run (a list of command-line arguments, ending in the goal name),',
        'predicates (a list of objects with name, arity and public),',
        'checks (a list of objects with label, goal, expect and negative),',
        'divergences_applied (a list of objects with swi, cocolog, rule and cite),',
        'uncertain (a list of strings),',
        'refusal (null, or an object with want, because, layer and nearest).',
        'Every predicate you define must be prefixed with the program name.',
        'Do not call halt. End main by writing the word done on its own line.'
    ], ' ', I).

%% `write_file_from_codes/2', NOT `write_file/2'. There is no stream layer
%% here -- no open/3, no close/1 -- and library(files) names the one predicate
%% that writes a whole file. cocolint's own G1 caught the wrong name in this
%% very file, which is the smallest possible demonstration that the tool works.
coco_write_file(Path, Codes) :-
    (   catch(write_file_from_codes(Path, Codes), _, fail)
    ->  true
    ;   throw(error(coco_agent_error(cannot_write, Path), coco_generate/0))
    ).
