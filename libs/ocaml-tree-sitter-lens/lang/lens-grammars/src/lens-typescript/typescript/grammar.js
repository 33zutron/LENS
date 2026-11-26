/*
  lens-typescript

  Extends the standard typescript grammar with lens pattern constructs.
*/

const typescript_grammar =
      require('tree-sitter-typescript/typescript/grammar');

const lensExt = require('../common/lens-ext');

module.exports = grammar(typescript_grammar, {
  name: 'typescript',
  ...lensExt,
});
