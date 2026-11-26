/*
  lens-jsonnet

  Extends the standard jsonnet grammar with lens pattern constructs.
*/

const base_grammar = require('tree-sitter-jsonnet/grammar');

module.exports = grammar(base_grammar, {
  name: 'jsonnet',

  conflicts: ($, previous) => previous.concat([
  ]),

  /*
     Support for lens ellipsis ('...') and metavariables ('$FOO'),
  */
  rules: {
    // No need for _LENS_EXPRESSION hack here, because jsonnet allows
    // toplevel expressions.
      
    // Metavariables
    id: ($, previous) => {
      return choice(
        previous,
        $._lens_metavariable
      );
    },

    _lens_metavariable: $ => token(/\$[A-Z_][A-Z_0-9]*/),

    // Ellipsis
    expr: ($, previous) => choice(
      $.lens_ellipsis,
      $.deep_ellipsis,
      previous
    ),
    field: ($, previous) => choice(
      $.lens_ellipsis,
      previous
    ),
    param: ($, previous) => choice(
      $.lens_ellipsis,
      previous
    ),

    // The actual ellipsis rules
    lens_ellipsis: $ => '...',
      
    deep_ellipsis: $ => seq(
            '<...', $.expr, '...>'
    ),
  }
});
