# CI commands

Read-only commands to list runs and get logs. Use the CLI that is installed and logged in. If none
is, tell the user which CLI to install or log in to. Do not ask for a token in the chat.

Facts that are true for all systems:

- A run result of "passed" is the pass outcome for a test only if the runner fails the build on a
  test failure. Make sure of that in the CI definition (`continue-on-error`, `allow_failure`,
  `continueOnError`).
- Logs have a timestamp prefix on each line, and some have CRLF line ends. Remove the two before
  you compare lines.
- Get counts from the summary line of the runner, for example Playwright `6 passed`, `1 flaky`,
  Jest `Tests: 1 failed, 41 passed`, Gradle `334 tests completed, 1 failed`. Some runners print no
  counts, for example `pytest -q`.
- A pull request run frequently builds a merge commit that is in no branch. If `git fetch <sha>`
  fails, do not try to get that commit. Find the failure from the file, test name and line in the
  error, and read the code on the default branch.

## GitHub Actions (`gh`)

```bash
# Runs in the window. `attempt` > 1 means that someone re-ran the run at the same commit.
gh run list --workflow <file.yml> --created ">=<YYYY-MM-DD>" --limit 500 \
  --json databaseId,conclusion,headSha,headBranch,event,attempt,createdAt,updatedAt

# Jobs and steps of a run, with their results
gh run view <run-id> --json jobs

# Log of the failed steps only. Start here.
gh run view <run-id> --log-failed

# An earlier attempt of the same run. A failed attempt 1 and a passed attempt 2 is a same-commit pair.
gh run view <run-id> --attempt 1 --log-failed

# Artifacts: test reports, traces, screenshots
gh run download <run-id> --dir <tmp dir>

# Full log of a run. Use this for runs that passed when retries are on.
# Each line is "<job>\t<step>\t<timestamp> <text>". Remove the prefix when you save the log.
gh run view <run-id> --log | perl -pe 's/^[^\t]*\t[^\t]*\t\S+Z //; s/\r$//' > <tmp dir>/<run-id>.log
```

- `conclusion` is `success`, `failure`, `cancelled`, `timed_out`, `skipped` or `action_required`.
  `cancelled` and `timed_out` are usually infrastructure or a superseded push, not a test result.
  `action_required` is a pull request from a fork that waits for approval. No test ran.
- `--branch main` also gives pull requests from forks whose branch is named `main`. To get the
  runs of the default branch only, filter for `event == "push"`.
- Use `-R <owner>/<repo>` when the current directory is not the repository.
- BSD `sed` on macOS does not know `\t`. Use `perl` or `awk` to remove the log prefix.


## GitLab CI (`glab`)

```bash
# Pipelines in the window
glab api --paginate "projects/:id/pipelines?updated_after=<YYYY-MM-DD>T00:00:00Z&per_page=100"

# Jobs of a pipeline. A retried job is a same-commit pair.
glab api "projects/:id/pipelines/<pipeline-id>/jobs?include_retried=true&per_page=100"

# Log of a job
glab api "projects/:id/jobs/<job-id>/trace"

# Artifacts of a job (zip)
glab api "projects/:id/jobs/<job-id>/artifacts" > <tmp dir>/artifacts.zip
```

`glab` replaces `:id` with the project of the current repository. If the project uploads JUnit
reports, `projects/:id/pipelines/<pipeline-id>/test_report` gives the result of each test without
a log download.

## Azure DevOps (`az` with the `azure-devops` extension)

```bash
# Pipelines and their ids
az pipelines list --query "[].{id:id,name:name}" -o table

# Runs of a pipeline, newest first. Filter by date yourself.
az pipelines runs list --pipeline-ids <id> --top 500 --query-order FinishTimeDesc \
  --query "[].{id:id,result:result,sha:sourceVersion,branch:sourceBranch,start:startTime,finish:finishTime}"

# Tasks of a run, with the log id of each task
az devops invoke --area build --resource timeline \
  --route-parameters project=<project> buildId=<run-id> --api-version 7.1 \
  --query "records[?type=='Task'].{name:name,result:result,logId:log.id}"

# Log of one task
az devops invoke --area build --resource logs \
  --route-parameters project=<project> buildId=<run-id> logId=<log-id> --api-version 7.1 \
  --out-file <tmp dir>/<run-id>.log
```

- The log id of the same task changes between runs. Read the timeline of each run.
- `partiallySucceeded` usually comes from a step that is not a test step, for example an image
  scan with warnings. Make sure with the timeline before you count the run as a test failure.
- Some tokens cannot read the Test Management API (`/_apis/test/...`, error 401). Then get the
  test outcomes from the log of the test task.

## Other CI systems

Use the CLI or API of the system if one is available and logged in (CircleCI, Buildkite, Jenkins).
You need the same three things: the list of runs with commit and result, the log of the test step
for each failed run, and the artifacts. If you cannot get CI data, tell the user, and continue
with local evidence only: run the suspect test again and again at the current commit.
