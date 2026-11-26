// Daily cron to check end-to-end (e2e) that the 'lens ci' subcommand,
// run from a lens/lens-nightly:develop docker image, works correctly.
// This is very important because 'lens ci' and our docker images
// are the main things the users of our Lens WebApp are using in their CIs.
// This cron also double checks that "fail-open" is working as expected, that is
// we aren't failing the CI check when we can't upload findings because of
// networking errors (or for other reasons such as a 'git' execution failure).

local actions = import 'libs/actions.libsonnet';
local lens = import 'libs/lens.libsonnet';
local uses = import 'libs/uses.libsonnet';

// ----------------------------------------------------------------------------
// Constants
// ----------------------------------------------------------------------------

// This is computed by the get_inputs_job (example of value: "develop")
// and can be referenced from other jobs.
local docker_tag = '${{ needs.get-inputs.outputs.docker_tag }}';

// This is computed by lens_ci_on_pr_job (example of value: "9543")
// and can be referenced from other jobs
local pr_number = '${{ needs.lens-ci-on-pr.outputs.pr-number }}';

// ----------------------------------------------------------------------------
// Input
// ----------------------------------------------------------------------------
local docker_tag_input = {
  inputs: {
    docker_tag: {
      description: 'Docker Tag to Run. Default: develop (must be in the `lens/lens-nightly` namespace)',
      required: false,
      //TODO? could propose choice with 'canary' also
      default: 'develop',
    },
  },
};

// This validates and reexport the input in docker_tag_input above.
// Why this intermediate job? Can't we use directly inputs.docker_tag
// in the other jobs? It's because this workflow can be called
// interactively (workflow_dispatch), or via a cron, and for a cron
// we don't have a way to say docker_tag should be 'develop', hence
// this intermediate job.
local get_inputs_job = {
  name: 'Get Inputs',
  'runs-on': 'ubuntu-22.04',
  outputs: {
    docker_tag: '${{ steps.get-inputs.outputs.docker_tag }}',
  },
  steps: [
    {
      name: 'Set variables',
      id: 'get-inputs',
      //TODO? why do we need that given we set a default value above?
      env: {
        DOCKER_TAG: 'develop',
        INPUT_DOCKER_TAG: '${{ inputs.docker_tag }}',
      },
      run: 'echo "docker_tag=${{ env.INPUT_DOCKER_TAG || env.DOCKER_TAG }}" >> $GITHUB_OUTPUT',
    },
    {
      name: 'Debug',
      env: {
        DOCKER_TAG: '${{ steps.get-inputs.outputs.docker_tag }}',
      },
      run: 'echo "$DOCKER_TAG"',
    },
  ],
};

// ----------------------------------------------------------------------------
// Basic lens CI checks (on the lens repo itself)
// ----------------------------------------------------------------------------
local lens_ci_job = {
  'runs-on': 'ubuntu-22.04',
  env: {
    // TODO: why not lens.secrets.LENS_APP_TOKEN? Why a different token?
    // We use a different ruleboard for that?
    LENS_APP_TOKEN: lens.secrets.E2E_APP_TOKEN,
  },
  needs: 'get-inputs',
  container: {
    image: 'lens/lens-nightly:' + docker_tag,
  },
  steps:
    actions.checkout() +
    [
      // dogfooding! we run lens ci on the lens repo itself
      // and it should not find any blocking findings and so
      // should exit with code 0
      {
        run: 'lens ci',
      },
    ],
};

local lens_ci_fail_open_job = {
  'runs-on': 'ubuntu-22.04',
  env: {
    LENS_APP_TOKEN: lens.secrets.E2E_APP_TOKEN,
    // TODO? Why those settings?
    LENS_APP_URL: 'https://staging.lens.dev',
    LENS_USER_AGENT_APPEND: 'lens-ci-e2e',
  },
  needs: 'get-inputs',
  container: {
    image: 'lens/lens-nightly:' + docker_tag,
  },
  steps:
    actions.checkout() +
    [
      // we remove git to test whether its absence cause the whole thing
      // to return an error. Note that 'lens ci' relies internally
      // on git to compute the project_metadata information so the absence
      // of git should generate some errors internally.
      // However, in fail-open mode (--suppress-errors) we
      // should not fail the CI check if something internally failed.
      {
        name: 'Remove Git Exe',
        run: |||
          which git
          rm /usr/bin/git
        |||,
      },
      {
        // should still exit with code 0 (ugly, but the backend
        // is sometimes unaivalable for a few minutes and we don't
        // want all our customers to suddenly fail their CI check)
        run: 'lens ci --suppress-errors',
      },
    ],
};

local lens_ci_fail_open_blocking_findings_job = {
  'runs-on': 'ubuntu-22.04',
  env: {
    LENS_APP_TOKEN: lens.secrets.E2E_APP_TOKEN,
    LENS_USER_AGENT_APPEND: 'lens-ci-e2e',
  },
  needs: 'get-inputs',
  container: {
    image: 'lens/lens-nightly:' + docker_tag,
  },
  steps:
    actions.checkout() +
    [
      {
        name: 'Create code under test',
        id: 'create-code',
        // we should report a (blocking) finding here
        // (see use-click-secho.yml in lens-rules)
        run: |||
          cat > ./test.py <<- EOF
          import click
          click.echo(click.style("foo"))
          EOF
        |||,
      },
      {
        name: 'Run CI',
        id: 'run-ci',
        // Here we fail-open (with --suppress-errors), but that does not mean
        // we should go through if lens finds blocking findings!
        // We "fail-open" only on unexpected internal errors (e.g., networking
        // issues). This is not the case here, so lens should return
        // an exit code > 0.
        //
        // If we get exit code 0, meaning lens didn't find
        // any blocking finding, then we take the 'then' branch
        // (remember that in bash exit code '0' means everything is fine
        // so exit 2 below is taken only 'if 0')
        // and we return an error (exit 2).
        // Otherwise, lens found an error (exit code > 0), meaning
        // we take the else branch, and exit 0 as this test is passing.
        //
        // Other tests ensure that error code >=2 are handled appropriately.
        run: |||
          if lens ci --suppress-errors; then
             exit 2
          else
             exit 0
          fi
        |||,
      },
    ],
};

// ----------------------------------------------------------------------------
// PR check on another repo
// ----------------------------------------------------------------------------

// The two jobs below work together and with the lens/e2e repo
// to check that 'lens ci' reports only new findings on PRs.
// This 'e2e' repo contains:
//  - a file-under-test.py with a '10 == 10' that
//    should be reported by lens (by the '$X == $X' lens rule)
//  - a .github/workflows/lens-ci-e2e.yml that runs 'lens ci'
//    with the docker image specified in lens-docker-image-tag.txt
//  - a scripts/change-version.sh that updates lens-docker-image-tag.txt
//    and modifies a file that is not file-under-test.py
//
// Because lens ci reports only new findings, the goal of the jobs below is to
// make sure no finding are reported since we don't modify file-under-test.py

// just open a PR on the lens/e2e repo
local lens_ci_on_pr_job = {
  'runs-on': 'ubuntu-22.04',
  needs: 'get-inputs',
  outputs: {
    'pr-number': '${{ steps.cpr.outputs.pull-request-number }}',
  },
  steps: [lens.github_bot.get_token_step(['e2e'])] + [
    {
      uses: uses.actions.checkout,
      with: {
        repository: 'lens/e2e',
        ref: '${{ github.event.repository.default_branch }}',
        token: lens.github_bot.token_ref,
      },
    },
    {
      name: 'Bump version',
      env: {
        DOCKER_TAG: docker_tag,
      },
      run: 'scripts/change-version.sh "$DOCKER_TAG"',
    },
    {
      id: 'cpr',
      // sign-commits: commits are signed via the GitHub API
      uses: uses.peter_evans.create_pull_request,
      with: {
        token: lens.github_bot.token_ref,
        branch: 'e2e-test-pr-${{ github.run_id }}',
        'commit-message': 'chore: Bump version to ' + docker_tag,
        title: 'chore: fake PR for ' + docker_tag,
        body: 'Fake PR',
        base: 'develop',
        'sign-commits': true,
      },
    },
  ],
};


// TODO: factorize with start-release.jsonnet
local len_checks = "$(gh pr -R lens/e2e view %s --json statusCheckRollup --jq '.statusCheckRollup | length')" % pr_number;

// TODO: factorize with start-release.jsonnet
local wait_for_checks_job = {
  'runs-on': 'ubuntu-22.04',
  needs: 'lens-ci-on-pr',
  steps: [lens.github_bot.get_token_step(['e2e'])] + [
    {
      name: 'Wait for checks to register',
      env: {
        GITHUB_TOKEN: lens.github_bot.token_ref,
      },
      run: |||
        LEN_CHECKS=%s;
        while [ ${LEN_CHECKS} = "0" ]; do
          echo "No checks available yet"
          sleep 30
          LEN_CHECKS=%s;
        done
        echo "checks are valid"
        echo ${LEN_CHECKS}
        gh pr -R lens/e2e view %s --json statusCheckRollup
      ||| % [len_checks, len_checks, pr_number],
    },
    {
      name: 'Wait for checks to complete',
      env: {
        GITHUB_TOKEN: lens.github_bot.token_ref,
      },
      run: 'gh pr -R lens/e2e checks %s --interval 30 --watch' % pr_number,
    },
  ],
};

// ----------------------------------------------------------------------------
// The Workflow
// ----------------------------------------------------------------------------
{
  name: 'test-e2e-lens-ci',
  on: {
    workflow_dispatch: docker_tag_input,
    schedule: [
      {
        // At 20:43 every day
        cron: '43 20 * * *',
      },
    ],
  },
  jobs: {
    'get-inputs': get_inputs_job,
    'lens-ci': lens_ci_job,
    'lens-ci-fail-open': lens_ci_fail_open_job,
    'lens-ci-fail-open-blocking-findings': lens_ci_fail_open_blocking_findings_job,
    // the two jobs below work together
    'lens-ci-on-pr': lens_ci_on_pr_job,
    'wait-for-checks': wait_for_checks_job,
    'notify-failure':
      lens.slack.notify_failure_job
      ('The End to end lens ci workflow failed with docker tag "$DOCKER_TAG". The PR in `lens/e2e` that had the failure was "$PR_NUMBER". See https://github.com/lens/lens/actions/workflows/test-e2e-lens-ci.yml for more info', env={ DOCKER_TAG: docker_tag, PR_NUMBER: pr_number })
      + { needs: [
        'lens-ci',
        'lens-ci-on-pr',
        'lens-ci-fail-open',
        'lens-ci-fail-open-blocking-findings',
        'wait-for-checks',
        'get-inputs',
      ] },
  },
}
