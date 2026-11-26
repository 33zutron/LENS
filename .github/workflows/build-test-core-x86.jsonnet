// This workflow builds and test lens-core. It also generates an artifact
// which is used in many other workflows such as tests.jsonnet or

local actions = import 'libs/actions.libsonnet';
local gha = import 'libs/gha.libsonnet';
local lens = import 'libs/lens.libsonnet';

// exported for other workflows
local artifact_name = 'lens-core-x86-artifact';

// This container has opam already installed, as well as an opam switch
// already created, and a big set of packages already installed. Thus,
// the 'make install-deps-for-lens-core' below is very fast and
// almost a noop.
// TODO: switch to setup-ocaml@v2 + GHA cache
local container = lens.containers.ocaml_alpine;

// ----------------------------------------------------------------------------
// The job
// ----------------------------------------------------------------------------
local job =
  container.job(
    actions.checkout_with_submodules() +
    lens.build_test_steps() +
    [
      actions.upload_artifact_step(artifact_name, 'bin/lens-core'),
    ]
  );

// ----------------------------------------------------------------------------
// The Workflow
// ----------------------------------------------------------------------------
{
  name: 'build-test-core-x86',
  // This is called from tests.jsonnet and release.jsonnet
  // TODO: just make this job a func so no need to use GHA inherit/call
  on: gha.on_dispatch_or_call,
  jobs: {
    job: job,
  },
  // to be reused by other workflows
  export:: {
    artifact_name: artifact_name,
  },
}
