-- Per-module Z3 equivalence of the OPTIMISED gate-map vs the behavioural
-- golden.  Parse + run the passes once, gate-map every module with whatever
-- GATE_MAP_* optimisation env is set, then miter_hier each module (children
-- abstracted as uninterpreted -> tractable, no full-CPU OOM).  A DIFFER means
-- an optimisation pass (balance / lutpack / mfs2 / mixed-cover) broke that
-- module.  ONLY=modA,modB restricts to a subset.
dofile("/home/jonathan/v7-johnson-demo/ibexsoc/openflow/svs/_files_only.lua")
local p = svd.parse("verible", "top_vc707_mini", FILES)
p = svd.unroll(p); p=svd.inline(p); p=svd.iflift(p)
p = svd.blocking_subst(p); p=svd.meminfer(p); p=svd.memlower(p); p=svd.srl_infer(p)

-- collect module names
local names = svd.module_names(p)
local NT={}; local cnt=0; local i=1; local n=strlen(names)
while i<=n do local j=strfind(names,",",i,1); local nm
  if j then nm=strsub(names,i,j-1); i=j+1 else nm=strsub(names,i,n); i=n+1 end
  if strlen(nm)>0 then cnt=cnt+1; NT[cnt]=nm end
end

-- gate-map every module (uses GATE_MAP_* env for optimisation)
local kcov = tonumber(os.getenv("GATE_MAP_K") or "6") or 6
local result=p; local k=1
while k<=cnt do
  result = svd.splice(result, NT[k], svd.mapped_to_prog(svd.gate_map(svd.pick(result,NT[k]),kcov,0)))
  k=k+1
end

-- optional subset filter (ONLY=modA,modB); no filter => all modules
only = os.getenv("ONLY")
function wanted(m)
  if not only then return 1 end
  if strfind(only, m, 1, 1) then return 1 else return nil end
end

print("==== PER-MODULE MITER (opt gate-map vs behavioural golden) ====")
k=1
while k<=cnt do
  local M=NT[k]
  if wanted(M) then
    print("MITER "..M.." "..svd.miter_hier(p, result, M))
  end
  k=k+1
end
print("==== DONE ====")
