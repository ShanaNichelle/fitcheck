// ATS parse simulation for fitcheck.
// Reads a resume the way an applicant tracking system does: as plain extracted text,
// then reports anything a parser would choke on.
//
//   swift ats_parse.swift <resume.pdf | resume.html | resume.docx | resume.txt>
//
// HTML is first rendered to PDF with headless Chrome, because the PDF is what gets submitted.
// Output has two parts: === TEXT === (what the ATS sees) and === DIAGNOSTICS ===.

import Foundation
import PDFKit

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

guard CommandLine.arguments.count >= 2 else { fail("usage: swift ats_parse.swift <resume file>") }
let inPath = (CommandLine.arguments[1] as NSString).expandingTildeInPath
let inURL = URL(fileURLWithPath: inPath)
let ext = inURL.pathExtension.lowercased()
guard FileManager.default.fileExists(atPath: inPath) else { fail("not found: \(inPath)") }

var text = ""
var pageCount = 0
var pageTexts: [String] = []
var sourceNotes: [String] = []

func run(_ launch: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let out = Pipe(); p.standardOutput = out; p.standardError = Pipe()
    try? p.run(); p.waitUntilExit()
    return String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

func readPDF(_ url: URL) {
    guard let doc = PDFDocument(url: url) else { fail("could not open PDF: \(url.path)") }
    pageCount = doc.pageCount
    for i in 0..<doc.pageCount { pageTexts.append(doc.page(at: i)?.string ?? "") }
    text = pageTexts.joined(separator: "\n")
}

// Scan HTML and its local stylesheets for layout choices that commonly break parsing.
func scanHTMLSource(_ url: URL) {
    guard let html = try? String(contentsOf: url, encoding: .utf8) else { return }
    var css = ""
    let linkRx = try! NSRegularExpression(pattern: #"<link[^>]+href="([^"]+\.css)""#, options: [.caseInsensitive])
    for m in linkRx.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
        if let r = Range(m.range(at: 1), in: html) {
            let href = String(html[r])
            if href.hasPrefix("http") { continue }
            let cssURL = URL(fileURLWithPath: href, relativeTo: url.deletingLastPathComponent())
            if let c = try? String(contentsOf: cssURL, encoding: .utf8) { css += c }
        }
    }
    let both = html + "\n" + css
    func has(_ p: String) -> Bool { both.range(of: p, options: [.regularExpression, .caseInsensitive]) != nil }
    if html.range(of: "<table", options: .caseInsensitive) != nil { sourceNotes.append("LAYOUT TABLE: <table> in resume HTML; tables can scramble reading order") }
    if html.range(of: "<img", options: .caseInsensitive) != nil { sourceNotes.append("IMAGE: <img> in resume HTML; any text inside an image is invisible to an ATS") }
    if has(#"column-count|columns\s*:"#) { sourceNotes.append("COLUMNS: CSS multi column layout; parsers may read across columns") }
    if has(#"grid-template-columns"#) { sourceNotes.append("GRID: CSS grid columns; check that reading order in TEXT is still top to bottom") }
    if has(#"::?(before|after)\s*\{[^}]*content\s*:\s*["'][^"']+["']"#) { sourceNotes.append("CSS GLYPH: ::before/::after inserts visible characters; check TEXT for stray symbols") }
    if has(#"font-awesome|material-icons|icomoon|<i class=\"(fa|icon)"#) { sourceNotes.append("ICON FONT: icon font in use; icons extract as private use characters or vanish") }
    if has(#"position\s*:\s*(absolute|fixed)"#) { sourceNotes.append("POSITIONED TEXT: absolute or fixed positioning; can pull text out of reading order") }
}

switch ext {
case "pdf":
    readPDF(inURL)
case "html", "htm":
    scanHTMLSource(inURL)
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("fitcheck_\(UUID().uuidString).pdf")
    _ = run("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            ["--headless", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf=\(tmp.path)", inURL.absoluteString])
    guard FileManager.default.fileExists(atPath: tmp.path) else { fail("Chrome could not render \(inPath) to PDF") }
    readPDF(tmp)
    try? FileManager.default.removeItem(at: tmp)
case "docx", "doc", "rtf":
    text = run("/usr/bin/textutil", ["-convert", "txt", "-stdout", inPath])
    pageTexts = [text]
    sourceNotes.append("WORD FILE: text pulled with textutil; headers, footers, and text boxes are not included, which mirrors many parsers")
case "txt", "md":
    text = (try? String(contentsOf: inURL, encoding: .utf8)) ?? ""
    pageTexts = [text]
default:
    fail("unsupported file type: .\(ext)")
}

print("=== TEXT ===")
print(text)
print("=== DIAGNOSTICS ===")
print("file: \(inPath)")
if pageCount > 0 { print("pages: \(pageCount)") }
let words = text.split { $0 == " " || $0 == "\n" }.count
print("words: \(words)")
if words < 100 { print("!! NEARLY EMPTY TEXT: the file may be an image or scanned PDF; an ATS would see almost nothing") }

// Characters that parsers mangle or that signal decoration.
var glyphHits: [String: [String]] = [:]
func classify(_ s: Unicode.Scalar) -> String? {
    switch s.value {
    case 0xE000...0xF8FF: return "private use (icon font)"
    case 0xFB00...0xFB06: return "ligature"
    case 0xFFFD: return "replacement character (failed decode)"
    case 0x2190...0x21FF: return "arrow"
    case 0x2600...0x27BF: return "symbol or dingbat"
    case 0x25A0...0x25FF: return "geometric shape"
    case 0x1F000...0x1FFFF: return "emoji"
    case 0x2022, 0x00B7, 0x2013, 0x2014, 0x2019, 0x2018, 0x201C, 0x201D, 0x2026, 0x00A0: return nil  // ordinary typography
    default: return nil
    }
}
let lines = text.components(separatedBy: .newlines)
for line in lines {
    for s in line.unicodeScalars {
        if let kind = classify(s) {
            let ctx = line.trimmingCharacters(in: .whitespaces)
            let label = "\(kind) U+\(String(s.value, radix: 16, uppercase: true))"
            if (glyphHits[label]?.count ?? 0) < 3 { glyphHits[label, default: []].append(String(ctx.prefix(90))) }
        }
    }
}
if glyphHits.isEmpty { print("glyphs: none") }
for (k, v) in glyphHits.sorted(by: { $0.key < $1.key }) {
    print("!! GLYPH \(k)")
    for c in v { print("     in: \(c)") }
}

// Contact details: must be in the body text, near the top.
let head = lines.prefix(6).joined(separator: " ")
let email = text.range(of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, options: .regularExpression) != nil
let emailTop = head.range(of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, options: .regularExpression) != nil
let phone = text.range(of: #"\(?\d{3}\)?[\s.\-]?\d{3}[\s.\-]?\d{4}"#, options: .regularExpression) != nil
print("contact: email \(email ? (emailTop ? "found near top" : "found, not near top") : "MISSING"), phone \(phone ? "found" : "MISSING")")
if !email || !phone { print("!! CONTACT: missing from extracted text; if it is in a header, footer, or image, the ATS cannot see it") }

// Standard section headings.
let standard = ["summary", "profile", "experience", "work experience", "professional experience", "employment history",
                "education", "skills", "technical skills", "certifications", "projects", "areas of expertise",
                "core competencies", "volunteer experience", "awards", "publications", "leadership"]
var found: [String] = []
var glyphHeadings: [String] = []
for line in lines {
    let raw = line.trimmingCharacters(in: .whitespaces)
    // Strip leading decoration so the heading is still found, but report it: many parsers
    // match headings from the first character and miss "■ Education" entirely.
    let t = String(raw.drop(while: { !$0.isLetter && !$0.isNumber })).trimmingCharacters(in: .whitespaces)
    let decorated = t != raw && !t.isEmpty
    guard t.count >= 4, t.count <= 32, !t.contains("|"), !t.contains(":"), !t.contains("."),
          t.split(separator: " ").count <= 4 else { continue }
    let isTitleCase = t.split(separator: " ").allSatisfy { $0.first?.isUppercase ?? false || ["&", "and", "of", "in"].contains(String($0)) }
    guard isTitleCase || t == t.uppercased() else { continue }
    // Parsers key on the core word, so "Education & Certifications" still reads as Education.
    let low = t.lowercased()
    if standard.contains(where: { low == $0 || low.hasPrefix($0 + " ") || low.hasSuffix(" " + $0) }) {
        found.append(t)
        if decorated { glyphHeadings.append(raw) }
    }
}
for g in glyphHeadings { print("!! GLYPH BEFORE HEADING: \"\(g)\"; remove the symbol so the parser recognizes the section") }
print("sections recognized: \(found.isEmpty ? "NONE" : found.joined(separator: ", "))")
if !found.contains(where: { $0.lowercased().contains("experience") || $0.lowercased().contains("employment") }) {
    print("!! SECTIONS: no standard Experience heading found")
}
if !found.contains(where: { $0.lowercased().contains("education") }) { print("!! SECTIONS: no Education heading found") }
if !found.contains(where: { $0.lowercased().contains("skills") }) { print("!! SECTIONS: no Skills heading found") }

// Date formats: parsers compute years of experience from these.
let datePatterns: [(String, String)] = [
    ("YYYY to YYYY", #"\b(19|20)\d{2}\s*[–—-]\s*((19|20)\d{2}|Present|Current|present|current)\b"#),
    ("Mon YYYY", #"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)[a-z]*\.?\s+(19|20)\d{2}\b"#),
    ("MM/YYYY", #"\b(0?[1-9]|1[0-2])/(19|20)\d{2}\b"#),
]
var dateKinds: [String] = []
for (name, rx) in datePatterns where text.range(of: rx, options: .regularExpression) != nil { dateKinds.append(name) }
print("date formats: \(dateKinds.isEmpty ? "NONE FOUND" : dateKinds.joined(separator: ", "))")
if dateKinds.count > 1 { print("!! DATES: mixed formats; pick one so years of experience compute cleanly") }
if dateKinds.isEmpty { print("!! DATES: no recognizable date ranges; years of experience cannot be computed") }

// Repeated lines across pages usually mean a running header or footer.
if pageTexts.count > 1 {
    var seen: [String: Int] = [:]
    for p in pageTexts {
        let pl = Set(p.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count > 3 })
        for l in pl { seen[l, default: 0] += 1 }
    }
    for (l, n) in seen where n == pageTexts.count { print("!! REPEATED ON EVERY PAGE (header or footer?): \(l.prefix(90))") }
}

// Link text with no visible URL: an ATS keeps only the visible words.
// Only short lines: a label like "Portfolio" or "LinkedIn", not the word inside a sentence.
for l in lines where (l.lowercased().contains("portfolio") || l.lowercased().contains("linkedin")) && l.count < 40 {
    if l.range(of: #"(https?://|www\.|\.com|\.co|\.io|\.design|\.me)"#, options: .regularExpression) == nil {
        print("!! LINK TEXT ONLY: \"\(l.trimmingCharacters(in: .whitespaces).prefix(80))\" has no visible URL")
    }
}

for n in sourceNotes { print("!! \(n)") }
