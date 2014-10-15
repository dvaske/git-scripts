#!/bin/bash
# Script to clean up old and merged branches
# Only checks remotes/origin branches
# All branches which are merged (pointing to a commit with children) are
# considered for deletion. Also all branches that points to leaf nodes in the
# history tree, but are more than 2 months old are considered for deletion.
# Author: Aske Olsson

# sha-ids of all branches with no children
leaf_ids=$(git rev-list --remotes --children | grep -v ' ' | sort)
# list of all branches: name sha commit-subject
all_branches=$(git branch -a -v --no-abbrev | sed 's/..//' | grep remotes/origin)

# Merged branches are not leafs
echo "$leaf_ids" > leaf_ids
echo "$all_branches" > all_branches
merged=$(grep -F -v -f leaf_ids all_branches | cut -f 1 -d " ")
# also store name of leafs
leafs=$(grep -F -f leaf_ids all_branches | cut -f 1 -d " ")
echo "$leafs" > leafs

# Find all the active branches, i.e. branches updated within the last 2 months:
git for-each-ref --sort='-committerdate' --format='%(committerdate:relative)%09%(refname)' refs/remotes/origin | sed -n '/3 months/q;p' | cut -f 2 | sed -e 's-refs/--' >active_by_comitter
git for-each-ref --sort='-authordate' --format='%(authordate:relative)%09%(refname)' refs/remotes/origin | sed -n '/3 months/q;p' | cut -f 2 | sed -e 's-refs/--' >active_by_author
active_branches=$(sort -u active_by_comitter active_by_author)

echo "$active_branches" > active_branches

inactive_leafs=$(grep -xvF -f active_branches leafs)

echo "Branches that qualify for deletion"
for b in $merged; do echo "$b  -merged"; done
for b in $inactive_leafs; do echo "$b  -inactive but leaf node"; done

rm -f active_branches active_by_author active_by_comitter leaf_ids leafs all_branches

