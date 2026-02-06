# Team AI vs Claude Agent Teams: Comparison

## Overview

**Team AI** is an open-source, file-based inter-agent communication system that enables coordination across different AI tools and IDEs. **Claude Agent Teams** is Anthropic's first-party experimental feature built into Claude Code for orchestrating multiple Claude Code sessions as a coordinated team.

Both aim to solve multi-agent coordination, but they differ significantly in scope, architecture, and philosophy.

## Feature Comparison

| Feature | Team AI | Claude Agent Teams |
|---|---|---|
| **Status** | Stable, community-driven | Experimental, disabled by default |
| **Cross-tool support** | Yes (Claude Code, Cursor, VSCode, Continue, Antigravity, Perplexity) | No (Claude Code only) |
| **Architecture** | Decentralized, peer-to-peer messaging | Centralized, lead-teammate hierarchy |
| **Transport** | Filesystem + MCP (stdio) + CLI | In-process or tmux split panes |
| **Agent discovery** | Registry-based (`registry.json`) | Team config file (`~/.claude/teams/`) |
| **Message format** | YAML frontmatter + Markdown body | Internal Claude Code messaging |
| **Task management** | Per-agent message queues (todo/wip/done) | Shared task list with dependencies |
| **Shared artifacts** | Yes (screenshots, plans, documents) | No dedicated artifact system |
| **Heartbeat/liveness** | Yes (automatic, configurable threshold) | No (relies on process lifecycle) |
| **Broadcast messaging** | Yes (with tag/capability filtering) | Yes (to all teammates) |
| **Plan approval workflow** | No | Yes (read-only plan mode until lead approves) |
| **Delegate mode** | No | Yes (restricts lead to coordination-only) |
| **Session resumption** | Agents persist across sessions via filesystem | Limited (in-process teammates not restored on `/resume`) |
| **Nested coordination** | Flat peer network (any agent can message any other) | No nesting (only lead manages team) |
| **Dependencies** | Bash (core), Node.js (MCP only) | Claude Code CLI |
| **Token overhead** | Minimal (messages are small files) | High (each teammate is a full Claude instance) |
| **Setup complexity** | Install scripts + per-IDE configuration | Single env variable |

## Architecture Comparison

### Team AI: Decentralized File-Based Bus

```
~/.team-ai/
  agents/
    {uuid}/
      metadata.json       # Agent info (name, state, capabilities, git branch)
      incoming/
        todo/             # Pending messages
        wip/              # In-progress messages
        done/             # Completed messages
  artifacts/              # Shared files
  registry.json           # Agent index
```

- **Model**: Any agent registers itself and can message any other agent directly.
- **Protocol**: Filesystem as message bus with directory-based locking for concurrency.
- **Integration**: MCP servers for IDE tools, CLI commands for shell use, hooks for Claude Code.
- **Liveness**: Heartbeat timestamps with automatic cleanup of stale agents (>1 hour).

### Claude Agent Teams: Centralized Lead-Teammate

```
~/.claude/
  teams/{team-name}/
    config.json           # Team members, IDs, types
  tasks/{team-name}/      # Shared task list
```

- **Model**: One lead session spawns and coordinates teammate sessions.
- **Protocol**: Internal Claude Code IPC; teammates auto-deliver messages to lead.
- **Integration**: Built into Claude Code natively. No external tool support.
- **Liveness**: Process-based; teammates notify lead when idle/stopped.

## When to Use Which

### Use Team AI When

- **Cross-tool coordination is needed**: You're running Claude Code, Cursor, and VSCode simultaneously and need agents in different tools to communicate.
- **Persistent agent presence**: You want agents to remain discoverable and contactable across sessions, even after restarts.
- **Loose coupling**: Agents work independently on separate concerns and only need occasional coordination (e.g., "heads up, I changed the auth API").
- **Low token cost**: Communication is file-based and doesn't consume LLM tokens for coordination overhead.
- **Custom tool integration**: You need to integrate agents from tools not supported by Claude Agent Teams.

### Use Claude Agent Teams When

- **Deep Claude Code collaboration**: All agents are Claude Code sessions and need tight coordination with shared task lists and dependency tracking.
- **Structured team workflows**: You want a lead to assign tasks, approve plans, and synthesize results from multiple parallel workers.
- **Parallel exploration**: Multiple agents need to investigate competing hypotheses, review from different angles, or build independent modules simultaneously.
- **Interactive steering**: You want to message individual teammates directly, redirect approaches in real-time, and have the lead orchestrate.
- **Built-in task dependencies**: Tasks have ordering constraints (A must finish before B can start).

### Complementary Use

The two systems are **not mutually exclusive**. A practical setup could use:

- **Claude Agent Teams** for tight intra-team coordination within Claude Code (e.g., a lead + 3 specialists working on a feature).
- **Team AI** for cross-tool awareness (e.g., notifying a Cursor agent about breaking changes made by the Claude Code team).

## Detailed Differences

### Communication Model

| Aspect | Team AI | Claude Agent Teams |
|---|---|---|
| **Topology** | Peer-to-peer mesh | Star (lead at center) |
| **Message routing** | Direct (sender writes to receiver's inbox) | Via lead or direct teammate messaging |
| **Message types** | request, info, query (with priority levels) | Free-form natural language |
| **Message persistence** | Filesystem (survives crashes/restarts) | In-memory (lost on session end) |
| **Artifact sharing** | Dedicated artifact system with file attachments | Via filesystem (agents share working directory) |

### Agent Lifecycle

| Aspect | Team AI | Claude Agent Teams |
|---|---|---|
| **Creation** | Explicit registration via CLI or auto-register on IDE startup | Lead spawns teammates on demand |
| **Discovery** | Registry lookup (`ai-list`) | Team config file |
| **Identity** | UUID + name + capabilities + tags | Name + agent ID + agent type |
| **Termination** | Explicit deregister or automatic cleanup after stale timeout | Lead requests shutdown; teammate can accept/reject |
| **Persistence** | Survives session restarts | Tied to session lifecycle |

### IDE/Tool Support

| Tool | Team AI | Claude Agent Teams |
|---|---|---|
| Claude Code | Full (hooks, skills, CLI) | Native (built-in) |
| Cursor | MCP server | Not supported |
| VSCode/Copilot | MCP server | Not supported |
| Continue | Context provider | Not supported |
| Google Antigravity | MCP server | Not supported |
| Perplexity | MCP server | Not supported |

### Security

| Aspect | Team AI | Claude Agent Teams |
|---|---|---|
| **Authentication** | None (relies on OS file permissions) | Inherits Claude Code auth |
| **Encryption** | None | None (local IPC) |
| **Permission model** | Full filesystem access required | Lead's permissions propagate to teammates |
| **Isolation** | Per-agent directory isolation | Each teammate is a separate process |

## Limitations Summary

### Team AI Limitations
- No built-in authentication or encryption
- No task dependency management
- No plan approval workflows
- Requires per-IDE setup and configuration
- Filesystem I/O bound (no pagination on large registries)
- No structured team hierarchy or delegation modes

### Claude Agent Teams Limitations
- Experimental; disabled by default
- Claude Code only (no cross-tool support)
- No session resumption for in-process teammates
- High token cost (each teammate is a full Claude instance)
- One team per session; no nested teams
- Fixed lead (cannot transfer leadership)
- Split panes require tmux or iTerm2
- Task status can lag; teammates may forget to mark tasks complete
- Shutdown can be slow (waits for current tool call to finish)

## Summary

| Dimension | Team AI | Claude Agent Teams |
|---|---|---|
| **Strength** | Cross-tool, lightweight, persistent | Deep coordination, structured workflows |
| **Weakness** | No task orchestration, manual coordination | Claude Code only, high token cost |
| **Best for** | Multi-IDE awareness and loose coordination | Focused parallel work within Claude Code |
| **Philosophy** | Universal message bus for any AI tool | First-party team orchestration for Claude Code |

Both projects address the growing need for multi-agent coordination in AI-assisted development. Team AI takes a tool-agnostic, infrastructure approach (the "message bus"), while Claude Agent Teams takes an opinionated, workflow-oriented approach (the "team manager"). As the multi-agent ecosystem matures, the ideal setup may well involve both.
