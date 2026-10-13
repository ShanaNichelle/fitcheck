---
name: track
description: Track job applications in the user's chosen tracker (Notion or a spreadsheet). Use when the user asks to update an application's status ("mark Acme as Applied"), add a note or a follow up date, log or track a role, see what they have applied to or what is pending, or change how they track applications.
---

# Fitcheck: Track

Keep the user's application tracker current. The method they chose (Notion, spreadsheet, or none) is saved in `~/.fitcheck/config.md`, so never ask them again which one they use.

**First, read `<this skill's base directory>/../../shared/setup.md`**, then `{SHARED}/tracking.md`, and follow them.

## What the user might ask

| Request | Do |
| :- | :- |
| "Mark Acme as Applied", "add a note to Acme", "set a follow up for Friday" | "Updating an application" in `tracking.md` |
| "Track this role", "add Acme to my tracker" | "Logging a new application". Fill what you can from that role's `fitcheck data` folder if one exists; otherwise ask for company, role, and link |
| "What have I applied to?", "what's pending?", "show my tracker" | "Showing the tracker" |
| "Track in Notion instead", "switch to a spreadsheet", "stop tracking" | Update `TRACKING` in `config.md`, then run "Tracking setup" for the new method. Offer to copy existing rows across; never delete the old tracker |

## When tracking is off

If `TRACKING` is `none` or missing, say so and ask: *"You're not tracking applications yet. Want me to set up (1) Notion or (2) a simple spreadsheet?"* If they decline, stop.

## Guardrails

- When more than one application matches, list them and ask which. Never guess.
- Change only what was asked. Never delete a row or page unless the user asks for that specific one.
- A new application to a company already in the tracker gets its own row; it never overwrites the earlier one.
