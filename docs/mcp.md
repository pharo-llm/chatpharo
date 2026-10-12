# MCP (Model Context Protocol)

ChatPharo can integrate with external tool servers via MCP. When enabled, MCP tools are exposed as callable tools to the model (similar to built-in and custom tools).

## What MCP enables

- Connect to one or more MCP servers
- Discover server-provided tools
- Expose those tools to the active agent as “clients”
- Execute tools and return results into chat history

## How it fits in the system

```text
Agent tool calling
   |
   v
Tool dispatcher
   |------------------------|
   v                        v
Built-in tools         Custom tools
   |
   v
MCP registry (optional) -> external MCP servers -> tools
```

## Configuration

Typical steps:

1. Enable MCP in settings.
2. Configure servers (command/host/port depending on implementation).
3. Connect servers.
4. Verify tools appear in the enabled tool list (or are usable by the agent).

## The other direction: ChatPharo as an MCP server

To let Claude Code, Codex CLI or Gemini CLI use the tools of your image, see **terminal-agents.md**.

## Related docs

- Tools: **tools.md**
- Safety: **safety-ethics.md**
