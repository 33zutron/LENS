/*
  lens-sqlite

  Extends the standard sqlite grammar with lens pattern constructs.
*/

const base_grammar = require('tree-sitter-sqlite/grammar');

module.exports = grammar(base_grammar, {
  name: 'sqlite',

  conflicts: ($, previous) => previous.concat([
  ]),

  /*
     Support for lens ellipsis ('...') and metavariables ('$FOO'),
     if they're not already part of the base grammar.
  */
  rules: {
  /*
    lens_ellipsis: $ => '...',

    _expression: ($, previous) => {
      return choice(
        $.lens_ellipsis,
        ...previous.members
      );
    }
  */
  }
});
