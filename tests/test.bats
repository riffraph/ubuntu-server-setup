#!/bin/bash

load 'lib/bats-support/load'
load 'lib/bats-assert/load'
load 'lib/bats-files/load'
    

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    MANAGE_CACHE_SCRIPT="${DIR}/../templates/manage-cache.sh"
}


## What features do i want?
## Observability
# 1. a way to reconcile and observe what is and isn't backed up
# 2. a way to view what folders are cached

## Cache management
# 1. cache based on retain list
# 2. delete from cache if not in retain list and files are backed up


## Observability tests

@test ".reconcile requires 2 folders to compare" {
    
}


# @test ".check_required_environment requires CI_COMMIT_REF_SLUG environment variable" {
#   unset CI_COMMIT_REF_SLUG
#   assert_empty "${CI_COMMIT_REF_SLUG}"
#   source ${profile_script}
#   run check_required_environment
#   assert_failure
#   assert_output --partial "CI_COMMIT_REF_SLUG"
# }

# @test ".check_required_environment requires CI_PROJECT_NAME environment variable" {
#   unset CI_PROJECT_NAME
#   assert_empty "${CI_PROJECT_NAME}"
#   source ${profile_script}
#   run check_required_environment
#   assert_failure
#   assert_output --partial "CI_PROJECT_NAME"
# }

# @test ".check_required_environment is successful if required environment is present" {
#   source ${profile_script}
#   run check_required_environment
#   assert_success
# }



# @test "" {
# }


@test "should return concatenated strings" {
    run ${MANAGE_CACHE_SCRIPT} 'Hello ' 'Baeldung' '/tmp/output'

    assert_output 'Hello Baeldung'
}


teardown() {
    rm -f /tmp/output
}