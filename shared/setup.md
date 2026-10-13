# Fitcheck Setup

Every Fitcheck skill reads this first. It covers where things live and the one time setup questions.

## Where things live

- **`{SHARED}`**: this folder. From any Fitcheck skill it is `<skill base directory>/../../shared` (the base directory is shown when the skill loads). Use the real path in every command.
  - `scoring.md`: the scoring rules
  - `template.html`: the fit assessment layout, styles built in
  - `resume_template.html` and `resume.css`: the tailored resume layout
  - `ats_parse.swift`: the parser simulation (macOS)
  - `render.sh`: turns HTML into PDF with Google Chrome
  - `tracking.md`: how applications are logged and updated
  - `rules_template.md`: the starting point for the user's rules file
- **`~/.fitcheck/`**: the user's own settings, kept outside the plugin so updates never erase them.
  - `config.md`: answers to the setup questions below
  - `rules.md`: standing rules and style settings (phrases to avoid, retired claims, wording preferences, the avoid dashes setting). If it does not exist, copy `rules_template.md` there.
- **`{OUTPUT_ROOT}/{Application folder}/`**: everything for one application.
  - `Fit Assessment.html`, `Fit Assessment.pdf`
  - `resume.html`, `{Full Name} Resume.pdf` (after tailoring)
  - `fitcheck data/`: the working notes that let a later session pick up where this one stopped
    - `posting.txt`: the posting's URL, the date fetched, and its full text, verbatim
    - `scoring.md`: every term with bucket, weight, current credit, and projected credit, plus K, T, Q, P
    - `changes.md`: the resume path that was scored, the context files used, the scores, and every recommended change, numbered, each with a status: `proposed`, `approved`, `dropped`, `edited`, or `applied`

**Application folder name:** the company name in plain words (`Acme`). If that folder already holds a different posting from the same company, use `Acme (Role Title)` for the new one.

## Setup questions

Read `~/.fitcheck/config.md` (create the folder if needed). Ask only the questions whose answers are missing, one at a time, and save each answer so it is never asked again. The user can change any answer later by saying so; update the file when they do.

1. **Output folder** (`OUTPUT_ROOT`). *"Where should I save your assessments and tailored resumes? For example ~/Documents/Job Search."*
2. **Career history** (`CAREER_HISTORY`). *"Do you have anything beyond your resume I can draw on: a career summary, project case studies, interview stories? Point me to the files or folder. This is how I find true experience your resume leaves out."* Save the paths, or `none`. If a saved path no longer exists on a later run, say so and ask again.
3. **Tracking** (`TRACKING`). *"How would you like to track applications? (1) Connect Notion, (2) I create a simple tracker spreadsheet for you, or (3) don't track."* Save `notion`, `spreadsheet`, or `none`, then follow "Tracking setup" in `tracking.md` for that choice.
4. **Tools.** Check `which swift` and that `/Applications/Google Chrome.app` exists. If `swift` is missing, tell the user to run `xcode-select --install` once (a free Apple install, a few minutes) and stop until it is done. If Chrome is missing, the HTML files still work; say the PDFs need Chrome.

## Rules that apply to every Fitcheck skill

- **Never manufacture experience, metrics, tools, titles, or dates.** Every claim traces to the resume or a document in `CAREER_HISTORY`.
- **Never round or estimate a metric.** Use figures exactly as the source states them.
- Peer level and direct. Honest assessment, not flattery.
- Plain words. Translate internal company jargon into language any recruiter understands.
- **Avoid dashes setting.** If `~/.fitcheck/rules.md` has `Avoid dashes: on`, use no dashes of any kind in the assessment, the resume, or file names: use commas, colons, or parentheses instead. The one exception is a hyphen inside a verbatim JD keyword (for example `data-driven`, `cross-functional`), which must stay so it matches. If the setting is `off` or missing, write normally.
