#!/bin/bash

#set -x
#PS4='$LINENO: '

namefile="name.txt"

sleeptime="0.2s"

function valid() {
	name="$1"

	echo "$name" | tr ' ' '_'  | tr '.' '-'
}

function node() {
	name="$1"
	echo "$name" > "$namefile"
	git add "$namefile" > /dev/null 2>&1
	git commit -m "$name" > /dev/null 2>&1
}

function orphan() {
	name="$1"
	echo "Creating orphan $name..."
	git checkout --orphan "$(valid "$name")" > /dev/null 2>&1
	node "$name"
	sleep "$sleeptime"
}

function child() {
	parent1="$1"
	parent2="$2"
	child="$3"

	git checkout "$(valid "$parent1")" > /dev/null 2>&1
	echo "Love is in the air..."
	git branch "$(valid "$child")" > /dev/null 2>&1
	git checkout "$(valid "$child")" > /dev/null 2>&1
	sleep "$sleeptime"
	echo "Creating child $child of $parent1 and $parent2..."
	git merge --allow-unrelated-histories --no-commit --no-ff --no-edit "$(valid "$parent2")" > /dev/null 2>&1
	node "$child"
	sleep "$sleeptime"
}

function notExists() {
	name="$1"
	if test -z "$(git branch | tr '*' ' ' | awk '{print $1}' | grep "$(valid "$name")")"; then	
		return 0
	else
		return 1
	fi
}

mkdir -p ./repo
pushd ./repo || exit 1

treefile="../$1"

rm -rf ".git"
rm *
git init > /dev/null 2>&1

while read -r line; do
	parent1="$(echo "$line" | awk -F, '{print $1}')"
	parent2="$(echo "$line" | awk -F, '{print $2}')"
	child="$(echo "$line" | awk -F, '{print $3}')"

	if notExists "$parent1"; then
		orphan "$parent1"
	fi
	if notExists "$parent2"; then
		orphan "$parent2"
	fi

	child "$parent1" "$parent2" "$child"
done < "$treefile"

popd || exit 1

