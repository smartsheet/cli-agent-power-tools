# AGENTS.md

This file is the primary reference for any AI agent working in this repo. Read it fully before writing, editing, or reviewing any agent file.

---

## What this repo is

CLI Agent Power Tools is a collection of six purpose-built AI agents for Smartsheet power users. Each agent is called a **Power Tool** — a single-file, opinionated agent that handles one specific project management workflow that would otherwise take minutes of manual clicking.

The six Power Tools are:

| Tool | Stage | What it does |
|---|---|---|
| `bottleneck-scanner` | READ | Scans active projects, ranks overloaded owners by weighted load, surfaces redistribution candidates |
| `reassignment-helper` | WRITE | Reassigns one person's work to another across every sheet they own, with preview and paper trail |
| `engagement-cloner` | CREATE | Clones a project sheet's structure (not data) into a new sheet for a new engagement |
| `risk-scanner` | SCAN | Scores open work across schedule, blocker, and owner-gap signals; ranks by combined signal count |
| `standup-prep` | BRIEF | Builds a focused pre-meeting brief from risk-scanner output or a live data pass |
| `status-comms-writer` | DRAFT | Drafts Slack updates, status emails, and escalations from any upstream Power Tool output |

The tools are designed to work independently or as part of two chained workflows:

- **Arc 1: Read → Write → Create** — diagnose overload, rebalance work, formalize new scope
- **Arc 2: Scan → Brief → Draft** — identify risk, surface what to raise, communicate it

Each stage's output feeds the next through a structured JSON output contract. Human approval gates every write.

The agents run against the [Smartsheet MCP server](https://mcp.smartsheet.com), which exposes twenty years of Smartsheet's work graph — row-level discussion threads, workspace hierarchy, cross-sheet dependencies, permission model, and the full read/write/create surface. The agents compose against this directly from the user's terminal.

---

## Prerequisites

Every Power Tool requires the Smartsheet MCP server to be registered before any agent will function. The `tools:` list in an agent's frontmatter restricts what the agent can call — it does not register the server. Registration is a one-time setup step per machine.

- **Claude Code:** run `./smartsheet_mcp_setup.sh` or follow the [manual setup docs](https://developers.smartsheet.com/ai-mcp/smartsheet/install-the-smartsheet-mcp-server/connect-claude-code)
- **Gemini CLI:** run `./gemini_mcp_setup.sh`

An agent missing its MCP server will fail silently or produce errors on the first tool call. If an agent seems to do nothing, verify MCP registration first.

---

## Runtimes

Every Power Tool is defined twice — once for each supported CLI runtime. The agent bodies are maintained to produce equivalent outcomes on both runtimes, with runtime-specific sections where the platforms require different behavior.

### Claude Code

- **Agent files:** `.claude/agents/*.md`
- **Loaded by:** Claude Code CLI (`claude`)
- **Docs:** https://docs.anthropic.com/en/docs/claude-code/sub-agents

### Gemini CLI

- **Agent files:** `.gemini/agents/*.md`
- **Loaded by:** Gemini CLI (`gemini`)
- **Docs:** https://geminicli.com/docs/core/subagents

---

## Differences between runtimes

### 1. Frontmatter format

The `tools` field differs in format and tool naming convention.

**Claude Code** — comma-separated string, double-underscore separators:
```yaml
---
name: risk-scanner
description: Scans active projects for risks...
tools: mcp__smartsheet__get_resource_guide, mcp__smartsheet__search, mcp__smartsheet__get_sheet_summary
---
```

**Gemini CLI** — YAML array, single-underscore separators:
```yaml
---
name: risk-scanner
description: Scans active projects for risks...
tools:
  - mcp_smartsheet_get_resource_guide
  - mcp_smartsheet_search
  - mcp_smartsheet_get_sheet_summary
---
```

The confirmed valid frontmatter fields for Gemini subagents are `name`, `description`, and `tools`. No other fields are needed.

### 2. Agent chaining

This is the most important behavioral difference between the two runtimes.

**Claude Code** has an orchestration layer. When an agent body says something like "Want me to invoke `reassignment-helper`?", the Claude orchestrator interprets that natural language and dispatches to the named agent. The agent body does not need to make an explicit tool call.

**Gemini CLI** has no such orchestration layer. Agents must explicitly call the `invoke_agent` tool to hand off to another agent. Natural language handoff suggestions alone are not sufficient.

As a result, every Power Tool that chains to another has two separate "After the action" implementations:

```markdown
<!-- Claude Code version of "After the action" -->
Always end with one concrete handoff offer:
- "Want me to invoke `reassignment-helper` to move those items?"

<!-- Gemini CLI version of "After the action" -->
Your behavior depends on how you were invoked.

**1. If in Interactive Mode:**
  1. Ask the user: "I've completed the scan. Want me to invoke `reassignment-helper`?"
  2. On confirmation: execute `invoke_agent`.

**2. If in Automated Chain Mode:**
  - Immediately execute:
    `print(default_api.invoke_agent(agent_name='reassignment-helper', prompt='This is an automated chain. ...'))`
```

The final agent in a chain (`status-comms-writer`) calls `complete_task()` when done in automated chain mode.

#### Chain propagation contract

The automated chain flag is not a runtime state — it lives in the prompt. An agent only knows it is in automated chain mode if the prompt it received explicitly says so (e.g. "This is an automated chain."). When invoking the next agent, the calling agent must include that phrase in the prompt it passes, and must pass along the relevant data from its output contract. If either is missing, the downstream agent defaults to interactive mode and stops to ask the user for confirmation.

The terminal agent (`status-comms-writer`) must call `complete_task()` at the end of its automated run so the chain resolves cleanly. All other agents pass the chain forward via `invoke_agent`.

### 3. Runtime references in body text

Agent bodies must be runtime-neutral. Do not refer to "Claude" or "Gemini" in the body text of an agent. Use "the orchestrating model" or "this agent" instead.

The one exception already present in the repo: `status-comms-writer` previously said "Claude (the orchestrating instance)" — this has been corrected to "the orchestrating model" in both versions.

---

## Agent file templates

Both templates share an identical body structure. The only differences are the frontmatter format and the "After the action" section.

### Claude Code template (`.claude/agents/your-tool-name.md`)

```markdown
---
name: your-tool-name
description: One sentence on what it does. One sentence on when to use it. Trigger phrases include "phrase one", "phrase two", "phrase three".
tools: mcp__smartsheet__get_resource_guide, mcp__smartsheet__<tool_two>, mcp__smartsheet__<tool_three>
---

# Your Tool Name

One opening line on purpose. State the arc stage (READ / WRITE / CREATE / SCAN / BRIEF / DRAFT) if applicable.

## What you do

1. **Step one** — description.
2. **Step two** — description.
3. **Step three** — description.

## How to respond

<output format with a concrete example using real-looking names and data>

## After the action

Always end with exactly one concrete handoff offer:

- "Want me to invoke `next-tool` to [do the next thing]?"

## Write rules (if applicable)

- Rule one.
- Rule two.

## What not to do

- Don't do X.
- Don't do Y.

## Efficient tool use

- Start with `search` to find active sheets in scope.
- One `get_sheet_summary` per sheet.
- Only call `list_row_discussions` on rows already flagged — not on every row.

## Output contract (for chaining)

When called inside a chain, return structured output:

\`\`\`json
{
  "field_one": "<value>",
  "field_two": ["<item>"]
}
\`\`\`
```

### Gemini CLI template (`.gemini/agents/your-tool-name.md`)

The body is identical to the Claude version except the "After the action" section, which must use explicit `invoke_agent` calls.

```markdown
---
name: your-tool-name
description: One sentence on what it does. One sentence on when to use it. Trigger phrases include "phrase one", "phrase two", "phrase three".
tools:
  - mcp_smartsheet_get_resource_guide
  - mcp_smartsheet_<tool_two>
  - mcp_smartsheet_<tool_three>
---

# Your Tool Name

[Identical body content as Claude version, down to "After the action"]

## After the action

Your behavior depends on how you were invoked.

**1. If in Interactive Mode (the user asked for a single action):**
  1. Ask the user: "I've completed [the action]. Want me to invoke `next-tool` to [do the next thing]?"
  2. On confirmation, execute the `invoke_agent` tool call.

**2. If in Automated Chain Mode (your prompt instructed you to proceed automatically):**
  - Immediately execute:
    `print(default_api.invoke_agent(agent_name='next-tool', prompt='This is an automated chain. [Context and data]. Proceed without confirmation.'))`
  - Replace the prompt content with the relevant output from your output contract.

[Remaining sections identical to Claude version]
```

---

## Validating equivalent outcomes

"Equivalent outcomes" means the same data is read, the same decisions are made, and the same output contract is returned — regardless of runtime. Use this checklist when verifying a new or modified agent:

- [ ] The domain logic (what to scan, what to write, what to flag) is word-for-word identical between `.claude/agents/` and `.gemini/agents/` versions
- [ ] The output contract JSON schema is identical between both versions
- [ ] The "What not to do" and "Efficient tool use" sections are identical
- [ ] The tool lists cover exactly the same Smartsheet operations (only the naming format differs)
- [ ] In interactive mode on both runtimes: the agent surfaces a handoff offer and waits for confirmation before proceeding
- [ ] In automated chain mode on Gemini: the agent calls `invoke_agent` without pausing; on Claude: the orchestrator routes forward from the natural language offer
- [ ] The terminal agent (`status-comms-writer`) produces the same draft format on both runtimes

If any of these diverge, the versions are out of sync and must be reconciled before merging.

---

## Rules for writing and maintaining agents

1. **Write the body once.** All sections except "After the action" and frontmatter must be identical across both runtime versions. If you change the domain logic in one, change it in the other.

2. **Never expand tool scope without justification.** A READ-stage agent must have no write tools. A WRITE-stage agent must have no create tools. Scope is a feature.

3. **Keep the output contract stable.** Downstream agents depend on the JSON shape. Changes to output contracts require updating every agent that consumes them.

4. **Test on both runtimes before submitting.** A fix that works on Claude but breaks Gemini's chain is not done.

5. **Do not reference runtime names in body text.** "The orchestrating model" not "Claude". The body must be accurate regardless of which runtime loads it.

6. **Update `AGENTS.md` when you learn something new.** If you discover a runtime nuance, a Smartsheet MCP behavior, a chaining edge case, or any pattern that isn't documented here, add it. This file is the single source of truth for how agents are written in this repo — keep it current.

For the full contributing guide including design principles, PR checklist, and expansion pack ideas, see `CONTRIBUTING.md`.
