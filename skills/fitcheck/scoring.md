# Fitcheck Scoring

The score simulates how an applicant tracking system ranks a resume against a posting. It is not any one vendor's algorithm. It models what Workday, Greenhouse, Lever, iCIMS, Ashby, and resume scanners such as Jobscan have in common:

1. They **parse** the file into plain text and fields. What fails to parse earns nothing.
2. They apply **knockout** rules (years, degree, location, authorization) before any ranking.
3. They **match terms literally**. They do not understand synonyms.
4. They weight the **job title** heavily, because recruiters search by title first.

Weights are never fixed in advance. They come from **how this JD is worded**: which section a term sits in, and how often the posting repeats it.

## Step 1: Segment the JD

Sort every line of the posting into one bucket:

| Bucket | Typical headings | Term weight |
| :- | :- | :- |
| Title | The posting title itself | Scored separately (see Title alignment) |
| Required | Requirements, Qualifications, What you'll need, You have, Must have, Minimum | 3 |
| Responsibilities | What you'll do, Responsibilities, In this role, Your impact | 2 |
| Preferred | Nice to have, Bonus, Preferred, Plus, Extra credit | 1 |
| Context | About us, Benefits, Culture, EEO, Salary, Perks | 0, ignore |

If a posting has no headings, use its own language: "must", "required", "you have" put a line in Required, while "ideally", "a plus", "bonus" put it in Preferred. Everything else goes in Responsibilities.

## Step 2: Extract terms

From the Required, Responsibilities, and Preferred buckets, pull every term an ATS could match. **Keep the JD's exact wording.**

- **Hard skills and tools**: whatever the field names. Figma or design systems for a designer; Python, AWS, or CI/CD for an engineer; Salesforce or pipeline forecasting in sales; Epic or triage in nursing; GAAP or month end close in accounting
- **Methods and practices**: user research, Agile, root cause analysis, account planning, patient education, data-driven, end-to-end
- **Domain**: consumer, B2B, SaaS, fintech, healthcare, logistics, public sector, e-commerce
- **Soft skills**: collaboration, communication, ambiguity, influence, stakeholder management
- **Credentials and thresholds**: years of experience, degree, certification, location, authorization

Merge duplicates into one term with a mention count. "Design system" in Responsibilities plus "design systems" in Required becomes one term, bucketed at its highest weight, with mentions = 2.

**Term weight** = bucket weight + 1 for each extra mention (cap +2), then multiply by:

- Hard skills, tools, methods, domain: ×1.0
- Soft skills: ×0.5. ATS tools weight these low, and nearly every resume claims them.

Write each term's weight into the working notes. The final document reports the top weighted terms, so the scoring can be checked.

## Step 3: Match against the parsed text

Match against the **TEXT output of `ats_parse.swift`**, never the HTML source. If the parser lost it, the ATS lost it.

| Match | Credit | Example |
| :- | :- | :- |
| Exact phrase, in summary or experience | 1.0 | JD "stakeholder management", resume bullet "stakeholder management" |
| Exact phrase, only in Skills or Areas | 0.85 | Listed, but not shown in use |
| Variant: plural, stem, word order, hyphenation, acronym alone | 0.5 | JD "A/B testing", resume "AB tests"; JD "user experience (UX)", resume "UX" only |
| Synonym only | 0.1 | JD "user research", resume "customer interviews" |
| Absent | 0 | |

When the JD gives an acronym alongside its spelled out form, the resume should carry both once: "WCAG 2.1 AA (Web Content Accessibility Guidelines)" is overkill, but "user experience (UX)" style pairs matter for the posting's core terms.

**Keyword score (K)** = Σ(weight × credit) ÷ Σ(weight) × 100.

Repetition beyond twice adds nothing to K. Never recommend stuffing.

## Step 4: Title alignment (T)

Compare the posting's title with the resume's role line, headline, and most recent job title, as parsed.

| Match | T |
| :- | :- |
| Exact posting title appears (role line or a held title) | 100 |
| Same seniority and same core noun ("Senior Project Manager" vs "Senior Technical Project Manager") | 75 |
| Core noun only, seniority differs or absent | 45 |
| Different function | 0 |

For a split title such as "Sr./Staff Software Engineer", matching either level counts as exact. The role line under the name is a free, truthful fix whenever the candidate actually does that job. Recommend it every time T is below 100.

## Step 5: Qualifications (Q)

Score the knockout style items the JD states: years, degree, certifications, location, authorization, clearance.

- Years come from the parsed date ranges, the way an ATS computes them, not from a "6+ years" claim in the summary. Overlapping roles are counted once. Volunteer and consulting roles count only if they appear under Experience with dates.
- Degree: "or equivalent" accepts a relevant diploma, certificate, or equivalent experience.
- Each stated item is met (1), partially met (0.5), or missed (0). Q = average × 100.
- **If the JD states no such items, Q's weight is redistributed to K.**

**Hard gate rule:** if a stated item is an explicit minimum (a "must", or a numeric threshold) and it is missed, the overall score is **capped at 60**, whatever the other components say. Name the gate in the Hard gates section.

## Step 6: Parse health (P)

Start at 100. Deduct for each issue the parser reports or the HTML scan finds:

| Issue | Deduction |
| :- | :- |
| Nearly empty text (image or scanned PDF) | 100 |
| Contact details missing from body text | 30 |
| No recognizable Experience heading | 25 |
| Reading order scrambled (columns, tables, positioned text) | 20 |
| Glyph or icon before a section heading or job title | 10 each, max 20 |
| Decorative glyphs elsewhere, private use characters, failed decodes | 5 each, max 15 |
| Mixed or missing date formats | 10 |
| No Education or Skills heading | 5 each |
| Running header or footer carrying content | 10 |
| Portfolio or LinkedIn as link text with no visible URL | 5 |

Ordinary typography is fine and never deducted: • bullets, en dashes in date ranges, curly quotes, the pipe character, ampersands.

## Step 7: Combine

```
Overall = 0.65·K + 0.15·T + 0.10·Q + 0.10·P
          (if no stated qualifications: 0.75·K + 0.15·T + 0.10·P)
          capped at 60 if a hard gate is missed
```

Round to a whole number.

## Two scores

| Score | How it is computed |
| :- | :- |
| **Current** | The resume exactly as given |
| **Projected** | The resume after every recommended change, rescored with the same rules |

Recommend every truthful change, so Projected is the honest top for this resume and context. If a true change is left out (page space, tone), still list it as a row, mark it "not applied," and give its points, so the remaining headroom is visible without a separate score.

**Target:** 90 to 95. If Projected is below 90, say so in the score box, and name the two or three unclaimable gaps that hold it there. A truthful 84 is the right answer when 84 is the truth.

Do not chase 100. A resume matching every term verbatim reads as stuffed to the human who opens it next, and some ATS tools flag near verbatim JD copying. Ninety to 95 is the realistic top band.

## Calibration

These are simulations. Report sub scores (K, T, Q, P) in the "How it was scored" section so anyone reading can check the arithmetic. When a final rescore after tailoring differs from Projected by more than 3 points, say why.
