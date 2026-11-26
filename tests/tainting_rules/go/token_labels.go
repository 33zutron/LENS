// See https://github.com/returntocorp/lens/issues/6355 if this breaks.
// We shouldn't produce a finding because the label should prevent the match. 

func foo() {
	x := 1 + a.b + 3
	// ok: go-token-labels 
	sink(x)
}