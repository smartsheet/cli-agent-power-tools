# Using the CLI Agent Power Tools

Ways to use these: interactively, as one-shot tasks, or chained through the Read → Write → Create adoption arc with stage gates. Pick the depth that matches the workflow.

---

## 1. Invoking a Power Tool

Once the pack is installed and Claude Code is running, Power Tools activate three ways:

**Natural language.** Just ask for what you need. Claude Code reads each Power Tool's `description` field and picks the right one.

```
> Who's the bottleneck across my active projects?
→ bottleneck-scanner engages

> Reassign everything from Alex to Jordan
→ reassignment-helper engages

> Clone the Q2 Phoenix sheet for the new Acme engagement
→ engagement-cloner engages
```

**Explicit invocation.** Name the Power Tool when you want to skip the routing.

```
> Use bottleneck-scanner on the Healthcare practice
> Use reassignment-helper to move Alex's work to Jordan, exclude Phoenix
> Use engagement-cloner with Q2 Phoenix as the template, new name "Q3 Healthcare — Acme"
```

**Inside Claude Code's conversation flow.** When the main Claude Code instance delegates to a Power Tool, it runs in its own context with its own restricted tool set. The output comes back summarized into the main conversation.

---

## 2. Running Power Tools as Tasks

This is where the CLI earns its keep. Every Power Tool can run unattended.

### One-shot headless invocation

Use `claude -p` for a non-interactive run.

```bash
claude -p "Use bottleneck-scanner on the Healthcare practice"
```

Add `--output-format json` when piping into another tool.

```bash
claude -p "Use bottleneck-scanner on the Healthcare practice" --output-format json
```

### Scheduled jobs (cron)

Run a weekly bottleneck scan, pipe the result into Slack.

```bash
# Monday morning overload scan → #pmo-leadership
0 8 * * 1  cd ~/my-projects \
  && claude -p "Use bottleneck-scanner on workspace Healthcare practice" \
  | slack-cli post --channel pmo-leadership
```

Draft the handover previews when someone rolls off, so you're not scrambling Friday night.

```bash
# Every Friday 4pm, draft next-week handovers based on the roll-off sheet
0 16 * * 5  cd ~/my-projects \
  && claude -p "Check the roll-off sheet. For any person rolling off next week, use reassignment-helper in dry-run mode to preview what would move where. Email me the summaries." \
  | mail -s "Next week's handovers — draft previews" pmo-lead@example.com
```

### Event-triggered (CI/CD)

Block a release if the engagement sheet it depends on has too many overloaded owners.

```yaml
# .github/workflows/release-gate.yml
- name: Capacity gate
  run: |
    SCAN=$(claude -p "Use bottleneck-scanner on the Release Train workspace" --output-format json)
    BLOCKERS=$(echo "$SCAN" | jq '.overloaded_owners | length')
    if [ "$BLOCKERS" -gt 2 ]; then
      echo "Too many overloaded owners on the release path — halting"
      exit 1
    fi
```

### Hooks (always-on automation)

Claude Code hooks fire on session events. Auto-run a bottleneck scan on the first session start of the week.

```json
// .claude/hooks.json
{
  "onSessionStart": "If today is Monday and it's before 10am local time, silently invoke bottleneck-scanner on the default workspace and prepend findings to my first user message."
}
```

---

## 3. Chaining Power Tools with Stage Gates

**The advanced pattern.** The three Power Tools compose into the Read → Write → Create adoption arc. Each stage's output feeds the next — but only through explicit human approval at each gate.

This is the pattern that lets a PMO scale AI-assisted portfolio operations without ever letting the AI execute a write somebody didn't approve.

### The canonical chain

```
┌─────────────────────┐  gate 1  ┌─────────────────────┐  gate 2  ┌─────────────────────┐
│ bottleneck-scanner  │ ──────>  │ reassignment-helper │ ──────>  │ engagement-cloner   │
│ (READ — diagnose)   │ approve? │ (WRITE — rebalance) │ approve? │ (CREATE — new work) │
└─────────────────────┘          └─────────────────────┘          └─────────────────────┘
         validate                         validate                         validate
```

**The story it tells:** Monday morning — scan finds Sarah overloaded. Gate 1 — PM approves the proposed redistribution. Reassignment helper moves 4 low-priority rows from Sarah to Jordan and leaves a paper trail. Gate 2 — PM approves spinning up a new engagement to formalize the new scope Jordan just absorbed. Engagement cloner creates the new sheet. Every step, the human said yes.

### Interactive chain (human in the loop at each gate)

```bash
# Stage 1 — READ — Diagnose
SCAN=$(claude -p "Use bottleneck-scanner on the Healthcare practice" --output-format json)

COUNT=$(echo "$SCAN" | jq '.overloaded_owners | length')
if [ -z "$COUNT" ] || [ "$COUNT" = "null" ] || [ "$COUNT" -eq 0 ]; then
  echo "No overloaded owners found — nothing to chain"
  exit 0
fi

echo "Found $COUNT overloaded owners."
echo "$SCAN" | jq '.overloaded_owners'
echo "$SCAN" | jq '.redistribution_candidates'

# Gate 1
read -p "Proceed to reassignment? [y/N]: " go
[ "$go" = "y" ] || exit 0

# Stage 2 — WRITE — Rebalance
FROM=$(echo "$SCAN" | jq -r '.redistribution_candidates[0].owner_from')
TO=$(echo "$SCAN" | jq -r '.redistribution_candidates[0].suggested_owner_to')
REASSIGN=$(claude -p "Use reassignment-helper with prior context: $SCAN. Move the suggested candidates from $FROM to $TO, confirm before writing." --output-format json)

echo "$REASSIGN" | jq '.write_results'

# Gate 2
read -p "Proceed to engagement clone for the rebalanced scope? [y/N]: " go
[ "$go" = "y" ] || exit 0

# Stage 3 — CREATE — Formalize
claude -p "Use engagement-cloner to spin up a new sheet for the rebalanced scope, using the primary sheet from the reassignment as the structural source."
```

### Dry-run before any write

When a Power Tool offers to make changes, always preview first. Claude Code's permission system gates writes by default, but an explicit dry-run is belt-and-braces — especially for reassignments that touch many rows.

```bash
claude -p "Use reassignment-helper to move everything from Alex to Jordan.
           Preview only. Do not write. Return the plan as JSON."
```

Review the plan. If it looks right, approve the execution as a second call that references the same scope.

### Validation patterns

Each Power Tool returns output you can validate before using it. Minimum contract:

| Power Tool | Must always return | Halt if missing |
|---|---|---|
| `bottleneck-scanner` | `scanned_sheets`, `overloaded_owners`, `redistribution_candidates` | Yes |
| `reassignment-helper` | `source`, `target`, `rows_changed`, `write_results`, `permission_issues` | Yes |
| `engagement-cloner` | `new_sheet_id`, `destination`, `columns_created`, `carryover_decisions` | Yes |

If validation fails at any stage, halt the chain and surface the failure. Don't let a malformed stage pass bad data downstream — that's where chained AI workflows go wrong.

### Why stage gates matter

Three principles worth internalizing before you build a chain:

**AI analyzes and recommends; humans decide and act.** Gates enforce the boundary between analysis (cheap, reversible) and action (consequential, sometimes irreversible).

**Every write needs a reader.** Before any Power Tool modifies a sheet, creates a row, or reassigns an owner, a human sees the proposed change and approves it.

**Fail loud, not silent.** A chain that halts on bad data is a chain that can be debugged. A chain that papers over bad data is a chain that lands you explaining to your VP why Jordan now owns 47 rows they never asked for.

---

## Quick reference — the three Power Tools

| Power Tool | Stage | Invocation style | Best as a task | Chains to |
|---|---|---|---|---|
| `bottleneck-scanner` | READ | Monday morning, before portfolio review | Cron → Slack | Feeds `reassignment-helper` |
| `reassignment-helper` | WRITE | When someone rolls off, on leave, re-slotted | Dry-run on cron, live on demand | Feeds `engagement-cloner` |
| `engagement-cloner` | CREATE | Engagement kickoff, new wave starts | On-demand only (create ops rarely scheduled) | Usually the last stage |

---

## Where to go next

- **New to the pack?** Run `bottleneck-scanner` interactively on a practice or workspace you know well. See what it surfaces.
- **Ready to automate?** Schedule `bottleneck-scanner` as a weekly cron. Low risk, high signal, builds habit.
- **Building a chain?** Start with the Read → Write arc. Add Create once the first two are muscle memory.
- **Contributing?** See `CONTRIBUTING.md`. Keep new Power Tools under 300 lines, scoped, and opinionated.
