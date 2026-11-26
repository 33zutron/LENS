/*
  lens-cfquery

  Extends the standard cfquery grammar with lens pattern constructs.

  Metavariables ($FOO) work natively because $ is valid in identifiers.
*/

const base_grammar = require('tree-sitter-cfml/cfquery/grammar');

module.exports = grammar(base_grammar, {
  name: 'cfquery',

  conflicts: ($, previous) => previous.concat([
    [$.lens_expression_ellipsis, $.spread_element],
    [$.lens_expression_ellipsis, $.rest_pattern],
    [$.lens_expression_ellipsis, $.spread_element, $.rest_pattern],
    [$.lens_expression_ellipsis, $.lens_ellipsis],
    [$.spread_element, $.rest_pattern, $.lens_ellipsis],
    [$.spread_element, $.rest_pattern, $.lens_ellipsis, $.lens_expression_ellipsis],
  ]),

  rules: {
    lens_ellipsis: $ => '...',
    lens_expression_ellipsis: $ => '...',
    deep_ellipsis: $ => seq('<...', $.expression, '...>'),

    _node: ($, previous) => choice(
      previous,
      $.lens_ellipsis,
    ),

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
