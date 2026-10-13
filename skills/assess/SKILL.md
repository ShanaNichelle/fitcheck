---
name: assess
description: Assess how well a resume fits a job posting, the way an applicant tracking system (ATS) would. Produces a fit assessment (HTML and PDF) with a current score, a projected score, and the truthful changes that close the gap. Use when the user asks to assess their fit, asks "am I a good fit for this role", "should I apply to this", "how does my resume match this job", wants an ATS check or score, or shares a job posting alongside their resume.
---

# Fitcheck: Assess

Read a resume as an applicant tracking system does, score it against one posting, and recommend the changes that raise the score **without inventing anything**. This skill recommends only. Building the tailored resume is the `tailor` skill; tracking is the `track` skill.

**First, read `<this skill's base directory>/../../shared/setup.md`** and complete any missing setup. It defines `{SHARED}`, `{OUTPUT_ROOT}`, the application folder, the `fitcheck data` files, and rules that apply to everything below.

## Inputs

- **Job description**: a URL or pasted text. For a URL, try WebFetch first, but WebFetch summarizes, and scoring needs the exact wording. If the result looks summarized, fetch the raw page with `curl -sL "<url>"` and strip the HTML tags. If both fail, ask for a paste.
- **Resume**: a PDF, HTML, DOCX, or TXT path. If none is given, ask. Prefer the PDF they actually submit, since that is what the ATS reads.
- **Context**: everything in `CAREER_HISTORY`, plus anything the user adds for this run. These are the only places a "surface" change may come from. With `none`, score from the resume alone.

## Steps

### 1. Parse the resume like an ATS

```
swift {SHARED}/ats_parse.swift "<resume path>"
```

The `=== TEXT ===` block is what the ATS sees. **All matching runs against this text, never the source.** The `=== DIAGNOSTICS ===` block feeds Parse health and the ATS formatting section. Lines starting `!!` are issues.

Also read the TEXT top to bottom once, like a person, and note anything the diagnostics cannot catch: a job title and employer fused onto one line with the description, dates separated from their job, a running header splitting a bullet, sections out of order.

### 2. Read the JD and the rules

- Pull company, role title verbatim, location and work model, salary if published, and the posting URL.
- Read `{SHARED}/scoring.md` and follow it exactly: segment the JD into buckets, extract terms in the JD's own wording, and weight them.
- Read `~/.fitcheck/rules.md`. A resume line that breaks one of its rules is a **cut** row.

### 3. Read the context

Read every context source. Build a working list of **claimable facts**, each with its source (file and section, case study name, or story title). A term is "missing but true" only if a claimable fact supports it.

### 4. Score

Follow `scoring.md` steps 3 through 7 to get K, T, Q, P and the overall **Current** score. Then draft the changes (step 5) and rescore the resume as it would read after them: **Projected**. Check the arithmetic before writing anything.

### 5. Recommend changes

Each change is one numbered row, with a tag, a **source**, and the **points** it adds (the overall score difference it makes on its own, rounded; use "<1" when small).

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
- Formatting fixes go in the ATS formatting section, not the rationale table, but their effect is included in Projected. The tailored resume layout fixes most of them automatically.

### 6. Write the assessment

- Work out the application folder per `setup.md`. If it already holds an assessment of this **same posting**, ask: *"You already have an assessment for this role from {date}. Replace it, or keep both?"* Keep both means `Fit Assessment 2` (then 3) for the HTML and PDF.
- Copy `{SHARED}/template.html` and fill every placeholder. Section order is fixed:
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
- Save as `Fit Assessment.html`, then render:
  `bash {SHARED}/render.sh "{folder}/Fit Assessment.html" "{folder}/Fit Assessment.pdf"`
- Open the PDF once with the Read tool to check it rendered (tables intact, nothing cut off).

### 7. Save the working notes

Write these to `{folder}/fitcheck data/` so the `tailor` skill can pick up later, even in a new session or after the posting is taken down:

- `posting.txt`: posting URL, date fetched, company, role title, then the full posting text verbatim.
- `scoring.md`: one table of every term (term, bucket, weight, current credit, projected credit), then K, T, Q, P and the overall Current and Projected.
- `changes.md`: at the top, the resume path that was scored, the context files used, and the date. Then every change from step 5 as a numbered list: tag, the change in full (exact wording to add or remove, and where), source, points, and `Status: proposed`. Formatting fixes are listed too.

### 8. Report and hand off

In chat, keep it short:
- Current and Projected, and the verdict line. If the fit is weak, say so first.
- The changes as a numbered list (tag, change, points)
- Any hard gate or formatting issue
- The path to `Fit Assessment.pdf`

Then ask: *"Want me to build the tailored resume with all of these, or drop or change any first?"*

- If they say go, or name changes to drop or edit: update each `Status` in `changes.md` to `approved`, `dropped`, or `edited` (with the new wording), then continue with the `tailor` skill's steps.
- If they stop here: leave statuses as `proposed`. Tell them they can come back any time with `/fitcheck:tailor {Company}`.

## Guardrails

- Score against parsed text only.
- Report Projected honestly, even when it is below the 90 to 95 target.
- This skill writes only the assessment and the `fitcheck data` notes. It never edits the user's resume.
