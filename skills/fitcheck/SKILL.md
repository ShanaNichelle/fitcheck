---
name: fitcheck
description: Score a resume against a job description the way an ATS would, produce a fit assessment (HTML and PDF), and after the user approves the changes, build a tailored ATS friendly resume (HTML and PDF) and log the application. Trigger when the user asks to assess fit, check ATS match, score or tailor a resume against a JD, or invokes /fitcheck.
---

# Fitcheck

Read a resume as an applicant tracking system does, score it against one posting, and recommend the changes that raise the score **without inventing anything**. Then, once the user approves, build the tailored resume, rescore it, and log the application the way the user chose.

## Files in this folder

- `scoring.md`: the scoring rules. Read it every run.
- `template.html`: the fit assessment layout, styles built in.
- `resume_template.html` and `resume.css`: the tailored resume layout. Single column and ATS friendly.
- `ats_parse.swift`: the parser simulation (macOS).
- `render.sh`: turns HTML into PDF with Google Chrome.
- `rules_template.md`: the starting point for the user's own rules file.

`{SKILL_DIR}` below means this skill's base directory, which is shown when the skill loads. Use that real path in every command.

## The user's own files

These live in `~/.fitcheck/`, outside the skill, so updates to the skill never erase them:

- `~/.fitcheck/config.md`: created on first run; holds the user's answers to the setup questions.
- `~/.fitcheck/rules.md`: the user's standing rules and style settings (phrases to avoid, retired claims, wording preferences, the avoid dashes setting). On first run, copy `rules_template.md` here if the file does not exist.

## First run setup

Read `~/.fitcheck/config.md` (create the `~/.fitcheck` folder if needed). Ask only the questions whose answers are missing, one at a time, then save every answer there so it is never asked again. The user can change any answer later by saying so; update the file when they do.

1. **Output folder** (`OUTPUT_ROOT`). *"Where should I save your assessments and tailored resumes? For example ~/Documents/Job Search."*
2. **Career history** (`CAREER_HISTORY`). *"Do you have anything beyond your resume I can draw on: a career summary, project case studies, interview stories? Point me to the files or folder. This is how I find true experience your resume leaves out."* Save the paths, or `none`. If a saved path no longer exists on a later run, say so and ask again.
3. **Tracking** (`TRACKING`). *"How would you like to track applications? (1) Connect Notion, (2) I create a simple tracker spreadsheet for you, or (3) don't track."* Save `notion`, `spreadsheet`, or `none`, then follow **Tracking setup** below for that choice.
4. **Tools.** Check `which swift` and that `/Applications/Google Chrome.app` exists. If `swift` is missing, tell the user to run `xcode-select --install` once (a free Apple install, a few minutes) and stop until it is done. If Chrome is missing, the HTML files still work; say the PDFs need Chrome.

### Tracking setup

**Spreadsheet.** Create `{OUTPUT_ROOT}/Applications.csv` with this header row, and save its path as `TRACKER`:
`Company,Role,Posting URL,Date Added,Status,Current Score,Final Score,Resume,Notes`
It opens in Numbers, Excel, or Google Sheets.

**Notion.**
1. Check whether Notion tools are already available in this session. If not, ask permission, then run `claude mcp add --transport http notion https://mcp.notion.com/mcp`, and tell the user: *"Type /mcp, choose notion, and sign in. Then restart Claude Code and run /fitcheck again."* Stop until they do.
2. Ask: *"Do you already have an applications database in Notion? If yes, paste its link. If not, paste the link to a page where I should create one."*
3. Existing database: read its properties and map them to the fields below. Never rename or delete their properties.
   New database: create one named **Applications** under their page, with: Company (title), Role (text), Posting URL (url), Status (select: Ready to Apply, Applied, Interviewing, Offer, Rejected, Archived), Date Added (date), Current Score (number), Final Score (number), Notes (text).
4. Save the database link as `NOTION_DATABASE`.

## Inputs

**Required**
- **Job description**: a URL or pasted text. For a URL, try WebFetch first, but WebFetch summarizes, and scoring needs the exact wording. If the result looks summarized, fetch the raw page with `curl -sL "<url>"` and strip the HTML tags. If both fail, ask for a paste.
- **Resume**: a PDF, HTML, DOCX, or TXT path. If none is given, ask. Prefer the PDF they actually submit, since that is what the ATS reads.

**Context**: everything in `CAREER_HISTORY`, plus anything the user adds for this run. These are the only places a "surface" change may come from. With `none`, score from the resume alone.

## Part 1: Assess

### 1. Parse the resume like an ATS

```
swift {SKILL_DIR}/ats_parse.swift "<resume path>"
```

The `=== TEXT ===` block is what the ATS sees. **All matching runs against this text, never the source.** The `=== DIAGNOSTICS ===` block feeds Parse health and the ATS formatting section. Lines starting `!!` are issues.

Also read the TEXT top to bottom once, like a person, and note anything the diagnostics cannot catch: a job title and employer fused onto one line with the description, dates separated from their job, a running header splitting a bullet, sections out of order.

### 2. Read the JD and the rules

- Pull company, role title verbatim, location and work model, salary if published, and the posting URL.
- Read `scoring.md` and follow it exactly: segment the JD into buckets, extract terms in the JD's own wording, and weight them.
- Read `~/.fitcheck/rules.md`. A resume line that breaks one of its rules is a **cut** row. Note its style settings for everything you write.

### 3. Read the context

Read every context source. Build a working list of **claimable facts**, each with its source (file and section, case study name, or story title). A term is "missing but true" only if a claimable fact supports it.

### 4. Score

Follow `scoring.md` steps 3 through 7 to get K, T, Q, P and the overall **Current** score. Then draft the changes (step 5) and rescore the resume as it would read after them: **Projected**.

Keep a working table of every term with weight, bucket, current credit, and projected credit. It is not printed in full, but it is what the numbers come from. Check the arithmetic before writing anything.

### 5. Recommend changes

Each change is one row in the rationale table, with a tag, a **source**, and the **points** it adds (the overall score difference it makes on its own, rounded; use "<1" when small).

| Tag | Use it when | Source must be |
| :- | :- | :- |
| base | Choosing which resume to start from, when the user has several versions | The file |
| reword | The resume already shows it; swap in the JD's exact wording | The resume line |
| surface | True, documented in the context, absent from the resume | Context file and section |
| promote | On the resume but buried (Skills only, last page, inside a clause); move it where it counts | The resume line |
| cut | Rule breaks, or content that earns nothing for this JD and costs space | n/a |

Rules for changes:
- **No source, no row.** If a JD term has no supporting fact anywhere, it goes in "Absent, not claimable" or "What cannot be fixed on paper". Never soften a missing qualification into a vaguer version of itself.
- Recommend every truthful change, so Projected is the honest top. A true change left out for page space still gets a row marked "not applied" with its points.
- Order rows by points, highest first, after the base row.
- Use the JD's exact phrase, in its exact form: "collaborate" and "collaborated" only match as variants. Prefer placing a high weight term in a summary or experience line (credit 1.0) over Skills only (0.85).
- Title: if T is under 100 and the candidate truthfully does the posted job, recommend the role line under the name match the posting title.
- Two mentions of a term is enough. Never recommend stuffing.
- Formatting fixes go in the ATS formatting section, not the rationale table, but their effect is included in Projected. Rebuilding in `resume_template.html` fixes most of them automatically.

### 6. Write the assessment

- Folder: `{OUTPUT_ROOT}/{Company}/`. Create it if missing; company name in plain words, spaces allowed.
- Copy `template.html` and fill every placeholder. Section order is fixed:
  1. Score box (Current, Projected; verdict; logistics)
  2. How it was scored (sub scores table, top weighted terms)
  3. Hard gates
  4. The parallel to lead with (optional)
  5. Requirement by requirement
  6. Keyword coverage (present / missing but true / absent, not claimable)
  7. Rationale for the changes
  8. **ATS formatting**: only issues actually found. If none, one line saying it parses cleanly.
  9. What cannot be fixed on paper
  10. Before applying
- Save as `Fit Assessment.html`. If `Fit Assessment.html` **or** `Fit Assessment.pdf` already exists, do not overwrite either: use `Fit Assessment 2` (then 3, and so on) for both files.
- Render: `bash {SKILL_DIR}/render.sh "{folder}/Fit Assessment.html" "{folder}/Fit Assessment.pdf"`
- Open the PDF once with the Read tool to check it rendered (tables intact, nothing cut off).

### 7. Pause for approval

Show the user, briefly:
- Current and Projected, and the verdict line
- The rationale rows as a numbered list (tag, change, points)
- Any hard gate or formatting issue
- The path to `Fit Assessment.pdf`

Ask: *"Want me to build the tailored resume with all of these, or drop or change any first?"* **Build nothing until they answer.** If they only wanted the assessment, stop here. Record any dropped or edited rows.

## Part 2: Build

### 8. Build the tailored resume

- Copy `resume_template.html` to `{OUTPUT_ROOT}/{Company}/resume.html`. Replace **all** sample content with the user's own: name, contact details, and every role, exactly as their resume states them. Never guess contact details; if one is missing, leave it out and say so.
- Replace the empty `<style>` block with the full contents of `resume.css`, so the file stands alone.
- Apply the approved changes, and only those. Every claim and metric traces to the resume or the context. Keep their strong bullets as written; edits are surgical.
- Keep it to two pages (one if they have under five years of experience, unless their original was longer). If additions push it over, cut the content that earns no terms for this posting, and record each cut as a row in the assessment.
- Zones, so nothing repeats:

  | Zone | Holds |
  | :- | :- |
  | Positioning line | 3 to 4 claims, the two second read |
  | Areas of Expertise | Practices and capabilities. 6 to 8 items, max 3 lines |
  | Skills | Things with names: tools, platforms, standards, named methods. Each term once |

  The only allowed repeat is positioning line to Areas of Expertise. Compare all three zones for near duplicates ("User Research" vs "Research & User Testing") and remove each from the Skills side.
- Check before rendering: no line breaks a rule in `~/.fitcheck/rules.md`; every approved term is present.

### 9. Render, rescore, and finalize

- Render: `bash {SKILL_DIR}/render.sh "{folder}/resume.html" "{folder}/{Full Name} Resume.pdf"`
- Open it with the Read tool: page count, layout, nothing cut off.
- Parse the new PDF with `ats_parse.swift` and rescore with `scoring.md`. Confirm each approved term actually appears in the parsed text; a term that was lost in the rewrite goes back in before you finish.
- Update `Fit Assessment.html` in place: add a **Final** score to the score box, mark dropped rows and edited rows, add any cuts made for space, and if Final differs from Projected by more than 3 points, add one sentence saying why. Re-render its PDF.

### 10. Track the application

Follow `TRACKING` from `~/.fitcheck/config.md`:
- **spreadsheet**: append one row to `TRACKER` using Python's `csv` module so commas and quotes stay safe. Status `Ready to Apply`; Resume is the PDF's path; Notes holds location and salary if published.
- **notion**: create one new page in `NOTION_DATABASE` with the same fields. Use an existing select option when one matches; never create near duplicate options. Put the resume PDF's local path in Notes.
- **none**: skip.

**A new application always gets its own row.** Roles get reposted, and applying again is a separate event with its own date, resume, and outcome, so logging never overwrites an earlier row. If the company already appears, still add a row and start its Notes with a cross reference, for example `Second application; previous row added 30 Sept 2026.`

### Updating a tracked application

When the user asks to change a tracked application (for example "mark FieldAI as Applied", "add a note to the Acme row", "set the follow up date"), update it directly in the tracker or Notion:
- Find rows matching the company (and the role, if they named one).
- **Exactly one match:** make the change, then confirm what changed in one line.
- **More than one match** (they applied to that company more than once): do not guess. List the matches with role, date added, and status, and ask which one.
- **No match:** say so, and offer to add a row instead.
- Change only the fields they asked about. In the spreadsheet, rewrite the file with Python's `csv` module so every other row stays exactly as it was.

### 11. Report

Short, in chat:
- Current, Projected, Final
- Paths to the resume PDF, resume HTML, and `Fit Assessment.pdf`
- Where it was tracked (row added, or Notion link)
- The top five posting terms to reuse in application form answers

## Writing style

- Peer level and direct. Honest assessment, not flattery. If the fit is weak, say so in the first line.
- **Avoid dashes setting.** If `~/.fitcheck/rules.md` has `Avoid dashes: on`, use no dashes of any kind in the assessment, the resume, or file names: use commas, colons, or parentheses instead. The one exception is a hyphen inside a verbatim JD keyword (for example `data-driven`, `cross-functional`), which must stay so it matches. If the setting is `off` or missing, write normally.
- Plain words. Translate internal company jargon into language any recruiter understands.

## Guardrails

- **Never manufacture experience, metrics, tools, titles, or dates.** Every claim traces to the resume or a provided context source.
- **Never round or estimate a metric.** Use figures exactly as the source states them.
- Score against parsed text only.
- Report Projected honestly, even when it is below the 90 to 95 target.
- **Never build before the user approves.** Never overwrite their original resume; the tailored one is always a new file in the company folder.
- Logging a new application never overwrites an earlier row. Edit existing rows only when the user asks, and ask which one when several match. Never delete rows or pages unless the user asks for that specific row.
