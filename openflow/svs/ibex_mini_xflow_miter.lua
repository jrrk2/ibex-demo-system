-- IBEX MINI: Z3 cross-flow equivalence — GOLDEN (Vivado synth netlist) vs
-- VERIBLE (SVS frontend -> gate-map).  Hierarchical miter (miter_hier) pairs
-- common module names leaves-first, abstracts user submodules as uninterpreted
-- functions and cuts RAM/MMCM black boxes (assume-guarantee), so it scales past
-- the CPU without the flat-miter OOM.  Runs on the in-memory gate-map `result`,
-- so the bir_to_edif floating-net ERC does NOT block it.
--
-- Requires the SAME env as ibex_mini_svs.lua: SVS_DEFINE with SYNTHESIS=1,
-- MEMLOWER_FPGA=1, SVS_INCDIR.  Modes:
--   (default)         cross-flow: Vivado golden netlist (A) vs SVS gate-map (B)
--   SELF_MITER_TOP=M  self-miter: SVS behavioral (p) vs SVS gate-map (result) on
--                     module M — a DIFFER is a pure gate_map LOWERING bug
--                     (frontend bugs cancel, both sides share them).
--   MITER_TOP=M       choose the cross-flow miter root (default ibex_mini_system)
dofile("/home/jonathan/v7-johnson-demo/ibexsoc/openflow/svs/_files_only.lua")

local p = svd.parse("verible", "top_vc707_mini", FILES)
p = svd.unroll(p); p=svd.inline(p); p=svd.iflift(p)
p = svd.blocking_subst(p); p=svd.meminfer(p); p=svd.memlower(p); p=svd.srl_infer(p)

local names = svd.module_names(p)
NT={}; local cnt=0; local i=1; local n=strlen(names)
while i<=n do local j=strfind(names,",",i,1); local nm
  if j then nm=strsub(names,i,j-1); i=j+1 else nm=strsub(names,i,n); i=n+1 end
  if strlen(nm)>0 then cnt=cnt+1; NT[cnt]=nm end
end
local result=p; local k=1
while k<=cnt do
  local M=NT[k]
  print("gate_map "..M)
  result = svd.splice(result, M, svd.mapped_to_prog(svd.gate_map(svd.pick(result,M),6,0)))
  k=k+1
end

-- GM_DUMP=<module>: dump the gate-mapped BIR of one module (to trace a dropped
-- driver, e.g. the driverless RAM write-enable nets).
if os.getenv("GM_DUMP") then
  print("GMBIR_START"); print(svd.bir(svd.pick(result, os.getenv("GM_DUMP")))); print("GMBIR_END")
  error("gm dump done")
end
-- BEHAV_DUMP=<module>: same module from the pre-gate-map behavioral p (the
-- reference the gate-map should preserve).
if os.getenv("BEHAV_DUMP") then
  print("BHBIR_START"); print(svd.bir(svd.pick(p, os.getenv("BEHAV_DUMP")))); print("BHBIR_END")
  error("behav dump done")
end

-- SELF-MITER: behavioral (p) vs gate-map (result), SAME boundaries/names (no
-- canon), so a DIFFER is a genuine SVS gate_map lowering bug.
if os.getenv("SELF_MITER_TOP") then
  local m = os.getenv("SELF_MITER_TOP")
  print("=== SELF-MITER (SVS behavioral vs SVS gate-map): " .. m .. " ===")
  print(svd.miter_hier(p, result, m))
  error("self-miter done")
end

-- Reconcile SVS param-specialised names (base__P1_D32_…) with Vivado's clean
-- base names so leaves pair.
result = svd.canon_module_names(result)

-- Side A: Vivado's GOLDEN synth netlist of the mini design (module-preserved).
-- GOLD_NETLIST selects it; default = the -flatten_hierarchy none boundary-
-- preserved reference (no cross-module const-prop / port pruning), which is the
-- fair comparison.  The P&R "rebuilt" netlist bakes top tie-offs into children
-- (gpio gp_i=0, dmi_jtag_tap tck=0) and yields spurious per-module DIFFERs.
local gold = os.getenv("GOLD_NETLIST") or "/tmp/ibex_mini_goldref_noflat.v"
local A = svd.parse("verible", "top_vc707_mini", {gold})
A = svd.canon_module_names(A)

local miter_top = os.getenv("MITER_TOP") or "ibex_mini_system"

-- BEHAV_MITER: compare Vivado GOLDEN (A) against the SVS *behavioral* program
-- (pre-create_circuit `p`, canon-named) instead of the gate-mapped `result`.
-- The frontend/blocking_subst bug lives in `p` before gate_map, so this isolates
-- whether the miter can see the bug at the behavioral level — i.e. whether the
-- vacuity is introduced by create_circuit/gate_map or is intrinsic to the miter.
if os.getenv("BEHAV_MITER") then
  local pc = svd.canon_module_names(p)
  print("=== IBEX MINI BEHAV MITER: Vivado GOLDEN (A) vs SVS behavioral p (B) — top=" .. miter_top .. " ===")
  print(svd.miter_hier(A, pc, miter_top))
  error("behav-miter done")
end

print("=== IBEX MINI CROSS-FLOW MITER: Vivado GOLDEN (A) vs SVS VERIBLE gate-map (B) — top=" .. miter_top .. " ===")
print("golden modules: " .. svd.module_names(A))
print(svd.miter_hier(A, result, miter_top))
