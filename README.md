# Tiny Dragon — two derivatives

**[▶ Play both derivatives](https://g-c-3.github.io/tiny-dragon/)**
— opens a picker linking to the Legal and Ultra versions.

Two variants of the original 185-byte Tiny Dragon, built to answer two
different questions: *"how small can this get?"* and *"how much correctness
can it gain without ballooning?"*

| | bytes | what changed |
|---|---|---|
| `tiny.com` (original) | 185 | baseline |
| `ultra/tiny_ultra.com` | **181** | same behavior, 4 bytes smaller |
| `hyper/tiny_hyper.com` | **174** | Ultra + three more cuts, one with a real tradeoff |
| `legal/tiny_legal.com` | **582** | adds real move-legality checking |

Each folder is a drop-in copy of the original repo layout (`.asm` + `.com` +
an `index.html` that boots it via js-dos), so either can replace the
original's files directly, or be hosted side by side.

## Tiny Dragon: Ultra (181 bytes)

One golf trick, applied safely: BIOS's `int 10h` video mode-set (`mov
ax,3; int 10h`) clears the entire screen to blanks with attribute `07h` as
a side effect. The original then *also* wrote that same attribute byte
itself, once per board cell, via `mov byte [es:di],07h` inside the render
loop — 4 bytes of code that write a value BIOS already put there. Since
this program never changes video modes again after startup, that write is
redundant. Dropping it: **185 → 181 bytes**, with identical gameplay.

This relies on the standard (and very well-established) BIOS/DOSBox
behavior of clearing to `07h` on a mode-set — it's not something this
program guarantees for itself the way the original's explicit write did,
so it's worth a quick visual check in your actual target (DOSBox/js-dos)
that the colors still look right, especially if you ever run it in an
environment with non-standard BIOS behavior.

A more aggressive (and *not* applied here) further cut would be to drop
the `mov ax,3; int 10h` mode-set entirely too (−5 more bytes → 176), on
the assumption that DOS already left the screen in 80×25 text mode. That's
a common assumption in size-golfed COM programs, but it's meaningfully
riskier — if something before this program left the screen in a graphics
mode or a different attribute state, the board simply won't render
correctly. Mentioned here rather than shipped, since it trades away the
original's "just works" reliability for 5 bytes.

**That aggressive cut *is* shipped as the next tier down** — see Hyper below.

## Tiny Dragon: Hyper (174 bytes)

Takes Ultra further with three more cuts:

1. **Drops the mode-set call entirely** (`mov ax,3; int 10h`, −5 bytes),
   assuming DOS already left the screen in 80×25 text mode. This is the
   "more aggressive" idea mentioned above, now actually applied. It's a
   real, meaningfully bigger assumption than Ultra's: Ultra still
   explicitly *sets* the mode (and gets the attribute-clear as a proven
   side effect of that); Hyper just hopes the mode is already right and
   whatever attribute is already on screen happens to be sane. Fine in a
   fresh DOSBox/js-dos session (the common case here); much less of a
   sure thing after other programs have run on real hardware.
2. **Replaces the AI-scan loop's exit check** — `cmp si,board+64` (4 bytes,
   full 16-bit immediate, since `board` sits too far into the file for
   a signed 8-bit immediate) followed by `jne ai_scan` (2 bytes) — with a
   `mov cx,64` once up front and a plain `loop ai_scan` (2 bytes) at the
   branch point. This one carries no extra risk versus Ultra: it's a pure
   instruction-count trick, verified to behave identically. Net −1 byte.
3. **Reuses that same CX counter for the *other* bounds check** inside the
   scan — whether the square 8 below the current one is still on the
   board. CX decrements once per square scanned, so "this is one of the
   bottom 8 squares, with nothing below it" is exactly "CX ≤ 8" at that
   point — no separate address math needed. Swapping `cmp di,board+64 /
   jae ai_next` (6 bytes, another full-immediate compare) for `cmp cx,8 /
   jbe ai_next` (5 bytes, 8 fits the sign-extended 8-bit immediate form)
   saves 1 more byte, again with no added risk. Verified directly against
   all 8 bottom-row squares (each correctly refuses to move off-board)
   plus the square just above the bottom row (correctly still moves).

**181 → 174 bytes.**

If you want Hyper's two `loop`/CX tricks but *not* the mode-set risk, the
`tiny_hyper.asm` comments show exactly what to add back for a 179-byte
"best of both" — Ultra's safety with Hyper's two free bytes.

## Tiny Dragon: Legal (582 bytes)

Adds real piece-movement legality checking for the human (White) side:

- **Source square** must hold a White (uppercase) piece.
- **Destination square** must not hold another White piece (no self-capture).
- **Shape rules** per piece:
  - **Pawn**: one square forward if empty; two squares forward only from
    the starting rank, and only if both the destination *and* the jumped
    square are empty; diagonal only as a capture (never onto an empty
    square).
  - **Knight**: the two (±1,±2)/(±2,±1) L-shapes.
  - **Bishop**: equal file/rank delta, with every square strictly between
    source and destination required to be empty.
  - **Rook**: same file or same rank, same path-clear requirement.
  - **Queen**: bishop-or-rook, same path-clear requirement.
  - **King**: one square in any direction.
- An illegal move is simply ignored: the board re-renders and you're
  asked to move again. The AI does **not** get a free turn off an illegal
  human input.

**Deliberately not implemented** (same honest scope the original's README
already stakes out for itself):
- check / checkmate / stalemate detection — there's no king-safety
  awareness, so you *can* legally move into or ignore check.
- castling, en passant, pawn promotion.
- The AI's reply is untouched — it's still the original's "shove the
  first movable black piece down a row" heuristic. It was left
  unvalidated on purpose: since it can only ever produce in-bounds,
  non-capturing single-step moves by construction, it can't produce
  anything the legality checker above would need to reject anyway.

This is the expected shape of the trade-off: real movement legality for
six piece types plus sliding-path detection is roughly 3× the original's
size. Tiny chess programs that also add check detection (the actual hard
part of "legal chess") are typically several times larger still — this
version stops short of that on purpose, matching the original's stated
scope.

## How this was built and verified

This sandbox had no internet access — no `apt-get nasm`, no DOSBox/js-dos,
no `pip install keystone/capstone/unicorn`. Rather than hand-encode x86
opcodes and hope, I wrote a small x86-16 assembler + 8086 real-mode
emulator from scratch (`tools/x86lib.py`) and used it as a stand-in
"automated emulator test harness," the same idea the original project's
own README describes using during development.

Confidence in the toolchain itself: I re-encoded the *original* `tiny.asm`
with this assembler and confirmed the output is **byte-for-byte identical**
to the real `nasm`-built `tiny.com` you uploaded. (This caught two real
bugs along the way — a segment-override-prefix ordering bug and a direct-
memory-addressing decode bug in the emulator, both since fixed.)

Both derivatives were then run through the emulator across scripted move
sequences — initial render, legal moves of every piece type, several
illegal-move rejections (wrong shape, blocked path, self-capture, same-
square), and multi-move sequences — with the resulting board state
inspected after each, not just "it didn't crash." Hyper was separately
regression-tested against the same move sequences as Ultra to confirm the
mode-set removal and CX-based scan checks don't change gameplay logic
(including targeted tests placing a piece at every square in the AI
scan's bottom row, to directly exercise the boundary case the CX trick
replaced). The mode-set risk itself — actual on-screen appearance — is
inherently something my emulator can't check, since it doesn't model real
BIOS video state; that part is on you to eyeball in DOSBox/js-dos.

**What I could *not* verify here**: actual assembly with a real `nasm`
binary, and on-screen rendering/colors in a real DOSBox/js-dos session.
The `.asm` source files are plain, standard NASM syntax (no special
directives beyond what the original already used), so:

```
nasm -f bin tiny_legal.asm -o tiny_legal.com
nasm -f bin tiny_ultra.asm -o tiny_ultra.com
```

should reproduce (or, for `tiny_legal.asm`, likely slightly *undercut* —
see note below) the `.com` files already included here. Please do that
sanity check, and open the included `index.html` in each folder, before
treating either as final.

**Note on `tiny_legal.com`'s byte count:** NASM automatically picks the
shortest valid encoding for every conditional jump — 2 bytes if the target
is close enough, a wider near form only when it has to. My own assembler
doesn't implement that automatically; I approximated it with an iterative
"try short, widen only the ones that don't fit, re-assemble" loop, which
converged at 582 bytes. Real `nasm` should land at the same size or a few
bytes smaller, never larger.
