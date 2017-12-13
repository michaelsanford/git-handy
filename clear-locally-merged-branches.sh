#!/bin/bash
MERGED_INTO=${1:-"develop"}

statistics() {
  echo
  echo "Remaining local branches:"
  git branch

  echo
  echo "These local branches are not merged into ${MERGED_INTO}:"
  git branch --no-merged ${MERGED_INTO}

  echo
  echo "Size of local repo: $(git count-objects)"

  git status
}

error () {
  echo "WARNING: Something went wrong. Aborting..."
  if [[ ${1} ]]; then echo "The previous command exited with ${?}"; fi

  echo "This is the current state of your working copy:"
  git status
}

confirm () {
  read -r -p "Are you sure? [y/N] " response
  case ${response} in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
     echo "Ok, aborting..."
     echo
     false
     ;;
  esac
}

check_on_main_branch() {
  local current_branch;
  current_branch=$(git symbolic-ref -q --short HEAD)
  if [ "${current_branch}" != "${MERGED_INTO}" ]; then
    echo "You should be on '${MERGED_INTO}' for this operation. I can switch branches for you."
    confirm && git checkout "${MERGED_INTO}" || error $?
  fi
}

delete_local_merged_branches() {
  git branch --merged ${MERGED_INTO} | egrep -v "(^\*|${MERGED_INTO})" | xargs git branch --delete
}

# Step 1
echo "Fetching remote branch state"
git fetch --all

# Step 2
echo "The following local branches have been merged into ${MERGED_INTO} and will be deleted locally:"
git branch --merged ${MERGED_INTO} | egrep -v "(^\*|${MERGED_INTO})"
confirm && delete_local_merged_branches

# Step 3
echo "Would you like to run the garbage collector?"
confirm && \
 echo "Before garbage collecting: $(git count-objects)" && \
 git gc

trap statistics EXIT
trap error SIGHUP SIGINT SIGTERM
