## What needs to be done:
Create devcontainer definitions for:
 - devcontainer/github.com/pulp/pulpcore
 - devcontainer/github.com/pulp/pulp_maven
 - devcontainer/github.com/pulp/pulp_python

## Rules
- Do not modify anything from - devcontainer/github.com/pulp/pulp_plugin_template
- devcontainer/github.com/pulp/pulp_maven and devcontainer/github.com/pulp/pulp_python should follow almost equal code since they both are plugings


## Guideline
### Step 1
 execute:
```shell
devcontainer/github.com/pulp/pulp_plugin_template/generate.sh core
devcontainer/github.com/pulp/pulp_plugin_template/generate.sh maven python
```

the command above will generate:
 - devcontainer/github.com/pulp/pulpcore
 - devcontainer/github.com/pulp/pulp_maven
 - devcontainer/github.com/pulp/pulp_python

Those devcontainer definitions are proven to work and are the result of - devcontainer/github.com/pulp/pulp_plugin_template

### Step 2
use devcontainer/github.com/pulp/pulp-service as a directory structure template
and refactor the following devcontainers to follow the same structure and patterns:
 - devcontainer/github.com/pulp/pulpcore
 - devcontainer/github.com/pulp/pulp_maven
 - devcontainer/github.com/pulp/pulp_python

### Step 3
Take any feature present at devcontainer/github.com/pulp/pulp-service but not present at:
 - devcontainer/github.com/pulp/pulpcore
 - devcontainer/github.com/pulp/pulp_maven
 - devcontainer/github.com/pulp/pulp_python
And enrich the new devcontainers

### Step 4
Verify that the original outputs:
 ```shell
devcontainer/github.com/pulp/pulp_plugin_template/generate.sh core
devcontainer/github.com/pulp/pulp_plugin_template/generate.sh maven python
```
are aligned with the new devcontainer definitions. 
Warning: executing the generate.sh script will overwrite the files so you need to tweak temporarily the script so the output is done somewhere else so you can compare both outputs
