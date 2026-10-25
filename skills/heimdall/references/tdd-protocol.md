# TDD Protocol — Coders Build Test-First at Agreed Seams

Every coder follows this protocol for every ticket that changes behavior, in Build mode and in Direct mode. Reviewers audit against it. Adapted from Matt Pocock's `tdd` skill and its good-tests and mocking references (github.com/mattpocock/skills, MIT License, © 2026 Matt Pocock); Heimdall adds seam sign-off at G2, the red-first evidence audit, and the multi-agent rules.

## 1. What a good test is

Tests verify **behavior through public interfaces**, not implementation details. Code can change entirely; tests should not. A good test reads like a specification: "user can check out with a valid cart" says exactly what capability exists, and it survives refactors because it does not care about internal structure.

- Uses the public API only, and describes WHAT, not HOW.
- One logical assertion per test.
- Names use the project's domain vocabulary (the spec's Glossary, and `GLOSSARY.md` or `CONTEXT.md` if the repo has one).
- Expected values come from an independent source of truth: a literal, a worked example, the spec.

```typescript
// GOOD: verifies through the interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  expect((await getUser(user.id)).name).toBe("Alice");
});

// BAD: bypasses the interface (side channel)
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  expect(await db.query("SELECT * FROM users WHERE name = ?", ["Alice"])).toBeDefined();
});
```

## 2. Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside.

- Seams are proposed in the spec's Testing Decisions and **locked at G2** with the user, in HANDOFF.md (Testing Decisions: seam → module → test type → boundary doubles). This is Heimdall's version of "confirm the seams with the user before writing any test".
- Each ticket names the seams it tests. **Test only at those seams.**
- A coder that needs a seam not in HANDOFF stops and reports `BLOCKED: seam` with the proposed interface. The orchestrator may approve a seam that sits inside an already-approved module boundary (recorded in HANDOFF, informational); anything else goes to the user.

## 3. Anti-patterns (the reviewer rejects these)

- **Implementation-coupled:** mocks internal collaborators, tests private methods, asserts call counts or order, or verifies through a side channel. The tell: the test breaks on a refactor that did not change behavior.
- **Tautological:** the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`), so it passes by construction.
- **Horizontal slicing:** all tests first, then all implementation. Bulk tests verify imagined behavior and lock in test structure before the implementation teaches you anything. Work in vertical slices: one test, one implementation, repeat — each test a tracer bullet.

## 4. Doubles — mock only at system boundaries

Mock: external APIs (payment, email), time, randomness, sometimes the database (prefer a real test database, for example in a podman container) and the file system. Never mock your own modules or anything you control.

Design boundaries to be mockable:

- **Dependency injection:** pass clients in (`processPayment(order, paymentClient)`), never construct them inside from environment secrets.
- **SDK-style interfaces:** one function per external operation (`api.getUser`, `api.createOrder`), not one generic `fetch(endpoint, options)` that forces conditional logic into every mock.

## 5. The loop

For each acceptance criterion of the ticket, in order:

1. Pick the next behavior. Write **one** test at an agreed seam.
2. Run that test file. It must fail **for the right reason**: the behavior is missing. A typo, a wrong import path, or broken test setup is not red — fix the test and run again.
3. Write the minimum code that makes it pass. Do not anticipate later tests or add speculative features.
4. Run the test file; it passes. Run the type checker regularly.
5. Commit (section 6). Next behavior.

After the last criterion: run the **full suite** once, then sync with the integration tip and run it again (merge-protocol.md, L5).

**Refactoring is not part of the loop.** It happens in review: the reviewer flags smells, and the coder refactors in the fix round with the suite green before and after. Whole-branch cleanup happens at G6.

## 6. Red-first evidence

Reviewers cannot watch the loop, so the coder leaves evidence:

- **Commit order.** For each behavior, a `test(T<nn>): <behavior>` commit (the failing test) comes before the `feat(T<nn>): <behavior>` commit that makes it pass, or both land in one commit and the report quotes the red output. Fix rounds use `fix(T<nn>): …` and `refactor(T<nn>): …`. The squash merge collapses them, so the audit happens at review time.
- **Report table** (assets/return-report.md): criterion → test name → the one-line failure message seen at red → green.

The reviewer audits:

1. `git log --reverse --format='%h %s' <base>..<head>`: test commits precede or accompany the behavior they cover.
2. Every new test sits at a seam listed in the ticket.
3. **Red-at-base check** (mandatory in Production and on High-risk tickets; one spot-check in MVP; skipped in Prototype): run the ticket's new tests against the base code. They must fail. The orchestrator writes this script as `.heimdall/packets/T<nn>-red-at-base.sh` with every placeholder filled, and the review packet points at it; the reviewer runs it with `bash <absolute path>` (one allow-listed command, so no shell grant for loops or `mkdir` is needed):
   ```bash
   #!/usr/bin/env bash
   set -eu
   W=<worktree>; S=<worktree-root>/scratch-t<nn>; BASE=<base-sha>; HEAD=<head-sha>
   git -C "$W" worktree add --detach "$S" "$BASE"
   trap 'git -C "$W" worktree remove --force "$S"' EXIT
   (cd "$S" && <Install command from HANDOFF>)                  # the scratch tree has no installed dependencies
   git -C "$W" diff --name-only --diff-filter=AM "$BASE" "$HEAD" -- <test path globs from the touch set> | while read -r f; do
     mkdir -p "$S/$(dirname "$f")" && git -C "$W" show "$HEAD:$f" > "$S/$f"
   done
   (cd "$S" && <one-test-file command from HANDOFF> <the same files>) || echo "RED-AT-BASE: tests failed on the base code, as expected"
   ```
   `<base-sha>` is the report's `Synced with` SHA; `<test path globs>` are the test paths of the ticket's touch set. A test that fails in the scratch tree because of a missing dependency or a renamed module, not a missing behavior, is a setup error, not a red: fix the script's Install step and run again.
   A new test that passes on the base code tests nothing new.

## 7. Bugs

A bug fix starts with a test that reproduces the bug through a seam (red), then the fix (green). The ticket's acceptance includes "the reproduction no longer reproduces" and "no regression" (the full suite). For hard bugs, diagnose first: reproduce, minimise, hypothesise, instrument, fix, regression-test.

## 8. Special cases

- **Scaffold, config, and docs tickets** have no behavior to drive. The ticket says `TDD: n/a — <reason>` and names a verification instead (the build passes, the test runner finds a smoke test, CI runs).
- **Untested legacy code:** before changing it, a prefactor ticket adds characterization tests at the seam (pinning current behavior), then the change ticket proceeds test-first.
- **Wide refactors** (one mechanical change with a large blast radius) use expand–contract: add the new form beside the old, migrate call sites in batches (one ticket per batch, each green), then remove the old form. TDD applies to the expand step; batches are verified by the existing suite.
- **UI:** test behavior at the component or page seam (rendered output and user events), not styling. Visual acceptance uses screenshots in the report.
- **Prototype mode** may relax to "tests at seams, after the code" if the user chose that at G1; the reviewer then skips the commit-order audit but still rejects the anti-patterns.

## 9. Commands

HANDOFF.md (ARCH, "Commands") records the exact commands, set by the scaffold ticket: run one test file, run the full suite, type-check, lint, end-to-end. Coders use those commands, not guesses. There is no coverage target: agreed seams on the critical paths matter more than a percentage.
