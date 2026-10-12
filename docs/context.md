# Context: what the model knows before you type

A model only knows what is in its prompt. Before every request ChatPharo appends a context block to the system prompt, built by `ChatPharoContext` from ordered **layers** (`ChatPharoContextLayer` subclasses, package `AI-ChatPharo-Context`):

| Layer | Class | What it says | Switch |
|---|---|---|---|
| Environment | `ChatPharoEnvironmentLayer` | ChatPharo version, Pharo version, platform, locale, time | Applications → Context |
| How to work with this user | `ChatPharoWorkflowLayer` | Plan first, execute approved steps only, adapt when a tool call is refused | Applications → Plans and tasks |
| Project context (automatic) | `ChatPharoProjectLayer` | Image file, Git repositories with a local clone, their branch, packages with uncommitted changes | Applications → Context |
| Session context (short-term) | `ChatPharoSessionLayer` | Focused window, other open windows, latest code changes of the session (from Epicea) | Applications → Context |
| User and work memory (long-term) | `ChatPharoMemoryLayer` | User name, organization, Pharo experience, memories relevant to the question | Applications → Memory |

The context is rebuilt for each request, so the model sees the current branch and the current window, not a snapshot taken when the chat was opened. Each layer is capped (`characterBudget`, 2000 characters) so a large image cannot flood the prompt.

**Applications → Context** shows the exact text that will be sent with your next message.

```smalltalk
ChatPharoContext default promptFor: 'why does my test fail?'
```

## Conversations survive restarts and updates

`ChatPharo default` is the session of the image. Its chats are saved by `ChatPharoChatArchive` as one JSON file per chat in `<image directory>/chatpharo/chats/` after each answer, and restored when the session is created: closing the window, restarting the image or pulling a new version of ChatPharo no longer empties the chat. The files hold the full LLM history, tool calls and results included, so a restored conversation can be continued.

### After pulling a new version

A window that is open while ChatPharo's code is updated is made of widgets built by the old code: it keeps showing the conversation but cannot display new messages. The session listens for the end of package loads (`MCVersionLoaderStopped`) and, when the code of its window changed, rebuilds the window from the chats, which are model objects and are not affected. A window opened by a version older than this mechanism cannot heal itself: close it and reopen ChatPharo once.

`ChatPharo new` stays a transient session that writes nothing to disk; quick actions and tests use it.

## Adding a layer

Subclass `ChatPharoContextLayer`, implement `title`, `isEnabled` and `linesFor:`, and add it to `ChatPharoContext class >> settings:`.
