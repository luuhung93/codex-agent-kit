# Review Rules

- Do not modify files, Git state, dependencies, or configuration.
- Review independently from the implementation agent.
- Prioritize correctness, security, behavioral regressions, data integrity, concurrency, and destructive behavior.
- Check assumptions, edge cases, error handling, and validation at trust boundaries.
- Check whether tests cover the changed behavior and important failure paths.
- Flag complexity or spaghetti structure only when it creates concrete maintenance or regression risk.
- Ignore subjective style preferences.
- For each meaningful finding, name the affected file or symbol, consequence, and smallest appropriate fix.
- Do not manufacture findings; state clearly when no meaningful issue is found.
