---
name: tailor
description: Build the tailored, ATS friendly resume (HTML and PDF) for a job that Fitcheck has already assessed, applying only the changes the user approved, then rescore it and log the application. Use when the user says to build, tailor, or produce the resume for a role or company, says "go ahead" after a fit assessment, or asks to apply the recommended changes.
---

# Fitcheck: Tailor

Turn an approved fit assessment into a finished resume. Apply the approved changes and nothing else, rebuild the resume in the ATS friendly layout, rescore it, and log the application.

**First, read `<this skill's base directory>/../../shared/setup.md`** and complete any missing setup. It defines `{SHARED}`, `{OUTPUT_ROOT}`, the application folder, the `fitcheck data` files, and rules that apply to everything below.

## Steps

### 1. Find the assessment

- If this continues straight from the `assess` skill in the same conversation, use that application folder.
- Otherwise match what the user said ("tailor Acme", "build the resume for the design role") against the folders in `{OUTPUT_ROOT}` that contain `fitcheck data/`.
  - **One match:** use it.
  - **Several:** list them with role and assessment date, and ask which.
  - **None:** say there is no assessment for that role yet, and offer to run one now with the `assess` skill. Do not tailor without an assessment.
- Read `fitcheck data/posting.txt`, `scoring.md`, and `changes.md`, plus `Fit Assessment.html`. Confirm the resume path in `changes.md` still exists; if not, ask for the resume.
- If the assessment is more than a few weeks old, mention the date, and that the posting may have changed or closed.

### 2. Confirm the changes

- If every change in `changes.md` is already `approved`, `dropped`, or `edited`, go on.
- If any are still `proposed`, show the numbered list (tag, change, points) and ask: *"Build with all of these, or drop or change any?"* **Build nothing until they answer.** Record each answer as the row's `Status`.

### 3. Build the resume

- Copy `{SHARED}/resume_template.html` to `{folder}/resume.html`. Replace **all** sample content with the user's own: name, contact details, and every role, exactly as their resume states them. Never guess contact details; if one is missing, leave it out and say so.
- Replace the empty `<style>` block with the full contents of `{SHARED}/resume.css`, so the file stands alone.
- Apply the `approved` and `edited` changes, and only those. Every claim and metric traces to the resume or the context files named in `changes.md`. Keep their strong bullets as written; edits are surgical.
- Apply every formatting fix the assessment lists.
- Keep it to two pages (one if they have under five years of experience, unless their original was longer). If additions push it over, cut the content that earns no terms for this posting, and add each cut to `changes.md` as a new row.
- Zones, so nothing repeats:

  | Zone | Holds |
  | :- | :- |
  | Positioning line | 3 to 4 claims, the two second read |
  | Areas of Expertise | Practices and capabilities. 6 to 8 items, max 3 lines |
  | Skills | Things with names: tools, platforms, standards, named methods. Each term once |

  The only allowed repeat is positioning line to Areas of Expertise. Compare all three zones for near duplicates ("User Research" vs "Research & User Testing") and remove each from the Skills side.
- Check before rendering: no line breaks a rule in `~/.fitcheck/rules.md`.

### 4. Render and rescore

- Render: `bash {SHARED}/render.sh "{folder}/resume.html" "{folder}/{Full Name} Resume.pdf"`
- Open it with the Read tool: page count, layout, nothing cut off.
- Parse the new PDF: `swift {SHARED}/ats_parse.swift "{folder}/{Full Name} Resume.pdf"`. It should report no `!!` issues.
- Rescore against the saved `scoring.md` term table using `{SHARED}/scoring.md`. **Check every approved term actually appears in the parsed text**, and check the terms that were already present are still there: a rewrite can drop a term the original had. Anything lost goes back in before you finish.

### 5. Finalize the assessment

- Update `Fit Assessment.html` in place: add a **Final** score to the score box (`<div>Final<span class="score">NN</span></div>` after Projected), mark dropped and edited rows, add any cuts made for space, and say the formatting issues are fixed. If Final differs from Projected by more than 3 points, add one sentence saying why. Re-render its PDF.
- Update `changes.md`: set each change that went in to `Status: applied`, and record the Final score and the resume PDF path.

### 6. Log the application

Follow `{SHARED}/tracking.md`, "Logging a new application", with Status `Ready to Apply`. If `TRACKING` is `none`, skip.

### 7. Report

Short, in chat:
- Current, Projected, Final
- Paths to the resume PDF, `resume.html`, and `Fit Assessment.pdf`
- Where it was tracked (row added or updated, or the Notion link)
- The top five posting terms to reuse in application form answers
- A reminder to read the resume before sending it

## Guardrails

- **Never build before the user approves the changes.**
- **Never overwrite the user's original resume.** The tailored one is always a new file in the application folder. If `resume.html` already exists there, ask before replacing it.
- This skill never submits an application anywhere.
