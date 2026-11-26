// https://github.com/returntocorp/lens/issues/5040

function test1(input) {
    const param = input.body.param

    //ruleid: test
    sink(param)
  }

  function test2(input) {
    const { param }  = input.body

    //ruleid: test
    sink(param)
  }
