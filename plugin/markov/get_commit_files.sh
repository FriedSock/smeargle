#!/bin/bash

set -e

function main {
  for rev in `revisions`; do
    echo;
    echo "revision: $rev";
    echo "files: `files`";
    echo "----SEPERATOR----";
  done
}

function revisions {
  git log --all --oneline | cut -d ' ' -f 1
}

function long_hash {
  git rev-parse $rev
}

function files {
  git diff-tree --no-commit-id --name-only -r $rev
}

main

