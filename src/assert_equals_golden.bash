# assert_equals_golden
# ============
#
# Summary: Fail if the actual and golden file contents are not equal.
#
# Usage: assert_equals_golden [-e | --regexp | -d | --diff] [--stdin] [--allow-empty] [--] [- | <actual>] <golden file path>
#
# Options:
#   -e, --regexp        Treat file contents of <golden file path> as an multiline extended regular expression.
#   -d, --diff          Displays `diff` between <actual> and golden contents instead of full strings.
#   -, --stdin          Read <actual> value from STDIN. Do not pass <actual> if set.
#   <actual>            The value being compared. May be `-` to use STDIN. Omit if `--stdin` is passed.
#   <golden file path>  A file that has contents which must match against <actual>.
#
#   ```bash
#   @test 'assert_equals_golden()' {
#     assert_equals_golden 'have' 'some/path/golden_file.txt'
#   }
#   ```
#
# IO:
#   STDIN  - actual value, if `--stdin` or `-` is supplied.
#   STDERR - expected and actual values, or their diff, on failure
# Globals:
#   BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE - The golden file's contents will be updated to <actual> if it did not match. 
# Returns:
#   0 - if <actual> is equal to file contents in <golden file path>
#   1 - otherwise
#
# Golden files hold the entirety of the expected output.
# Contents will properly/consistently match to empty lines / trailing new lines (when used with `run --keep-empty-lines` or similar).
# Golden files are, by default, not allowed to be empty. This is to catch common authoring errors. If intented, this can be overridden with `--allow-empty`.
#
# Golden files have a number of benefits when used for asserting against output, including:
#   * WYSIWYG plaintext output assertions (separating asserted output from test case logic).
#   * Test failure output that is searchable (asserted output is checked into repo as files).
#   * Clear file diffs of test assertions during merge / code review.
#   * Terse assertions in test cases (single assert instead of many verbose `assert_line` and `refute_line` for every line of output).
#   * Reusable golden files (declared once, used for many test cases).
#   * Clear intention (same exact expected output) when asserted against same goldens in multiple test cases.
#   * Can be clearly diff'd across multiple lines in failure message(s).
#   * Easily updated.
#
# The assertion string target, <actual>, can instead be supplied via STDIN.
# If `--stdin` is supplied, or if `-` is given as <actual>, STDIN will be read for the checked string.
# When suppliying `--stdin`, only 1 argument (<golden file path>) should be supplied.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set, failed assertions will result in the golden file being updated.
# The golden file contents is updated to be able to pass upon subsequent runs.
# All tests that update goldens still fails (enforcing that all passing tests are achieved with pre-existing correct golden).
# This is set via an environment variable to allow mass golden file updates across many tests.
#
# ## Literal matching
#
# On failure, the expected and actual values are displayed. Line count is always displayed.
#
#   ```
#   -- value does not match golden --
#   golden contents (1 lines):
#   want
#   actual value (1 lines):
#   have
#   --
#   ```
#
# If `--diff` is given, the output is changed to `diff` between <actual> and the golden file contents.
#
#   ```
#   -- value does not match golden --
#   1c1
#   < have
#   ---
#   > want
#   --
#   ```
#
# ## Regular expression matching
#
# If `--regexp` is given, the golden file contents is treated as a multiline extended regular expression.
# This allows for volatile output (e.g. timestamps, identifiers) and/or secrets to be removed from golden files, but still constrained for proper asserting.
# Regular expression special characters (`][\.()*+?{}|^$\\`), when used as literals, must be escaped in the golden file.
# The regular expression golden file contents respects `\n` characters and expressions which span multiple lines.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set with `--regexp`, special logic is used to reuse lines where possible.
# Each line in the existing golden will attempt to match to the line of <actual>, preferring longer lines.
# If no pre-existing golden line matches, that line will be updated with the exact line string from <actual>.
# Not all lines can be reused (e.g. multiline expressions), but the golden file can be manually changed after automatic update.
#
# `--diff` is not supported with `--regexp`.
#
assert_equals_golden() {
  local -i is_mode_regexp=0
  local -i show_diff=0
  local -i use_stdin_set_by_opt=0
  local -i use_stdin_set_by_arg=0
  local -i allow_empty=0

  while (( $# > 0 )); do
    case "$1" in
      -e|--regexp)
        is_mode_regexp=1
        shift
        ;;
      -d|--diff)
        show_diff=1;
        shift
        ;;
      --stdin)
        use_stdin_set_by_opt=1;
        shift
        ;;
      --allow-empty)
        allow_empty=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -)
        use_stdin_set_by_arg=1
        break
        ;;
      --*=|-*)
        echo "Unsupported flag '$1'." \
        | batslib_decorate 'ERROR: assert_equals_golden'
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if (( use_stdin_set_by_opt )) && [ $# -ne 1 ]; then
    __assert_golden__print_incorrect_number_of_arguments_msg 'assert_equals_golden' "$#" 1
    return 1
  elif (( ! use_stdin_set_by_opt )) && [ $# -ne 2 ] ; then
    __assert_golden__print_incorrect_number_of_arguments_msg 'assert_equals_golden' "$#" 2
    return 1
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    __assert_golden__print_diff_regexp_incompat_msg 'assert_equals_golden'
    return 1
  fi

  local value="$1"
  local golden_file_path="${2-}"
  if (( use_stdin_set_by_opt )) || (( use_stdin_set_by_arg )); then
    value="$(cat - && printf '.')"
    value="${value%.}"
  fi
  if (( use_stdin_set_by_opt )); then
    golden_file_path="$1"
  fi

  local -r -i update_goldens_on_failure="${BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE:+1}"

  if ! __assert_golden__validate_file_path 'assert_equals_golden' 'Golden file' "$golden_file_path"; then
    return 1
  fi

  local golden_file_contents=
  if ! __assert_golden__read_golden_file_contents 'assert_equals_golden' "$golden_file_path" "$allow_empty" 'golden_file_contents'; then
    return 1
  fi

  local -i assert_failed=0
  local -i invalid_regexp=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      __assert_golden__print_invalid_extended_regular_expression_msg 'assert_equals_golden'
      assert_failed=1
      invalid_regexp=1
    elif ! [[ "$value" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$value" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      __assert_golden__print_not_matching_show_diff_msg 'assert_equals_golden' 'value' "$value" "$golden_file_path" "$golden_file_contents"
    elif ! (( is_mode_regexp )); then
      __assert_golden__print_not_matching_whole_contents_msg 'assert_equals_golden' 'value' "$value" "$golden_file_path" "$golden_file_contents"
    elif ! (( invalid_regexp )); then
      __assert_golden__print_not_matching_regexp_msg 'assert_equals_golden' 'value' "$value" "$golden_file_path" "$golden_file_contents"
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        __assert_golden__update_golden_file_contents_nonregexp 'assert_equals_golden' "$value" "$golden_file_path"
      else
        __assert_golden__update_golden_file_contents_regexp 'assert_equals_golden' "$value" "$golden_file_path"
      fi
    fi
  fi
  return $assert_failed
}

# assert_output_equals_golden
# ============
#
# Summary: Fail if the `output` environment variable and golden file contents are not equal.
#
# Usage: assert_output_equals_golden [-e | --regexp | -d | --diff] [--allow-empty] [--] <golden file path>
#
# Options:
#   -e, --regexp        Treat file contents of <golden file path> as an multiline extended regular expression.
#   -d, --diff          Displays `diff` between `output` and golden contents instead of full strings.
#   <golden file path>  A file that has contents which must match against `output`.
#
#   ```bash
#   @test 'assert_output_equals_golden()' {
#     run echo 'have' 
#     assert_output_equals_golden 'some/path/golden_file.txt'
#   }
#   ```
#
# IO:
#   STDERR - expected and actual outputs, or their diff, on failure
# Globals:
#   output - the actual output asserted against golden file contents.
#   BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE - The golden file's contents will be updated to `output` if it did not match. 
# Returns:
#   0 - if `output` is equal to file contents in <golden file path>
#   1 - otherwise
#
# Golden files hold the entirety of the expected output.
# Contents will properly/consistently match to empty lines / trailing new lines (when used with `run --keep-empty-lines` or similar).
# Golden files are, by default, not allowed to be empty. This is to catch common authoring errors. If intented, this can be overridden with `--allow-empty`.
#
# Golden files have a number of benefits when used for asserting against output, including:
#   * WYSIWYG plaintext output assertions (separating asserted output from test case logic).
#   * Test failure output that is searchable (asserted output is checked into repo as files).
#   * Clear file diffs of test assertions during merge / code review.
#   * Terse assertions in test cases (single assert instead of many verbose `assert_line` and `refute_line` for every line of output).
#   * Reusable golden files (declared once, used for many test cases).
#   * Clear intention (same exact expected output) when asserted against same goldens in multiple test cases.
#   * Can be clearly diff'd across multiple lines in failure message(s).
#   * Easily updated.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set, failed assertions will result in the golden file being updated.
# The golden file contents is updated to be able to pass upon subsequent runs.
# All tests that update goldens still fails (enforcing that all passing tests are achieved with pre-existing correct golden).
# This is set via an environment variable to allow mass golden file updates across many tests.
#
# ## Literal matching
#
# On failure, the expected and actual output are displayed. Line count is always displayed.
#
#   ```
#   -- output does not match golden --
#   golden contents (1 lines):
#   want
#   actual output (1 lines):
#   have
#   --
#   ```
#
# If `--diff` is given, the output is changed to `diff` between `output` and the golden file contents.
#
#   ```
#   -- output does not match golden --
#   1c1
#   < have
#   ---
#   > want
#   --
#   ```
#
# ## Regular expression matching
#
# If `--regexp` is given, the golden file contents is treated as a multiline extended regular expression.
# This allows for volatile output (e.g. timestamps, identifiers) and/or secrets to be removed from golden files, but still constrained for proper asserting.
# Regular expression special characters (`][\.()*+?{}|^$\\`), when used as literals, must be escaped in the golden file.
# The regular expression golden file contents respects `\n` characters and expressions which span multiple lines.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set with `--regexp`, special logic is used to reuse lines where possible.
# Each line in the existing golden will attempt to match to the line of <actual>, preferring longer lines.
# If no pre-existing golden line matches, that line will be updated with the exact line string from <actual>.
# Not all lines can be reused (e.g. multiline expressions), but the golden file can be manually changed after automatic update.
#
# `--diff` is not supported with `--regexp`.
#
assert_output_equals_golden() {
  local -i is_mode_regexp=0
  local -i show_diff=0
  local -i allow_empty=0
  : "${output?}"

  while (( "$#" )); do
    case "$1" in
      -e|--regexp)
        is_mode_regexp=1
        shift
        ;;
      -d|--diff)
        show_diff=1;
        shift
        ;;
      --allow-empty)
        allow_empty=1
        shift
        ;;
      --)
        shift
        break
        ;;
      --*=|-*)
        echo "Unsupported flag '$1'." \
        | batslib_decorate 'ERROR: assert_output_equals_golden'
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 1 ]; then
    __assert_golden__print_incorrect_number_of_arguments_msg 'assert_output_equals_golden' "$#" 1
    return 1
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    __assert_golden__print_diff_regexp_incompat_msg 'assert_output_equals_golden'
    return 1
  fi

  local -r golden_file_path="${1-}"
  local -r -i update_goldens_on_failure="${BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE:+1}"

  if ! __assert_golden__validate_file_path 'assert_output_equals_golden' 'Golden file' "$golden_file_path"; then
    return 1
  fi

  local golden_file_contents=
  if ! __assert_golden__read_golden_file_contents 'assert_output_equals_golden' "$golden_file_path" "$allow_empty" 'golden_file_contents'; then
    return 1
  fi

  local -i assert_failed=0
  local -i invalid_regexp=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      __assert_golden__print_invalid_extended_regular_expression_msg 'assert_output_equals_golden'
      assert_failed=1
      invalid_regexp=1
    elif ! [[ "$output" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$output" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      __assert_golden__print_not_matching_show_diff_msg 'assert_output_equals_golden' 'output' "$output" "$golden_file_path" "$golden_file_contents"
    elif ! (( is_mode_regexp )); then
      __assert_golden__print_not_matching_whole_contents_msg 'assert_output_equals_golden' 'output' "$output" "$golden_file_path" "$golden_file_contents"
    elif ! (( invalid_regexp )); then
      __assert_golden__print_not_matching_regexp_msg 'assert_output_equals_golden' 'output' "$output" "$golden_file_path" "$golden_file_contents"
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        __assert_golden__update_golden_file_contents_nonregexp 'assert_output_equals_golden' "$output" "$golden_file_path"
      else
        __assert_golden__update_golden_file_contents_regexp 'assert_output_equals_golden' "$output" "$golden_file_path"
      fi
    fi
  fi
  return $assert_failed
}

# assert_file_equals_golden
# ============
#
# Summary: Fail if the target file and golden file contents are not equal.
#
# Usage: assert_file_equals_golden [-e | --regexp | -d | --diff] [--allow-empty] [--] <target file path> <golden file path>
#
# Options:
#   -e, --regexp        Treat file contents of <golden file path> as an multiline extended regular expression.
#   -d, --diff          Displays `diff` between target file and golden contents instead of full strings.
#   <golden file path>  A file that has contents which must match against the target file's contents.
#
#   ```bash
#   @test 'assert_file_equals_golden()' {
#     run echo 'have' 
#     assert_file_equals_golden 'generated/file.txt' 'some/path/golden_file.txt'
#   }
#   ```
#
# IO:
#   STDERR - expected and actual outputs, or their diff, on failure
# Globals:
#   BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE - The golden file's contents will be updated to the target file's contents if it did not match. 
# Returns:
#   0 - if <target file path> contents is equal to file contents in <golden file path>
#   1 - otherwise
#
# Golden files hold the entirety of the expected output.
# Contents will properly/consistently match to empty lines / trailing new lines (when used with `run --keep-empty-lines` or similar).
# Golden files are, by default, not allowed to be empty. This is to catch common authoring errors. If intented, this can be overridden with `--allow-empty`.
#
# Golden files have a number of benefits when used for asserting against output, including:
#   * WYSIWYG plaintext output assertions (separating asserted output from test case logic).
#   * Test failure output that is searchable (asserted output is checked into repo as files).
#   * Clear file diffs of test assertions during merge / code review.
#   * Terse assertions in test cases (single assert instead of many verbose `assert_line` and `refute_line` for every line of output).
#   * Reusable golden files (declared once, used for many test cases).
#   * Clear intention (same exact expected output) when asserted against same goldens in multiple test cases.
#   * Can be clearly diff'd across multiple lines in failure message(s).
#   * Easily updated.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set, failed assertions will result in the golden file being updated.
# The golden file contents is updated to be able to pass upon subsequent runs.
# All tests that update goldens still fails (enforcing that all passing tests are achieved with pre-existing correct golden).
# This is set via an environment variable to allow mass golden file updates across many tests.
#
# ## Literal matching
#
# On failure, the expected and actual output are displayed. Line count is always displayed.
#
#   ```
#   -- file contents does not match golden --
#   golden contents (1 lines):
#   want
#   actual file contents (1 lines):
#   have
#   --
#   ```
#
# If `--diff` is given, the output is changed to `diff` between target file and the golden file contents.
#
#   ```
#   -- file contents does not match golden --
#   1c1
#   < have
#   ---
#   > want
#   --
#   ```
#
# ## Regular expression matching
#
# If `--regexp` is given, the golden file contents is treated as a multiline extended regular expression.
# This allows for volatile output (e.g. timestamps, identifiers) and/or secrets to be removed from golden files, but still constrained for proper asserting.
# Regular expression special characters (`][\.()*+?{}|^$\\`), when used as literals, must be escaped in the golden file.
# The regular expression golden file contents respects `\n` characters and expressions which span multiple lines.
#
# If the `BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE` environment variable is set with `--regexp`, special logic is used to reuse lines where possible.
# Each line in the existing golden will attempt to match to the line of <actual>, preferring longer lines.
# If no pre-existing golden line matches, that line will be updated with the exact line string from <actual>.
# Not all lines can be reused (e.g. multiline expressions), but the golden file can be manually changed after automatic update.
#
# `--diff` is not supported with `--regexp`.
#
assert_file_equals_golden() {
  local -i is_mode_regexp=0
  local -i show_diff=0
  local -i allow_empty=0

  while (( "$#" )); do
    case "$1" in
      -e|--regexp)
        is_mode_regexp=1
        shift
        ;;
      -d|--diff)
        show_diff=1;
        shift
        ;;
      --allow-empty)
        allow_empty=1
        shift
        ;;
      --)
        shift
        break
        ;;
      --*=|-*)
        echo "Unsupported flag '$1'." \
        | batslib_decorate 'ERROR: assert_file_equals_golden'
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 2 ]; then
    __assert_golden__print_incorrect_number_of_arguments_msg 'assert_file_equals_golden' "$#" 2
    return 1
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    __assert_golden__print_diff_regexp_incompat_msg 'assert_file_equals_golden'
    return 1
  fi

  local -r target_file_path="${1-}"
  local -r golden_file_path="${2-}"
  local -r -i update_goldens_on_failure="${BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE:+1}"

  if ! __assert_golden__validate_file_path 'assert_file_equals_golden' 'Target file' "$target_file_path" \
    || ! __assert_golden__validate_file_path 'assert_file_equals_golden' 'Golden file' "$golden_file_path"; then
    return 1
  fi

  local target_file_contents=
  if ! __assert_golden__read_file_contents 'assert_file_equals_golden' 'target file' "$target_file_path" 'target_file_contents'; then
    return 1
  fi

  local golden_file_contents=
  if ! __assert_golden__read_golden_file_contents 'assert_file_equals_golden' "$golden_file_path" "$allow_empty" 'golden_file_contents'; then
    return 1
  fi

  local -i assert_failed=0
  local -i invalid_regexp=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      __assert_golden__print_invalid_extended_regular_expression_msg 'assert_file_equals_golden'
      assert_failed=1
      invalid_regexp=1
    elif ! [[ "$target_file_contents" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$target_file_contents" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      __assert_golden__print_not_matching_show_diff_msg 'assert_file_equals_golden' 'file contents' "$target_file_contents" "$golden_file_path" "$golden_file_contents"
    elif ! (( is_mode_regexp )); then
      __assert_golden__print_not_matching_whole_contents_msg 'assert_file_equals_golden' 'file contents' "$target_file_contents" "$golden_file_path" "$golden_file_contents"
    elif ! (( invalid_regexp )); then
      __assert_golden__print_not_matching_regexp_msg 'assert_file_equals_golden' 'file contents' "$target_file_contents" "$golden_file_path" "$golden_file_contents"
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        __assert_golden__update_golden_file_contents_nonregexp 'assert_file_equals_golden' "$target_file_contents" "$golden_file_path"
      else
        __assert_golden__update_golden_file_contents_regexp 'assert_file_equals_golden' "$target_file_contents" "$golden_file_path"
      fi
    fi
  fi
  return $assert_failed
}

__assert_golden__print_incorrect_number_of_arguments_msg() {
  local -r assert_function_name="$1"
  local -r -i actual_arg_count="$2"
  local -r -i expected_arg_count="$3"

  if [[ $expected_arg_count -eq 1 ]]; then
    echo "Incorrect number of arguments: $actual_arg_count. Expected $expected_arg_count argument." \
    | batslib_decorate "ERROR: $assert_function_name"
  else
    echo "Incorrect number of arguments: $actual_arg_count. Expected $expected_arg_count arguments." \
    | batslib_decorate "ERROR: $assert_function_name"
  fi
}

__assert_golden__print_diff_regexp_incompat_msg() {
  local -r assert_function_name="$1"

  echo "\`--diff' not supported with \`--regexp'" \
  | batslib_decorate "ERROR: $assert_function_name"
}

__assert_golden__validate_file_path() {
  local -r assert_function_name="$1"
  local -r file_description="$2"
  local -r file_path="$3"

  if [ -z "$file_path" ]; then
    echo "$file_description path was not given or it was empty." \
    | batslib_decorate "ERROR: $assert_function_name"
    return 1
  fi
  if [ ! -e "$file_path" ]; then
    echo "$file_description was not found. File path: '$file_path'" \
    | batslib_decorate "ERROR: $assert_function_name"
    return 1
  fi
}

__assert_golden__read_golden_file_contents() {
  local -r assert_function_name="$1"
  local -r golden_file_path="$2"
  local -r -i allow_empty="$3"
  local -r output_variable_name="$4"

  local -n golden_file_contents_ref="$output_variable_name"
  if ! __assert_golden__read_file_contents "$assert_function_name" 'golden file' "$golden_file_path" 'golden_file_contents_ref'; then
    return 1
  fi
  if [ -z "$golden_file_contents_ref" ] && ! (( allow_empty )); then
    echo "Golden file contents is empty. This may be an authoring error. Use \`--allow-empty\` if this is intentional." \
    | batslib_decorate "ERROR: $assert_function_name"
    return 1
  fi
}

__assert_golden__read_file_contents() {
  local -r assert_function_name="$1"
  local -r file_description="$2"
  local -r file_path="$3"
  local -r output_variable_name="$4"

  local -n file_contents_ref="$output_variable_name"
  # Load the contents from the file.
  # Append a period (to be removed on the next line) so that trailing new lines are preserved.
  if ! file_contents_ref="$(cat "$file_path" 2>/dev/null && printf '.')"; then
    echo "Failed to read ${file_description}. File path: '$file_path'" \
    | batslib_decorate "ERROR: $assert_function_name"
    return 1
  fi
  file_contents_ref="${file_contents_ref%.}"
}

__assert_golden__print_invalid_extended_regular_expression_msg() {
  local -r assert_function_name="$1"
  {
    echo "Invalid extended regular expression in golden file."
    echo "Golden file: $golden_file_path"
    batslib_print_kv_multi \
      'golden contents' "$golden_file_contents"
  } \
  | batslib_decorate "ERROR: $assert_function_name"
}

__assert_golden__print_not_matching_show_diff_msg() {
  local -r assert_function_name="$1"
  local -r contents_description="$2"
  local -r actual_contents="$3"
  local -r golden_file_path="$4"
  local -r golden_file_contents="$5"

  {
    echo "Golden file: $golden_file_path"
    diff <(echo "$actual_contents") <(echo "$golden_file_contents")
  } \
  | batslib_decorate "${assert_function_name}: $contents_description does not match golden"
}

__assert_golden__print_not_matching_regexp_msg() {
  local -r assert_function_name="$1"
  local -r contents_description="$2"
  local -r actual_contents="$3"
  local -r golden_file_path="$4"
  local -r golden_file_contents="$5"

  {
    echo "Golden file: $golden_file_path"
    batslib_print_kv_multi \
      'golden contents' "$golden_file_contents" \
      "actual $contents_description"    "$actual_contents"
  } \
  | batslib_decorate "${assert_function_name}: $contents_description does not match regexp golden"
}

__assert_golden__print_not_matching_whole_contents_msg() {
  local -r assert_function_name="$1"
  local -r contents_description="$2"
  local -r actual_contents="$3"
  local -r golden_file_path="$4"
  local -r golden_file_contents="$5"

  {
    echo "Golden file: $golden_file_path"
    batslib_print_kv_multi \
      'golden contents' "$golden_file_contents" \
      "actual $contents_description"    "$actual_contents"
  } \
  | batslib_decorate "${assert_function_name}: $contents_description does not match golden"
}

__assert_golden__update_golden_file_contents_nonregexp() {
  local -r assert_function_name="$1"
  local -r new_golden_contents="$2"
  local -r golden_file_path="$3"

  # Non-regex golden update is straight forward.
  # Write the contents to the golden file (and check for write errors).
  if ! printf '%s' "$new_golden_contents" 2>/dev/null > "$golden_file_path"; then
    echo "Failed to write into golden file during update: '$golden_file_path'." \
    | batslib_decorate "FAIL: $assert_function_name"
  else
    __assert_golden__print_updated_golden_file_msg "$assert_function_name"
  fi
}

__assert_golden__update_golden_file_contents_regexp() {
  local -r assert_function_name="$1"
  local -r new_golden_contents="$2"
  local -r golden_file_path="$3"

  # To do a best-approximation for regex goldens,
  # try and use existing lines as a library for updated lines (preferring longer lines).
  # This is done line by line on the output.
  # Unfortunately, this does not handle multi-line regex in the golden (e.g. `(.*\n){10}`).
  # Any line guess which is not preferred can be manually corrected/updated by the author.
  local -a output_lines=()
  local -a sorted_golden_lines=()
  local temp=
  while IFS='' read -r temp; do
    output_lines+=("$temp")
  done < <(printf '%s' "$new_golden_contents" ; printf '\n')
  while IFS='' read -r temp; do
    sorted_golden_lines+=("$temp")
  done < <(echo "$golden_file_contents" | awk '{ print length, $0 }' | sort -nrs | cut -d" " -f 2- ; printf '\n')

  # First, clear out the golden file's contents so new data can just be appended below (and check for write errors).
  if ! : 2>/dev/null > "$golden_file_path"; then
    echo "Failed to write into golden file during update: '$golden_file_path'." \
    | batslib_decorate "FAIL: $assert_function_name"
  else
    # Go line by line over the output, looking for the best suggested replacement.
    local best_guess_for_line=
    for line_in_output in "${output_lines[@]}"; do
      # Default the output line itself as the best guess for the new golden.
      # Though, the output line needs to be properly escaped for when being used in regex matching (on subsequent runs of the test).
      best_guess_for_line="$(echo "$line_in_output" | sed -E 's/([][\.()*+?{}|^$\\])/\\\1/g')"
      for line_in_golden in "${sorted_golden_lines[@]}"; do
        if [[ "$line_in_output" =~ ^${line_in_golden}$ ]]; then
          # If there's a line from the previous golden output that matches, use that is the best guess instead.
          # No need to escape special characters, as `line_in_golden` is already in proper form.
          best_guess_for_line="$line_in_golden"
          break
        fi
      done
      if [ -s "$golden_file_path" ]; then
        printf '\n' >> "$golden_file_path"
      fi
      printf '%s' "$best_guess_for_line" >> "$golden_file_path"
    done

    __assert_golden__print_updated_golden_file_msg "$assert_function_name"
  fi
}

__assert_golden__print_updated_golden_file_msg() {
  local -r assert_function_name="$1"

  echo "Golden file updated after mismatch." \
  | batslib_decorate "FAIL: $assert_function_name"
}
