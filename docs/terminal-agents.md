# Terminal agents: Claude Code, Codex CLI, Gemini CLI

`ChatPharoMCPBridge` exposes the tools of the running image over MCP (Streamable HTTP), so an agent in your terminal can read and change the live image.

## Start

**Settings → Application → Terminal agents → Start**, or:

```smalltalk
ChatPharoMCPBridge default start.
ChatPharoMCPBridge default connectionInstructions
```

Then, in a terminal:

```bash
claude mcp add --transport http chatpharo http://localhost:8765/mcp
codex mcp add chatpharo --url http://localhost:8765/mcp
gemini mcp add --transport http chatpharo http://localhost:8765/mcp
```

Any MCP client that speaks Streamable HTTP can use the same URL. The flags above are the ones these CLIs document at the time of writing; check `<cli> mcp add --help` if one is refused.

## What the agent gets

Exactly `ChatPharoToolbox new enabledTools`: the built-in tools you left enabled, your custom tools and the tools of connected MCP servers. The list is computed for each request, so toggling a tool in the settings takes effect immediately.

## Safety

- The bridge listens on the loopback interface only.
- Requests with a non-local `Origin` header are refused (a web page cannot drive the image).
- Mutating tools go through the same confirmation dialog as in a chat; the agent receives your refusal and its reason.
- There is no authentication token: any program running under your account can reach the bridge while it runs. Stop it when you do not use it.

## Protocol notes

One JSON-RPC message, or a batch, per `POST /mcp`; the reply is `application/json`. Notifications are answered `202`. `GET /mcp` answers `405`: the bridge sends no server-initiated messages. MCP itself (initialize, tools/list, tools/call) is handled by `McpServer` from pharo-mcp.
