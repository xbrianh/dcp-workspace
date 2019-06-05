#!/bin/bash
set -euo pipefail

# install vim plugins
vim +PluginInstall +qall 2>&1 > /dev/null

config=$(echo ${1:-""} | sed 's/\\"/"/g' | jq -c .)

if [[ ${config} ]]; then
    # configure the GCP project
    gcp_project=$(echo ${config} | jq -r .profiles.${DEPLOYMENT}.gcp_project)
    gcloud config set project ${gcp_project}
    
    if [[ -d ~/.aws ]]; then
        # set the AWS_PROFILE env var, inline into bashrc
        aws_profile=$(echo ${config} | jq -r .profiles.${DEPLOYMENT}.aws_profile)
        echo "export AWS_PROFILE=${aws_profile}" >> ~/.bashrc
    fi

    # Configure git
	git_config=$(echo ${config} | jq .git)
	if [[ ${git_config} != null ]]; then
        git config --global credential.helper store
        git config --global user.name "$(echo ${git_config} | jq -r .name)"
        git config --global user.email "$(echo ${git_config} | jq -r .email)"
    fi
    
    # Clone repos
    mkdir ~/.virtualenvs
    for repo in $(echo ${config} | jq -r .repositories[].url); do
        branch=$(echo ${config} | jq -r --arg n $repo '.repositories[] | select(.url==$n)' | jq -r .deployments.${DEPLOYMENT}.branch)
        git clone --branch ${branch} $repo
        repo_name=$(basename $repo | cut -d '.' -f 1)
    	repo_home=$(pwd -P)/$repo_name
        venv_dir=~/.virtualenvs/${repo_name}_venv
    	/usr/local/bin/virtualenv -p /usr/bin/python3 ${venv_dir}
        if [[ -e $repo_home/requirements.txt ]]; then
            (cd $repo_home && ${venv_dir}/bin/pip install -r requirements.txt)
        fi
        if [[ -e ${repo_home}/requirements-dev.txt ]]; then
            (cd $repo_home && ${venv_dir}/bin/pip install -r requirements-dev.txt)
        fi
    done
fi

sudo /etc/init.d/ssh start
sleep 1000000
