TOP = "tc_bitsel_mux"
FILES = { "/home/jonathan/v7-johnson-demo/ibexsoc/openflow/svs/tc_bitsel_mux.sv" }

p = svd.parse("verible", TOP, FILES)
print("==== parse ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.unroll(p)
print("==== unroll ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.inline(p)
print("==== inline ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.iflift(p)
print("==== iflift ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.blocking_subst(p)
print("==== blocking_subst ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.meminfer(p)
print("==== meminfer ===="); print(svd.bir(svd.pick(p, TOP)))
p = svd.srl_infer(p)
print("==== srl_infer ===="); print(svd.bir(svd.pick(p, TOP)))
svd.write_verilog(p, "/tmp/svs_ibex_mini/tc_bitsel.v")
print("WROTE /tmp/svs_ibex_mini/tc_bitsel.v")
