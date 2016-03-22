#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/query/show.sh

# Default entries
declare -r TEST_QUERY_API_ID="123-456-7890"
declare -r TEST_QUERY_API_VERSION="v201601"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -r TEST_QUERY_INVALID_METHOD="UPDATE RV_REPORT SET R='v'"
# > Show
declare -r TEST_QUERY_BASIC_SHOW="SHOW TABLES"
declare -r TEST_QUERY_BASIC_SHOW_REQUEST='([FULL]="0" [QUERY]="SHOW TABLES" [STATEMENT]="SHOW TABLES" [METHOD]="show" )'
declare -r TEST_QUERY_FULL_SHOW="show full tables"
declare -r TEST_QUERY_FULL_SHOW_REQUEST='([FULL]="1" [QUERY]="show full tables" [STATEMENT]="show full tables" [METHOD]="show" )'
declare -r TEST_QUERY_FULL_LIKE_SHOW="SHOW FULL TABLES LIKE \"CAMPAIGN%\""
declare -r TEST_QUERY_FULL_LIKE_SHOW_REQUEST='([FULL]="1" [QUERY]="SHOW FULL TABLES LIKE \"CAMPAIGN%\"" [STATEMENT]="SHOW FULL TABLES" [LIKE]="CAMPAIGN%" [METHOD]="show" )'
declare -r TEST_QUERY_LIKE_SHOW="show tables like 'CAMPAIGN%'"
declare -r TEST_QUERY_LIKE_SHOW_REQUEST="([FULL]=\"0\" [QUERY]=\"show tables like 'CAMPAIGN%'\" [STATEMENT]=\"show tables\" [LIKE]=\"CAMPAIGN%\" [METHOD]=\"show\" )"
declare -r TEST_QUERY_INCOMPLETE_LIKE_SHOW="SHOW TABLES LIKE"
declare -r TEST_QUERY_EMPTY_LIKE_SHOW="SHOW TABLES LIKE \"\""
declare -r TEST_QUERY_EMPTY_LIKE_SHOW_REQUEST='([FULL]="0" [QUERY]="SHOW TABLES LIKE \"\"" [STATEMENT]="SHOW TABLES" [LIKE]="" [METHOD]="show" )'
declare -r TEST_QUERY_FULL_WITH_SHOW="show full tables with 'ViewThroughConversions'"
declare -r TEST_QUERY_FULL_WITH_SHOW_REQUEST="([FULL]=\"1\" [QUERY]=\"show full tables with 'ViewThroughConversions'\" [STATEMENT]=\"show full tables\" [METHOD]=\"show\" [WITH]=\"ViewThroughConversions\" )"
declare -r TEST_QUERY_WITH_SHOW="SHOW TABLES WITH 'ViewThroughConversions'"
declare -r TEST_QUERY_WITH_SHOW_REQUEST="([FULL]=\"0\" [QUERY]=\"SHOW TABLES WITH 'ViewThroughConversions'\" [STATEMENT]=\"SHOW TABLES\" [METHOD]=\"show\" [WITH]=\"ViewThroughConversions\" )"
declare -r TEST_QUERY_EMPTY_WITH_SHOW="SHOW TABLES WITH \"\""
declare -r TEST_QUERY_EMPTY_WITH_SHOW_REQUEST='([FULL]="0" [QUERY]="SHOW TABLES WITH \"\"" [STATEMENT]="SHOW TABLES" [METHOD]="show" [WITH]="" )'
declare -r TEST_QUERY_INCOMPLETE_WITH_SHOW="SHOW TABLES WITH"
declare -r TEST_QUERY_INCOMPLETE_SHOW="SHOW"
declare -r TEST_QUERY_STUPID_SHOW="SHOW TABLES WITH 'ViewThroughConversions rv'"


readonly TEST_QUERY_SHOW_COMPONENTS="-11-01-21-21-01-01-01-21-01-01-01-01-21-21"

function test_awqlShowQuery ()
{
    local test

    #1 Check nothing
    test=$(awqlShowQuery)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_QUERY}" ]] && echo -n 1

    #2 Check with valid query
    test=$(awqlShowQuery "${TEST_QUERY_BASIC_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_BASIC_SHOW_REQUEST}" ]] && echo -n 1

    #3 Check with update query
    test=$(awqlShowQuery "${TEST_QUERY_INVALID_METHOD}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1

    #4 Check with incomplete show query
    test=$(awqlShowQuery "${TEST_QUERY_INCOMPLETE_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #5 Check with full query in lowercase
    test=$(awqlShowQuery "${TEST_QUERY_FULL_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_SHOW_REQUEST}" ]] && echo -n 1

    #6 Check with full query like in uppercase
    test=$(awqlShowQuery "${TEST_QUERY_FULL_LIKE_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_LIKE_SHOW_REQUEST}" ]] && echo -n 1

    #7 Check with query like in lowercase
    test=$(awqlShowQuery "${TEST_QUERY_LIKE_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_LIKE_SHOW_REQUEST}" ]] && echo -n 1

    #8 Check with incomplete query like
    test=$(awqlShowQuery "${TEST_QUERY_INCOMPLETE_LIKE_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #9 Check with empty query like
    test=$(awqlShowQuery "${TEST_QUERY_EMPTY_LIKE_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_EMPTY_LIKE_SHOW_REQUEST}" ]] && echo -n 1

    #10 Check with full query with and use upper or lower case
    test=$(awqlShowQuery "${TEST_QUERY_FULL_WITH_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_WITH_SHOW_REQUEST}" ]] && echo -n 1

    #11 Check with query with in vertical display
    test=$(awqlShowQuery "${TEST_QUERY_WITH_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_WITH_SHOW_REQUEST}" ]] && echo -n 1

    #12 Check with empty query with
    test=$(awqlShowQuery "${TEST_QUERY_EMPTY_WITH_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_EMPTY_WITH_SHOW_REQUEST}" ]] && echo -n 1

    #13 Check with incomplete query with
    test=$(awqlShowQuery "${TEST_QUERY_INCOMPLETE_WITH_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #14 Check with incomplete query with
    test=$(awqlShowQuery "${TEST_QUERY_STUPID_SHOW}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlShowQuery" "${TEST_QUERY_SHOW_COMPONENTS}" "$(test_awqlShowQuery)"