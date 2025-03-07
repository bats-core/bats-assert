# assert_equal
# ============
#
# Summary: Fail if the actual and expected values are not equal.
#
# Usage: assert_equal [-d] <actual> <expected>
#
# Options:
#   <actual>      The value being compared.
#   <expected>    The value to compare against.
#   -d, --diff     Show diff between `expected` and `$output`
#
#   ```bash
#   @test 'assert_equal()' {
#     assert_equal 'have' 'want'
#   }
#   ```
#
# IO:
#   STDERR - expected and actual values, on failure
# Globals:
#   none
# Returns:
#   0 - if values equal
#   1 - otherwise
#
# On failure, the expected and actual values are displayed.
#
#   ```
#   -- values do not equal --
#   expected : want
#   actual   : have
#   --
#   ```
#
# If the `--diff` option is set, a diff between the expected and actual output is shown.
assert_equal() {
  local -i show_diff=0

  while (( $# > 0 )); do
    case "$1" in
    -d|--diff) show_diff=$(( $# > 1 )); shift ;;
    *) break ;;
    esac
  done

  if [[ $1 != "$2" ]]; then
    if (( show_diff )); then
      diff -u <(echo "$1") <(echo "$2") | tail -n +3 \
      | batslib_decorate 'values do not equal' \
      | fail
    else
       batslib_print_kv_single_or_multi 8 \
      'expected' "$2" \
      'actual'   "$1" \
      | batslib_decorate 'values do not equal' \
      | fail
    fi
  fi
}
