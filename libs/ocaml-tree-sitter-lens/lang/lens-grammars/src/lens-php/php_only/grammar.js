/*
  lens-php_only

  Extends the standard php_only grammar with lens pattern constructs.
*/

const php_only_grammar = require('tree-sitter-php/php_only/grammar');

const lensExt = require('../common/lens-ext');

module.exports = grammar(php_only_grammar, {
  name: 'php_only',
  ...lensExt,
});
