#!/bin/bash

green="\e[0;32m"
magenta="\e[0;35m"
cyan="\e[0;36m"
bold_cyan="\e[1;36m"
yellow="\e[0;33m"
red="\e[0;31m"
blue="\e[0;34m"
reset="\e[0m"
source_note_color="\e[36;40m"

script_file=$(echo "$0" | grep -oE "[a-zA-Z0-9_]+.sh$")

function logstyle-printf() {
    elapsed_minutes=$(bc <<< "scale=2; $SECONDS/60")
    units="m"
    printf "$source_note_color[$script_file $elapsed_minutes$units%5d]$reset $1"
}

current_branch=$(git branch | grep '^* ')
if [[ "$current_branch" != "* main" ]]; then
    logstyle-printf "$red""Do autoreleasing from branch main.$reset\n"
    exit
fi

release_to_branch="prerelease"

FOUND_VERSION_CHANGE=0
FOUND_ANOTHER_CHANGE=0
status=$(git status -s |
{
while IFS= read -r line
  do
    is_modified_file=$(echo "$line" | grep -oE '^ ?M')
    if [[ "$is_modified_file" == ' M' || "$is_modified_file" == 'M' ]]; then
        if [[ "$line" == ' M spatialprofilingtoolbox/version.txt' ]]; then
            FOUND_VERSION_CHANGE=1
        else
            FOUND_ANOTHER_CHANGE=1
        fi
    fi

    is_added_file=$(echo "$line" | grep -oE '^A[M ] ')
    if [[ "$is_added_file" != "" ]]; then
        FOUND_ANOTHER_CHANGE=1
    fi
done

if [[ ( "$FOUND_VERSION_CHANGE" == "1" ) && ( "$FOUND_ANOTHER_CHANGE" == "1" ) ]]; then
    echo "11"
fi

if [[ ( "$FOUND_VERSION_CHANGE" == "0" ) ]]; then
    echo "0x"
fi
})

if [[ "$status" == "11" ]];
then
    logstyle-printf "$red""Version has changed, but found another change. Not ready to autorelease.$reset\n"
    exit
fi

if [[ "$status" == "0x" ]];
then
    logstyle-printf "$red""Version has not changed, so not ready to autorelease.$reset\n"
    logstyle-printf "$yellow""Maybe you need one last commit?$reset\n"
    exit
fi

logstyle-printf "$green""Ready to autorelease: Version is updated, and everything else under version control is unmodified.$reset\n"
logstyle-printf "$green""Building package.$reset\n"
if test -d 'dist'; then
    rm dist/*
fi
python3 -m build 1>/dev/null
logstyle-printf "$green""Built:$reset\n"
for f in dist/*;
do
    logstyle-printf "$yellow""    $f$reset\n"
done

installed=$(pip3 freeze | grep spatialprofilingtoolbox | wc -l)
if [[ "$installed" == "1" ]]; then
    pip3 uninstall -y spatialprofilingtoolbox 1>/dev/null 2> stderr.txt
fi

function clean_exit() {
    deactivate
    rm -rf venv/
    exit
}

logstyle-printf "$green""Installing wheel into virtual environment.$reset\n"
python3 -m venv venv
source venv/bin/activate
for wheel in dist/*.whl;
do
    pip install $wheel 1>/dev/null 2> stderr.txt
done

pip install pytest 1>/dev/null 2> stderr.txt

logstyle-printf "$green""Running unit tests.$reset\n"
cd tests/
outcome=$(python -m pytest -q . | tail -n1 | grep "[0-9]\+ \(failed\|errors\)")
if [[ ! "$outcome" == "" ]]; then
    logstyle-printf "$red""Something went wrong in unit tests.$reset\n"
    clean_exit
fi

logstyle-printf "$green""Running integration tests.$reset\n"
outcome=$(./tests_integration.sh | tail -n1 | grep "all [0-9]\+ SPT workflows integration tests passed in")
if [[ "$outcome" == "" ]]; then
    logstyle-printf "$red""Something went wrong in integration tests.$reset\n"
    clean_exit
fi

cd ..
deactivate
rm -rf venv/

source tests/cleaning.sh
_cleanup

# Just for testing autorelease! Remove this
exit
exit
exit

version=$(cat spatialprofilingtoolbox/version.txt)
logstyle-printf "$green""Committing this version:$reset$bold_cyan v$version$reset\n"
git add spatialprofilingtoolbox/version.txt 1>/dev/null 2> stderr.txt && \
    git commit -m "Autoreleasing v$version" 1>/dev/null 2> stderr.txt && \
    git tag v$version 1>/dev/null 2> stderr.txt && \
    git push 1>/dev/null 2> stderr.txt && \
    git push origin v$version 1>/dev/null 2> stderr.txt && \
    logstyle-printf "$green""Pushed ""$bold_cyan""v$version$reset$green on remote branch$reset$yellow main$reset$green .\n" && \
    logstyle-printf "$green""Migrating updates to $reset$yellow$release_to_branch$reset$green branch.$reset\n" && \
    rm spatialprofilingtoolbox/version.txt && \
    git checkout $release_to_branch 1>/dev/null 2> stderr.txt && \
    git merge main 1>/dev/null 2> stderr.txt && \
    git push 1>/dev/null 2> stderr.txt && \
    git checkout main 1>/dev/null 2> stderr.txt && \
    logstyle-printf "$green""Uploading to PyPI.$reset\n" && \
    python3 -m twine upload --repository spatialprofilingtoolbox dist/* && \
    logstyle-printf "$green""Done.$reset\n"
