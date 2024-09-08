- Add a --help API
https://github.com/cwshugg/argonaut.vim
 - value hinting

"foo must be defined"
"foo requires a value"
"foo needs to be used 3 times (you used it 2 times)"

etc

Do TODO notes

- Argument validation
 - named arguments
  - must have a value (or more than one)
 - counts
  - users if they used 1 time but needed 2. etc etc.
  - Only for required arguments, obviously
  - If count = "*" then don't, I guess.

