# A first, partial token run: `deepseek-chat`

2026-11-14. The token benchmark was run through an Anthropic-compatible
gateway, so this is a token comparison and not the Claude price comparison
the README describes.

| | |
|---|---|
| model | `deepseek-chat` |
| endpoint | `https://api.deepseek.com/anthropic` |
| auth | bearer token (`ANTHROPIC_AUTH_TOKEN`) |
| effort | `high` |
| max tokens | 16 000 per call |
| rounds | at most 4 |
| reps | 3 (only the first is partial) |
| tasks | all ten |
| arms | `python`, `cocolog`, `cocolog-card` |
| cocolog | 3.62.4 at `5e33a87` |

The run was stopped during rep 1, in the `paths` / `cocolog` episode:
**16 of 90 episodes** are logged, all 16 passed, in 27 rounds and 337 970
tokens. Five tasks have all three arms; `paths` has Python only. Reps 2
and 3 were not run.

## Tokens by task and arm

| task | python | cocolog | cocolog-card |
|---|---:|---:|---:|
| `bank` | 1 857 | 21 506 | 40 918 |
| `calc` | 31 625 | 27 460 | 60 677 |
| `family` | 12 837 | 11 843 | 55 641 |
| `jsonsum` | 4 238 | 5 150 | 15 609 |
| `knapsack` | 584 | 8 862 | 13 999 |
| `paths` | 25 164 | — | — |

The two arms have different work in `paths` only, so the report's overall
ratios include 25 164 Python tokens with no cocolog counterpart and
understate the cocolog cost. The fair comparison is the five tasks with
all three arms:

| arm | tokens per task solved | against Python |
|---|---:|---:|
| `python` | 10 228 | 1.00× |
| `cocolog` | 14 964 | 1.46× |
| `cocolog-card` | 37 369 | 3.65× |

The generated report, whose `1.18×` and `2.94×` ratios mix the incomplete
`paths` episodes, is in `2026-11-14-deepseek-chat-partial.report.txt`.
The episode log is in `2026-11-14-deepseek-chat-partial.jsonl`.

No dollar figure is given: `deepseek-chat` is not in the benchmark's
`tk_price/5`, so the report says `no price`. The raw log still carries each
call's `input`, `cache_write`, `cache_read` and `output` counts.

## Every episode that completed

All 16 passed. The rounds and tokens are the episode's own totals.

| task | arm | rounds | tokens |
|---|---|---:|---:|
| `bank` | python | 1 | 1 857 |
| `bank` | cocolog | 3 | 21 506 |
| `bank` | cocolog-card | 2 | 40 918 |
| `calc` | python | 2 | 31 625 |
| `calc` | cocolog | 2 | 27 460 |
| `calc` | cocolog-card | 3 | 60 677 |
| `family` | python | 1 | 12 837 |
| `family` | cocolog | 1 | 11 843 |
| `family` | cocolog-card | 4 | 55 641 |
| `jsonsum` | python | 1 | 4 238 |
| `jsonsum` | cocolog | 1 | 5 150 |
| `jsonsum` | cocolog-card | 1 | 15 609 |
| `knapsack` | python | 1 | 584 |
| `knapsack` | cocolog | 1 | 8 862 |
| `knapsack` | cocolog-card | 1 | 13 999 |
| `paths` | python | 2 | 25 164 |

This is a partial sample, not a result for the full benchmark. The run can
be repeated with `reps=1` for all ten tasks, or with the default `reps=3`.
