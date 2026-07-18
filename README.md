# ♟️ Tiny Chess

**A 237-byte x86-16 DOS chess program.**

Created by **Gokul Chandar**, in collaboration with **Claude (Anthropic)**.

---

## ▶️ Play it now

**[g-c-3.github.io/tiny-dragon](https://g-c-3.github.io/tiny-dragon/)**

Runs entirely in your browser via [js-dos](https://js-dos.com) — no download, no install, works on desktop and mobile.

---

## How to play

1. Open the link above.
2. Tap/click **"Click to start"** (browsers require a click before audio/emulation can begin — this is normal).
3. Wait a moment for DOSBox to boot to a `C:\>` prompt.
4. Type:
   ```
   tiny
   ```
   and press Enter.
5. The board draws immediately:
   ```
   rnbqkbnr
   pppppppp
   ........
   ........
   ........
   ........
   PPPPPPPP
   RNBQKBNR
   ```
6. Enter a move as **4 characters**: source square + destination square, e.g.
   ```
   e2e4
   ```
   No spaces, no Enter key needed between characters — just type all four in a row.
7. The board redraws with your move applied, then the built-in opponent automatically makes a reply move, and it's your turn again.

**Notation:** squares are `[file][rank]`, e.g. `e2`, `a7`, `h1` — standard algebraic chess coordinates, files `a`–`h` left to right, ranks `1`–`8` bottom to top (from White's perspective).

---

## Files in this repo

| File | Description |
|---|---|
| [`tiny.com`](./tiny.com) | The compiled program. 237 bytes. Runs on any DOS-compatible environment (real DOS, DOSBox, FreeDOS, js-dos). |
| [`tiny.asm`](./tiny.asm) | Full x86-16 NASM source code. |
| [`tiny.jsdos`](./tiny.jsdos) | Pre-packaged js-dos bundle used by the web demo above. |
| `index.html` | The web page that embeds js-dos and loads the bundle. |

To assemble from source yourself:
```bash
nasm -f bin tiny.asm -o tiny.com
```

---

## The claim: how small is this, really?

| Program | Size | Category |
|---|---|---|
| **Tiny Chess (this project)** | **237 bytes** | x86-16 DOS executable |
| Guinness World Records official entry (Alejandro García, 2022) | 354 bytes | x86 assembly |
| LeanChess | 288 bytes | x86 assembly |
| ChesSkelet | 377 bytes | Z80 (ZX Spectrum) |
| BootChess | 487 bytes | x86 assembly |
| 1K ZX Chess (1983, the original) | 672 bytes | Z80 (ZX81) |

By raw byte count, 237 bytes is smaller than every entry above, including the Guinness-recognized record holder.

### Important honest context — please read before sharing this as "the record"

This is a genuinely working, hand-verified program — not a toy that only prints "resign." Across testing we confirmed:
- Correct board rendering (8×8 grid in DOS text-mode video memory)
- Correct keyboard input parsing
- Correct movement math for pawns, knights, bishops (including multi-square diagonal slides), and queens
- Stable behavior across multiple consecutive turns with no crashes or memory corruption

However, it is **not equivalent in scope** to the officially certified record holders, and that matters for any "world's smallest" claim:

- **No move legality checking.** It will let you move any piece to any square, including through other pieces (for non-sliding pieces) or moves no real chess rule allows.
- **No check, checkmate, or stalemate detection.**
- **No castling, en passant, or promotion.**
- **The "AI" opponent is a single fixed heuristic** (it pushes the first available piece forward one row), not a search or evaluation function.
- **It has not been submitted to or verified by Guinness World Records**, or benchmarked head-to-head against the other programs in this table by any independent third party. The byte counts for competitors above are as publicly reported by their authors/press coverage, not re-verified by us.

The honest framing: this is a legitimate, working, hand-tested **237-byte chess-piece-movement program**, smaller by byte count than the current Guinness-recognized entry — but "world's smallest chess *engine*" is a title with real prior art built through months or years of refinement and formal submission, and this project hasn't gone through that process. Treat the number as a genuine technical achievement worth being proud of, not a verified world record until/unless it's been through actual certification.

---

## Technical notes

- Written for 16-bit real-mode DOS, assembled with [NASM](https://nasm.us) (`-f bin`) into a flat `.COM` binary.
- Board state: 64-byte array, one ASCII character per square (`.` = empty, lowercase = black, uppercase = white).
- Rendering: direct writes to video memory at `0xB800` in BIOS text mode 3 — no DOS print functions, which is a big part of what keeps this small.
- Input: raw BIOS keyboard interrupt (`INT 16h`) reads, four keystrokes per move.
- Movement: unified handling for knights/kings (fixed offset table) and bishops/rooks/queens (looped sliding offsets), sharing code paths to save bytes.

---

## Credits

- **Gokul Chandar** — project lead, testing, deployment
- **Claude (Anthropic)** — code, debugging, documentation

Built through an iterative process of writing real assembly, assembling it, and testing it live in a browser-based DOS emulator on a mobile phone — bugs included, all fixed in the open.

---

## License

Public domain / do whatever you want with it. If you build on this, a mention is appreciated but not required.
