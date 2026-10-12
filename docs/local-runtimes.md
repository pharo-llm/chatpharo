# Local runtimes: Ollama and LM Studio

ChatPharo finds Ollama and LM Studio on your machine and starts them when needed.

- `ChatPharoLocalRuntime all` — the known runtimes (`ChatPharoOllamaRuntime`, `ChatPharoLMStudioRuntime`).
- `isInstalled` looks at the usual install locations per platform. It does not rely on `PATH`, which a Pharo started from the launcher does not inherit from your shell.
- `ensureRunning` starts `ollama serve` or `lms server start` in the background and waits (30 s by default) until the server answers.

With **Settings → Application → Local runtimes** active, a chat that uses a local agent starts its runtime before sending a message. The panel lists each runtime with its state and program path.

## One-click Ollama

**Settings → Agent → Ollama → Set up Ollama for me** starts the server, selects the best installed model (tool-capable models first) and puts the others in **Fallback models**. With no model installed it downloads `qwen3:4b`.

## Fallback models

Every agent has `fallbackModels`. When the selected model answers a usage limit (HTTP 429 or 402, or a quota message) or does not exist (404), the next model is tried and the switch is noted in the reasoning of the answer. Authentication and other errors are reported as before.

## Small models that write tool calls as text

Some local models answer a function call as JSON text instead of a structured tool call. `ChatPharoTextualToolCallParser` recognises an answer that consists only of such a call to a tool that is really offered, and executes it.
