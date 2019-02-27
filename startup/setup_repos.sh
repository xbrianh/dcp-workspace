#!/bin/bash
set -euo pipefail

echo ${DCP_WORKSPACE_REPOS}
for repo_url in ${DCP_WORKSPACE_REPOS}; do
	git clone $repo_url
done
