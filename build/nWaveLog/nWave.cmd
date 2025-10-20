wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/user1/avsd25/avsd2541/AVSD-2024-VPU-Project/build/chip.fsdb}
verdiSetActWin -win $_nWave1
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/top_tb"
wvGetSignalSetScope -win $_nWave1 "/top_tb/chip"
wvGetSignalSetScope -win $_nWave1 "/top_tb/i_DRAM"
wvGetSignalSetScope -win $_nWave1 "/top_tb/i_ROM"
wvGetSignalSetScope -win $_nWave1 \
           "/top_tb/chip/u_TOP/CPU_wrapper/i_VPU/i_VPU_id_stage"
wvGetSignalSetScope -win $_nWave1 \
           "/top_tb/chip/u_TOP/CPU_wrapper/i_VPU/i_VPU_issue_stage"
wvResizeWindow -win $_nWave1 54 237 1093 675
wvExit
