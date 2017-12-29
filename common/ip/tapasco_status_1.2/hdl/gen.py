#!/usr/bin/python
str = """          12'd%d: reg_data_out <= C_SLOT_KERNEL_ID_%d;
          12'd%d: reg_data_out <= 32'hFFFFFFFF - C_SLOT_LOCAL_MEM_%d;"""

for x in range(1,129):
    print str % (240 + x * 16, x, 240 + x * 16 + 4, x)
