# Benchmarks

The `AI-ChatPharo-Benchmarks` package gives you a complete, reproducible
benchmarking pipeline for code generation (and related tasks) that runs
**inside the same Pharo image** as the rest of ChatPharo.

It answers questions like:

- *Which API am I using?* (Every result records the agent class, model name,
  and base URL.)
- *Did the model use tools, and which ones?* (Every result records the tool
  call count and tool names.)
- *Does the ChatPharo ecosystem actually help my model?* (Run with strategy
  `#ecosystem` and `#rawLLM` and compare.)

It is **dynamic**: benchmarks are extracted from a live Pharo package, so
when the package changes the gold data follows automatically — no
hand-curated dataset to maintain.

---

## Quick start

```smalltalk
"1. Build a benchmark from a live package."
bench := ChatPharoBenchmarksAPI buildFromPackage: 'AI-ChatPharo-Tools'.
ChatPharoBenchmarksAPI save: bench.

"2. Run it through the full ChatPharo ecosystem (tools, browser env, history)."
agent  := ChatPharoSettings default agent.
report := ChatPharoBenchmarksAPI
              run: bench
              withAgent: agent
              strategy: #ecosystem.
ChatPharoBenchmarksAPI save: report.

"3. Compare ecosystem vs raw LLM head-to-head."
comparison := ChatPharoBenchmarksAPI
                  compare: bench
                  ecosystemAgent: agent
                  rawAgent: agent.
comparison asDictionary.
```

Files land under `~/Documents/chatpharo-benchmarks/` by default — change the
location with `ChatPharoBenchmarkStore root: aFileReference`.

---

## Architecture

```
ChatPharoBenchmarksAPI       ← single-class facade, what most users call
        │
        ├── ChatPharoBenchmarkBuilder         ← package → benchmark (gold data)
        ├── ChatPharoBenchmarkRunner          ← benchmark + config → report
        ├── ChatPharoBenchmarkComparison      ← N reports → diff
        └── ChatPharoBenchmarkStore           ← JSON persistence
                                              (default: ~/Documents/chatpharo-benchmarks)

Entities
  ChatPharoBenchmark        — collection of cases + metadata
  ChatPharoBenchmarkCase    — one atomic task (method to generate, …)
  ChatPharoBenchmarkResult  — outcome of one case under one configuration
  ChatPharoBenchmarkReport  — aggregated results of one full run

Configurability
  ChatPharoBenchmarkConfiguration   — strategy + agent + scorers + threshold
  ChatPharoBenchmarkPromptTemplate  — how cases are rendered into prompts
  ChatPharoBenchmarkCodeExtractor   — pulls Smalltalk out of LLM responses

Scorers (all subclasses of ChatPharoBenchmarkScorer)
  ChatPharoBenchmarkExactMatchScorer        — strict string equality
  ChatPharoBenchmarkNormalizedMatchScorer   — whitespace-insensitive equality
  ChatPharoBenchmarkASTMatchScorer          — structural AST equality
  ChatPharoBenchmarkCompilationScorer       — does it parse?
  ChatPharoBenchmarkTokenOverlapScorer      — Jaccard over identifiers
```

---

## Building a benchmark from a package

`ChatPharoBenchmarkBuilder` walks a Pharo package and emits one case per
method that passes the filters.

```smalltalk
bench := ChatPharoBenchmarkBuilder new
    packageNamed: 'AI-ChatPharo-Tools';
    kind: #methodGeneration;          "or #methodExplanation, #classGeneration, #snippetCompletion"
    excludeProtocol: 'initialization';
    excludeProtocol: 'tests';
    minSourceSize: 60;                 "skip trivial getters/setters"
    maxSourceSize: 4000;               "skip giant methods"
    maxCases: 100;                     "cap the run"
    selectorFilter: [ :sel | (sel beginsWith: 'private') not ];
    build.
```

Every case is given a deterministic id of the form
`<package>/<Class>/<selector>/<kind>` so reports stay comparable across
package versions, and diffs are meaningful when the package does change.

---

## Running a benchmark

Two strategies are first-class citizens:

### `#ecosystem` — full ChatPharo

The agent is used verbatim through `agent copyForChat`, which means:

- the agent's system prompt is active,
- `ChatPharoBrowserEnvironment` tools are attached,
- tool calls are dispatched and their results fed back,
- the multi-iteration tool-call loop inside each backend is honoured.

Each `ChatPharoBenchmarkResult` records:

- `agentClassName`, `modelName`, `apiBaseURL` — *which API was used*,
- `toolsEnabled = true`, `toolCallCount`, `toolCallNames` — *whether and
  how the model used tools*,
- `promptTokens`, `completionTokens`, `totalTokens`, `latencyMs` — cost.

### `#rawLLM` — bypass the ecosystem

A single-shot call goes directly to the vendor:

- no Pharo-specific system prompt (a neutral one is used),
- no tools attached at all (`tools: #()`),
- no iterations, no carry-over,

so you measure the underlying model on its own. The result records
`toolsEnabled = false` and `toolCallCount = 0`.

### Same agent, both strategies

Pointing the same agent at both strategies is the canonical apples-to-apples
comparison:

```smalltalk
ChatPharoBenchmarksAPI
    compare: bench
    ecosystemAgent: agent
    rawAgent:       agent.
```

### Multi-config matrix

```smalltalk
configs := {
    ChatPharoBenchmarkConfiguration ecosystemWith: claudeAgent.
    ChatPharoBenchmarkConfiguration rawLLMWith:    claudeAgent.
    ChatPharoBenchmarkConfiguration ecosystemWith: ollamaAgent.
    ChatPharoBenchmarkConfiguration rawLLMWith:    ollamaAgent.
}.
comparison := ChatPharoBenchmarksAPI compare: bench withConfigurations: configs.
```

---

## Scoring

By default each result is scored by **all** built-in scorers; the
`primaryScorerName` (default `'normalizedMatch'`) decides pass/fail via
`passThreshold` (default `0.9`).

| Scorer name        | What it measures                                              |
|--------------------|---------------------------------------------------------------|
| `exactMatch`       | Strict string equality with the gold source.                  |
| `normalizedMatch`  | Equality after collapsing whitespace.                         |
| `astMatch`         | Structural equality of the parsed Pharo AST.                  |
| `compilation`      | 1.0 iff the generated code parses as a method/expression.     |
| `tokenOverlap`     | Jaccard similarity over identifier tokens.                    |

Add your own by subclassing `ChatPharoBenchmarkScorer` and overriding
`#scoreName` and `#score:against:`. Configure with:

```smalltalk
config scorers: { MyScorer new. ChatPharoBenchmarkASTMatchScorer new }.
config primaryScorerName: 'mySemanticScore'.
config passThreshold: 0.75.
```

---

## Persistence

`ChatPharoBenchmarkStore` saves benchmarks and reports as JSON via
`STONJSON`. Layout:

```
<root>/
  benchmarks/
    AI-ChatPharo-Tools-methodGeneration-2026-04-15T….json
  reports/
    AI-ChatPharo-Tools-methodGeneration/
      ecosystem-claude-3-5-sonnet-2026-04-15T….json
      rawLLM-claude-3-5-sonnet-2026-04-15T….json
```

Every report includes a top-level `summary` block (pass rate, average
latency, total tokens, total tool calls, mean of every scorer) so a
dashboard can read it without reprocessing the per-case results.

Reload anytime:

```smalltalk
report := ChatPharoBenchmarksAPI loadReportFrom:
    (FileLocator documents / 'chatpharo-benchmarks' / 'reports' / '…').
report passRate.
```

---

## Why this design

- **Live, not static.** The benchmark is rebuilt from the Pharo package on
  demand, so it cannot drift away from reality.
- **Same code path the user runs.** The `#ecosystem` strategy invokes the
  exact same `getResponseForPrompt:` that the chat UI uses, including tools,
  history, and the multi-iteration loop — no parallel test harness to keep
  in sync.
- **Honest baseline.** The `#rawLLM` strategy strips the ecosystem
  entirely and talks to the same vendor with `tools: #()` and a neutral
  system prompt, so the comparison is meaningful.
- **Reproducibility-first.** Every result records *exactly* which model,
  base URL, agent class, and tool count produced it. Reports are pure JSON
  on disk.
