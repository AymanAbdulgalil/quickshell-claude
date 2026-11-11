import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../controls"

// The text of one note. Notes are Markdown on disk; images are `![](images/x.png)`, shown in place while editing.
// The text is held as rich text only so images can sit inside it: every position below counts each character, line
// break and image as one, and plain() is what the line and word logic reads. Styling is only ever applied as character
// formats over that text (see "Live styling"), so the Markdown itself is never changed by it.
Item {
    id: root

    required property string notesDir

    property bool loading: false
    // Positions of the other text cursors (Ctrl+Shift+Up and Down). The main one is the TextEdit's own.
    property var extras: []
    property bool applying: false
    property var extraRects: []

    // Set while styles are applied: selections and cursor moves made then are not the user's.
    property bool styling: false
    property string lastPlain: ""
    property int lastLineCount: 0
    property string lastKinds: ""
    // Set when an edit touched a line away from the cursors, so all lines are styled again.
    property bool pendingFull: false
    // Line starts of what is being edited (one line, or a whole table): its Markdown markers show.
    property int litFrom: -1
    property int litTo: -1
    property string structureText: ""
    property var structureCache: null

    // What is drawn over the text, from updateLayout().
    property var overlayJson: ({})
    property var lineTops: []
    property var lineHeights: []
    property int currentLine: 0
    property rect lineHighlight: Qt.rect(0, 0, 0, 0)
    property var tableModel: []
    property var quoteModel: []
    property var ruleModel: []
    property var checkModel: []
    property var imageModel: []
    // Sideways scroll of each table and image strip that is wider than the note, by key. Replaced, never changed in
    // place, so what draws them follows.
    property var tableOffsets: ({})
    property var imageOffsets: ({})
    // Ten lines of room after the last one, as in code editors: scrolling can use it, and typing on the last line keeps
    // some of it in view.
    readonly property real lineStep: mono.lineSpacing
    readonly property real bottomRoom: 10 * lineStep
    // --- Search (Ctrl+F) and every match of the selection (Ctrl+F2). Matches are { from, to } in plain() positions.
    property bool searching: false
    property string query: ""
    property bool matchCase: false
    property bool wholeWord: false
    property var searchHits: []
    property int hitIndex: -1
    // What Ctrl+F2 put cursors after; highlighted until the text changes or the cursors go.
    property var occurrenceHits: []
    // Both, as rectangles in the text's coordinates: { x, y, width, height, current }.
    property var hitRects: []
    // Where a Ctrl+clicked link flashes, in the text's coordinates.
    property rect linkFlash: Qt.rect(0, 0, 0, 0)
    property bool inTable: false
    // Set from updateLayout: as a binding on the text's own width it would be a loop.
    property real unwrappedWidth: 0
    readonly property int checkSize: 12
    readonly property int quotePadding: 6
    // A quote's side margins, as set in marginOf: the text starts this far in, and the block ends this far after it.
    readonly property int quoteSide: 30
    // Set while following the caret past the right end, so the text is wide enough to scroll there at once.
    property real followWidth: 0
    readonly property bool wrapped: Settings.notesWrap
    readonly property string imageMode: wrapped ? Settings.notesImagesWrapped : Settings.notesImagesUnwrapped
    // Where the caret is drawn. Updated only when styling is done, so it glides without passing through detours.
    property rect caretRect: Qt.rect(0, 0, 2, Theme.fonts.body)
    // Undo steps as { text, cursor }. Styling would otherwise fill the document's own undo history.
    property var undoSteps: []
    property var redoSteps: []

    signal edited
    signal closeRequested
    // Ctrl+ shortcuts that belong to the panel. Returns true when used.
    property var panelKey: event => false

    readonly property string dirUrl: "file://" + notesDir + "/"
    readonly property var imagePattern: /!\[[^\]]*\]\(([^)]+)\)/g
    readonly property int indentWidth: 4
    readonly property string indentText: " ".repeat(indentWidth)

    // Where the writable area starts and ends inside this item, for what is laid out like the text (the help page).
    readonly property real textLeft: gutter.width
    readonly property real textRight: edit.rightPadding

    function focusNow() {
        edit.forceActiveFocus();
    }

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Each line is a paragraph: a <br/> reads back as a space, not a line break.
    function paragraphs(lines, kinds) {
        return lines.map((l, i) => {
            const margin = marginOf(kinds ? kinds[i] : "");
            return l === "" ? '<p style="-qt-paragraph-type:empty; margin:' + margin + ';"></p>'
                            : '<p style="margin:' + margin + '; white-space:pre-wrap;">' + l + "</p>";
        }).join("");
    }

    // Quote lines sit inside their block's margins, with room above and below for its background and marks.
    function marginOf(kind) {
        if (kind === "")
            return "0";
        const top = kind.includes("f") ? quotePadding * 2 : 0;
        const bottom = kind.includes("l") ? quotePadding * 2 : 0;
        return top + "px " + quoteSide + "px " + bottom + "px " + quoteSide + "px";
    }

    // Inserted at p, this splits the line there.
    readonly property string lineBreak: '<p style="margin:0;"></p><p style="-qt-paragraph-type:empty; margin:0;"></p>'

    // Text for the middle of a line. Without pre-wrap the HTML reader would collapse its spaces.
    function inlineHtml(text) {
        return '<span style="white-space:pre-wrap;">' + escapeHtml(text) + "</span>";
    }

    function imageTag(url) {
        if (imageMode === "asis")
            return '<img src="' + url + '" />';
        if (imageMode === "fixed")
            return '<img src="' + url + '" height="' + Settings.notesImageHeight + '" />';
        return '<img src="' + url + '" width="' + Math.max(80, Math.round(flick.width - edit.rightPadding - 4)) + '" />';
    }

    function loadDocument(md) {
        const body = escapeHtml(md).replace(imagePattern, (all, path) => {
            const url = path.startsWith("/") ? "file://" + path : path.startsWith("file:") ? path : dirUrl + path;
            return imageTag(url);
        });
        edit.text = paragraphs(body.split("\n"), kindsOf(md.split("\n")));
    }

    function setMarkdown(md) {
        loading = true;
        extras = [];
        loadDocument(md);
        edit.cursorPosition = 0;
        restyleAll();
        undoSteps = [{ text: md, cursor: 0 }];
        redoSteps = [];
        loading = false;
    }

    function imageUrls() {
        const urls = [];
        const tag = /<img[^>]*src="([^"]+)"/g;
        let found;
        while ((found = tag.exec(edit.text)) !== null)
            urls.push(found[1]);
        return urls;
    }

    // Plain text, with each image's place (U+FFFC) put back as a Markdown link, in document order.
    function markdown() {
        const urls = imageUrls();
        let i = 0;
        return plain().replace(/\uFFFC/g, () => {
            const url = decodeURI(urls[i++] ?? "");
            const relative = url.startsWith(dirUrl) ? url.slice(dirUrl.length) : url.replace(/^file:\/\//, "");
            return "![](" + relative + ")";
        });
    }

    function insertImage(path) {
        edit.insert(edit.cursorPosition, imageTag(encodeURI("file://" + path)));
    }

    function insertPlain(text) {
        edit.insert(edit.cursorPosition, paragraphs(escapeHtml(text).split("\n")));
    }

    // Ctrl+V: an image on the clipboard is saved beside the notes, anything else goes in as plain text.
    Process {
        id: paster

        command: ["sh", "-c", `
            if wl-paste --list-types | grep -q '^image/png'; then
                f="$DIR/images/pasted-$(date +%s%N).png"
                mkdir -p "$DIR/images" && wl-paste --type image/png > "$f" && printf 'IMG%s' "$f"
            else
                printf 'TXT'; wl-paste --no-newline --type text/plain 2>/dev/null
            fi
        `]
        environment: ({ DIR: root.notesDir })

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.startsWith("IMG"))
                    root.insertImage(text.slice(3));
                else if (text.length > 3)
                    root.insertPlain(text.slice(3));
            }
        }
    }

    // --- Lines. Rich text hands back Unicode separators for line breaks; one for one, so positions still match.
    function plain() {
        return edit.getText(0, edit.length).replace(/[\u2028\u2029]/g, "\n");
    }

    function lineStart(s, p) {
        return p <= 0 ? 0 : s.lastIndexOf("\n", p - 1) + 1;
    }

    function lineEnd(s, p) {
        const e = s.indexOf("\n", p);
        return e < 0 ? s.length : e;
    }

    // The whole lines the selection touches. A selection ending right after a line break does not include the next line.
    function selectedBlock(s) {
        const from = edit.selectionStart;
        let to = edit.selectionEnd;
        if (to > from && s[to - 1] === "\n")
            to--;
        return [lineStart(s, from), lineEnd(s, to)];
    }

    function lineStarts(s, a, b) {
        const starts = [a];
        for (let i = s.indexOf("\n", a); i >= 0 && i < b; i = s.indexOf("\n", i + 1))
            starts.push(i + 1);
        return starts;
    }

    // HTML for part of the text, keeping any images in it.
    function fragment(from, to) {
        if (from === to)
            return "";
        return edit.getText(from, to).includes("\uFFFC") ? edit.getFormattedText(from, to) : inlineHtml(edit.getText(from, to).replace(/[\u2028\u2029]/g, "\n"));
    }

    // --- Markdown styling
    function wrapSelection(before, after) {
        const a = edit.selectionStart;
        const b = edit.selectionEnd;
        const s = plain();
        if (a - before.length >= 0 && s.slice(a - before.length, a) === before && s.slice(b, b + after.length) === after) {
            edit.remove(b, b + after.length);
            edit.remove(a - before.length, a);
            edit.select(a - before.length, b - before.length);
            return;
        }
        edit.insert(b, inlineHtml(after));
        edit.insert(a, inlineHtml(before));
        if (a === b)
            edit.cursorPosition = a + before.length;
        else
            edit.select(a + before.length, b + before.length);
    }

    // Adds a marker to the start of each selected line, or takes it off. `strip` is what a line's old marker looks like.
    function prefixLines(prefix, strip) {
        const s = plain();
        const [a, b] = selectedBlock(s);
        const starts = lineStarts(s, a, b);
        const removing = starts.every(st => s.slice(st).startsWith(prefix));
        for (let i = starts.length - 1; i >= 0; i--) {
            const st = starts[i];
            const old = (s.slice(st, lineEnd(s, st)).match(strip) ?? [""])[0];
            if (old !== "")
                edit.remove(st, st + old.length);
            if (!removing)
                edit.insert(st, inlineHtml(prefix));
        }
    }

    function heading(level) {
        prefixLines("#".repeat(level) + " ", /^#{1,6} /);
    }

    function insertLink() {
        const a = edit.selectionStart;
        const b = edit.selectionEnd;
        edit.insert(b, inlineHtml("](url)"));
        edit.insert(a, inlineHtml("["));
        edit.select(b + 3, b + 6);
    }

    function insertTable() {
        const at = edit.cursorPosition;
        insertPlain("| Column | Column |\n| ------ | ------ |\n|        |        |");
        edit.select(at + 2, at + 8);
    }

    function insertCodeBlock() {
        wrapSelection("```\n", "\n```");
    }

    function style(name) {
        switch (name) {
        case "bold":
            wrapSelection("**", "**");
            break;
        case "italic":
            wrapSelection("*", "*");
            break;
        case "strike":
            wrapSelection("~~", "~~");
            break;
        case "code":
            wrapSelection("`", "`");
            break;
        case "h1":
            heading(1);
            break;
        case "h2":
            heading(2);
            break;
        case "h3":
            heading(3);
            break;
        case "list":
            prefixLines("- ", /^(- \[[ x]\] |[-*] |\d+\. )/);
            break;
        case "numbered":
            prefixLines("1. ", /^(- \[[ x]\] |[-*] |\d+\. )/);
            break;
        case "task":
            prefixLines("- [ ] ", /^(- \[[ x]\] |[-*] |\d+\. )/);
            break;
        case "quote":
            prefixLines("> ", /^> /);
            break;
        case "link":
            insertLink();
            break;
        case "table":
            insertTable();
            break;
        }
        focusNow();
    }

    // --- Line operations
    function selectLine() {
        const s = plain();
        const [a, b] = selectedBlock(s);
        edit.select(a, Math.min(edit.length, b + 1));
    }

    function indentLines(right) {
        const s = plain();
        const hadSelection = edit.selectionStart !== edit.selectionEnd;
        const cursor = edit.cursorPosition;
        const [a, b] = selectedBlock(s);
        const starts = lineStarts(s, a, b);
        let firstDelta = 0;
        for (let i = starts.length - 1; i >= 0; i--) {
            const st = starts[i];
            if (right) {
                edit.insert(st, inlineHtml(indentText));
                firstDelta = indentWidth;
            } else {
                const spaces = (s.slice(st, st + indentWidth).match(/^ */) ?? [""])[0].length;
                if (spaces > 0)
                    edit.remove(st, st + spaces);
                firstDelta = -spaces;
            }
        }
        if (hadSelection) {
            const t = plain();
            edit.select(a, lineEnd(t, a + Math.max(0, b - a + (right ? indentWidth : -indentWidth) * starts.length - 1)));
        } else {
            edit.cursorPosition = Math.max(a, cursor + firstDelta);
        }
    }

    function moveLines(down) {
        pendingFull = true;
        const s = plain();
        const had = edit.selectionStart !== edit.selectionEnd;
        const keepFrom = edit.selectionStart;
        const keepTo = edit.selectionEnd;
        const [a, b] = selectedBlock(s);
        let shift;
        if (down) {
            if (b >= s.length)
                return;
            const next = b + 1;
            const nextEnd = lineEnd(s, next);
            const html = fragment(next, nextEnd);
            edit.remove(b, nextEnd);
            edit.insert(a, lineBreak);
            if (html !== "")
                edit.insert(a, html);
            shift = nextEnd - next + 1;
        } else {
            if (a === 0)
                return;
            const prev = lineStart(s, a - 1);
            const html = fragment(prev, a - 1);
            edit.remove(prev, a);
            const end = prev + b - a;
            edit.insert(end, lineBreak);
            if (html !== "")
                edit.insert(end + 1, html);
            shift = prev - a;
        }
        if (had)
            edit.select(keepFrom + shift, keepTo + shift);
        else
            edit.cursorPosition = keepFrom + shift;
    }

    // --- More than one cursor
    function allCursors() {
        return [edit.cursorPosition].concat(extras);
    }

    function addCursor(down) {
        const s = plain();
        const all = allCursors();
        const from = down ? Math.max(...all) : Math.min(...all);
        const column = edit.cursorPosition - lineStart(s, edit.cursorPosition);
        const here = lineStart(s, from);
        if (down ? lineEnd(s, from) >= s.length : here === 0)
            return;
        const target = down ? lineEnd(s, from) + 1 : lineStart(s, here - 1);
        const q = Math.min(target + column, lineEnd(s, target));
        if (!all.includes(q))
            extras = extras.concat([q]);
    }

    function clearCursors() {
        extras = [];
    }

    // Applies an edit at every cursor, last first so earlier positions stay valid. `fn(p)` returns
    // { shift, caret }: how far following text moved, and where this cursor ends up relative to p.
    function atCursors(fn) {
        applying = true;
        const main = edit.cursorPosition;
        const positions = allCursors().slice().sort((a, b) => b - a);
        let done = [];
        for (const p of positions) {
            const r = fn(p);
            done = done.map(c => ({ was: c.was, now: c.now + r.shift }));
            done.push({ was: p, now: p + r.caret });
        }
        edit.cursorPosition = done.find(c => c.was === main).now;
        extras = done.filter(c => c.was !== main).map(c => c.now);
        applying = false;
    }

    function typeEverywhere(text) {
        atCursors(p => {
            edit.insert(p, inlineHtml(text));
            return { shift: text.length, caret: text.length };
        });
    }

    function moveEverywhere(key) {
        const s = plain();
        const step = p => {
            const column = p - lineStart(s, p);
            if (key === Qt.Key_Left)
                return Math.max(0, p - 1);
            if (key === Qt.Key_Right)
                return Math.min(s.length, p + 1);
            if (key === Qt.Key_Up) {
                const here = lineStart(s, p);
                if (here === 0)
                    return p;
                const prev = lineStart(s, here - 1);
                return Math.min(prev + column, lineEnd(s, prev));
            }
            if (lineEnd(s, p) >= s.length)
                return p;
            const next = lineEnd(s, p) + 1;
            return Math.min(next + column, lineEnd(s, next));
        };
        applying = true;
        const moved = [...new Set(extras.map(step))];
        edit.cursorPosition = step(edit.cursorPosition);
        extras = moved.filter(p => p !== edit.cursorPosition);
        applying = false;
    }

    function handleMultiKey(event) {
        if (event.key === Qt.Key_Backspace) {
            atCursors(p => {
                if (p === 0)
                    return { shift: 0, caret: 0 };
                edit.remove(p - 1, p);
                return { shift: -1, caret: -1 };
            });
        } else if (event.key === Qt.Key_Delete) {
            atCursors(p => {
                if (p >= edit.length)
                    return { shift: 0, caret: 0 };
                edit.remove(p, p + 1);
                return { shift: -1, caret: 0 };
            });
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            atCursors(p => {
                edit.insert(p, lineBreak);
                return { shift: 1, caret: 1 };
            });
        } else if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
            moveEverywhere(event.key);
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            typeEverywhere(event.text);
        } else {
            return false;
        }
        return true;
    }

    function refreshExtraRects() {
        extraRects = extras.map(p => edit.positionToRectangle(p));
    }

    onExtrasChanged: {
        refreshExtraRects();
        // Ctrl+F2's highlights go with its cursors.
        if (extras.length === 0 && occurrenceHits.length > 0) {
            occurrenceHits = [];
            updateHitRects();
        }
    }

    function handleStyleKey(event, shift) {
        const plainKeys = { [Qt.Key_B]: "bold", [Qt.Key_I]: "italic", [Qt.Key_K]: "link", [Qt.Key_T]: "table", [Qt.Key_1]: "h1", [Qt.Key_2]: "h2", [Qt.Key_3]: "h3", [Qt.Key_QuoteLeft]: "code" };
        const shiftKeys = { [Qt.Key_X]: "strike", [Qt.Key_L]: "list", [Qt.Key_N]: "numbered", [Qt.Key_Q]: "quote" };
        const name = (shift ? shiftKeys : plainKeys)[event.key];
        if (name)
            style(name);
        return !!name;
    }

    // --- Live styling. Each line gets character formats for what its Markdown means, as it is typed. Markers (**, #, ...) are
    // shrunk away except on the line being edited, where they show dimmed. The text itself is untouched. Tables, check boxes,
    // quote backgrounds and rules are drawn over the hidden source (see "Drawn over the text").
    function fontOf(o) {
        return Qt.font({
            family: o.family ?? Theme.fonts.familyMono,
            pixelSize: o.size ?? Theme.fonts.body,
            bold: !!o.bold,
            italic: !!o.italic,
            strikeout: !!o.strike
        });
    }

    function paint(a, b, o) {
        if (b <= a)
            return;
        edit.select(a, b);
        edit.cursorSelection.font = fontOf(o);
        edit.cursorSelection.color = o.color ?? Theme.colors.foreground;
    }

    // Runs fn with the user's cursor and selection put back afterwards, in the same direction.
    function keepingSelection(fn) {
        styling = true;
        const from = edit.selectionStart;
        const to = edit.selectionEnd;
        const cursor = edit.cursorPosition;
        fn();
        if (from !== to) {
            if (cursor === from)
                edit.select(to, from);
            else
                edit.select(from, to);
        } else {
            edit.cursorPosition = cursor;
        }
        styling = false;
        caretRect = edit.cursorRectangle;
        Qt.callLater(updateLayout);
    }

    function isTableLine(line) {
        return /^\s*\|/.test(line);
    }

    function cellsOf(line) {
        return line.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map(c => c.trim());
    }

    // String.matchAll does not exist in QML's JavaScript.
    function matches(pattern, text) {
        const found = [];
        pattern.lastIndex = 0;
        for (let m = pattern.exec(text); m !== null; m = pattern.exec(text))
            found.push(m);
        return found;
    }

    // Which lines are code, quotes and tables. Consecutive quote lines are one block; anything between them, even an empty line, ends it.
    function classify(lines) {
        const out = [];
        let fence = false;
        for (const text of lines) {
            const opens = /^```/.test(text);
            out.push({ fence: fence || opens, quote: !fence && !opens && /^>( |$)/.test(text) });
            if (opens)
                fence = !fence;
        }
        return out;
    }

    function kindsOf(lines) {
        const cls = classify(lines);
        return cls.map((c, i) => !c.quote ? "" : "q" + (i === 0 || !cls[i - 1].quote ? "f" : "") + (i === cls.length - 1 || !cls[i + 1].quote ? "l" : ""));
    }

    // The lines of s, with their tables. Asked for many times per change, so the last answer is kept.
    function structure(s) {
        if (structureText === s && structureCache !== null)
            return structureCache;
        const texts = s.split("\n");
        const cls = classify(texts);
        const lines = [];
        const byStart = {};
        const tables = [];
        let at = 0;
        let table = null;
        texts.forEach((text, i) => {
            const line = { st: at, en: at + text.length, text: text, index: i, fence: cls[i].fence, quote: cls[i].quote, table: null };
            if (!line.fence && isTableLine(text)) {
                if (table === null) {
                    table = { lines: [] };
                    tables.push(table);
                }
                table.lines.push(line);
                line.table = table;
            } else {
                table = null;
            }
            lines.push(line);
            byStart[at] = line;
            at += text.length + 1;
        });
        for (const t of tables)
            t.valid = t.lines.length >= 2 && isRule(cellsOf(t.lines[1].text));
        structureText = s;
        structureCache = { lines: lines, byStart: byStart, tables: tables };
        return structureCache;
    }

    function lineIndexAt(lines, p) {
        let low = 0;
        let high = lines.length - 1;
        while (low < high) {
            const mid = Math.ceil((low + high) / 2);
            if (lines[mid].st <= p)
                low = mid;
            else
                high = mid - 1;
        }
        return low;
    }

    // What counts as being edited at p: the whole table if p is in one, otherwise its line. Given as line starts.
    function litRangeAt(s, p) {
        const info = structure(s);
        const line = info.lines[lineIndexAt(info.lines, p)];
        return line.table ? [line.table.lines[0].st, line.table.lines[line.table.lines.length - 1].st] : [line.st, line.st];
    }

    function isLit(st) {
        return st >= litFrom && st <= litTo;
    }

    readonly property int maskBold: 1
    readonly property int maskItalic: 2
    readonly property int maskStrike: 4
    readonly property int maskCode: 8
    readonly property int maskLink: 16
    readonly property int maskMarker: 32

    // What each character of a line is, as bit masks. Emphasis nests in any order: ***both***, ~~**struck bold**~~ and so on.
    function inlineMasks(line) {
        const mask = new Array(line.length).fill(0);
        const blocked = new Array(line.length).fill(false);
        const span = (a, b, bits) => {
            for (let i = a; i < b; i++) {
                mask[i] |= bits;
            }
        };
        const block = (a, b) => {
            for (let i = a; i < b; i++)
                blocked[i] = true;
        };
        for (const m of matches(/`[^`]+`/g, line)) {
            const end = m.index + m[0].length;
            span(m.index, m.index + 1, maskMarker);
            span(m.index + 1, end - 1, maskCode);
            span(end - 1, end, maskMarker);
            block(m.index, end);
        }
        for (const m of matches(/\[([^\]]+)\]\(([^)]*)\)/g, line)) {
            if (blocked[m.index])
                continue;
            const textEnd = m.index + 1 + m[1].length;
            span(m.index, m.index + 1, maskMarker);
            span(m.index + 1, textEnd, maskLink);
            span(textEnd, m.index + m[0].length, maskMarker);
            block(m.index, m.index + m[0].length);
        }
        for (const m of matches(/https?:\/\/[^\s<>|)\]]+/g, line)) {
            if (blocked[m.index])
                continue;
            span(m.index, m.index + m[0].length, maskLink);
            block(m.index, m.index + m[0].length);
        }

        const stack = [];
        const take = (bits, at, length, canOpen, canClose) => {
            let found = -1;
            for (let k = stack.length - 1; k >= 0 && found < 0; k--) {
                if (stack[k].bits === bits)
                    found = k;
            }
            if (found >= 0 && canClose) {
                const open = stack[found];
                stack.length = found;
                span(open.at, open.at + open.length, maskMarker);
                span(at, at + length, maskMarker);
                span(open.at + open.length, at, bits);
            } else if (canOpen) {
                stack.push({ bits: bits, at: at, length: length });
            }
        };
        for (let i = 0; i < line.length;) {
            const c = line[i];
            if (blocked[i] || (c !== "*" && c !== "~")) {
                i++;
                continue;
            }
            let run = 1;
            while (line[i + run] === c && !blocked[i + run])
                run++;
            const canOpen = i + run < line.length && !/\s/.test(line[i + run]);
            const canClose = i > 0 && !/\s/.test(line[i - 1]);
            if (c === "~" && run === 2) {
                take(maskStrike, i, 2, canOpen, canClose);
            } else if (c === "*" && run === 1) {
                take(maskItalic, i, 1, canOpen, canClose);
            } else if (c === "*" && run === 2) {
                take(maskBold, i, 2, canOpen, canClose);
            } else if (c === "*" && run === 3) {
                // Whichever is innermost closes first.
                const italicFirst = stack.length > 0 && stack[stack.length - 1].bits === maskItalic;
                take(italicFirst ? maskItalic : maskBold, i, italicFirst ? 1 : 2, canOpen, canClose);
                take(italicFirst ? maskBold : maskItalic, i + (italicFirst ? 1 : 2), italicFirst ? 2 : 1, canOpen, canClose);
            }
            i += run;
        }
        return mask;
    }

    function marker(a, b, lit, base) {
        if (lit)
            paint(a, b, Object.assign({}, base, { color: Theme.colors.inactive, bold: false, italic: false, strike: false }));
        else
            paint(a, b, { size: 1, color: Theme.colors.clear });
    }

    function styleOfMask(bits, base) {
        const o = Object.assign({}, base);
        if (bits & maskBold) {
            o.bold = true;
            o.color = Theme.colors.foregroundStrong;
        }
        if (bits & maskItalic)
            o.italic = true;
        if (bits & maskStrike) {
            o.strike = true;
            o.color = Theme.colors.muted;
        }
        if (bits & maskCode)
            o.color = Theme.colors.info;
        if (bits & maskLink)
            o.color = Theme.colors.accent;
        return o;
    }

    // Paints the inline styles of s[st, en), one run of same-styled characters at a time.
    function styleInline(s, st, en, lit, base) {
        const mask = inlineMasks(s.slice(st, en));
        for (let i = 0; i < mask.length;) {
            let j = i + 1;
            while (j < mask.length && mask[j] === mask[i])
                j++;
            if (mask[i] & maskMarker)
                marker(st + i, st + j, lit, base);
            else if (mask[i] !== 0)
                paint(st + i, st + j, styleOfMask(mask[i], base));
            i = j;
        }
    }

    function styleLine(s, st) {
        const info = structure(s).byStart[st];
        if (!info)
            return;
        const en = info.en;
        const line = info.text;
        const lit = isLit(st);
        if (info.fence) {
            paint(st, en, { color: Theme.colors.info });
            return;
        }
        paint(st, en, {});
        const heading = line.match(/^(#{1,6}) /);
        if (heading) {
            const size = Math.round(Theme.fonts.body * ([1.6, 1.35, 1.15][heading[1].length - 1] ?? 1));
            const base = { size: size, bold: true, color: Theme.colors.foregroundStrong, family: Theme.fonts.familyTitle };
            paint(st, en, base);
            marker(st, st + heading[0].length, lit, base);
            styleInline(s, st + heading[0].length, en, lit, base);
            return;
        }
        if (isRuleLine(line)) {
            paint(st, en, { color: lit ? Theme.colors.inactive : Theme.colors.clear });
            return;
        }
        if (info.table) {
            if (info.table.valid && !lit) {
                // Hidden: the first character keeps the row's height, the rest shrink so it can never wrap.
                const ruleRow = info === info.table.lines[1];
                paint(st, st + 1, { size: ruleRow ? 1 : Math.round(Theme.fonts.body * 1.7), color: Theme.colors.clear });
                paint(st + 1, en, { size: 1, color: Theme.colors.clear });
                return;
            }
            const first = info === info.table.lines[0];
            if (/^[\s|:-]+$/.test(line)) {
                paint(st, en, { color: Theme.colors.inactive });
                return;
            }
            const base = first ? { bold: true, color: Theme.colors.foregroundStrong } : {};
            paint(st, en, base);
            styleInline(s, st, en, lit, base);
            for (let i = line.indexOf("|"); i >= 0; i = line.indexOf("|", i + 1))
                paint(st + i, st + i + 1, { color: Theme.colors.inactive });
            return;
        }
        if (info.quote) {
            const base = { italic: true };
            const mark = Math.min(line.length, 2);
            paint(st, en, base);
            marker(st, st + mark, lit, base);
            styleInline(s, st + mark, en, lit, base);
            return;
        }
        const task = line.match(/^(\s*)[-*+] \[([ xX])\] /);
        if (task) {
            const body = task[0].length;
            const base = task[2] === " " ? {} : { color: Theme.colors.muted };
            paint(st + body, en, base);
            if (lit) {
                paint(st, st + body, { color: Theme.colors.muted });
            } else {
                // The space for the box: its inner character and the one after the bracket stay full width, unseen.
                const a = st + task[1].length;
                paint(a, a + 3, { size: 1, color: Theme.colors.clear });
                paint(a + 3, a + 4, { color: Theme.colors.clear });
                paint(a + 4, a + 5, { size: 1, color: Theme.colors.clear });
                paint(a + 5, a + 6, { color: Theme.colors.clear });
            }
            styleInline(s, st + body, en, lit, base);
            return;
        }
        const list = line.match(/^\s*([-*+]|\d+\.) /);
        if (list) {
            paint(st, st + list[0].length, { color: Theme.colors.muted });
            styleInline(s, st + list[0].length, en, lit, {});
            return;
        }
        styleInline(s, st, en, lit, {});
    }

    function isRuleLine(line) {
        return /^(-{3,}|\*{3,}|_{3,})\s*$/.test(line);
    }

    function setLit(s) {
        const range = litRangeAt(s, edit.cursorPosition);
        litFrom = range[0];
        litTo = range[1];
    }

    function restyleAll() {
        const s = plain();
        lastPlain = s;
        lastLineCount = s.split("\n").length;
        lastKinds = kindsOf(s.split("\n")).join(",");
        keepingSelection(() => {
            setLit(s);
            for (const st of lineStarts(s, 0, s.length))
                styleLine(s, st);
        });
    }

    // Reloads the document with the same text, for what only a rebuild can change: quote indents and image sizes.
    function rebuild() {
        const from = edit.selectionStart;
        const to = edit.selectionEnd;
        const cursor = edit.cursorPosition;
        const x = flick.contentX;
        const y = flick.contentY;
        const md = markdown();
        const wasLoading = loading;
        loading = true;
        styling = true;
        loadDocument(md);
        if (from !== to)
            edit.select(from, to);
        else
            edit.cursorPosition = cursor;
        styling = false;
        restyleAll();
        loading = wasLoading;
        flick.contentX = x;
        flick.contentY = y;
    }

    // After typing: the lines under the cursors, or everything if the shape of the text changed.
    function refreshStyle() {
        const s = plain();
        if (s === lastPlain)
            return;
        const lines = s.split("\n");
        if (kindsOf(lines).join(",") !== lastKinds) {
            pendingFull = false;
            rebuild();
            return;
        }
        const fences = (s.match(/^```/gm) ?? []).length !== (lastPlain.match(/^```/gm) ?? []).length;
        if (lines.length !== lastLineCount || fences || pendingFull) {
            pendingFull = false;
            restyleAll();
            return;
        }
        lastPlain = s;
        keepingSelection(() => {
            setLit(s);
            const starts = new Set(allCursors().map(p => lineStart(s, p)));
            for (const st of starts)
                styleLine(s, st);
        });
    }

    // Moving to another line or table shows its markers and hides the last one's: a check list item, for one, shows its raw
    // "- [ ]" while the caret is in it. A selection within one line counts (a click that moves a pixel selects a character);
    // one across lines does not, so dragging a selection does not restyle every line it passes.
    function refreshLitLine() {
        if (styling)
            return;
        const s = plain();
        if (s !== lastPlain)
            return;
        if (edit.selectionStart !== edit.selectionEnd && s.slice(edit.selectionStart, edit.selectionEnd).includes("\n"))
            return;
        updateCurrentLine();
        const range = litRangeAt(s, edit.cursorPosition);
        if (range[0] === litFrom && range[1] === litTo)
            return;
        const wasFrom = litFrom;
        const wasTo = litTo;
        keepingSelection(() => {
            litFrom = range[0];
            litTo = range[1];
            if (wasFrom >= 0 && wasTo <= s.length && lineStart(s, wasFrom) === wasFrom) {
                for (const st of lineStarts(s, wasFrom, wasTo))
                    styleLine(s, st);
            }
            for (const st of lineStarts(s, range[0], range[1]))
                styleLine(s, st);
        });
    }

    // --- Drawn over the text: where each table, quote, rule, check box and image is, read back from the laid-out text.
    function setIfChanged(name, value) {
        const json = JSON.stringify(value);
        if (overlayJson[name] === json)
            return;
        overlayJson[name] = json;
        root[name] = value;
    }

    function cellHtml(cell) {
        const mask = inlineMasks(cell);
        let html = "";
        for (let i = 0; i < mask.length;) {
            let j = i + 1;
            while (j < mask.length && mask[j] === mask[i])
                j++;
            if (!(mask[i] & maskMarker)) {
                let part = escapeHtml(cell.slice(i, j));
                if (mask[i] & maskBold)
                    part = "<b>" + part + "</b>";
                if (mask[i] & maskItalic)
                    part = "<i>" + part + "</i>";
                if (mask[i] & maskStrike)
                    part = "<s>" + part + "</s>";
                if (mask[i] & (maskCode | maskLink))
                    part = '<font color="' + (mask[i] & maskCode ? Theme.colors.info : Theme.colors.accent) + '">' + part + "</font>";
                html += part;
            }
            i = j;
        }
        return html;
    }

    function visibleLength(cell) {
        return inlineMasks(cell).filter(m => !(m & maskMarker)).length;
    }

    function tableEntry(table, key) {
        const pad = Theme.space.m;
        const first = edit.positionToRectangle(table.lines[0].st);
        const rows = [];
        const raw = [];
        table.lines.forEach((line, i) => {
            if (i === 1)
                return;
            const r = edit.positionToRectangle(line.st);
            rows.push({ y: r.y - first.y, height: r.height, source: i, cells: cellsOf(line.text) });
        });
        const count = Math.max(...rows.map(r => r.cells.length));
        const columns = [0];
        for (let c = 0; c < count; c++) {
            const widest = Math.max(3, ...rows.map(r => visibleLength(r.cells[c] ?? "")));
            columns.push(columns[c] + Math.ceil(widest * mono.averageCharacterWidth) + 2 * pad);
        }
        const last = rows[rows.length - 1];
        for (const r of rows)
            r.cells = r.cells.map(cellHtml);
        return {
            key: key,
            x: first.x,
            y: first.y,
            height: last.y + last.height,
            total: columns[count],
            // Unwrapped, the note scrolls instead, so the table is drawn whole.
            available: wrapped ? flick.width - first.x - edit.rightPadding : columns[count],
            columns: columns,
            rows: rows,
            lines: table.lines.map(l => l.st)
        };
    }

    function updateLayout() {
        if (!edit.visible && flick.width <= 0)
            return;
        // The text as it is now: a width change from typing can lay out before refreshStyle has read the new text, and
        // offsets one character stale put a quote line's end on the next line, which read as wrapped: the block flashed to
        // the full width (2026-11-11).
        const s = plain();
        const info = structure(s);
        const tops = [];
        const heights = [];
        for (const line of info.lines) {
            const r = edit.positionToRectangle(line.st);
            tops.push(r.y);
            heights.push(r.height);
        }
        lineTops = tops;
        lineHeights = heights;

        const tables = [];
        info.tables.forEach((t, key) => {
            if (t.valid && !isLit(t.lines[0].st))
                tables.push(tableEntry(t, key));
        });
        setIfChanged("tableModel", tables);
        // A drawn table is wider than its hidden source, so it counts toward how far the note scrolls sideways.
        const widest = Math.max(edit.contentWidth, ...tables.map(t => t.x + t.total));
        unwrappedWidth = Math.max(widest + edit.rightPadding + 4, followWidth);

        const quotes = [];
        const rules = [];
        const checks = [];
        let quoteTop = -1;
        let quoteRight = 0;
        for (const line of info.lines) {
            const r = { y: tops[line.index], height: heights[line.index] };
            if (line.quote) {
                if (quoteTop < 0) {
                    quoteTop = r.y;
                    quoteRight = 0;
                }
                // The block ends at its own longest line. A line that wraps fills the width; unwrapped, none does.
                const end = edit.positionToRectangle(line.en);
                quoteRight = Math.max(quoteRight, wrapped && end.y > r.y + 1 ? edit.width - edit.rightPadding : end.x + quoteSide);
                const next = info.lines[line.index + 1];
                if (!next || !next.quote) {
                    quotes.push({ y: quoteTop - quotePadding, height: end.y + end.height - quoteTop + 2 * quotePadding, width: Math.min(quoteRight, edit.width - edit.rightPadding) });
                    quoteTop = -1;
                }
                continue;
            }
            if (line.fence || line.table || isLit(line.st))
                continue;
            if (isRuleLine(line.text)) {
                rules.push({ y: Math.round(r.y + r.height / 2) });
                continue;
            }
            const task = line.text.match(/^(\s*)[-*+] \[([ xX])\] /);
            if (task) {
                const inner = line.st + task[1].length + 3;
                const box = edit.positionToRectangle(inner);
                checks.push({ pos: inner, x: box.x, y: box.y + Math.round((box.height - checkSize) / 2), checked: task[2] !== " " });
            }
        }
        setIfChanged("quoteModel", quotes);
        setIfChanged("ruleModel", rules);
        setIfChanged("checkModel", checks);

        // While wrapping, an image that is not fitted to the width gets a strip of its own over it, which scrolls
        // sideways when the picture is wider than the note (unwrapped, the note scrolls instead).
        const images = [];
        if (wrapped && imageMode !== "fit") {
            const urls = imageUrls();
            let n = 0;
            for (let p = s.indexOf("\uFFFC"); p >= 0; p = s.indexOf("\uFFFC", p + 1)) {
                const r = edit.positionToRectangle(p);
                images.push({ key: n, url: urls[n] ?? "", x: r.x, bottom: r.y + r.height, fixed: imageMode === "fixed" });
                n++;
            }
        }
        setIfChanged("imageModel", images);
        if (hitRects.length > 0 || searching)
            updateHitRects();
        updateCurrentLine();
    }

    function updateCurrentLine() {
        const info = structure(lastPlain);
        const line = info.lines[lineIndexAt(info.lines, edit.cursorPosition)];
        currentLine = line.index;
        const top = edit.positionToRectangle(line.st);
        const bottom = edit.positionToRectangle(line.en);
        lineHighlight = Qt.rect(0, top.y, 0, bottom.y + bottom.height - top.y);
        const range = litRangeAt(lastPlain, edit.cursorPosition);
        inTable = !!line.table && line.table.valid && range[0] === line.table.lines[0].st;
    }

    // --- Undo
    function snapshot() {
        const text = markdown();
        if (undoSteps.length > 0 && undoSteps[undoSteps.length - 1].text === text)
            return;
        undoSteps = undoSteps.concat([{ text: text, cursor: edit.cursorPosition }]).slice(-200);
        redoSteps = [];
    }

    function restore(step) {
        const steps = undoSteps;
        const redo = redoSteps;
        setMarkdown(step.text);
        undoSteps = steps;
        redoSteps = redo;
        edit.cursorPosition = Math.min(step.cursor, edit.length);
        edited();
    }

    function undo() {
        snapshotTimer.stop();
        snapshot();
        if (undoSteps.length < 2)
            return;
        const current = undoSteps[undoSteps.length - 1];
        undoSteps = undoSteps.slice(0, -1);
        redoSteps = redoSteps.concat([current]);
        restore(undoSteps[undoSteps.length - 1]);
    }

    function redo() {
        if (redoSteps.length === 0)
            return;
        const step = redoSteps[redoSteps.length - 1];
        redoSteps = redoSteps.slice(0, -1);
        undoSteps = undoSteps.concat([step]);
        restore(step);
    }

    Timer {
        id: snapshotTimer

        interval: 400
        onTriggered: root.snapshot()
    }

    // --- Tables: cells line up, Tab goes across and Enter goes down, adding columns and rows at the end.
    function tableBlock(s, p) {
        const here = lineStart(s, p);
        if (!isTableLine(s.slice(here, lineEnd(s, here))))
            return null;
        let a = here;
        while (a > 0) {
            const prev = lineStart(s, a - 1);
            if (!isTableLine(s.slice(prev, a - 1)))
                break;
            a = prev;
        }
        let b = lineEnd(s, here);
        while (b < s.length) {
            const nextEnd = lineEnd(s, b + 1);
            if (!isTableLine(s.slice(b + 1, nextEnd)))
                break;
            b = nextEnd;
        }
        const rows = s.slice(a, b).split("\n").map(l => l.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map(c => c.trim()));
        const row = s.slice(a, here).split("\n").length - 1;
        const column = Math.max(0, (s.slice(here, p).match(/\|/g) ?? []).length - 1);
        return { a: a, b: b, rows: rows, row: row, column: Math.min(column, rows[row].length - 1) };
    }

    function isRule(row) {
        return row.every(c => /^:?-+:?$/.test(c));
    }

    // Writes the table back with its columns lined up and puts the cursor in a cell.
    function writeTable(t, row, column) {
        const columns = Math.max(...t.rows.map(r => r.length));
        for (const r of t.rows) {
            while (r.length < columns)
                r.push("");
        }
        const widths = [];
        for (let c = 0; c < columns; c++)
            widths.push(Math.max(3, ...t.rows.filter(r => !isRule(r)).map(r => r[c].length)));
        const lines = t.rows.map(r => "| " + r.map((cell, c) => isRule(r) ? "-".repeat(widths[c]) : cell.padEnd(widths[c])).join(" | ") + " |");
        edit.remove(t.a, t.b);
        edit.insert(t.a, paragraphs(lines.map(escapeHtml)));
        let at = t.a;
        for (let r = 0; r < row; r++)
            at += lines[r].length + 1;
        at += 2;
        for (let c = 0; c < column; c++)
            at += widths[c] + 3;
        edit.cursorPosition = at + t.rows[row][column].length;
    }

    function tableTab(t, back) {
        if (back) {
            if (t.column > 0)
                writeTable(t, t.row, t.column - 1);
            return;
        }
        if (t.column + 1 >= t.rows[t.row].length) {
            t.rows.forEach(r => r.push(isRule(r) ? "---" : ""));
        }
        writeTable(t, t.row, t.column + 1);
    }

    function tableEnter(t, back) {
        if (back) {
            let previous = t.row - 1;
            if (previous >= 0 && isRule(t.rows[previous]))
                previous--;
            if (previous >= 0)
                writeTable(t, previous, t.column);
            return;
        }
        let next = t.row + 1;
        if (next < t.rows.length && isRule(t.rows[next]))
            next++;
        if (next >= t.rows.length) {
            t.rows.push(t.rows[0].map(() => ""));
            next = t.rows.length - 1;
        }
        writeTable(t, next, t.column);
    }


    function tableAction(name) {
        const t = tableBlock(plain(), edit.cursorPosition);
        if (!t || t.rows.length < 2 || !isRule(t.rows[1]))
            return;
        if (name === "addRow") {
            const at = Math.max(t.row + 1, 2);
            t.rows.splice(at, 0, t.rows[0].map(() => ""));
            writeTable(t, at, t.column);
        } else if (name === "addColumn") {
            t.rows.forEach(r => r.splice(t.column + 1, 0, isRule(r) ? "---" : ""));
            writeTable(t, t.row, t.column + 1);
        } else if (name === "deleteRow" && t.row >= 2) {
            t.rows.splice(t.row, 1);
            const row = t.rows.length > 2 ? Math.min(t.row, t.rows.length - 1) : 0;
            writeTable(t, row, t.column);
        } else if (name === "deleteColumn" && t.rows[0].length > 1) {
            t.rows.forEach(r => r.splice(t.column, 1));
            writeTable(t, t.row, Math.min(t.column, t.rows[0].length - 1));
        }
        focusNow();
    }

    // --- Enter
    function breakLine(prefix) {
        if (edit.selectionStart !== edit.selectionEnd)
            edit.remove(edit.selectionStart, edit.selectionEnd);
        const at = edit.cursorPosition;
        edit.insert(at, lineBreak);
        if (prefix !== "")
            edit.insert(at + 1, inlineHtml(prefix));
        edit.cursorPosition = at + 1 + prefix.length;
    }

    // A list, numbered or check list line continues on the next one, at the same indent. Enter on an empty item ends the list.
    function continueList(s) {
        const at = edit.cursorPosition;
        const st = lineStart(s, at);
        const line = s.slice(st, lineEnd(s, at));
        const m = line.match(/^(\s*)([-*+]|\d+\.)( \[[ xX]\])? (.*)$/);
        if (!m)
            return false;
        if (m[4] === "" && at === st + line.length) {
            edit.remove(st, st + line.length);
            edit.cursorPosition = st;
            return true;
        }
        const number = /^\d/.test(m[2]) ? (parseInt(m[2]) + 1) + "." : m[2];
        breakLine(m[1] + number + (m[3] ? " [ ]" : "") + " ");
        return true;
    }

    // Ctrl+Enter: a new line under this one, whatever the cursor is doing. From a table, under the table.
    function lineBelow(s, table) {
        const at = table ? table.b : lineEnd(s, edit.cursorPosition);
        edit.deselect();
        edit.insert(at, lineBreak);
        edit.cursorPosition = at + 1;
    }

    // Down on the last line goes to its end.
    function downAtEnd(shift) {
        if (edit.cursorRectangle.y < edit.positionToRectangle(edit.length).y)
            return false;
        if (shift)
            edit.moveCursorSelection(edit.length);
        else
            edit.cursorPosition = edit.length;
        return true;
    }

    // --- Mouse
    function linkAt(p) {
        return linkRangeAt(p)?.url ?? "";
    }

    // The link at p, with where it starts and ends, or null.
    function linkRangeAt(p) {
        const s = lastPlain;
        const st = lineStart(s, p);
        const found = linkMatch(s.slice(st, lineEnd(s, p)), p - st);
        return found ? { url: found.url, from: st + found.from, to: st + found.to } : null;
    }

    function linkInText(text, column) {
        return linkMatch(text, column)?.url ?? "";
    }

    function linkMatch(text, column) {
        const inside = m => column < 0 || (column >= m.index && column < m.index + m[0].length);
        for (const m of matches(/\[([^\]]+)\]\(([^)\s]+)\)/g, text)) {
            if (inside(m))
                return { url: m[2], from: m.index, to: m.index + m[0].length };
        }
        for (const m of matches(/https?:\/\/[^\s<>|)\]]+/g, text)) {
            if (inside(m))
                return { url: m[0], from: m.index, to: m.index + m[0].length };
        }
        return null;
    }

    // Ctrl+click: the link lights up and fades, so the click is seen to have done something while the browser starts.
    function flashLink(range) {
        const a = edit.positionToRectangle(range.from);
        const b = edit.positionToRectangle(range.to);
        const sameRow = Math.abs(a.y - b.y) < 1;
        linkFlash = Qt.rect(a.x, a.y, Math.max(4, (sameRow ? b.x : edit.width - edit.rightPadding) - a.x), a.height);
        flashAnimation.restart();
    }

    function openLink(url) {
        const target = /^[a-z][a-z0-9+.-]*:/i.test(url) ? url : "https://" + url;
        const browser = Settings.browser.trim();
        Quickshell.execDetached((browser !== "" ? browser.split(/\s+/) : ["xdg-open"]).concat([target]));
    }

    function checkAt(x, y) {
        return checkModel.find(c => x >= c.x - 2 && x <= c.x + checkSize + 2 && y >= c.y - 2 && y <= c.y + checkSize + 2) ?? null;
    }

    function toggleCheck(check) {
        const cursor = edit.cursorPosition;
        pendingFull = true;
        applying = true;
        edit.remove(check.pos, check.pos + 1);
        edit.insert(check.pos, inlineHtml(check.checked ? " " : "x"));
        edit.cursorPosition = cursor;
        applying = false;
    }

    function tableCellAt(x, y) {
        const t = tableModel.find(e => y >= e.y && y < e.y + e.height && x >= e.x && x < e.x + Math.min(e.total, e.available));
        if (!t)
            return null;
        const inner = x - t.x + (tableOffsets[t.key] ?? 0);
        let column = 0;
        while (column + 2 < t.columns.length && inner >= t.columns[column + 1])
            column++;
        let row = t.rows[0];
        for (const r of t.rows) {
            if (y - t.y >= r.y)
                row = r;
        }
        const st = t.lines[row.source];
        const text = lastPlain.slice(st, lineEnd(lastPlain, st));
        let pipe = text.indexOf("|");
        for (let c = 0; c < column && pipe >= 0; c++)
            pipe = text.indexOf("|", pipe + 1);
        const cell = cellsOf(text)[column] ?? "";
        return { pos: pipe < 0 ? st : Math.min(st + pipe + 2 + cell.length, st + text.length), cell: cell };
    }

    // Everything moves in the same frame (2026-11-11): the wrap mode and width follow the setting at once, so the
    // images are sized for the new mode and the line numbers, tables and marks are placed again before anything is
    // drawn. Done later, as before, the text reflowed first and the rest caught up a frame or two behind.
    function toggleWrap() {
        Settings.notesWrap = !Settings.notesWrap;
        rebuild();
        if (wrapped)
            flick.contentX = 0;
        updateLayout();
        focusNow();
    }

    function isWordChar(c) {
        return c !== undefined && /[A-Za-z0-9_\u00C0-\uFFFF]/.test(c) && c !== "\uFFFC";
    }

    // Every place `needle` occurs in s. Whole words: not touching a letter, digit or underscore on either side.
    function occurrences(s, needle, caseSensitive, whole) {
        const found = [];
        if (needle === "")
            return found;
        const hay = caseSensitive ? s : s.toLowerCase();
        const pin = caseSensitive ? needle : needle.toLowerCase();
        for (let i = hay.indexOf(pin); i >= 0; i = hay.indexOf(pin, i + pin.length)) {
            if (whole && (isWordChar(s[i - 1]) || isWordChar(s[i + pin.length])))
                continue;
            found.push({ from: i, to: i + pin.length });
            if (found.length >= 5000)
                break;
        }
        return found;
    }

    function openSearch() {
        const picked = edit.selectionStart !== edit.selectionEnd ? plain().slice(edit.selectionStart, edit.selectionEnd) : "";
        if (picked !== "" && !picked.includes("\n"))
            query = picked;
        searching = true;
        findField.text = query;
        findField.focusNow();
        findField.selectAll();
        runSearch(true);
    }

    function closeSearch() {
        searching = false;
        searchHits = [];
        hitIndex = -1;
        updateHitRects();
        focusNow();
    }

    // Finds again. `jump` moves to the first match at or after the caret, as typing a search does.
    function runSearch(jump) {
        if (!searching)
            return;
        const hits = occurrences(plain(), query, matchCase, wholeWord);
        searchHits = hits;
        if (hits.length === 0) {
            hitIndex = -1;
        } else if (jump || hitIndex < 0 || hitIndex >= hits.length) {
            const from = edit.selectionStart;
            const next = hits.findIndex(h => h.from >= from);
            hitIndex = next >= 0 ? next : 0;
            if (jump)
                showHit();
        }
        updateHitRects();
    }

    function stepHit(by) {
        if (searchHits.length === 0)
            return;
        hitIndex = (hitIndex + by + searchHits.length) % searchHits.length;
        showHit();
        updateHitRects();
    }

    // Selects the current match, which also shows that line's raw text if it was styled away, and scrolls to it.
    function showHit() {
        const h = searchHits[hitIndex];
        if (!h)
            return;
        edit.select(h.from, h.to);
        follow(edit.positionToRectangle(h.from));
        follow(edit.positionToRectangle(h.to));
    }

    // Ctrl+F2: a cursor at the end of every match of the selected text, the main one at the end of the selection.
    function cursorsAtMatches() {
        const s = plain();
        const from = edit.selectionStart;
        const to = edit.selectionEnd;
        const picked = s.slice(from, to);
        if (picked === "" || picked.includes("\n"))
            return;
        const hits = occurrences(s, picked, true, false);
        if (hits.length < 2)
            return;
        applying = true;
        edit.deselect();
        edit.cursorPosition = to;
        extras = hits.filter(h => h.to !== to).map(h => h.to);
        applying = false;
        occurrenceHits = hits;
        updateHitRects();
    }

    function rectsOf(h, current) {
        const a = edit.positionToRectangle(h.from);
        const b = edit.positionToRectangle(h.to);
        if (Math.abs(a.y - b.y) < 1)
            return [{ x: a.x, y: a.y, width: Math.max(2, b.x - a.x), height: a.height, current: current }];
        // Wrapped across rows: to the end of the first, and from the start of the last.
        return [{ x: a.x, y: a.y, width: Math.max(2, edit.width - edit.rightPadding - a.x), height: a.height, current: current },
            { x: 0, y: b.y, width: Math.max(2, b.x), height: b.height, current: current }];
    }

    function updateHitRects() {
        let rects = [];
        searchHits.forEach((h, i) => rects = rects.concat(rectsOf(h, i === hitIndex)));
        for (const h of occurrenceHits)
            rects = rects.concat(rectsOf(h, false));
        hitRects = rects;
    }

    onQueryChanged: runSearch(true)
    onMatchCaseChanged: runSearch(true)
    onWholeWordChanged: runSearch(true)

    // --- Scrolling. The note's Flickable takes no input; this one handler decides where the wheel goes: up and down
    // to the note, sideways (a sideways wheel, or Shift) to the table or image strip under the pointer when it is wider
    // than the note, otherwise to the note itself when unwrapped. `at` is in the text's coordinates.
    function wheel(event, at) {
        let dx = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x / 120 * 3 * lineStep;
        let dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 3 * lineStep;
        if ((event.modifiers & Qt.ShiftModifier) && dx === 0) {
            dx = dy;
            dy = 0;
        }
        if (dy !== 0)
            scrollTo(flick.contentX, flick.contentY - dy);
        if (dx === 0)
            return;
        const table = at ? tableModel.find(t => at.y >= t.y && at.y < t.y + t.height && at.x >= t.x && at.x < t.x + Math.min(t.total, t.available) && t.total > t.available) : null;
        if (table)
            return scrollPart("tableOffsets", table.key, table.total - table.available, (tableOffsets[table.key] ?? 0) - dx);
        const strip = at ? stripAt(at.x, at.y) : null;
        if (strip && strip.most > 0)
            return scrollPart("imageOffsets", strip.key, strip.most, (imageOffsets[strip.key] ?? 0) - dx);
        if (!wrapped)
            scrollTo(flick.contentX - dx, flick.contentY);
    }

    function scrollTo(x, y) {
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, x));
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y));
    }

    function scrollPart(name, key, most, to) {
        const next = Object.assign({}, root[name]);
        next[key] = Math.max(0, Math.min(most, to));
        root[name] = next;
    }

    // Image strips report their own size once the picture loads; see the Repeater.
    property var strips: ({})

    function stripAt(x, y) {
        for (const k in strips) {
            const st = strips[k];
            if (st && x >= st.x && x < st.x + st.width && y >= st.y && y < st.y + st.height)
                return st;
        }
        return null;
    }

    // Keeps the caret in view. Unwrapped, it keeps a few characters of room to its right, and the text is widened at
    // once if the caret is past its end, so the view never scrolls further than the content allows and then jumps back
    // (the jitter of 2026-11-09). On the last line, some of the room under the text stays in view.
    function follow(r) {
        const lastLine = r.y >= edit.positionToRectangle(edit.length).y - 1;
        const below = lastLine ? Math.min(bottomRoom, flick.height * 0.4) : 0;
        if (r.y < flick.contentY)
            flick.contentY = r.y;
        else if (r.y + r.height + below > flick.contentY + flick.height)
            flick.contentY = Math.min(edit.height - flick.height, r.y + r.height + below - flick.height);
        if (wrapped)
            return;
        const room = 4 * mono.averageCharacterWidth;
        if (r.x - room < flick.contentX) {
            flick.contentX = Math.max(0, r.x - room);
        } else if (r.x + room > flick.contentX + flick.width) {
            followWidth = r.x + room + edit.rightPadding;
            if (unwrappedWidth < followWidth)
                unwrappedWidth = followWidth;
            flick.contentX = r.x + room - flick.width;
        }
    }

    // Styles are character formats painted with the theme's colors and fonts, so a theme change paints them again
    // (otherwise only lines touched afterwards followed it). Waits a moment, since a preset changes many values at once.
    readonly property string themeKey: [Theme.colors.foreground, Theme.colors.foregroundStrong, Theme.colors.muted, Theme.colors.inactive,
        Theme.colors.accent, Theme.colors.info, Theme.colors.clear, Theme.fonts.familyMono, Theme.fonts.familyTitle, Theme.fonts.body].join()
    onThemeKeyChanged: themeRestyle.restart()

    Timer {
        id: themeRestyle

        interval: 60
        onTriggered: if (root.lastPlain !== "" || root.plain() !== "")
            root.restyleAll()
    }

    Connections {
        target: Settings

        function onNotesImagesWrappedChanged() {
            Qt.callLater(root.rebuild);
        }

        function onNotesImagesUnwrappedChanged() {
            Qt.callLater(root.rebuild);
        }

        function onNotesImageHeightChanged() {
            Qt.callLater(root.rebuild);
        }
    }

    FontMetrics {
        id: mono

        font.family: Theme.fonts.familyMono
        font.pixelSize: Theme.fonts.body
    }

    // --- Line numbers. One label per line on screen, whichever those are.
    Item {
        id: gutter

        readonly property int digits: String(Math.max(1, root.lineTops.length)).length
        readonly property int firstVisible: {
            let low = 0;
            let high = root.lineTops.length;
            while (low < high) {
                const mid = Math.floor((low + high) / 2);
                if (root.lineTops[mid] + root.lineHeights[mid] < flick.contentY)
                    low = mid + 1;
                else
                    high = mid;
            }
            return low;
        }
        readonly property int visibleCount: {
            const bottom = flick.contentY + flick.height;
            let n = 0;
            for (let i = firstVisible; i < root.lineTops.length && root.lineTops[i] < bottom; i++)
                n++;
            return n;
        }

        width: Math.max(2, digits) * Math.ceil(mono.averageCharacterWidth) + Theme.space.xl
        height: parent.height
        clip: true

        Repeater {
            model: gutter.visibleCount

            Label {
                required property int index

                readonly property int line: gutter.firstVisible + index
                readonly property bool isCurrent: line === root.currentLine

                y: (root.lineTops[line] ?? 0) - flick.contentY
                height: root.lineHeights[line] ?? 0
                visible: height >= 6
                width: gutter.width - Theme.space.m
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: Theme.fonts.familyMono
                color: isCurrent ? Theme.colors.foreground : Theme.colors.inactive
                text: Settings.notesLineNumbers === "relative" && !isCurrent ? Math.abs(line - root.currentLine) : line + 1

                Behavior on color {
                    ColorMotion {
                        preset: Theme.motion.quick
                    }
                }
            }
        }
    }

    Flickable {
        id: flick

        anchors.left: gutter.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: edit.width
        contentHeight: edit.height
        boundsBehavior: Flickable.StopAtBounds
        // All scrolling goes through root.wheel(), which knows about tables and images.
        interactive: false
        onWidthChanged: if (root.lastPlain.includes("\uFFFC"))
            Qt.callLater(root.rebuild)

        TextEdit {
            id: edit

            width: root.wrapped ? flick.width : Math.max(root.unwrappedWidth, flick.width)
            height: Math.max(implicitHeight + root.bottomRoom, flick.height)
            rightPadding: Theme.space.ml
            textFormat: TextEdit.RichText
            wrapMode: root.wrapped ? TextEdit.Wrap : TextEdit.NoWrap
            color: Theme.colors.foreground
            selectionColor: Theme.colors.accent
            selectedTextColor: Theme.colors.onAccent
            font.family: Theme.fonts.familyMono
            font.pixelSize: Theme.fonts.body
            selectByMouse: true
            persistentSelection: true
            focus: true

            // The TextEdit places its cursor delegate from C++, which animations cannot follow, so that one is left empty and
            // the visible caret is drawn below, from cursorRectangle.
            cursorDelegate: Item {}

            onContentHeightChanged: Qt.callLater(root.updateLayout)
            onContentWidthChanged: Qt.callLater(root.updateLayout)
            onWidthChanged: Qt.callLater(root.updateLayout)

            onTextChanged: {
                if (root.loading || root.styling || plain() === root.lastPlain)
                    return;
                root.edited();
                snapshotTimer.restart();
                if (root.occurrenceHits.length > 0)
                    root.occurrenceHits = [];
                if (root.searching)
                    Qt.callLater(root.runSearch, false);
                Qt.callLater(root.refreshStyle);
                if (root.extras.length > 0)
                    root.refreshExtraRects();
            }

            onSelectionStartChanged: if (!root.styling)
                Qt.callLater(root.refreshLitLine)
            onSelectionEndChanged: if (!root.styling)
                Qt.callLater(root.refreshLitLine)

            // A click or any ordinary move drops the extra cursors.
            onCursorPositionChanged: {
                if (root.styling)
                    return;
                if (!root.applying && root.extras.length > 0)
                    root.clearCursors();
                Qt.callLater(root.refreshLitLine);
            }

            onCursorRectangleChanged: {
                if (root.styling)
                    return;
                root.caretRect = cursorRectangle;
                root.follow(cursorRectangle);
            }

            Keys.onPressed: event => {
                const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                const alt = (event.modifiers & Qt.AltModifier) !== 0;
                event.accepted = true;

                if (root.panelKey(event))
                    return;
                if (event.key === Qt.Key_Escape) {
                    if (root.searching)
                        root.closeSearch();
                    else if (root.extras.length > 0)
                        root.clearCursors();
                    else
                        root.closeRequested();
                    return;
                }
                if (ctrl && !shift && event.key === Qt.Key_F)
                    return root.openSearch();
                if (ctrl && event.key === Qt.Key_F2)
                    return root.cursorsAtMatches();
                if (root.searching && event.key === Qt.Key_F3)
                    return root.stepHit(shift ? -1 : 1);
                if (alt && !ctrl && event.key === Qt.Key_Z)
                    return root.toggleWrap();
                if (alt && event.key === Qt.Key_Right)
                    return root.indentLines(true);
                if (alt && event.key === Qt.Key_Left)
                    return root.indentLines(false);
                if (alt && event.key === Qt.Key_Up)
                    return root.moveLines(false);
                if (alt && event.key === Qt.Key_Down)
                    return root.moveLines(true);
                if (ctrl && shift && event.key === Qt.Key_Up)
                    return root.addCursor(false);
                if (ctrl && shift && event.key === Qt.Key_Down)
                    return root.addCursor(true);
                if (event.key === Qt.Key_Down && !ctrl && !alt && root.extras.length === 0 && root.downAtEnd(shift))
                    return;
                if (ctrl && event.key === Qt.Key_L && !shift)
                    return root.selectLine();
                if (ctrl && event.key === Qt.Key_Z && !shift)
                    return root.undo();
                if (ctrl && (event.key === Qt.Key_Y || (shift && event.key === Qt.Key_Z)))
                    return root.redo();
                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.extras.length === 0) {
                    const s = root.plain();
                    const table = root.tableBlock(s, edit.cursorPosition);
                    if (ctrl)
                        return root.lineBelow(s, table);
                    if (table)
                        return root.tableEnter(table, shift);
                    if (shift)
                        return root.breakLine("");
                    if (root.continueList(s))
                        return;
                    return root.breakLine("");
                }
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    const table = root.tableBlock(root.plain(), edit.cursorPosition);
                    if (table && !ctrl)
                        return root.tableTab(table, event.key === Qt.Key_Backtab);
                }
                if (ctrl && event.key === Qt.Key_V) {
                    paster.running = true;
                    return;
                }
                if (ctrl && root.handleStyleKey(event, shift))
                    return;
                // Shift+Tab outdents, the opposite of Tab (it used to cycle note tabs too; Ctrl+Shift+Tab does that).
                if (event.key === Qt.Key_Backtab && !ctrl)
                    return root.indentLines(false);
                if (event.key === Qt.Key_Tab && !ctrl) {
                    // Only spaces, never a tab character.
                    if (edit.selectionStart !== edit.selectionEnd && edit.selectedText.includes("\u2029"))
                        root.indentLines(true);
                    else
                        root.typeEverywhere(root.indentText);
                    return;
                }
                if (root.extras.length > 0 && !ctrl && !alt && root.handleMultiKey(event))
                    return;
                event.accepted = false;
            }

            // Behind the text: quote blocks and the current line.
            Repeater {
                model: root.quoteModel

                Item {
                    required property var modelData

                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    z: -2

                    // Square corners, on request (2026-11-10).
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.colors.surfaceHover
                    }

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: Theme.colors.muted
                    }

                    // The big opening and closing marks sit in the room the quote's margins leave.
                    Label {
                        x: Theme.space.s
                        y: -2
                        height: 30
                        clip: true
                        text: "\u201C"
                        color: Theme.colors.muted
                        font.family: Theme.fonts.familyTitle
                        font.pixelSize: 34
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space.s
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -12
                        text: "\u201D"
                        color: Theme.colors.muted
                        font.family: Theme.fonts.familyTitle
                        font.pixelSize: 34
                    }
                }
            }

            Rectangle {
                z: -1
                y: root.lineHighlight.y
                width: Math.max(edit.width, flick.width)
                height: root.lineHighlight.height
                color: Theme.colors.surfaceHover
                opacity: 0.6
                visible: edit.activeFocus

                Behavior on y {
                    NumberAnimation {
                        duration: Theme.motion.quick.duration * 0.7
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.motion.quick.duration * 0.7
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Search matches and Ctrl+F2's matches, behind the text. The current search match is stronger.
            Repeater {
                model: root.hitRects

                Rectangle {
                    required property var modelData

                    z: -1
                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    radius: Math.min(2, Theme.shape.innerRadius)
                    color: Theme.colors.accent
                    opacity: modelData.current ? 0.55 : 0.22
                    border.width: modelData.current ? 1 : 0
                    border.color: Theme.colors.accent
                }
            }

            // Over the hidden source lines.
            Repeater {
                model: root.ruleModel

                Rectangle {
                    required property var modelData

                    y: modelData.y
                    width: edit.width - edit.rightPadding
                    height: 1
                    color: Theme.colors.border
                }
            }

            Repeater {
                model: root.tableModel

                NoteTable {
                    offsets: root.tableOffsets
                    onScrolled: p => root.scrollPart("tableOffsets", key, most, p)
                }
            }

            Repeater {
                model: root.checkModel

                Rectangle {
                    id: checkBox

                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: root.checkSize
                    height: root.checkSize
                    radius: Math.min(3, Theme.shape.innerRadius)
                    color: modelData.checked ? Theme.colors.accent : Theme.colors.clear
                    border.color: modelData.checked ? Theme.colors.accent : Theme.colors.muted
                    border.width: 1

                    Part {
                        anchors.centerIn: parent
                        visible: checkBox.modelData.checked
                        slot: "powerGlyph"

                        readonly property string glyph: "check"
                        readonly property color tint: Theme.colors.onAccent
                        readonly property int iconSize: 10
                    }
                }
            }

            // While wrapping: a strip over each image that is not fitted to the width, scrolling sideways when the picture
            // is wider than the note. Fixed height or the picture's own.
            Repeater {
                model: root.imageModel

                Rectangle {
                    id: strip

                    required property var modelData

                    readonly property int key: modelData.key
                    // The picture's window; the strip itself reaches the edge, covering the inline image under it.
                    readonly property real view: width - edit.rightPadding
                    readonly property real most: Math.max(0, picture.width - view)
                    readonly property real offset: Math.min(root.imageOffsets[key] ?? 0, most)

                    x: modelData.x
                    y: modelData.bottom - height
                    width: flick.width - x
                    height: modelData.fixed ? Settings.notesImageHeight : picture.implicitHeight
                    color: Theme.colors.surfaceRaised
                    clip: true

                    // So the wheel can find it.
                    function report() {
                        const next = Object.assign({}, root.strips);
                        next[key] = { key: key, x: x, y: y, width: view, height: height, most: most };
                        root.strips = next;
                    }

                    onXChanged: report()
                    onYChanged: report()
                    onWidthChanged: report()
                    onMostChanged: report()
                    Component.onCompleted: report()
                    Component.onDestruction: {
                        const next = Object.assign({}, root.strips);
                        delete next[key];
                        root.strips = next;
                    }

                    Item {
                        width: strip.view
                        height: parent.height
                        clip: true

                        Image {
                            id: picture

                            x: -strip.offset
                            height: strip.modelData.fixed ? parent.height : implicitHeight
                            fillMode: Image.PreserveAspectFit
                            source: strip.modelData.url
                            asynchronous: true
                        }
                    }

                    AutoScrollBar {
                        horizontal: true
                        width: strip.view
                        anchors.bottom: parent.bottom
                        contentSize: picture.width
                        viewSize: strip.view
                        position: strip.offset
                        onMoved: p => root.scrollPart("imageOffsets", strip.key, strip.most, p)
                    }
                }
            }

            // The link just Ctrl+clicked.
            Rectangle {
                id: flashBox

                x: root.linkFlash.x - 2
                y: root.linkFlash.y
                width: root.linkFlash.width + 4
                height: root.linkFlash.height
                radius: Theme.shape.innerRadius
                color: Theme.colors.accent
                opacity: 0
                z: -1

                SequentialAnimation {
                    id: flashAnimation

                    NumberAnimation {
                        target: flashBox
                        property: "opacity"
                        to: 0.45
                        duration: Theme.motion.quick.duration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: flashBox
                        property: "opacity"
                        to: 0
                        duration: Theme.motion.standard.duration * 3
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            // What the text itself should not handle: boxes, links, a click below the end, table cells, sideways scrolling.
            // No drag and drop in or out, on request (2026-11-10).
            MouseArea {
                id: pointer

                property var pending: null
                property bool pointing: false

                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: pointing ? Qt.PointingHandCursor : Qt.IBeamCursor

                function decide(mouse) {
                    const ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                    const plainClick = mouse.modifiers === Qt.NoModifier;
                    const p = edit.positionAt(mouse.x, mouse.y);
                    const link = ctrl ? root.linkRangeAt(p) : null;
                    if (link)
                        return { kind: "link", url: link.url, range: link };
                    const check = root.checkAt(mouse.x, mouse.y);
                    if (check)
                        return { kind: "check", check: check };
                    const cell = root.tableCellAt(mouse.x, mouse.y);
                    if (cell) {
                        const url = ctrl ? root.linkInText(cell.cell, -1) : "";
                        return url !== "" ? { kind: "link", url: url, range: null } : { kind: "cell", pos: cell.pos };
                    }
                    const end = edit.positionToRectangle(edit.length);
                    if (plainClick && mouse.y > end.y + end.height)
                        return { kind: "end" };
                    return null;
                }

                onPressed: mouse => {
                    pending = mouse.button === Qt.LeftButton ? decide(mouse) : null;
                    if (!pending) {
                        mouse.accepted = false;
                        return;
                    }
                    root.focusNow();
                    if (pending.kind === "end") {
                        edit.deselect();
                        edit.cursorPosition = edit.length;
                    } else if (pending.kind === "cell") {
                        edit.deselect();
                        edit.cursorPosition = pending.pos;
                    }
                }

                onPositionChanged: mouse => {
                    if (pressed)
                        return;
                    // A pointer over links (Ctrl+click opens them) and check boxes.
                    const p = edit.positionAt(mouse.x, mouse.y);
                    const r = edit.positionToRectangle(p);
                    const onText = mouse.y >= r.y && mouse.y < r.y + r.height;
                    const cell = root.tableCellAt(mouse.x, mouse.y);
                    pointing = root.checkAt(mouse.x, mouse.y) !== null || (cell ? root.linkInText(cell.cell, -1) !== "" : onText && root.linkAt(p) !== "");
                }

                onWheel: event => root.wheel(event, Qt.point(event.x, event.y))

                onReleased: {
                    const done = pending;
                    pending = null;
                    if (!done)
                        return;
                    if (done.kind === "link") {
                        if (done.range)
                            root.flashLink(done.range);
                        root.openLink(done.url);
                    } else if (done.kind === "check") {
                        root.toggleCheck(done.check);
                    }
                }
            }

            // The caret: glides to where the cursor is, and breathes instead of blinking.
            Rectangle {
                id: caret

                x: root.caretRect.x
                y: root.caretRect.y
                width: 2
                height: root.caretRect.height
                color: Theme.colors.accent
                visible: edit.activeFocus

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.motion.quick.duration * 0.7
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Theme.motion.quick.duration * 0.7
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation on opacity {
                    id: breathe

                    running: edit.activeFocus
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 450
                    }
                    NumberAnimation {
                        from: 1
                        to: 0
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                    PauseAnimation {
                        duration: 150
                    }
                    NumberAnimation {
                        from: 0
                        to: 1
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                }

                Connections {
                    target: edit

                    function onCursorPositionChanged() {
                        if (root.styling)
                            return;
                        caret.opacity = 1;
                        breathe.restart();
                    }
                }
            }

            // The other cursors.
            Repeater {
                model: root.extraRects

                Rectangle {
                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: 2
                    height: modelData.height
                    color: Theme.colors.accent
                }
            }
        }
    }

    // --- The search box, at the top right over the text, as in code editors.
    Rectangle {
        id: searchBox

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.space.xs
        anchors.rightMargin: Theme.space.ml + Theme.space.xs
        z: 3
        width: Math.min(parent.width - Theme.space.xl, 330)
        height: Theme.control.regular + 2 * Theme.space.xs
        radius: Theme.shape.controlRadius
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: Theme.shape.borderWidth
        opacity: root.searching ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.quick
            }
        }

        Keys.onPressed: event => {
            const alt = (event.modifiers & Qt.AltModifier) !== 0;
            if (alt && event.key === Qt.Key_C)
                root.matchCase = !root.matchCase;
            else if (alt && event.key === Qt.Key_W)
                root.wholeWord = !root.wholeWord;
            else if (event.key === Qt.Key_F3)
                root.stepHit((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F)
                findField.selectAll();
            else if (event.key === Qt.Key_Escape)
                root.closeSearch();
            else
                return;
            event.accepted = true;
        }

        Row {
            anchors.fill: parent
            anchors.margins: Theme.space.xs
            spacing: Theme.space.xxs

            TextField {
                id: findField

                width: parent.width - count.width - 4 * Theme.control.small - 5 * Theme.space.xxs
                height: Theme.control.regular
                placeholder: "Find"
                onTextChanged: root.query = text
                onAccepted: root.stepHit((enterModifiers & Qt.ShiftModifier) ? -1 : 1)
            }

            Label {
                id: count

                width: Math.max(implicitWidth, 46)
                height: Theme.control.regular
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.query !== "" && root.searchHits.length === 0 ? Theme.colors.error : Theme.colors.muted
                text: root.query === "" ? "" : root.searchHits.length === 0 ? "None" : (root.hitIndex + 1) + "/" + root.searchHits.length

                Behavior on color {
                    ColorMotion {}
                }
            }

            // Match case, whole words: lit while on.
            Repeater {
                model: [["Aa", "matchCase"], ["W", "wholeWord"]]

                InteractiveSurface {
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.control.small
                    height: Theme.control.small
                    restColor: Theme.colors.clear
                    selected: root[modelData[1]]
                    onClicked: {
                        root[modelData[1]] = !root[modelData[1]];
                        findField.focusNow();
                    }

                    Label {
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        font.family: Theme.fonts.familyMono
                        font.underline: parent.modelData[1] === "wholeWord"
                        color: parent.selected ? Theme.colors.onAccent : Theme.colors.foreground

                        Behavior on color {
                            ColorMotion {}
                        }
                    }
                }
            }

            // Previous and next.
            Repeater {
                model: [-1, 1]

                InteractiveSurface {
                    required property int modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.control.small
                    height: Theme.control.small
                    restColor: Theme.colors.clear
                    enabled: root.searchHits.length > 0
                    opacity: enabled ? 1 : 0.4
                    onClicked: root.stepHit(modelData)

                    Part {
                        anchors.centerIn: parent
                        slot: "powerGlyph"
                        rotation: parent.modelData < 0 ? 180 : 0

                        readonly property string glyph: "chevron"
                        readonly property color tint: Theme.colors.foreground
                        readonly property int iconSize: 12
                    }
                }
            }
        }
    }

    // --- Scroll bars: show while scrolling or when the pointer is on them, then fade. Sideways only when unwrapped.
    AutoScrollBar {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentSize: flick.contentHeight
        viewSize: flick.height
        position: flick.contentY
        onMoved: p => flick.contentY = p
    }

    AutoScrollBar {
        horizontal: true
        anchors.left: flick.left
        anchors.right: parent.right
        anchors.rightMargin: Theme.space.ml
        anchors.bottom: parent.bottom
        visible: !root.wrapped && most > 0.5
        contentSize: flick.contentWidth
        viewSize: flick.width
        position: flick.contentX
        onMoved: p => flick.contentX = p
    }

    // The wheel over the line numbers and the edges, which the text's own handler does not cover.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: event => root.wheel(event, null)
    }
}
