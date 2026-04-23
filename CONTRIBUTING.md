# Contributing to CLI Agent Power Tools

We want this to grow. PRs are welcome, forks are welcome, derivatives are welcome. Here's the bar for what gets merged.

---

## Design principles

Every Power Tool in this repo has to pass these:

**One workflow, one file.** A Power Tool does one thing a project manager actually does every week. Not five things, not "a general utility." If your Power Tool needs a paragraph to describe its scope, it's doing too much.

**Under 300 lines.** The frontmatter, system prompt, output contract — all of it, under 300 lines. If you need more, the Power Tool is too big. Split it into two.

**Opinionated, not neutral.** Bake the domain knowledge in. "Overdue means Due Date < today AND Status ≠ Complete." "CONTACT_LIST columns take emails not names." "Parent rows auto-roll up — don't double-count." Teach the agent what a good PM knows.

**Restricted tool set.** List only the MCP tools the Power Tool actually needs. A READ-stage tool should have no write tools. A WRITE-stage tool should have no create tools. Scope is a feature.

**Confirms before every write.** No Power Tool writes without showing the user what will change and getting an explicit "yes." Even if the user's original ask was unambiguous.

**Leaves a paper trail.** Any Power Tool that modifies data should document what it did, where, and why — via row comments, discussion threads, or sheet-level notes.

**Returns a structured output contract.** Every Power Tool must publish the JSON shape it returns. This is what makes chaining possible.

---

## File shape

Every `.md` file under `.claude/agents/` follows the same skeleton:

```markdown
---
name: your-power-tool-name
description: One sentence on what it does, one sentence on when to use it, then trigger phrases.
tools: mcp__smartsheet__<only the tools you need>
---

# Your Power Tool Name

One opening line on purpose. Reference the Read → Write → Create stage if applicable.

## What you do
<numbered list of behaviors>

## How to respond
<output format with an example>

## After the action
<concrete follow-on offer>

## Write rules (if applicable)
<MCP-specific gotchas>

## What not to do
<PM-specific pitfalls>

## Efficient tool use
<token-aware tool call patterns>

## Output contract (for chaining)
<JSON schema example>
```

Copy the shape of `bottleneck-scanner.md`, `reassignment-helper.md`, or `engagement-cloner.md` as a starting point.

---

## What we're looking for

**Daily Cadence pack** (in progress):
- `risk-scanner` — daily risk sweep across active projects
- `standup-prep` — pre-meeting brief, 3 items worth raising
- `status-comms-writer` — drafts emails, Slack updates, escalations from live data

**Governance pack** (open):
- `data-quality-auditor` — null values, inconsistent dropdowns, orphaned rows
- `dropdown-standardizer` — fixes "Done" / "Complete" / "Finished" drift
- `stale-cleanup` — flags active-status items with 30+ day staleness
- `permission-sweep` — audits who has access to what, flags over-sharing

**Setup pack** (open):
- `workspace-organizer` — bulk workspace/folder restructuring
- `template-converter` — turns working sheets into reusable templates
- `starter-sharer` — bulk-shares new sheets to the right groups on creation

If you're building something that doesn't fit any of these, we'll likely accept it if it passes the design principles above — just open an issue first so we can talk about where it slots in.

---

## Pull request checklist

Before you submit:

- [ ] Power Tool file is under 300 lines
- [ ] Frontmatter has `name`, `description` with trigger phrases, and a scoped `tools` list
- [ ] All MCP tools listed are actually used in the system prompt
- [ ] Output contract JSON schema is included
- [ ] Behaviors are opinionated — the agent knows the domain quirks
- [ ] `README.md` tool table updated if this is a new headline Power Tool
- [ ] `USAGE.md` updated if new chaining patterns are enabled
- [ ] You tested it against at least one real Smartsheet sheet

---

## Code of conduct

Be kind. Be specific. Be useful. If your PR comment sounds like something you'd be uncomfortable saying to a coworker at lunch, rewrite it. We don't have time for the other thing.

---

## Questions

Open an issue on the repo, or reach out to the maintainers. We read everything.
