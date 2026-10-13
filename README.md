# Fitcheck

Fitcheck is a skill for [Claude Code](https://claude.com/claude-code). It reads your resume the way an applicant tracking system (ATS) does, scores it against one job posting, and tells you exactly what to change to raise the score, using only things that are true about you. It never invents experience.

Once you approve the changes, it builds the tailored resume and logs the application.

**What you get for each job:**

- **A fit assessment** (web page and PDF): your current score, the projected score after changes, every recommended change with its source and the points it adds, ATS formatting problems, and the honest gaps no rewrite can close
- **A tailored resume** (web page and PDF) in a clean, single column layout that ATS parsers read reliably, with a final score
- **A tracked application**, in Notion or a simple spreadsheet, if you want one

## What you need

- A Mac (Windows and Linux are not supported yet)
- [Claude Code](https://claude.com/claude-code)
- Google Chrome, for the PDFs
- Apple's free developer tools. If you have never installed them, Fitcheck tells you, and it takes one command.

## Install

In Claude Code, run these two commands:

```
/plugin marketplace add ShanaNichelle/fitcheck
/plugin install fitcheck@fitcheck
```

Then restart Claude Code.

## First run

Type `/fitcheck:fitcheck`, or just say "run a fit check". It asks three questions once and remembers your answers:

1. **Where to save your files.** For example `~/Documents/Job Search`.
2. **Where your career history lives.** Point it to any documents with more detail than your resume: a career summary, project case studies, interview stories. This is how Fitcheck finds true experience your resume leaves out. If you have none, say so, and it works from your resume alone. (Worth making one: a single document listing every project, metric, and story improves every future application.)
3. **How to track applications:**
   - **Notion**: you sign in once, and it adds rows to an existing database or creates one.
   - **Spreadsheet**: it creates `Applications.csv` in your folder, which opens in Numbers, Excel, or Google Sheets.
   - **Don't track.**

To change an answer later, just tell it: "fitcheck: track in a spreadsheet instead."

## Each job

```
/fitcheck:fitcheck https://jobs.example.com/posting/1234 using ~/Documents/My Resume.pdf
```

1. It writes the fit assessment and shows you the scores and recommended changes.
2. You say go, or drop or change any of them. Nothing is built until you answer.
3. It builds the tailored resume, rescores it, and logs the application.

Your original resume is never changed. Everything for a job lands in its own folder, named after the company.

**Updating an application:** just ask, for example "fitcheck: mark Acme as Applied" or "add a note to the Acme row: recruiter call Friday." If you applied to the same company more than once, it asks which application you mean.

**If you track in the spreadsheet:** keep the file as `Applications.csv`. You can open it in Numbers, Excel, or Google Sheets, but when you save, choose CSV format. If you save it in the app's own format instead, you end up with two copies that drift apart: your edits in one, Fitcheck's new rows in the other. In Numbers, use File > Export To > CSV and save over `Applications.csv`.

## Your own rules and settings

Fitcheck keeps your settings in a folder named `.fitcheck` in your home folder, so updates never erase them. Ask Claude to "open my fitcheck rules", or edit `~/.fitcheck/rules.md` yourself. There you can:

- **Turn on "Avoid dashes"** to have everything written without dashes or hyphens
- List phrases or claims you never want on your resume
- Say how certain work must be described

## How scoring works

Fitcheck weights every term in the posting by where it appears (requirements count most, nice to haves least, company boilerplate not at all) and by how often it is repeated. It then matches those terms literally against the text a parser extracts from your resume file: exact phrases earn full credit, close variants earn half, and synonyms earn almost nothing, because that is how keyword matching behaves. Job title, stated minimums such as years of experience, and how cleanly the file parses make up the rest. The full rules are in [`skills/fitcheck/scoring.md`](skills/fitcheck/scoring.md).

**Scores run lower than you might expect.** A strong resume often starts around 55 to 70. 90 to 95 is the realistic top. When that is not reachable truthfully, Fitcheck says so and explains what holds it back.

## Please read

- **The score is a simulation.** It models behavior that ATS products and resume scanners have in common. It is not the algorithm of any specific vendor, and no score guarantees an interview or a job.
- **It will not lie for you.** Every recommended change must trace to your resume or your career documents. If the posting asks for something you have not done, Fitcheck lists it as a gap.
- **You are responsible for what you submit.** Read the tailored resume before you send it.

## Privacy

Fitcheck runs on your computer inside Claude Code. Your resume, career documents, assessments, and tracker stay in the folders you choose. Fitcheck itself sends nothing anywhere. Two things to know:

- Claude Code processes what you give it under your own Claude account and its privacy terms, like anything else you do in Claude Code.
- If you choose Notion tracking, the application details you log (company, role, link, scores, notes) are saved to your Notion workspace.

## Feedback

Found a problem or have an idea? Open an issue on this repository.

## License

MIT. See [LICENSE](LICENSE).
