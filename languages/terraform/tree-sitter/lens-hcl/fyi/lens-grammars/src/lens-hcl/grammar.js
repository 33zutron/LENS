/*
  lens-hcl

  Extends the standard hcl grammar with lens pattern constructs.
*/

const base_grammar = require('tree-sitter-hcl/grammar');

module.exports = grammar(base_grammar, {
  name: 'hcl',

  // Keep template repetitions inline when the standalone parser normalizes
  // hidden rules. The scanner recognizes a directive start only in states
  // where a literal chunk is also valid, including at the end of a body.
  inline: ($, previous) => previous.concat([$._template]),

  conflicts: ($, previous) => previous.concat([
     // when added ellipsis for object_elems
     // Unresolved conflict for symbol sequence:
     // object_start  lens_ellipsis  •  '['  …
     // Possible interpretations:
     //  1:  object_start  (_expr_term  lens_ellipsis)  •  '['  …
     //  2:  object_start  (object_elem  lens_ellipsis)  •  '['  …
     [$._expr_term, $.object_elem],
  ]),

  /*
     Support for lens ellipsis ('...') and metavariables ('$FOO'),
     if they're not already part of the base grammar.
  */
  rules: {
    // Entry point
    config_file: ($, previous) => {
      return choice(
        previous,
        $.lens_expression
      );
    },

    // Alternate "entry point". Allows parsing a standalone expression.
    lens_expression: $ => seq('__LENS_EXPRESSION', $.expression),


    // Metavariables
    identifier: ($, previous) => {
      return choice(
        previous,
        $._lens_metavariable
      );
    },

    _lens_metavariable: $ => token(/\$[A-Z_][A-Z_0-9]*/),


    // Ellipsis
    body: ($, previous) => repeat1(
      choice(
        $.attribute,
        $.block,
        $.lens_ellipsis,
      ),
     ),

    object_elem: ($, previous) => {
      return choice(
        previous,
        $.lens_ellipsis
      );
    },

    _expr_term: ($, previous) => {
      return choice(
        previous,
        $.lens_ellipsis,
        $.deep_ellipsis
      );
    },

    lens_ellipsis: $ => '...',

    deep_ellipsis: $ => seq(
      '<...', $.expression, '...>'
    ),

  }
});
