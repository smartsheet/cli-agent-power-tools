# CLI Agent Power Tools for Smartsheet

Three open-source, opinionated Claude Code agents that turn the most common project-manager tasks into a sentence you type instead of an hour you click through.

**Find the bottleneck. Reassign the work. Clone the engagement.** All from your terminal, all using the Smartsheet MCP tools, all installable in sixty seconds.

---

## What this is

A starter pack of three local agents for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview), purpose-built against the [Smartsheet MCP server](https://mcp.smartsheet.com). Each one is a single markdown file under `.claude/agents/`. They activate automatically when you ask the right question, and they come pre-loaded with twenty years of Smartsheet behavior baked in.

| Stage | Power Tool | The prompt | What it typically replaces |
|---|---|---|---|
| **READ** | `bottleneck-scanner` | *"Who's the bottleneck across my active projects?"* | Opening sheets, counting tasks by owner, cross-checking thread context |
| **WRITE** | `reassignment-helper` | *"Reassign everything from Alex to Jordan."* | Filtering each sheet, clicking each row, checking access |
| **CREATE** | `engagement-cloner` | *"Clone this project sheet for a new engagement."* | Finding a template, copying, clearing data, renaming, re-sharing |

These aren't just prompts. Each Power Tool is a **local agent** on your machine that orchestrates deep calls into our platform — reading discussion threads, writing to the work graph, composing against Smartsheet's production MCP tools, all operating within your Smartsheet session. Local intelligence on your terminal, commanding twenty years of Smartsheet behavior.

---

## Why these three, in this order

The adoption arc that actually works is **Read → Write → Create.**

Start with the question you'd be embarrassed to ask a human — read-only, nothing changes, you just want to know. Move to the change you used to do by hand — previewed, confirmed, batched. End at the creation task you're tired of doing at the start of every engagement.

Most teams try to lead with the most impressive demo. Most teams burn out on AI adoption because the impressive demo was a write operation that made a mistake in week two. This pack is ordered the way real trust gets built.

---

## Quick install

```bash
# 1. Install Claude Code
npm install -g @anthropic-ai/claude-code

# 2. Clone this pack
git clone https://github.com/smartsheet/cli-agent-power-tools
cd cli-agent-power-tools

# 3. Get your Smartsheet Personal Access Token
# Go to Account > Personal Settings > API Access in Smartsheet to generate one

# 4. Set up Smartsheet MCP connection (choose one option):

# Option A: Run the automated setup script
./smartsheet_mcp_setup.sh

# Option B: Manual setup following Smartsheet's documentation
# https://developers.smartsheet.com/ai-mcp/smartsheet/install-the-smartsheet-mcp-server/connect-claude-code

# 5. Start Claude Code — Power Tools load automatically from .claude/agents/
claude
```

Then just ask:

```
> Who's the bottleneck across my active projects?
```

Power Tools route automatically based on what you ask. You can also invoke them explicitly: `use bottleneck-scanner on the Healthcare practice`.

---

## How this differs from Smartsheet's platform sub-agents

Worth making this explicit, because the words look similar.

**Smartsheet's platform sub-agents** are the production-grade, credit-bearing intelligence layer inside SmartAssist — Risk Analysis, Dependency Detection, Executive Summary, Resource Optimizer, and others. They run on Smartsheet's infrastructure, use proprietary execution data across 100K+ organizations, and are what customers are paying for when they use the platform's AI features.

**CLI Agent Power Tools** are something different. They're personal prompt configurations that live on your laptop, run in your Claude Code session, and use only the read/write/create MCP tools our server already exposes publicly. They don't invoke platform sub-agents. They don't carry Smartsheet's proprietary intelligence. They're the "get more out of the MCP tools you already have" toolkit.

Think of it this way: platform sub-agents are the industrial machinery. Power Tools are the sharp hand tools you keep in your desk drawer. Both useful, both Smartsheet-made, different jobs.

---

## Folder structure

```
cli-agent-power-tools/
├── .claude/
│   └── agents/
│       ├── bottleneck-scanner.md       ← READ
│       ├── reassignment-helper.md      ← WRITE
│       └── engagement-cloner.md        ← CREATE
├── .mcp.json                           # Shared team MCP config
├── LICENSE                             # MIT
├── CONTRIBUTING.md                     # How to submit new Power Tools
├── USAGE.md                            # Invocation, task automation, chaining
└── README.md                           # This file
```

One git pull gets your whole team the same setup.

---

## What's next

This is v1. If these find their people, we'll ship new expansion packs. Here's what we're thinking about — subject to change, open to contribution:

- **Daily Cadence pack** — `risk-scanner`, `standup-prep`, `status-comms-writer`. For teams that want AI running the daily rhythm, not just the portfolio-level work.
- **Governance pack** — `data-quality-auditor`, `dropdown-standardizer`, `stale-cleanup`, `permission-sweep`. For the PMO that owns sheet hygiene at scale.
- **Setup pack** — `workspace-organizer`, `template-converter`, `starter-sharer`. For the first 30 days of a new team or customer onboarding.

Pull requests welcome. See `CONTRIBUTING.md`.

---

## The bigger idea

Everyone in enterprise software this quarter is gluing a chatbot onto a shallow product and calling it AI. Talk to your todo list. Ask your spreadsheet a question. Cute demos; not much underneath.

Our MCP isn't reaching into a todo list. It's reaching into twenty years of workflow engine, a full dependency graph, row-level discussion threads, workspace hierarchy, formula resolution, cross-sheet references, permission model, and governance built before "AI governance" was a phrase anyone said out loud.

Put a terminal on top of a calendar app — you get a gimmick. Put a terminal on top of *that* — and a project manager can run a portfolio from it.

The CLI isn't the point. The work graph is the point. Local agents are the mechanism that lets you compose against twenty years of operational depth, at the speed of a sentence.

---

## A note on the underlying mechanism

For the technically curious: CLI Agent Power Tools are implemented as [Claude Code sub-agents](https://docs.claude.com/en/docs/claude-code/overview) — markdown files with YAML frontmatter under `.claude/agents/`. We call them Power Tools in our copy to keep them clearly distinct from Smartsheet's platform sub-agents, which are a separate product concept. The mechanism is Anthropic's; the domain expertise baked in is ours.

---

## License

MIT. Take it, fork it, ship derivatives. See `LICENSE`.

---

*Built by the Smartsheet AI Platform team. Maintained by Drew Garner, SVP of AI & Platform Strategy.*
