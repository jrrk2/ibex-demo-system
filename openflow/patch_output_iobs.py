#!/usr/bin/env python3
"""LEGACY / OPTIONAL -- the ibex-mini open flow is splice-free by default and no
longer calls this (validated on silicon 2026-07-27: johnson counter walks all 8
LEDs from the open flow's own fasm2frames IOB config, no Vivado bit).

History: this spliced "golden's" LVCMOS18 output-IOB config into the open
frames.  The apparent "missing ~7 bits per output" was NOT a prjxray segbits
gap -- it was a DESIGN MISMATCH: golden is the FULL lowrisc_ibex_demo_system
(with UART), the open build is the cut-down mini (LED-only, no UART), so the
splice copied the full demo's config (incl. UART_TX drive the mini doesn't
have) onto the mini bit.  The mini's own output config is correct and self-
consistent across all 8 LEDs.  Kept only for the opt-in GOLDEN_BIT path.

Usage: patch_output_iobs.py <golden.bit> <in.frames> <out.frames>
"""
import sys, os, re, json, csv, subprocess, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BR = os.path.join(ROOT, "deps/prjxray/build/tools/bitread")
DEV = os.path.join(ROOT, "deps/prjxray/database/virtex7")
PART = "xc7vx485tffg1761-2"
PARTYAML = os.path.join(DEV, PART, "part.yaml")
TILEGRID = os.path.join(DEV, "xc7vx485t", "tilegrid.json")
PKG = os.path.join(DEV, PART, "package_pins.csv")

# VC707 output ports (LVCMOS18, bank 13/15) -> package pin
OUT_PINS = {"LED0": "AM39", "LED1": "AN39", "LED2": "AR37", "LED3": "AT37",
            "LED4": "AR35", "LED5": "AP41", "LED6": "AP42", "LED7": "AU39",
            "UART_TX": "AU36"}


def out_tiles():
    tg = json.load(open(TILEGRID))
    pins = {r["pin"]: r for r in csv.DictReader(open(PKG))}
    tiles = {}  # (base, off, words, frames) -> tilename  (deduped)
    for pin in OUT_PINS.values():
        t = pins[pin]["tile"]
        b = tg[t]["bits"]["CLB_IO_CLK"]
        key = (int(b["baseaddr"], 16), b["offset"], b["words"], b["frames"])
        tiles[key] = t
    return tiles


def bitread_frames(bitfile, lo, hi):
    """Return {frame_addr -> [101 words]} reconstructed for [lo,hi]."""
    out = "/tmp/_oiob_%x_%x.bits" % (lo, hi)
    if os.path.exists(out):
        os.remove(out)
    subprocess.run([BR, "--part_file", PARTYAML, "-F", "0x%08X:0x%08X" % (lo, hi),
                    "-o", out, "-z", "-y", bitfile],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    frames = collections.defaultdict(lambda: [0] * 101)
    for ln in open(out):
        m = re.match(r"bit_([0-9a-f]+)_(\d+)_(\d+)", ln.strip())
        if m:
            frames[int(m.group(1), 16)][int(m.group(2))] |= 1 << int(m.group(3))
    return frames


def main():
    golden, infr, outfr = sys.argv[1], sys.argv[2], sys.argv[3]
    tiles = out_tiles()
    # golden word-slices per frame address: addr -> {(wlo,whi): [words...]}
    repl = collections.defaultdict(dict)  # addr -> {word_index: value}
    # IO-column minor frames 0..27 belong to the CO-LOCATED INT_L/INT_R
    # interconnect tiles (shared config column, segbits partition the minors:
    # LIOB18 features live in minors {0,29..33,38..39}).  Splicing ALL minors
    # copied GOLDEN's INT ROUTING over the open build's at the IOB word rows
    # (INT_L_X32Y33/49/127..140 = active tiles) -> shorted/severed open nets =
    # the ibex hart-side load corruption.  Restrict to the IOB/IOI minors.
    IOB_MINOR_LO = 28
    for (base, off, w, nf), tname in tiles.items():
        gf = bitread_frames(golden, base, base + nf - 1)
        for a in range(base + IOB_MINOR_LO, base + nf):
            words = gf.get(a, [0] * 101)
            for wi in range(off, off + w):
                repl[a][wi] = words[wi]
        print("  golden splice: %-22s 0x%08X minors[%d..%d] words[%d..%d]" %
              (tname, base, IOB_MINOR_LO, nf - 1, off, off + w - 1))
    # rewrite frames file
    lines = {}
    order = []
    for ln in open(infr):
        ln = ln.rstrip("\n")
        ad = ln.split(" ", 1)[0]
        try:
            a = int(ad, 16)
        except ValueError:
            order.append(("raw", ln)); continue
        words = [int(x, 16) for x in ln.split(" ", 1)[1].split(",")]
        lines[a] = words
        order.append(("frame", a))
    npatched = 0
    seen = set()
    for a, wd in repl.items():
        if a in lines:
            for wi, v in wd.items():
                lines[a][wi] = v
            npatched += 1
            seen.add(a)
        else:
            words = [0] * 101
            for wi, v in wd.items():
                words[wi] = v
            lines[a] = words
            order.append(("frame", a))
            npatched += 1
    out = []
    for kind, val in order:
        if kind == "raw":
            out.append(val)
        else:
            out.append("0x%08X %s" % (val, ",".join("0x%08X" % x for x in lines[val])))
    open(outfr, "w").write("\n".join(out) + "\n")
    print("patched %d output-IOB frames across %d tiles" % (npatched, len(tiles)))


if __name__ == "__main__":
    main()
