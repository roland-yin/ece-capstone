(globals
	version = 3
	space =0
	io_order = clockwise
)

(row_margin
	(north
		(io_row ring_number=1 margin=25.0)
	)
	(east
		(io_row ring_number=1 margin=25.0)
	)
	(west
		(io_row ring_number=1 margin=25.0)
	)
	(south
		(io_row ring_number=1 margin=25.0)
	)
)
(iopad

	(northwest
		(inst name = Corner_NW cell=PCORNER_G)
	)
	(northeast
		(inst name = Corner_NE cell=PCORNER_G)
	)
	(southeast
		(inst name = Corner_SE cell=PCORNERA_G)
	)
	(southwest
		(inst name = Corner_SW cell=PCORNERA_G)
	)

	(north
		(inst name = GND0 space=53)
		(inst name = VDD0 space=0)
		(inst name = GND1 )
		(inst name = VDD1 )
		(inst name = i2s_word_rx )
		(inst name = i2s_clock_rx )
		(inst name = i2s_input_0 )
		(inst name = i2s_input_1 )
		(inst name = i2s_input_2 )
		(inst name = i2s_input_3 )
		(inst name = NC0 )
	)

	(east
		(inst name = GND2 space=2.5)
		(inst name = VDD2 space=0)
		(inst name = GND3 )
		(inst name = VDD3 )
		(inst name = i2s_word_tx )
		(inst name = i2s_clock_tx )
		(inst name = i2s_data_output )
		(inst name = core_reset )
		(inst name = core_clock )
		(inst name = bypass_clock )
		(inst name = NC1 )
	)

	(south
		(inst name = GND4 space=53)
		(inst name = VDD4 space=0)
		(inst name = GND5 )
		(inst name = VDD5 )
		(inst name = bypass0 )
		(inst name = bypass1 )
		(inst name = bypass2 )
		(inst name = bypass3 )
		(inst name = bypass4 )
		(inst name = bypass5 )
		(inst name = bypass6 )
	)
	
	(west
		(inst name = GND6 space=2.5)
		(inst name = VDD6 space=0)
		(inst name = GND7)
		(inst name = VDD7)
		(inst name = bypass_ready)
		(inst name = bypass_valid)
		(inst name = intialization)
		(inst name = scan_enable)
		(inst name = scan_weight)
		(inst name = scan_xdata)
		(inst name = scan_clock )
	)
)
