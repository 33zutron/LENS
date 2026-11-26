/*
 * Lens extensions for PHP grammar.
 * These extensions are shared between both php and php_only variants.
 */
module.exports = {
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
};
