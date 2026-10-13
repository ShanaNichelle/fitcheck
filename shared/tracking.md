# Fitcheck Tracking

How applications are logged and updated. The user's method is `TRACKING` in `~/.fitcheck/config.md`: `notion`, `spreadsheet`, or `none`.

## Tracking setup

Run this once, when the user first picks a method or switches to a new one.

**Spreadsheet.** Create `{OUTPUT_ROOT}/Applications.csv` with this header row, and save its path as `TRACKER` in `config.md`:
`Company,Role,Posting URL,Date Added,Status,Current Score,Final Score,Resume,Notes`
It opens in Numbers, Excel, or Google Sheets. Tell the user to keep saving it as CSV.

**Notion.**
1. Check whether Notion tools are already available in this session. If not, ask permission, then run `claude mcp add --transport http notion https://mcp.notion.com/mcp`, and tell the user: *"Type /mcp, choose notion, and sign in. Then restart Claude Code and ask me again."* Stop until they do.
2. Ask: *"Do you already have an applications database in Notion? If yes, paste its link. If not, paste the link to a page where I should create one."*
3. Existing database: read its properties and map them to the fields below. Never rename or delete their properties.
   New database: create one named **Applications** under their page, with: Company (title), Role (text), Posting URL (url), Status (select: Assessed, Ready to Apply, Applied, Interviewing, Offer, Rejected, Archived), Date Added (date), Current Score (number), Final Score (number), Notes (text).
4. Save the database link as `NOTION_DATABASE` in `config.md`.

**None.** Nothing to set up. Skip every logging step silently.

## Fields

| Field | Value |
| :- | :- |
| Company | Company name |
| Role | Role title, verbatim from the posting |
| Posting URL | The posting link |
| Date Added | Today |
| Status | `Ready to Apply` once the tailored resume is built, then whatever the user says. `Assessed` only when the user asks to track a role they have assessed but not tailored |
| Current Score, Final Score | From the assessment. Final is blank until tailoring is done |
| Resume | Path to the tailored resume PDF, once it exists |
| Notes | Location, work model, and salary if published; anything the user adds |

## Logging a new application

Applications are logged when the tailored resume is built, not when a role is only assessed, so the tracker holds roles the user is actually pursuing. The user can ask to track an assessed role at any time.

- **spreadsheet**: append one row to `TRACKER` using Python's `csv` module so commas and quotes stay safe.
- **notion**: create one new page in `NOTION_DATABASE`. Use an existing select option when one matches; never create near duplicate options. Put the resume PDF's local path in Notes.

**A new application always gets its own row.** Roles get reposted, and applying again is a separate event with its own date, resume, and outcome, so logging never overwrites an earlier row. If the company already appears for a *different* posting or an earlier round, still add a row and start its Notes with a cross reference, for example `Second application; previous row added 30 Sept 2026.`

The one case that updates instead of adding: the same posting (same Posting URL) is already tracked because it was assessed earlier and is now being tailored. Update that row's Status, Final Score, and Resume.

## Updating an application

When the user asks to change a tracked application ("mark Acme as Applied", "add a note to the Acme row", "set a follow up date"):
- Find rows matching the company, and the role if they named one.
- **Exactly one match:** make the change, then confirm what changed in one line.
- **More than one match:** do not guess. List the matches with role, date added, and status, and ask which one.
- **No match:** say so, and offer to add a row instead.
- Change only the fields they asked about. In the spreadsheet, rewrite the file with Python's `csv` module so every other row stays exactly as it was. If they ask for a field the tracker lacks (for example a follow up date), add the column or property, then set it.
- Never delete a row or page unless the user asks for that specific one.

## Showing the tracker

When asked what they have applied to, what is pending, or for a summary: read the tracker and answer in a short table (Company, Role, Status, Date Added, Final Score), newest first. Offer the obvious next step, such as following up on anything Applied more than two weeks ago.
