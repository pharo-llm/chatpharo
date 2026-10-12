# Message flow (from “Send” to response)

This document explains what happens internally from the moment you send a message until the model output appears.

## High-level sequence diagram

```text
User
  |
  | (1) sendMessage
  v
ChatPharoPresenter (Spec)
  |
  | model sendMessage: text
  v
ChatPharoChat (conversation)
  |
  | (2) command parsing? (/help, /reset, ...)
  | (3) add user message -> UI + history
  | (4) build prompt:
  |     - history prefix
  |     - + memory context (optional)
  |     - + skills context (optional)
  | (5) multivers chain (optional) / cache (optional)
  v
ChatPharoAgent (backend)
  |
  | (6) HTTP request via ChatPharoTool (or backend-specific client)
  | (7) parse response (content, thinking, tool_calls)
  |
  | (8) tool loop (bounded):
  |     while tool_calls and iteration < maximumIterations:
  |         execute tool -> append tool result -> call model again
  v
ChatPharoChat
  |
  | (9) add assistant message -> UI + history
  | (10) notify listeners / update status
  v
User sees response
```

## Step-by-step lifecycle

### 1) UI triggers a send

The presenter sends the current input text to the model and records a frontend log entry.

### 2) Command parsing (optional)

If the text starts with a supported command, ChatPharo executes it locally:

- `/help`, `/clear`, `/reset`, `/export`, `/history`

No model call occurs for these commands.

### 3) UI message and history message are written together

ChatPharo keeps two synchronized representations:

- `ChatPharoMessage` for UI rendering
- `ChatPharoHistoryMessage` for LLM requests (role/content/tool_calls)

### 4) Prompt building

ChatPharo builds an effective prompt from multiple sources:

- **Conversation history** — `ChatPharoHistory`, each message exactly once
- **Context layers** appended to the system prompt: environment, workflow, project, session, long-term memory (see **context.md**)
- **Skills context** (enabled skills + optional auto-detected skills)

### 5) Multivers and cache (optional)

- **Multivers** can rewrite/refine the prompt across a chain of agents.
- **Caching** returns a previous response only for the same prompt in the same conversation state; repeating "continue" later in a chat always reaches the model.

### 6) Agent call

The selected `ChatPharoAgent` sends the request to the backend.

- Most cloud agents build OpenAI-like payloads (messages + tools) through `ChatPharoTool`.
- Some local agents use a backend-specific schema but preserve the same agent interface.

### 7) Response parsing

The response may include:

- assistant content
- optional thinking content
- optional tool calls (`tool_calls`)

### 8) Tool call loop (bounded)

If tool calls exist and tool calling is enabled/supported:

1. Execute the requested tool locally (browser, custom, MCP).
2. Append tool result to history as a tool message.
3. Call the model again with updated history.

Repeat until tool calls stop or `maximumIterations` (default 25) is reached. At the limit the model is asked once for a closing written answer without tools, so the user never gets an empty reply.

The loop is `ChatPharoConversationTurn`, shared by every backend. It sums token usage over all the requests of the turn and keeps the reasoning of each one (fields `reasoning_content`, `reasoning`, `thinking`, or inline `<think>` tags), which the **Reasoning** button of the answer shows. Tool calls of one reply run in the order the model listed them. A turn that fails or is cancelled is removed from the history.

### 9) Conversation update and notifications

The final assistant message is appended to UI and history, and listeners are notified.

### 10) Auto-summarize to memory (optional)

When enabled, ChatPharo can summarize conversations into memory for future context injection.

## Cancellation & concurrency

- Requests run asynchronously to keep the UI responsive.
- Cancelling terminates the in-flight prompt process and prevents applying the response.

## Related docs

- Tools: **tools.md**
- Memory: **memory.md**
- Multivers: **multivers.md**
