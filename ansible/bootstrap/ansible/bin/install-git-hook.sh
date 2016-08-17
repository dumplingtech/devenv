#!/bin/bash -e

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
repo_dir=$(dirname $(dirname ${dir}))/.git

if [ ! -d ${repo_dir}/hooks ]; then
    echo "Git hooks directory not found: ${repo_dir}/hooks"
    exit 1
fi

cp -v ${dir}/pre-commit ${repo_dir}/hooks/
chmod +x ${repo_dir}/hooks/pre-commit

echo "Okay!"
