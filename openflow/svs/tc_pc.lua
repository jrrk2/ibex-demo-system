TOP = "tc_param_concat"
FILES = { "/home/jonathan/v7-johnson-demo/ibexsoc/openflow/svs/tc_param_concat.sv" }
p = svd.parse("verible", TOP, FILES)
print("==== parse ====")
print(svd.bir(svd.pick(p, TOP)))
svd.write_verilog(p, "/tmp/svs_ibex_mini/tc_pc.v")
