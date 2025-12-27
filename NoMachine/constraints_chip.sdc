
set_max_transition 0.2 [current_design]

set clk_period 10
set rstn_period 100
set byp_period 2.5
set scan_period 20

create_clock -name RSTN -period $rstn_period core_reset/C
create_clock -name CLK -period $clk_period core_clock/C
create_clock -name BYP_CLK -period $byp_period bypass_clock/C
create_clock -name SCAN_CLK -period $scan_period_period scan_clock/C
