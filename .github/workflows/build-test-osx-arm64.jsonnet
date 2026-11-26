// This workflow builds and tests the lens-core binary for macOS arm64

local actions = import 'libs/actions.libsonnet';
local gha = import 'libs/gha.libsonnet';
local lens = import 'libs/lens.libsonnet';

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------
local runs_on = 'macos-15-xlarge';

// ----------------------------------------------------------------------------
// The jobs
// ----------------------------------------------------------------------------

local artifact_name = 'lens-osx-arm64-${{ github.sha }}';

local build_core_job = {
  'runs-on': runs_on,
  steps: actions.checkout_with_submodules() +
         // Workaround for brew lock conflict on openssl@3 during opam depext installs.
         // https://linear.app/lens/issue/CODE-10023
         [lens.brew_unlink_openssl_step] +
         lens.build_test_steps() +
         [
           actions.upload_artifact_step(artifact_name, './bin/lens-core'),
         ],
};

// ----------------------------------------------------------------------------
// The Workflow
// ----------------------------------------------------------------------------

{
  name: 'build-test-osx-arm64',
  on: gha.on_dispatch_or_call,
  jobs: {
    'build-core': build_core_job,
  },
}
