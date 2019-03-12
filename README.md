# DCP Workspace

This provides a containerized environment and tooling to safely perform operations on the DSS. Likely useful for other projects as well.

## Usage

All commands require a running [Docker](https://www.docker.com/) daemon.

To spawn a new workspace for a deployment, or reconnect to an existing workspace,

```
./workspace.sh {deployment}
```

For instance, `./workspace.sh staging`.

`deployment`  may be omitted to perform operations on `dev`.

To stop and delete a workspace

```
./kill.sh {deployment}
```

Additionally, workspace instances may be managed with standard Docker commands.

## Configuration

The default repoository, and deployments, are configured in `startup/config.json`.


## Security and Credentials

The workspace will attempt to pull in credentials from `~/.git-credentials`, `~/.aws`, and `~/.google`. when entering
any directory in the workspace, `environment` and `environment.{deployment}` will be sourced if present.

[git-secrets](https://github.com/awslabs/git-secrets) is configured for all repositores cloned inside the workspace.
