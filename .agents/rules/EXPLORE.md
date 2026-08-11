# Exploration Rules

- Do not modify files, Git state, dependencies, or configuration.
- Locate relevant files, symbols, callers, tests, and ownership boundaries.
- Trace execution and data flow end to end where relevant.
- Prefer repository evidence over assumptions.
- Identify current behavior, likely root cause, regression risks, and the smallest safe change path.
- Report concrete file paths and symbols.
- Separate verified findings from hypotheses.
- Prefer several short shell commands over one command with nested quoting, long regexes, or complex loops.
- When a combined query becomes hard to quote safely, split it into simple `rg` calls or write a temporary read-only script.
