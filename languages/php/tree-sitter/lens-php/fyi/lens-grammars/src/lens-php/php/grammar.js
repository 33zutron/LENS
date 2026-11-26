/*
  lens-php

  Extends the standard php grammar with lens pattern constructs.
*/

const php_grammar = require('tree-sitter-php/php/grammar');

const lensExt = require('../common/lens-ext');

module.exports = grammar(php_grammar, {
  name: 'php',
  ...lensExt,
});
