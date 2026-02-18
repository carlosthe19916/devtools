---
name: monitor-github
description: Monitors a set of github repositories. Tells me what to focus on next
disable-model-invocation: true
allowed-tools: Bash(gh auth status), Bash(gh issue view *), Bash(gh issue list *), Bash(gh pr view *), Bash(gh pr list *), Bash(gh search prs *), Bash(gh search issues *)
---

Use `gh` and use my username `carlosthe19916`

## Git repositories

Here is the list of repositories to monitor:
- https://github.com/guacsec/trustify-ui/
- https://github.com/guacsec/trustify/
- https://github.com/securesign/rhtas-console-ui/
- https://github.com/securesign/rhtas-console/
- https://github.com/pulp/pulp-ui-2/
- https://github.com/redhat-appstudio/tssc-backstage-plugins

## What to monitor

- Pull Requests
  - I opened
  - Where I am a reviewer
  - Where I am participating in
- Issues
  - Are assigned to me
  - Where I am participating in
  - Reported in the last 7 days

## Outcome

- Make a list of all the tasks I need to do. Organize it by repository and type of action. Pull Request reviews take higher priority.
- If Pull Request:
  - Add a Green Checkbox if I added my review already

Write the final output in a markdown file `monitor/github/dd-month-year.md` file inside this repository