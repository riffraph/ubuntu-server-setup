#!/bin/bash

set -ex

####
#   Loop through all the Vagrantfiles in the /Vagrant dir and run the unit tests (unit-tests.sh) against them
#   Test results are stored in the /results dir
###

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function runUnitTest() {
    local results_filename=${1}

    vagrant up
    vagrant ssh -c "cd /vagrant/tests; bash unit-tests.sh > results/${results_filename}.txt 2>&1"
    vagrant destroy -f
    rm -rf "Vagrantfile"
}

currentDir=$(getCurrentDir)

for file in "${currentDir}"/Vagrant/*; do
    filename=$(basename "${file}")
    cp "${currentDir}/Vagrant/${filename}" "${currentDir}/../Vagrantfile"
    cd "${currentDir}/../"
    runUnitTest "${filename}"
done
