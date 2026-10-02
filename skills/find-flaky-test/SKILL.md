---
name: find-flaky-test
description: Finds one flaky test from CI history, proves that it is flaky, finds the root cause and fixes it in the code. Use this skill when the user talks about flaky, intermittent or unstable tests, tests that pass on a re-run, red CI runs with no code change, or tests that fail "sometimes", also when the user does not say the word "flaky". Works for unit, integration and end-to-end tests (for example Playwright, Cypress, Jest, pytest, JUnit) with GitHub Actions, GitLab CI and Azure DevOps.
license: MIT
metadata:
  author: Heplon
  homepage: https://heplon.com
---

# Find and fix one flaky test

One run of this skill gives one flaky test with proof, a root cause and a fix in the working tree.
One test for each run is deliberate. A fix for the root cause of one flake is worth more than a list
of ten suspects, and the same mechanism is frequently behind many of the other failures.

## What "flaky" means

A test is flaky only if its outcome changes when nothing that can change the outcome has changed.
Hold to this definition. Most red CI runs are not flakes, and a "fix" for a test that fails for a
correct reason hides a bug.

Evidence, strongest first:

1. The same run has different outcomes across retry attempts of the test.
2. The same commit fails in one run or run attempt and passes in a different one.
3. The test fails on one branch and passes on a different branch, and the related code is identical.
4. The test fails in CI, but the suite passes locally at the exact commit of the failed run, and no
   difference in network, clock, locale or test order explains it.

Not flaky. Record these and continue with the next candidate:

- A failure that is the same each time at a commit. A frequent cause is that a test and the code it
  tests arrive in different commits.
- A pull request that fails again and again while the author pushes fixes.
- Infrastructure failures: lost runner, job timeout, registry or network outage, missing secret.
  The tests did not decide the result.
- A run that fails in a step that is not a test step, for example lint, build or image scan.
- A flake that the default branch does not have today. A later commit removed it. Record it as
  `fixed` and do not spend more time on it.

## Limits

- Stop after approximately 60 tool calls, or after 3 failed commits that are all deterministic.
  Then report what you have. "No flaky test found in this window" is a correct result.
- Read CI data and code. Do not trigger, re-run or cancel CI runs, and do not push, unless the user
  asks for it. Re-runs cost the user money and change the history that you examine.
- Send nothing out of the repository: no logs, code or secrets to external services.
- Put downloaded logs, artifacts and `git worktree` checkouts in a temporary directory outside the
  repository (`mktemp -d`). Remove the worktrees when you are done.

## Procedure

Do the steps in this sequence. Each step can end the search early, which saves the cost of the
steps after it.

**0. Read the ledger.** If `.flaky-tests/findings.md` exists, read it. Each test in it is settled.
Skip those tests and tell the user in one line which ones you skipped. Examine a test again only if
your new evidence contradicts its row.

**1. Find the scope.** Identify the CI system from the repository (`.github/workflows/`,
`.gitlab-ci.yml`, `azure-pipelines.yml`), the workflow or pipeline that runs the tests, the
test runner and its config file. Read the CI definition. If no job runs tests, a flaky test is not
possible there. Say so and stop. If more than one workflow runs tests and the user did not name
one, take the one with the most failed runs in the window. The window is the last 30 days unless the user gives a different one.

**2. List the runs in the window.** One call. `references/ci-providers.md` has the commands for
each CI system. Read it now.

**3. Use the runner's own flake report if there is one.** Read the runner config. If retries are
on, the runner already reports tests that failed and then passed, and that is class 1 evidence:
Playwright prints `N flaky` in the summary, Cypress shows the attempts for each test, pytest needs
a rerun plugin, Gradle and Maven need a retry plugin. If the logs have such a report, it is the
candidate list. Take the most frequent candidate and go to step 6. Do not run the suite locally to
prove what the runner already proved.

**4. If not, collect the failures.** Get the log of the test step for each failed run. One pass,
and save the logs in the temporary directory so that you do not download them again. Extract the
names of the failed tests and the first error line of each. Do not download the logs of runs that
passed. They can be very large, and the run result already tells you the outcome.

**5. Group the failures by commit.** A test with different outcomes at the same commit is the
primary suspect. Remember run attempts: a run that failed and passed after a re-run with no new
commit is a same-commit pair. If there is no such pair, try the suite locally at a failed commit,
in a `git worktree` in the temporary directory. First make sure that the suite can run locally at
all. Use a maximum of 5 calls for that. If it cannot run, write that down as a limit and continue
with the CI evidence only.

- CI fails and local fails the same way: deterministic. Discard.
- CI fails and local passes: a CI flake. Continue.

**6. Compare the suspect with the default branch.** Do this before you spend calls on the root
cause. Run `git fetch`, then read the test file on the default branch and
`git log <default branch> -- <test file>` for commits after the failed run. If the test is gone, or
a later commit removed the failure, the suspect is `fixed`. Take the next candidate.

**7. Find the root cause.** Read the test, the code it exercises and the failure output (error,
trace, screenshot, video if the run kept them). `references/root-causes.md` lists the mechanisms
that cause most flakes and how to confirm each one. Read it now.

For each possible cause, ask if it is the cause or an effect of something else. Prove it with
evidence, not with plausibility. Examples of evidence: the retry count, the timing in the trace, a
random value that is visible in the log, identical or different file hashes. If the suite runs
locally, try to reproduce the failure, for example with
`npx playwright test <file> -g "<name>" --repeat-each 20`. Think about what CI has and the local
machine does not: parallel workers, slow CPU, cold caches, a different timezone or locale, a
different test order, shared accounts or databases.

When you have the mechanism, make sure that it is still in the code on the default branch.

**8. Fix it.** Change the code in the working tree. Fix the mechanism, in the test or in the
product code, where the defect is. Some flaky tests show a product bug that users can also hit, for
example a button that is clickable before its handler is attached. Fix that in the product.

These are not fixes, because they hide the flake and keep the cause:

- More retries.
- A longer timeout, unless the evidence shows that the operation is correct and only slow.
- A fixed sleep.
- `skip`, `fixme`, quarantine, or deletion of the test or the assertion.

If only one of these is possible in the time you have, do not apply it. Describe the option to the
user and let the user decide.

Search the repository for the same pattern in other tests. Report the places. Fix them only if the
change is identical and small.

**9. Verify.** Run the fixed test again and again if the suite runs locally (20 times is a good
number for a slow test, 100 for a fast one). Run the related tests one time to make sure that they still pass. If you
cannot run the suite, say plainly that the fix is not verified. Do not commit or push unless the
user asks.

## Report

Give the report in your answer to the user. Write the finding, not the story of how you found it.
A reader must be able to decide in one minute if the fix is correct. Use this structure:

```markdown
# <Short title that names the mechanism>

**Test:** `<file>::<test name>`
**Evidence:** <class 1 to 4>. <Run ids, commit SHAs and dates of the different outcomes.>
**Failure rate:** <failures> of <runs that executed the test> in <window>.

## Cause
<The mechanism in two or three sentences, with the evidence that proves it.>

## Fix
<What you changed and in which files. A diff if it is short.>
<Verified: "passed 20 of 20 local runs", or "not verified because ...".>

## Impact
<CI minutes lost each month = failed runs x run duration (x shard count).>
<Human cost, for example re-runs and delayed merges. Say which numbers are measured and which are
estimates.>

## Same pattern in other places
<Files, or "none found".>
```

Add one line for each limit that changes how much the user can trust the result, for example that
local runs were not possible.

## Ledger

Then add rows to `.flaky-tests/findings.md`. Create the file with this header if it does not
exist. The next run reads the ledger and does not examine the same tests again.

```markdown
# Flaky test findings

| date | workflow | test or run | status | note |
|---|---|---|---|---|
```

Add one row for the finding and one row for each test or run that you ruled out. Do not change
rows that are there. `status` is one of `flaky` (the finding of a run), `deterministic`, `infra`,
`ruled-out`, `fixed` (the default branch does not have the flake now). Tell the user that the file
exists, so that they can commit it or ignore it.
