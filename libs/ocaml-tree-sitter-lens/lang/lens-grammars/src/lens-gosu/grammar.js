/*
  lens-gosu

  Extends the standard gosu grammar with lens pattern constructs.
*/

const base_grammar = require("tree-sitter-gosu/grammar");

module.exports = grammar(base_grammar, {
  name: "gosu",

  conflicts: ($, previous) => previous.concat([]),

  /*
     Support for lens ellipsis ('...') and metavariables ('$FOO'),
     if they're not already part of the base grammar.
  */
  rules: {
    lens_ellipsis: ($) => "...",

    parameterDeclaration: ($, previous) =>
      choice(previous, $.lens_ellipsis),

    usesStatement: ($, previous) =>
      choice(previous, $.lens_ellipsis),

    declaration: ($, previous) =>
      choice(...previous.members, $.lens_ellipsis),

    _statement: ($, previous) =>
      choice(...previous.members, $.lens_ellipsis),

    _expression: ($, previous) =>
      choice(previous, $.lens_ellipsis),
  },
});
