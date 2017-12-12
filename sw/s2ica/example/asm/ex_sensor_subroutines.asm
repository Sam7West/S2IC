#define slave_addr_apds 0xE2
#define slave_addr_abc 0xFF
#define apds_reg 1


write_apd_sensor:
	STA
	WR slave_addr_apds
	WR apds_reg_01
	WR 0xFF
	STO
	NOP
	NOP
	jmp main

read_apd_sensor:
	STA
	WR	slave_addr_apds
	WR	0xA
	STA	; repeated start
	WR	slave_addr_apds
	RDA	0
	RDN	1
	STO
	NOP
	jmp main
	
