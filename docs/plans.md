# Plans and the Task Manager

For a task that needs several actions, ChatPharo proposes a plan and **you validate each step** before anything is executed.

```text
You: "Add logging to the importer"
  -> model calls propose_plan(title, steps)
  -> "Validate plan" dialog: one check box per step + a feedback field
  -> model receives each step as approved / rejected, and your feedback
  -> model executes approved steps only, reporting with update_plan_step
  -> Task Manager shows the progress live
```

## Tools (`ChatPharoPlanTools`, package `AI-ChatPharo-Plan`)

| Tool | Purpose |
|---|---|
| `propose_plan` | Submit title and steps. Blocks until you validate. Answers the status of each step, your feedback and an instruction for the model. |
| `update_plan_step` | Report `in_progress`, `done` or `failed` on an approved step. A rejected step cannot be started. |
| `get_plan` | Read a plan back. |

A step you leave undecided, and every step of a dialog you close without validating, is rejected.

## Task Manager

Toolbar **Tasks**, or `ChatPharoTaskManagerPresenter new open`. Plans on the left with their progress, steps on the right with status and notes. It listens to `ChatPharoPlanBoard`, the object that keeps the plans of the image.

## Switching validation off

**Settings → Application → Plans and tasks.** When inactive, proposed plans are approved automatically and only serve as a progress display.

## When you refuse a tool call

The confirmation dialog of a mutating tool has a reason field. What you type there is sent to the model with the refusal (`reason` in the tool result), so it adapts instead of retrying.
