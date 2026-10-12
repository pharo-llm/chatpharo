# Architecture

This document describes ChatPharo as a set of layers with **separation of concerns**. All diagrams are plain text so the docs remain **100% Markdown**.

## Layered architecture overview

```text
+--------------------------------------------------------------+
| UI Layer (Spec presenters)                                   |
| - ChatPharoPresenter (tabs + input)                           |
| - Settings presenters (Agent, Tools, Skills, Memory, etc.)    |
| - Help + Thinking presenters                                  |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
| Chat Session Layer                                           |
| - ChatPharoChat (one conversation)                            |
| - ChatPharoMessage (UI messages)                              |
| - ChatPharoCommandParser (/help, /reset, /export, ...)         |
| - ChatPharoHistory + ChatPharoHistoryMessage (LLM log)        |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
| Prompt Orchestration Layer                                   |
| - ChatPharoContext: environment, workflow, project, session,  |
|   memory layers appended to the system prompt per request     |
| - Skills context injection (optional)                         |
| - Multivers prompt chaining (optional)                        |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
| Agent Layer (Backends)                                       |
| - ChatPharoAgent: one template for every backend              |
|   (subclasses only answer newCompletionClient)                |
| - ChatPharoConversationTurn: the single bounded tool loop,    |
|   token and reasoning accumulation, closing answer            |
| - fallbackModels on usage limit; local runtimes auto-start    |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
| Tool & Execution Layer                                       |
| - ChatPharoTool (OpenAI-like request/response + tool_calls)   |
| - ChatPharoToolbox: the one answer to "which tools now?"      |
| - ChatPharoToolProvider subclasses: navigation, plans, UI     |
| - Custom tools, MCP tools, Sandbox restrictions (optional)    |
| - ChatPharoMCPBridge: the same tools for terminal agents      |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
| Persistence & Observability                                  |
| - ChatPharoSettings (saved defaults)                          |
| - ChatPharoChatArchive: chats saved and restored              |
| - Memory store + history export/import                        |
| - ChatPharoLogger (frontend/backend/system logs)              |
+--------------------------------------------------------------+
```

## Key design goals

- **Pluggable backends**: any agent implementing the `ChatPharoAgent` contract can be selected.
- **Tooling as callable functions**: tools have a name/description/schema; the model can call them.
- **Optional subsystems**: Memory, Skills, Multivers, MCP, Sandbox can be enabled independently.
- **One history, one loop**: `ChatPharoHistory` is the single LLM transcript. The chat records the user prompt, the agent's turn records the model replies, and idempotent `ensureEndsWith…` operations guarantee no message is recorded twice.
- **Dual representation**: UI messages and LLM history messages are kept in sync but are different objects.
- **Extension by subclassing**: a new tool group is a `ChatPharoToolProvider` subclass, a new context layer a `ChatPharoContextLayer` subclass, a new backend a `ChatPharoAgent` subclass answering `newCompletionClient`.

## What to read next

- End-to-end execution path: **message-flow.md**
- Tool calling lifecycle: **tools.md**
- Memory injection model: **memory.md**
- Multivers chain: **multivers.md**
## Runtime flow summary

The layered view shows *where* things live; this snippet shows *how* they cooperate at runtime:

```text
ChatPharoPresenter -> ChatPharoChat
    -> (history + memory + skills + multivers) -> final prompt
    -> ChatPharoAgent -> ChatPharoTool (HTTP)
    -> (optional tool_calls loop) -> ChatPharoChat updates UI + history
```

For the fully detailed pipeline, see **message-flow.md**.
