# Ethernet (SGMII, GTX bank 117) + MDIO constraints for the merged ibex+eth
# top (top_vc707).  Port names match the eth_dev / top_vc707 ports.  sysclk is
# created in pins_vc707.xdc; this file adds the eth refclk/GT clocks and pins.

# 125 MHz SGMII refclk from the PHY to MGTREFCLK0 of GTX bank 117
set_property PACKAGE_PIN AH8 [get_ports sgmii_refclk_p]
set_property PACKAGE_PIN AH7 [get_ports sgmii_refclk_n]
create_clock -period 8.000 -name sgmii_refclk [get_ports sgmii_refclk_p]

# SGMII serial data (GTX bank 117)
set_property PACKAGE_PIN AN2 [get_ports sgmii_txp]
set_property PACKAGE_PIN AN1 [get_ports sgmii_txn]
set_property PACKAGE_PIN AM8 [get_ports sgmii_rxp]
set_property PACKAGE_PIN AM7 [get_ports sgmii_rxn]

# PHY reset + MDIO management (bank 13/14 LVCMOS18)
set_property PACKAGE_PIN AJ33 [get_ports eth_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports eth_rst_n]
set_false_path -to [get_ports eth_rst_n]
set_property PACKAGE_PIN AH33 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdc]
set_property PACKAGE_PIN AK33 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdio]
set_false_path -to [get_ports eth_mdc]
set_false_path -to [get_ports eth_mdio]
set_false_path -from [get_ports eth_mdio]

# GT TXOUTCLK = 62.5 MHz (1G SGMII); userclk2 (125 MHz) auto-derived via MMCM.
# Hierarchy-agnostic wildcard so it resolves under the deeper ibex hierarchy.
create_clock -period 16.000 -name gt_txoutclk \
    [get_pins -hierarchical -filter {NAME =~ */gtxe2_i/TXOUTCLK}]

# All three domains are mutually asynchronous (CDC via dual-clock BRAMs + sync).
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sysclk] \
    -group [get_clocks -include_generated_clocks gt_txoutclk] \
    -group [get_clocks -include_generated_clocks sgmii_refclk]
