function setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
}

@test 'bats-assert is installed and accessible' {
    run assert_equal 'batslib_print_kv_single' 'batslib_print_kv_single'
    assert_success
}
