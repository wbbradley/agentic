---
name: todo
description: Research and add a new task or phase to the front of a specified plan markdown file. Requires the plan file path as an explicit argument. Use when the user asks to plan or queue work that is beyond the current task.
---

Require the user to provide the exact path to the plan markdown file as an argument. Accept an
absolute path or a path relative to the current working directory. Resolve it once at the start.
Do not infer the path, search for a plan file, or default to `PLAN.md`. If the argument is missing,
stop and ask the user for it. The file may be created at that exact path if it does not exist.

Read `../add-task-workflow.md` in full and follow it, using the current user request as the task
description and the resolved argument as the plan file. Insert the task at the top of the queue so
it will be worked on next.
