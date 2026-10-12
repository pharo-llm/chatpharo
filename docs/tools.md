# Tools

Tools are the bridge between the LLM and the Pharo environment. When tool calling is enabled and the backend supports it, the model can request specific tool functions to be executed locally.

## Tool categories

### Built-in environment tools

`ChatPharoBrowserEnvironment` exposes a set of functions for IDE/codebase introspection, such as:

- list packages/classes
- describe classes/methods
- find methods by substring
- (optionally) evaluate code

These tools are typically toggled on/off via settings.

### Custom tools

Custom tools are user-defined functions created from the UI:

- name + description
- parameter definitions (schema-like)
- Smalltalk code body
- test execution from the tool editor
- saved into settings and exposed as “clients” to the LLM

### MCP tools (optional)

When MCP is enabled, MCP servers contribute tools which are surfaced as clients (see **mcp.md**).

## Tool calling lifecycle

```text
Model response includes tool_calls
            |
            v
ChatPharoAgent detects tool_calls
            |
            v
Execute tool locally (browser/custom/MCP)
            |
            v
Append tool result to ChatPharoHistory (role: tool)
            |
            v
Call model again with updated history
```

## Sandbox interaction

If the sandbox is enabled, tool execution can be restricted (filesystem/network/system access) and timed out.  
See **sandbox.md**.

## Extending tools

- For built-in tools: add functions to `ChatPharoBrowserEnvironment` and expose a proper schema.
- For user tools: create via the Tools UI (recommended for most use cases).
- For external tool servers: use MCP.

## Related docs

- Message flow: **message-flow.md**
- Sandbox: **sandbox.md**
- MCP: **mcp.md**

## Tool providers

A group of tools is a `ChatPharoToolProvider` subclass that answers `title`, `summary` and `tools`. Nothing else is registered: its tools appear in chats, in **Settings → Application → Tools** and for terminal agents.

| Provider | Tools |
|---|---|
| `ChatPharoNavigationTools` | `find_senders`, `find_implementors`, `find_class_references`, `find_classes`, `get_method_source`, `run_tests` |
| `ChatPharoPlanTools` | `propose_plan`, `update_plan_step`, `get_plan` (see **plans.md**) |
| `ChatPharoUITools` | `list_windows`, `describe_window`, `click_widget`, `type_text`, `select_item`, `open_browser`, `close_window` |

```smalltalk
MyTools >> tools [
	^ { (self
		   toolNamed: 'count_classes'
		   description: 'Counts the classes of a package.'
		   properties: (Dictionary with: 'package' -> (self property: 'string' description: 'Package name'))
		   required: #( 'package' )
		   do: [ :arguments | Dictionary with: 'count' -> (arguments at: 'package') asPackage definedClasses size ]) }
]
```

Send `beMutating` to a tool that changes the image, opens windows or runs code: the user is then asked before each call. Results are capped and say when they are truncated.

## Navigating a user interface

`describe_window` answers the controls of a Spec window — buttons, check boxes, text fields, lists, drop-downs, tabs, labels — each with an id, its text and its state. `click_widget`, `type_text` and `select_item` take that id or the exact text of the control. The model works on the structure of the UI, not on pixels, so it can drive your own Spec application. Windows not built with Spec are listed by title only; use `open_browser` for the System Browser.

## Upgrades

Settings remember which built-in tools they have seen. A tool shipped by a new version is enabled on first sight; a tool you disabled stays disabled.
