#!/bin/bash
# This script is intended to run once during container startup
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
home="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# Execute startup scripts
for name in $home/*; do
    echo $name
    if [[ $(basename $name) != "startup.sh" ]]; then
        if [[ -x $name ]]; then
            $name
        fi
    fi
done

# install vim plugins
vim +PluginInstall +qall 2>&1 > /dev/null

# configure the GCP project
gcp_project=$(cat ~/.startup/config.json | jq -r .deployments.${DEPLOYMENT}.gcp_project)
gcloud config set project ${gcp_project}

if [[ -d ~/.aws ]]; then
    # set the AWS_PROFILE env var, inline into bashrc
    aws_profile=$(cat ~/.startup/config.json | jq -r .deployments.${DEPLOYMENT}.aws_profile)
    echo "export AWS_PROFILE=${aws_profile}" >> ~/.bashrc
fi

# Create a venv
venv_name=dcp
mkdir ~/.virtualenvs
/usr/local/bin/virtualenv -p /usr/bin/python3 ~/.virtualenvs/${venv_name}
echo "source ~/.virtualenvs/${venv_name}/bin/activate" >> ~/.bashrc

# Clone repo
repo=$(cat ~/.startup/config.json | jq -r .repository)
branch=$(cat ~/.startup/config.json | jq -r .deployments.${DEPLOYMENT}.branch)
git clone --branch ${branch} $repo
repo_home=$(basename $repo | cut -d '.' -f 1)
(cd $repo_home && ~/.virtualenvs/${venv_name}/bin/pip install -r requirements-dev.txt)
