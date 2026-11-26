/*
  lens-tsx

  Extends the standard tsx grammar with lens pattern constructs.
*/

const tsx_grammar =
      require('tree-sitter-typescript/tsx/grammar');

const lensExt = require('../common/lens-ext');

module.exports = grammar(tsx_grammar, {
  name: 'tsx',
  ...lensExt,
});
