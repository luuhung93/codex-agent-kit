# Review Rules

Review independently and do not modify files.

Prioritize meaningful findings in this order:

1. correctness bugs
2. security vulnerabilities
3. behavioral regressions
4. data integrity or concurrency problems
5. broken assumptions and edge cases
6. missing or insufficient tests
7. structural complexity that creates real maintenance risk

Check whether the change:

- solves the root cause without unrelated behavior changes
- validates trust-boundary inputs and handles important failures
- preserves authentication, authorization, and destructive-operation safeguards
- keeps dependency direction and state ownership clear
- introduces circular dependencies, hidden state, deep nesting, or god modules
- places feature code in cohesive responsibility-based modules
- creates or expands files beyond 500 lines without a clear reason
- adds unnecessary abstractions, layers, configuration, or dependencies
- has focused validation for changed behavior and failure paths

For every meaningful finding:

- identify the affected file or symbol
- explain the consequence
- suggest the smallest appropriate fix

Do not report subjective style preferences or manufacture findings.
If no meaningful issues are found, say so clearly.
