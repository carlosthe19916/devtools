Make a plan to standarize the content of the devcontainer definitions.
- The objective if for the devcontainers to have similar directory structure.
- Similar script content
- Similar configuration
- Reduce the duplicate code and files

Understand the groups core, plugins, service, common, and ui. I don't neccesarily want equal configuration

I already made some progress with the pulp-dev-common, but I need you to enhance it.

## Core

[pulpcore](devcontainer/github.com/pulp/pulpcore) Is the core devcontainer that in theory can be self independent

## Plugins
The plugins are repositories that extend pulpcore
- [pulp_maven](devcontainer/github.com/pulp/pulp_maven)
- [pulp_python](devcontainer/github.com/pulp/pulp_python)

## Pulp-service
Pulp service is a wrapper for pulpcore + plugins

## Pulp-dev-common
is an effort to standarize and reduce the duplicate logic among all of them

## pulp-ui and pulp-ui-2
Only ui repositories, leave them alone as they are