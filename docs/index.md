# ChatPharo Documentation

ChatPharo is an AI coding assistant integrated into the Pharo IDE. This documentation set explains **how it works internally**, the **features** you can use day‑to‑day, and the **memory/tooling/safety** subsystems.

## Start here

1. **Open ChatPharo**
   - World menu: **ChatPharo → Temp ChatPharo**
   - Or open **ChatPharo Settings** / **Setup Wizard** from the same menu.
2. **Configure an agent** (local or cloud) in **Settings → Agent**.
3. **Send a message** from the chat input.
4. (Optional) Enable **Tools**, **Skills**, **Memory**, **Multivers**, **Sandbox**, or **MCP** in settings.

## Documentation map

- Big picture: **architecture.md**
- End-to-end runtime path: **message-flow.md**
- Practical usage: **features.md** + **tutorial.md**
- Extending ChatPharo: **tools.md**, **skills.md**, **mcp.md**, **director.md**

## Conventions used here

- **Class/Package names** appear in `monospace`.
- Diagrams are rendered as plain-text blocks so everything stays **Markdown-only**.
- Examples use Smalltalk (Pharo).

---

## Quick links

- [Architecture](architecture.md)
- [Message flow](message-flow.md)
- [Features](features.md)
- [Configuration](configuration.md)
- [Agents](agents.md)
- [Tools](tools.md)
- [Skills](skills.md)
- [Memory](memory.md)
- [Multivers](multivers.md)
- [MCP](mcp.md)
- [Sandbox](sandbox.md)
- [Safety & Ethics](safety-ethics.md)
- [Director/Team (multi-agent)](director.md)
- [Benchmarks](benchmarks.md)
- [IDE integration](integration.md)
- [Tutorial](tutorial.md)
- [Troubleshooting](troubleshooting.md)
- [Glossary](glossary.md)

---

## Documentation files

| File | What it covers |
|---|---|
| `index.md` | Entry point, navigation, and the full file index table. |
| `architecture.md` | Layered architecture diagrams and subsystem overview. |
| `message-flow.md` | Send message → prompt building → model call → tool loop → UI update. |
| `features.md` | User-facing feature tour: chat, browser integration, attachments, feedback, logs, help. |
| `configuration.md` | Settings model, defaults, persistence, and how toggles affect behavior. |
| `agents.md` | Backends (Claude, Gemini, Ollama, LM Studio, DeepSeek, etc.), capabilities, configuration. |
| `tools.md` | Built-in tools, custom tools, tool calling protocol, and execution lifecycle. |
| `skills.md` | Skills registry, manual/auto skill context injection, adding skills. |
| `memory.md` | Long-term memory model, retention, auto-summarize, prompt context injection. |
| `multivers.md` | Multi-step chain execution and prompt rewriting across agents. |
| `mcp.md` | MCP registry, connecting servers, and exposing MCP tools to the LLM. |
| `sandbox.md` | Code-execution sandbox, restrictions, and timeout behavior. |
| `safety-ethics.md` | Safety advisor warnings + ethics budgets/gating for high-impact settings. |
| `director.md` | Director/Team pattern for multi-agent task decomposition and result merging. |
| `integration.md` | Pharo IDE integration: world menu, editor actions, system browser context. |
| `tutorial.md` | Setup and the interactive tutorial entry points. |
| `troubleshooting.md` | Common issues and diagnostics. |
| `glossary.md` | Terminology used across the docs. |

*Generated on 2026-02-13.*
