# ♟️ Tiny Dragon (a.k.a. Tiny Chess)

**A 185-byte x86-16 DOS chess program.**

Created by **Gokul Chandar**, in collaboration with **Claude (Anthropic)**.

---

## ▶️ Play it now

**[g-c-3.github.io/tiny-dragon](https://g-c-3.github.io/tiny-dragon/)**

Runs entirely in your browser via [js-dos](https://js-dos.com) — no download, no install, works on desktop and mobile. The page loads the real `tiny.com` binary directly and starts it automatically.

---

## How to play

1. Open the link above.
2. Tap/click **"Click to start"** (browsers require a click before audio/emulation can begin — this is normal).
3. The game boots and draws the starting position automatically:
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
4. Enter a move as **4 characters**: source square + destination square, e.g.
   ```
   e2e4
   ```
   No spaces, no Enter key needed between characters — just type all four in a row.
5. The board redraws with your move applied, then the built-in opponent automatically makes a reply move, and it's your turn again.

**Notation:** squares are `[file][rank]`, e.g. `e2`, `a7`, `h1` — standard algebraic chess coordinates, files `a`–`h` left to right, ranks `1`–`8` bottom to top. **You play White** (the uppercase pieces, bottom two rows). The built-in opponent automatically plays Black (lowercase, top two rows).

---

## Files in this repo

| File | Description |
|---|---|
| [`tiny.com`](./tiny.com) | The compiled program. 185 bytes. Runs on any DOS-compatible environment (real DOS, DOSBox, FreeDOS, js-dos). |
| [`tiny.asm`](./tiny.asm) | Full x86-16 NASM source code — the actual human-readable proof of how the 185 bytes work. |
| `index.html` | The web page. Fetches `tiny.com` directly (cache-busted) and boots it via js-dos's `initFs`, so the live demo always reflects whatever is currently committed — no separate bundle file to keep in sync. |

To assemble from source yourself:
```bash
nasm -f bin tiny.asm -o tiny.com
```

---

## The claim: how small is this, really?

| Program | Size | Category |
|---|---|---|
| **Tiny Dragon (this project)** | **185 bytes** | x86-16 DOS executable |
| LeanChess | 328 bytes | x86 assembly |
| Guinness World Records official entry (Alejandro García, 2022) | 354 bytes | x86 assembly |
| ChesSkelet | 377 bytes | Z80 (ZX Spectrum) |
| BootChess | 487 bytes | x86 assembly |
| 1K ZX Chess (1983, the original) | 672 bytes | Z80 (ZX81) |

By raw byte count, 185 bytes is smaller than every entry above, including the Guinness-recognized record holder.

### Important honest context — please read before sharing this as "the record"

This is a genuinely working, thoroughly tested program — not a toy that only prints "resign." It has been verified two independent ways: an automated x86 emulator (testing dozens of move sequences, corner-of-board math, degenerate same-square input, and deliberately *poisoned* CPU registers to rule out hidden assumptions about starting machine state) and real hardware/browser testing on an actual DOS emulator. Confirmed working:

- Correct board rendering (8×8 grid in DOS text-mode video memory)
- Correct keyboard input parsing
- Correct movement math for pawns, knights, bishops (including multi-square diagonal slides), queens, and edge/corner squares
- Correct handling of a same-source-and-destination move (a real bug we found, traced, and fixed — see Development Log below)
- Stable behavior across long move sequences with no crashes or memory corruption, including under adversarial register conditions

However, it is **not equivalent in scope** to the officially certified record holders, and that matters for any "world's smallest" claim:

- **No move legality checking.** It will let you move any piece to any square, including through other pieces (for non-sliding pieces) or moves no real chess rule allows.
- **No check, checkmate, or stalemate detection.**
- **No castling, en passant, or promotion.**
- **The "AI" opponent is a single fixed heuristic** (it pushes the first available black piece forward one row, regardless of piece type — meaning it can make moves that aren't actually legal for that piece, e.g. moving a knight or bishop straight forward), not a search or evaluation function.
- **It has not been submitted to or verified by Guinness World Records**, or benchmarked head-to-head against the other programs in this table by any independent third party. The byte counts for competitors above are as publicly reported by their authors/press coverage, not re-verified by us.

The honest framing: this is a legitimate, working, rigorously-tested **185-byte chess-piece-movement program**, smaller by byte count than the current Guinness-recognized entry — but "world's smallest chess *engine*" is a title with real prior art built through months or years of refinement and formal submission, and this project hasn't gone through that process. Treat the number as a genuine technical achievement worth being proud of, not a verified world record until/unless it's been through actual certification.

---

## Technical notes

- Written for 16-bit real-mode DOS, assembled with [NASM](https://nasm.us) (`-f bin`) into a flat `.COM` binary.
- Board state: 64-byte array, one ASCII character per square (`.` = empty, lowercase = black, uppercase = white).
- Rendering: direct writes to video memory at `0xB800` in BIOS text mode 3 via `lodsb`/`stosb` string instructions, with `LOOP`-based 8×8 nested counting — no DOS print functions, which is a big part of what keeps this small.
- Input: raw BIOS keyboard interrupt (`INT 16h`) reads, four keystrokes per move.
- Movement: unified handling for knights/kings (fixed offset table) and bishops/rooks/queens (looped sliding offsets), sharing code paths to save bytes. Square lookup returns a ready-to-use pointer rather than a raw index, shrinking downstream addressing.
- The move-execution step uses an `xchg`-based swap (source ↔ temp ↔ destination) rather than separate read/write/clear instructions — a technique adapted from [LeanChess](https://github.com/leanchess/leanchess)'s source, which turned out to also fix a same-square-move bug as a side effect of the swap semantics.

---

## Development log (honest account, not a highlight reel)

This started at 237 bytes and was refined down to 185 across many rounds, including real mistakes caught and fixed along the way:

- Iterative byte-golfing: register-based addressing simplifications, `LOOP`-based loop restructuring, algebraic constant-folding, subroutine factoring, and string instructions (`lodsb`/`stosb`) in place of manual memory addressing.
- **A real correctness bug was introduced and caught mid-session**: a loop-counter optimization set only the low byte of a 16-bit register, which could have corrupted memory on real hardware where register contents at program start aren't guaranteed to be zero. Caught by deliberately testing with poisoned (non-zero garbage) initial registers, not by luck.
- **A second real bug** — moving a piece to its own square (e.g. typing the same square twice) caused that piece to vanish rather than stay put — was found through direct on-device testing, root-caused, and fixed by adopting a technique from LeanChess's own source code, which fixed the bug as a side effect while also being one byte smaller.
- Verification methodology deliberately combines automated emulation (fast iteration, adversarial register testing) with real on-device testing (the actual ground truth), because the two don't always agree by default — an earlier version of the automated test harness itself had a bug that produced a false "verified correct" result, which was only caught by cross-checking against real hardware.

---

## Credits

- **Gokul Chandar** — project lead, testing, deployment
- **Claude (Anthropic)** — code, debugging, documentation
- Move-execution technique adapted from **[LeanChess](https://github.com/leanchess/leanchess) by Dmitry Shechtman** (MIT licensed) — see Technical notes above

Built through an iterative process of writing real assembly, assembling it, testing it with an automated emulator, and testing it live in a browser-based DOS emulator on a mobile phone — bugs included, all found and fixed in the open.

---

## License

Public domain / do whatever you want with it. If you build on this, a mention is appreciated but not required.
