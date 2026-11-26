/*
  lens-make

  Extends the standard make grammar with lens pattern constructs.
*/

const base_grammar = require('tree-sitter-make/grammar');

module.exports = grammar(base_grammar, {
  name: 'make',

  conflicts: ($, previous) => previous.concat([
  ]),

  /*
     Support for lens ellipsis ('...') and metavariables ('$FOO'),
     if they're not already part of the base grammar.
  */
  rules: {
  /*
    lens_ellipsis: $ => '...',

    _expression: ($, previous) => choice(
      $.lens_ellipsis,
      ...previous.members
    ),
  */
  }
});
