#!/bin/sh

# MIT License
#
# Copyright (c) 2024 Stephan Michard
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Based on https://github.com/smichard/conventional_changelog

# Exit on error
set -e

# Error handling
trap 'echo "An error occurred at line $LINENO. Exiting."' ERR

# Path to the Git repository (current directory)
REPO_DIR="."
CHANGELOG_FILE="$REPO_DIR/CHANGELOG.md"
GITHUB_REPO_URL=$(git remote get-url origin 2>/dev/null | sed "s/\.git$//")
if [ -z "$GITHUB_REPO_URL" ]; then
	GITHUB_REPO_URL=0
fi

echo "Starting changelog generation script..."
echo "Repository:"
echo $GITHUB_REPO_URL
# Create or clear the changelog file
> $CHANGELOG_FILE

# Add the introductory text to the changelog
#echo "# Changelog" >> $CHANGELOG_FILE
#echo "" >> $CHANGELOG_FILE
#echo "All notable changes to this project will be documented in this file." >> $CHANGELOG_FILE
#echo "" >> $CHANGELOG_FILE
#echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)." >> $CHANGELOG_FILE
#echo "" >> $CHANGELOG_FILE

# Go to the repository directory
cd $REPO_DIR

# Define categories
CATEGORIES="feat fix ci perf docs test chore refactor"

# Regular expression for matching conventional commits
CONVENTIONAL_COMMIT_REGEX="^.* (feat|fix|ci|perf|docs|test|chore|refactor)(\(.*\))?: "

print_tag() {
	echo "Processing tag: $2"
	TAG_DATE=$(git log -1 --format=%ai $2 | cut -d ' ' -f 1)
	if [ "$2" = "HEAD" ]; then
		if [ $(git rev-parse $1) != $(git rev-parse "HEAD") ]; then
			echo "## Unreleased changes" >> $CHANGELOG_FILE
			echo "" >> $CHANGELOG_FILE
		fi
	else
		echo "## $2 ($TAG_DATE)" >> $CHANGELOG_FILE
		echo "" >> $CHANGELOG_FILE
	fi


	# Collect all commits for this tag range
	ALL_COMMITS=$(git log $1..$2 --oneline --always)

	# Process each category
	for KEY in $CATEGORIES; do
		CATEGORY_COMMITS=$(echo "$ALL_COMMITS" | grep -E "^.* $KEY(\(.*\))?: " || true)
		if [ ! -z "$CATEGORY_COMMITS" ]; then
			case $KEY in
				"feat") CATEGORY_NAME="Feature" ;;
				"fix") CATEGORY_NAME="Bug Fixes" ;;
				"ci") CATEGORY_NAME="Continuous Integration" ;;
				"perf") CATEGORY_NAME="Performance Improvements" ;;
				"docs") CATEGORY_NAME="Documentation" ;;
				"test") CATEGORY_NAME="Test" ;;
				"chore") CATEGORY_NAME="Chore" ;;
				"refactor") CATEGORY_NAME="Refactor" ;;
			esac
			echo "### $CATEGORY_NAME" >> $CHANGELOG_FILE
			echo "Listing commits for category: $CATEGORY_NAME under tag $2"
			echo "$CATEGORY_COMMITS" | while read -r COMMIT; do
				HASH=$(echo $COMMIT | awk '{print $1}')
				MESSAGE=$(echo $COMMIT | sed -E "s/^$HASH $KEY(\(.*\))?: //")
				PR_NUMBER=$(echo $MESSAGE | grep -oE '#[0-9]+' | tr -d '#')
				MESSAGE=$(echo $MESSAGE | sed -E '$s/ \(#$PR_NUMBER\)//')
				SCOPE=$(echo $COMMIT | sed -E "s/^$HASH $KEY(\((.*?)\))?: .*/\2/")
				if [ "$GITHUB_REPO_URL" != "0" ]; then
					if [ -n "$SCOPE" ]; then
						echo "- ($SCOPE) $MESSAGE ($GITHUB_REPO_URL/pull/$PR_NUMBER)" >> $CHANGELOG_FILE
					else
						echo "- $MESSAGE ($GITHUB_REPO_URL/pull/$PR_NUMBER)" >> $CHANGELOG_FILE
					fi
				else
					if [ -n "$SCOPE" ]; then
						echo "- ($SCOPE) $MESSAGE" >> $CHANGELOG_FILE
					fi
				fi
			done
			echo "" >> $CHANGELOG_FILE
		fi
	done

	# Process 'Other' category
	OTHER_COMMITS=$(echo "$ALL_COMMITS" | grep -v -E "$CONVENTIONAL_COMMIT_REGEX" || true)
	if [ ! -z "$OTHER_COMMITS" ]; then
		echo "### Other" >> $CHANGELOG_FILE
		echo "Listing commits for category: Other under tag $2"
		echo "$OTHER_COMMITS" | while read -r COMMIT; do
			HASH=$(echo $COMMIT | awk '{print $1}')
			MESSAGE=$(echo $COMMIT | sed -E 's/^[^ ]* //')
			PR_NUMBER=$(echo $MESSAGE | grep -oE '#[0-9]+' | tr -d '#')
			MESSAGE=$(echo $MESSAGE | sed -E '$s/ \(#$PR_NUMBER\)//')
			if [ "$GITHUB_REPO_URL" != "0" ]; then
				echo "- $MESSAGE ($GITHUB_REPO_URL/pull/$PR_NUMBER)" >> $CHANGELOG_FILE
			else
				echo "- $MESSAGE" >> $CHANGELOG_FILE
			fi
		done
		echo "" >> $CHANGELOG_FILE
	fi

	echo "Completed processing tag: $2"
	# Update the previous tag
}

# Iterate over tags
# Get the commit hash from 2 weeks ago
TWO_WEEKS_AGO_COMMIT=$(git rev-list -n 1 --before="2 weeks ago" HEAD)

# Check if the commit hash was found
if [ -z "$TWO_WEEKS_AGO_COMMIT" ]; then
	echo "No commit found from 2 weeks ago. Exiting."
	exit 1
fi

if [ -n "$1" ] && [ -n "$2" ]; then
	print_tag $1 $2
else
	print_tag $TWO_WEEKS_AGO_COMMIT HEAD
fi

echo "Changelog generation complete."
