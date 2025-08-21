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
        | batslib_decorate 'ERROR: assert_equals_golden' \
        | fail
        return $?
        ;;
      *)
        break
        ;;
    esac
  done

  if (( use_stdin_set_by_opt )) && [ $# -ne 1 ]; then
    echo "Incorrect number of arguments: $#. Using stdin, expecting 1 argument." \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  elif (( ! use_stdin_set_by_opt )) && [ $# -ne 2 ] ; then
    echo "Incorrect number of arguments: $#. Expected 2 arguments." \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    echo "\`--diff' not supported with \`--regexp'" \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
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

  if [ -z "$golden_file_path" ]; then
    echo "Golden file path was not given or it was empty." \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  fi
  if [ ! -e "$golden_file_path" ]; then
    echo "Golden file was not found. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  fi

  local golden_file_contents=
  # Load the contents from the file.
  # Append a period (to be removed on the next line) so that trailing new lines are preserved.
  golden_file_contents="$(cat "$golden_file_path" 2>/dev/null && printf '.')"
  if (( $? != 0 )); then
    echo "Failed to read golden file. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  fi
  golden_file_contents="${golden_file_contents%.}"
  if [ -z "$golden_file_contents" ] && ! (( allow_empty )); then
    echo "Golden file contents is empty. This may be an authoring error. Use \`--allow-empty\` if this is intentional." \
    | batslib_decorate 'ERROR: assert_equals_golden' \
    | fail
    return $?
  fi

  local -i assert_failed=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      echo "Invalid extended regular expression in golden file: \`$golden_file_contents'" \
      | batslib_decorate 'ERROR: assert_equals_golden' \
      | fail
      return $?
    elif ! [[ "$value" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$value" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      {
        echo "Golden file: $golden_file_path"
        diff <(echo "$value") <(echo "$golden_file_contents")
      } \
      | batslib_decorate 'value does not match golden' \
      | fail
    elif (( is_mode_regexp )); then
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents' "$golden_file_contents" \
          'actual value'    "$value"
      } \
      | batslib_decorate 'value does not match regexp golden' \
      | fail
    else
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents' "$golden_file_contents" \
          'actual value'    "$value"
      } \
      | batslib_decorate 'value does not match golden' \
      | fail
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        # Non-regex golden update is straight forward.
        printf '%s' "$value" 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_equals_golden' \
          | fail
          return $?
        fi
      else
        # To do a best-approximation for regex goldens,
        # try and use existing lines as a library for updated lines (preferring longer lines).
        # This is done line by line on the asserted value.
        # Unfortunately, this does not handle multi-line regex in the golden (e.g. `(.*\n){10}`).
        # Any line guess which is not preferred can be manually corrected/updated by the author.
        local -a output_lines=()
        local -a sorted_golden_lines=()
        local temp=
        while IFS='' read -r temp; do
          output_lines+=("$temp")
        done < <(printf '%s' "$value" ; printf '\n')
        while IFS='' read -r temp; do
          sorted_golden_lines+=("$temp")
        done < <(echo "$golden_file_contents" | awk '{ print length, $0 }' | sort -nrs | cut -d" " -f 2- ; printf '\n')
        # First, clear out the golden file's contents (so new data can just be appended below).
        : 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_equals_golden' \
          | fail
          return $?
        fi
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
      fi
      echo "Golden file updated after mismatch." \
      | batslib_decorate 'FAIL: assert_equals_golden' \
      | fail
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
        | batslib_decorate 'ERROR: assert_output_equals_golden' \
        | fail
        return $?
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 1 ]; then
    echo "Incorrect number of arguments: $#. Expected 1 argument." \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    echo "\`--diff' not supported with \`--regexp'" \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi

  local -r golden_file_path="${1-}"
  local -r -i update_goldens_on_failure="${BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE:-0}"

  if [ -z "$golden_file_path" ]; then
    echo "Golden file path was not given or it was empty." \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi
  if [ ! -e "$golden_file_path" ]; then
    echo "Golden file was not found. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi

  local golden_file_contents=
  # Load the contents from the file.
  # Append a period (to be removed on the next line) so that trailing new lines are preserved.
  golden_file_contents="$(cat "$golden_file_path" 2>/dev/null && printf '.')"
  if [ $? -ne 0 ]; then
    echo "Failed to read golden file. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi
  golden_file_contents="${golden_file_contents%.}"
  if [ -z "$golden_file_contents" ] && ! (( allow_empty )); then
    echo "Golden file contents is empty. This may be an authoring error. Use \`--allow-empty\` if this is intentional." \
    | batslib_decorate 'ERROR: assert_output_equals_golden' \
    | fail
    return $?
  fi

  local -i assert_failed=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      echo "Invalid extended regular expression in golden file: \`$golden_file_contents'" \
      | batslib_decorate 'ERROR: assert_output_equals_golden' \
      | fail
      return $?
    elif ! [[ "$output" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$output" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      {
        echo "Golden file: $golden_file_path"
        diff <(echo "$output") <(echo "$golden_file_contents")
      } \
      | batslib_decorate 'output does not match golden' \
      | fail
    elif (( is_mode_regexp )); then
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents' "$golden_file_contents" \
          'actual output'   "$output"
      } \
      | batslib_decorate 'output does not match regexp golden' \
      | fail
    else
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents' "$golden_file_contents" \
          'actual output'   "$output"
      } \
      | batslib_decorate 'output does not match golden' \
      | fail
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        # Non-regex golden update is straight forward.
        printf '%s' "$output" 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_output_equals_golden' \
          | fail
          return $?
        fi
      else
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
        done < <(printf '%s' "$output" ; printf '\n')
        while IFS='' read -r temp; do
          sorted_golden_lines+=("$temp")
        done < <(echo "$golden_file_contents" | awk '{ print length, $0 }' | sort -nrs | cut -d" " -f 2- ; printf '\n')
        # First, clear out the golden file's contents (so new data can just be appended below).
        : 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_output_equals_golden' \
          | fail
          return $?
        fi
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
      fi
      echo "Golden file updated after mismatch." \
      | batslib_decorate 'FAIL: assert_output_equals_golden' \
      | fail
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
        | batslib_decorate 'ERROR: assert_file_equals_golden' \
        | fail
        return $?
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 2 ]; then
    echo "Incorrect number of arguments: $#. Expected 2 argument." \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi

  if (( show_diff )) && (( is_mode_regexp )); then
    echo "\`--diff' not supported with \`--regexp'" \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi

  local -r target_file_path="${1-}"
  local -r golden_file_path="${2-}"
  local -r -i update_goldens_on_failure="${BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE:-0}"

  if [ -z "$target_file_path" ]; then
    echo "Target file path was not given or it was empty." \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi
  if [ ! -e "$target_file_path" ]; then
    echo "Target file was not found. File path: '$target_file_path'" \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi
  if [ -z "$golden_file_path" ]; then
    echo "Golden file path was not given or it was empty." \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi
  if [ ! -e "$golden_file_path" ]; then
    echo "Golden file was not found. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi

  local target_file_contents=
  # Load the contents from the file.
  # Append a period (to be removed on the next line) so that trailing new lines are preserved.
  target_file_contents="$(cat "$target_file_path" 2>/dev/null && printf '.')"
  if [ $? -ne 0 ]; then
    echo "Failed to read target file. File path: '$target_file_path'" \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi
  target_file_contents="${target_file_contents%.}"

  local golden_file_contents=
  # Load the contents from the file.
  # Append a period (to be removed on the next line) so that trailing new lines are preserved.
  golden_file_contents="$(cat "$golden_file_path" 2>/dev/null && printf '.')"
  if [ $? -ne 0 ]; then
    echo "Failed to read golden file. File path: '$golden_file_path'" \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi
  golden_file_contents="${golden_file_contents%.}"
  if [ -z "$golden_file_contents" ] && ! (( allow_empty )); then
    echo "Golden file contents is empty. This may be an authoring error. Use \`--allow-empty\` if this is intentional." \
    | batslib_decorate 'ERROR: assert_file_equals_golden' \
    | fail
    return $?
  fi

  local -i assert_failed=0
  if (( is_mode_regexp )); then
    if [[ ! '' =~ ^${golden_file_contents}$ ]] && [[ '' =~ ^${golden_file_contents}$ ]] || (( $? == 2 )); then
      echo "Invalid extended regular expression in golden file: \`$golden_file_contents'" \
      | batslib_decorate 'ERROR: assert_file_equals_golden' \
      | fail
      return $?
    elif ! [[ "$target_file_contents" =~ ^${golden_file_contents}$ ]]; then
      assert_failed=1
    fi
  elif [[ "$target_file_contents" != "$golden_file_contents" ]]; then
    assert_failed=1
  fi

  if (( assert_failed )); then
    if (( show_diff )); then
      {
        echo "Golden file: $golden_file_path"
        diff <(echo "$target_file_contents") <(echo "$golden_file_contents")
      } \
      | batslib_decorate 'file contents does not match golden' \
      | fail
    elif (( is_mode_regexp )); then
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents'      "$golden_file_contents" \
          'actual file contents' "$target_file_contents"
      } \
      | batslib_decorate 'file contents does not match regexp golden' \
      | fail
    else
      {
        echo "Golden file: $golden_file_path"
        batslib_print_kv_multi \
          'golden contents'      "$golden_file_contents" \
          'actual file contents' "$target_file_contents"
      } \
      | batslib_decorate 'file contents does not match golden' \
      | fail
    fi

    if (( update_goldens_on_failure )); then
      if ! (( is_mode_regexp )); then
        # Non-regex golden update is straight forward.
        printf '%s' "$target_file_contents" 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_file_equals_golden' \
          | fail
          return $?
        fi
      else
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
        done < <(printf '%s' "$target_file_contents" ; printf '\n')
        while IFS='' read -r temp; do
          sorted_golden_lines+=("$temp")
        done < <(echo "$golden_file_contents" | awk '{ print length, $0 }' | sort -nrs | cut -d" " -f 2- ; printf '\n')
        # First, clear out the golden file's contents (so new data can just be appended below).
        : 2>/dev/null > "$golden_file_path"
        if [[ $? -ne 0 ]]; then
          echo "Failed to write into golden file during update: '$golden_file_path'." \
          | batslib_decorate 'FAIL: assert_file_equals_golden' \
          | fail
          return $?
        fi
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
      fi
      echo "Golden file updated after mismatch." \
      | batslib_decorate 'FAIL: assert_file_equals_golden' \
      | fail
    fi
  fi
  return $assert_failed
}
