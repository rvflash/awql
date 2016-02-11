#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh


readonly TEST_TESTING_BASH_UNIT="-1"

function test_bashUnit ()
{
    echo "-1"
}


readonly TEST_TESTING_LAUNCH_ALL_TESTS="-1"

function test_launchAllTests ()
{
    echo "-1"
}


# Launch all functional tests
bashUnit "bashUnit" "${TEST_TESTING_BASH_UNIT}" "$(test_bashUnit)"
bashUnit "launchAllTests" "${TEST_TESTING_LAUNCH_ALL_TESTS}" "$(test_launchAllTests)"