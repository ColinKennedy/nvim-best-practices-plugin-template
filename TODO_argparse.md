- unittest for nargs

- The terminology has become strange. Flag arguments

- If a named arguiment is an nargs=1 argument then it should auto-complete to be --foo=, I guess

- Allow the 1th index to be used in place of name / names in all cases
 - So we can avoid having to write name / names everywhere

- Consider adding validation. e.g. error if the user tries to add overlapping arguments

- Add general validation for all public functions (add_argument, add_subparsers, add_parser, etc)

Do TODO notes