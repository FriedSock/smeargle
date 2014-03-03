#!/bin/bash

set -e

search_term=$1

function main {
  for rev in `revisions`; do
    echo;
    echo "revision: `long_hash`";
    echo "parent: `parent`";
    echo "commit_message: `commit_msg`";
    echo "----SEPERATOR----";
  done
}

function revisions {
  git log --oneline | grep "$search_term" | cut -d ' ' -f 1
}

function long_hash {
  git rev-parse $rev
}

function parent {
  git show --pretty=raw $rev | grep -e '^parent [a-z0-9]*$' | cut -f 2 -d ' '
}

function commit_msg {
  git log -n 1 --pretty=format:"((%s)) %b" $rev
}

main

