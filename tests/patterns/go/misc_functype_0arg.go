package foo

// this used to crash lens with --json with a NoTokenLocation
// exn because the  func() function type didn't have any token.
//ERROR: match
func asd(a func()) {
	a()
}
