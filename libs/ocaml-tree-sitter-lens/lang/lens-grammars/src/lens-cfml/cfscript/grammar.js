/*
  lens-cfscript

  Extends the standard cfscript grammar with lens pattern constructs.

  Metavariables ($FOO) work out of the box because $ is a valid identifier
  character in cfscript.
*/

const base_grammar = require('tree-sitter-cfml/cfscript/grammar');

module.exports = grammar(base_grammar, {
  name: 'cfscript',

  conflicts: ($, previous) => previous.concat([
    [$.expression, $.expression_statement],
    [$.lens_expression_ellipsis, $.spread_element],
    [$.lens_expression_ellipsis, $.rest_pattern],
    [$.lens_expression_ellipsis, $.spread_element, $.rest_pattern],
    [$.lens_expression_ellipsis, $.lens_ellipsis],
    [$.spread_element, $.rest_pattern, $.lens_ellipsis],
    [$.spread_element, $.rest_pattern, $.lens_ellipsis, $.lens_expression_ellipsis],
  ]),

  rules: {
    // Allow a standalone expression as a valid program (pattern).
    program: ($, previous) => choice(
      previous,
      $.lens_expression,
    ),

    // Alternate "entry point" for standalone expression patterns.
    lens_expression: $ => seq('__LENS_EXPRESSION', $.expression),

    // Statement-level ellipsis (for matching sequences of statements).
    lens_ellipsis: $ => '...',

    // Expression-level ellipsis (separate to reduce conflicts).
    lens_expression_ellipsis: $ => '...',

    deep_ellipsis: $ => seq('<...', $.expression, '...>'),

    statement: ($, previous) => choice(
      previous,
      $.lens_ellipsis,
    ),

    expression: ($, previous) => choice(
      previous,
      $.lens_expression_ellipsis,
      $.deep_ellipsis,
    ),

    _formal_parameter: ($, previous) => choice(
      $.lens_ellipsis,
      previous,
    ),
  }
});
