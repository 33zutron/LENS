// https://github.com/returntocorp/lens/issues/4301

// ERROR:
var a = require('b')

// OK:
var a = require(c)

// ERROR:
var a = require(c ? 'a': 'b') 
