# Root causes of flaky tests

The mechanisms behind most flakes, how to confirm each one, and the fix. Confirm before you fix.
Two mechanisms can give the same error message.

## Contents

- Timing in the browser (E2E)
- Random test data
- Shared state
- Time, locale and environment
- Visual comparison
- Async code in the test

## Timing in the browser (E2E)

**One-time check in place of a wait.** `isVisible()`, `count()`, `textContent()` and
`$(...)` read the page one time and do not wait. A condition such as
`if (await button.isVisible())` takes a different branch when the page is slow.
Confirm: the trace shows the element appear after the check. Fix: use an assertion that retries,
for example `await expect(locator).toBeVisible()`, or act on the locator directly, because
Playwright and Cypress actions wait for the element.

**Forced action.** `click({ force: true })` skips the checks that the element is visible, stable
and able to receive events. The click then lands before the handler is attached or on an overlay.
Confirm: the click is in the trace, but nothing follows it. Fix: remove `force`, and wait for the
thing that the user also waits for (the overlay is gone, the button is enabled).

**Fixed sleep.** `waitForTimeout(2000)`, `cy.wait(2000)` and `Thread.sleep` pass on a fast machine
and fail on a slow CI runner. Confirm: the failure follows a sleep, and CI timings are longer than
the sleep. Fix: wait for the condition, for example a response, an element or a URL.

**Action before the listener.** The test clicks first and then starts to wait for the response or
the navigation, so a fast response is missed. Confirm: the response is in the network log before
the wait starts. Fix: start the wait first, for example
`const response = page.waitForResponse(...); await button.click(); await response;`. In Cypress,
set `cy.intercept(...).as(...)` before the action.

**Click before hydration.** The server-rendered element is visible, but the framework has not
attached the handlers. Confirm: the click has no effect on the first attempt and works on a retry.
Fix: wait for a signal that the application is ready, or make the element disabled until it is.
This is frequently a product defect.

**Animation or layout shift.** The element moves while the test clicks, or a toast or cookie
banner covers it. Confirm: screenshots at the failure show the overlay or a half-finished
transition. Fix: wait for the transition to end, or disable animations in the test config.

**Unstable selector.** `nth()`, text that is on the page more than once, or an order that depends
on the load sequence. Confirm: the failure output shows a different element than the one you
expect. Fix: select by role, label or test id.

## Random test data

**Collision of random values.** A faker or random generator gives the same value twice, and the
test assumes that the values are different (for example `distinct()`, a unique constraint, or
"change the name to a new random name" that draws the old name). The failure rate is low and has
no pattern across commits. Confirm: the log shows the duplicate value. Fix: make the values
different by construction, for example with an index or a fixed suffix.

**Random value on a rare path.** Random input sometimes hits zero, null, an empty list or a
boundary, and the code or the assertion cannot handle it. Confirm: the failure message contains
the unusual value. Fix: set the values that the test depends on. If the product code fails on
valid input, fix the product code too.

## Shared state

**Test order.** A test depends on data that a different test made or did not remove. It fails when
the order or the shard assignment changes. Confirm: the test passes alone and fails after a
specific other test, or the reverse. Fix: each test makes its own data and removes it.

**Parallel workers share a resource.** The same user account, database row, port, file or queue.
Confirm: failures occur only when workers > 1, and the error shows a conflict (duplicate key,
"already exists", wrong session). Fix: a separate resource for each worker, for example with the
worker index in the name.

**Unfinished work of the test before.** An open request, timer or background job of one test
changes the state of the next test. Confirm: the failure has output that belongs to a different
test. Fix: wait for the work to finish, or cancel it in the teardown.

## Time, locale and environment

**Clock and timezone.** Tests near midnight, at the end of a month, on a clock change, or with a
CI runner in UTC and a developer machine in a different timezone. Confirm: the failures collect
at specific times of the day or dates. Fix: set the clock and the timezone in the test.

**Real external service.** The test calls a third-party API, a CDN or a shared staging system.
Confirm: the error is a network error or a 5xx from a host that the repository does not own.
Fix: mock that boundary in this test. If the test is there to test the integration, this is an
infrastructure problem, not a flaky test.

**Slow start of the test stack.** The tests start before the application or a dependency is
ready. Confirm: the first tests of the run fail with connection errors and the later ones pass.
Fix: a health check that waits for readiness before the tests start.

## Visual comparison

Screenshot tests fail on font rendering, anti-aliasing, a blinking cursor, animations, or data
that changes (dates, random values). Confirm: compare the hashes of the baseline in the
repository, the baseline that the run used and the actual image. See if the difference is the same
on each attempt. A difference that is the same each time is deterministic: the baseline is out of
date. A difference that changes is a flake. Fix: make the content stable (fixed data, fixed clock,
no animations, mask the areas that change). Do not raise the difference threshold as the first
answer.

## Async code in the test

A promise without `await`, an assertion in a callback that runs after the test ends, or a missing
`return` of a Cypress or promise chain. Confirm: the failure is reported in the wrong test, or the
test passes although the assertion did not run. Fix: await or return the promise. A linter rule
such as `no-floating-promises` finds the other places.

**Setup that does not wait.** A seed or setup helper returns before its work is done, so the test
reads data that is not there yet. The missing data is different each time, and a retry usually
passes. Causes are a `forEach` with an async callback, a `Promise.all` over values that are not
promises, or a builder that needs a last call to give its result (for example a ts-pattern
`match(...)` with no `.exhaustive()` or `.otherwise()`). A lint suppression for `require-await` or
`no-floating-promises` near the helper is a hint. Confirm: only the tests that use the helper are
flaky, and a small script shows that the helper resolves before the work is done. Fix: return and
await the promises in the helper.
