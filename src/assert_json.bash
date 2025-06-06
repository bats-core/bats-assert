# assert_json
# ======
#
# Summary: Fail if the given JSON does not match the provided jq expressions.
#
# Usage: assert_json <json> <jq_expression> [<jq_expression> ...]
#
# Examples:
#   assert_json "$json" '.name == "TestProject"' '.version == "1.0.0"'
#   assert_json "$json" '.policyConditions | length == 1'
#
#   # In a Bats test, using output from run command:
#   assert_json_output '.name == "TestProject"' '.version == "1.0.0"'
#
#   # For arrays:
#   assert_json "$json" '[.[] | .name] | sort == ["A", "B"]'
#
#   # For nested objects:
#   assert_json "$json" '.parent.uuid == "parent-id"'
#
# IO:
#   STDERR - the failed expression, on failure
# Globals:
#   none
# Returns:
#   0 - if the JSON matches all expressions
#   1 - otherwise
#
assert_json() {
  local json="$1" expression output
  shift

  for expression in "$@"
  do
    if ! output=$(echo "$json" | jq -e "$expression" 2>&1)
    then
      batslib_print_kv_single_or_multi 8 \
      'expression' "$expression" \
      'json'   "$json" \
      'output' "$output" \
      | batslib_decorate 'json does not match' \
      | fail
    fi
  done
}

# refute_json
# ========
#
# Summary: Fail if the given JSON matches any of the provided jq expressions.
#
# Usage: refute_json <json> <jq_expression> [<jq_expression> ...]
#
# Examples:
#   refute_json "$json" '.name == "NonExistentProject"'
#   refute_json "$json" '.policyConditions[]? | select(.uuid == "deleted-id")'
#
#   # In a Bats test, using output from run command:
#   refute_json_output '.name == "NonExistentProject"'
#
# IO:
#   STDERR - the failed expression, on failure
# Globals:
#   none
# Returns:
#   0 - if the JSON does not match any of the expressions
#   1 - otherwise, also if there is a usage or compile error in jq
#
refute_json() {
  local json="$1" expression output status
  shift

  for expression in "$@"
  do
    {
      output=$(echo "$json" | jq -e "$expression" 2>&1)
      status=$?
    } || true

    if (( status == 2 || status == 3 )); then
      batslib_print_kv_single_or_multi 8 \
      'expression' "$expression" \
      'json'   "$json" \
      'output' "$output" \
      | batslib_decorate 'jq encountered a usage or compile error' \
      | fail
    fi

    if (( status == 0 )); then
      batslib_print_kv_single_or_multi 8 \
      'expression' "$expression" \
      'json'   "$json" \
      'output' "$output" \
      | batslib_decorate 'json matches' \
      | fail
    fi
  done
}

# Usage: assert_json_output <jq_expression> [<jq_expression> ...]
# Example: assert_json_output '.name == "TestProject"'
assert_json_output() {
   assert_json "${output?}" "$@"
}

# Usage: refute_json_output <jq_expression> [<jq_expression> ...]
# Example: refute_json_output '.name == "NonExistentProject"'
refute_json_output() {
   refute_json "${output?}" "$@"
}
