-- IBEX MINI: structural sweep for the input-port-driver malformation.
-- A frontend/pass bug that redirects a write onto a module INPUT port is
-- invisible to the Z3 miter (inputs are modelled as free primary inputs, so the
-- write is silently dropped -> vacuous EQUIVALENT).  svd.check_input_drivers
-- scans every module of the behavioral program AFTER the full frontend pipeline
-- (same point the dm_csrs sbaddress_i bug appeared) with no Z3.
dofile("/home/jonathan/v7-johnson-demo/ibexsoc/openflow/svs/_files_only.lua")

local p = svd.parse("verible", "top_vc707_mini", FILES)
p = svd.unroll(p); p=svd.inline(p); p=svd.iflift(p)
p = svd.blocking_subst(p); p=svd.meminfer(p); p=svd.memlower(p); p=svd.srl_infer(p)

print("=== INPUT-PORT-DRIVER SWEEP (behavioral p, post-frontend) ===")
print(svd.check_input_drivers(p))
