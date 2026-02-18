---
name: monitor-slack
description: Monitors a set of Slack channels. Summarizes what is happening in different channels
disable-model-invocation: true
allowed-tools: mcp__slack__search_messages
---

## Slack channels

Here is the list of channels to monitor grouped by product:

Pulp (Calunga):
- `forum-calunga`
- `wg-packages-redhat-com-ui`

Red Hat Artifact Signer (RHTAS):
- `rhtas-support`
- `team-trusted-artifact-signer`
- `forum-trusted-artifact-signer`

Red Hat Trusted Profile Analizer (RHTPA):
- `forum-rhda`
- `forum-trusted-profile-analyzer`
- `rhtpa-support`
- `team-trusted-profile-analyzer`

Red Hat Advanced Developer Suite (RHADS):
- `forum-rhads`
- `forum-rhads-ecosystem`
- `forum-tsd-lounge`
- `team-trusted-software-delivery`

Trusted Software Development(TSD-UI):
- `tsd-ui`

Migration Tool for Applications (MTA):
- `forum-mta`

Artificial intelligence:
- `forum-pnd-ai-community`
- `forum-pnd-ai-community`
- `forum-skillsacademy-ai`

## What to monitor

> use `search_messages` tool for fetching messages

- Messages
- Threads
  - Always summarize the thread

## Outcome

- Make a summary of the messages and consider only today's messages
  - Write the final output in a markdown file `monitor/slack/dd-month-year-channels.md` file inside this repository
- Identify common patterns or conversations between all channels.
  - Make a summary of common things happening
  - Understand how all channels and projects are working for me to better understand the whole ecosystem
  - Write the final output in a markdown file `monitor/slack/dd-month-year-summary.md` file inside this repository
