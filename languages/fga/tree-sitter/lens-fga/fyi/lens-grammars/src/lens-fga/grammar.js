const base_grammar = require('../tree-sitter-fga/grammar');

module.exports = grammar(base_grammar, {
  name: 'fga',

  conflicts: ($, previous) => previous.concat([
    [$.relations]
  ]),

  rules: {
    lens_ellipsis: $ => '...',

    lens_metavariable: $ => /\$[A-Z_][A-Z_0-9]*/,

    type_declaration: ($, previous) => seq(
      optional('extend'),
      'type',
      choice($.identifier, $.lens_metavariable),
      '\n',
      optional($.relations)
    ),

    definition: ($, previous) => seq(
      'define',
      field('relation', choice($.identifier, $.lens_metavariable)),
      ':',
      $.relation_def
    ),

    _module_file: ($, previous) => seq(
      choice($.model, $.module),
      repeat(choice(
        $.type_declaration,
        $.condition_declaration,
        $.lens_ellipsis
      ))
    ),

    relations: ($, previous) => seq(
      'relations',
      repeat(choice(
        $.definition,
        $.lens_ellipsis
      ))
    ),

    _expression: ($, previous) => choice(
      ...previous.members,
      $.lens_ellipsis,
      $.lens_metavariable,
    ),

    param: ($, previous) => seq(
      choice($.identifier, $.lens_metavariable),  // Allow $VAR
      ':',
      choice($.type_identifier, $.lens_metavariable)  // Allow $TYPE
    ),

    direct_relationship: ($, previous) => seq(
      '[',
      choice(
        seq(
          seq(
            choice($.identifier, $.relation_ref, $.all, $.lens_metavariable),
            optional($.conditional)
          ),
          optional(repeat(seq(
            ',',
            seq(
              choice($.identifier, $.relation_ref, $.all, $.lens_metavariable),
              optional($.conditional)
            )
          )))
        ),
        $.lens_ellipsis
      ),
      ']'
    ),
  }
});
