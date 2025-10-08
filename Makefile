MAKEFLAGS += --no-print-directory

root_dir   := $(PWD)
src_dir    := ./src
syn_dir    := ./syn
pr_dir     := ./pr/icc2_ADFP_tsri/run
inc_dir    := ./include
sim_dir    := ./sim
vip_dir    := $(PWD)/vip
bld_dir    := ./build
log_dir    := ./log
lib_dir    := /usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog
lib_dir_io := /usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/

FSDB_DEF :=
ifeq ($(FSDB),1)
	FSDB_DEF := +FSDB
else ifeq ($(FSDB),2)
	FSDB_DEF := +FSDB_ALL
endif

ifeq ($(PROG),3)
	TB_FILE := top_tb_WDT.sv
else
	TB_FILE := top_tb.sv
endif

$(bld_dir):
	mkdir -p $(bld_dir)

$(log_dir):
	mkdir -p $(log_dir)

$(syn_dir):
	mkdir -p $(syn_dir)

$(pr_dir):
	mkdir -p $(pr_dir)

rtl_sim: | $(bld_dir) $(log_dir)
	@( \
		echo "Building and running PROG = $(PROG)"; \
		make -C $(sim_dir)/prog$(PROG); \
		cd $(bld_dir); \
		vcs -R -sverilog $(root_dir)/$(sim_dir)/$(TB_FILE) \
			-debug_access+all -full64 -debug_region+cell +memcbk \
			-f $(root_dir)/$(src_dir)/rtl_sim.f \
			+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir) \
			+define+prog$(PROG)$(FSDB_DEF) \
			+prog_path=$(root_dir)/$(sim_dir)/prog$(PROG) \
			+rdcycle=1 \
			+notimingcheck; \
	) 2>&1 | tee log/rtl$(PROG).log

syn_sim: | clean $(bld_dir) $(log_dir)
	( \
		echo "Synthesis simulation for PROG = $(PROG)"; \
		make -C $(sim_dir)/prog$(PROG); \
		cd $(bld_dir); \
		vcs -R -sverilog +neg_tchk -negdelay \
			-v $(lib_dir)/N16ADFP_StdCell.v \
			$(root_dir)/$(sim_dir)/$(TB_FILE) \
			-debug_access+all -full64 -diag=sdf:verbose \
			+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir) \
			+define+SYN+prog$(PROG)$(FSDB_DEF) \
			+no_notifier \
			+prog_path=$(root_dir)/$(sim_dir)/prog$(PROG) \
			+rdcycle=1; \
	) 2>&1 | tee log/syn$(PROG).log

pr_sim: | clean $(bld_dir) $(log_dir)
	( \
	  echo "PR simulation for PROG = $(PROG)"; \
	  make -C $(sim_dir)/prog$(PROG); \
	  cd $(bld_dir); \
	  vcs -R -sverilog +neg_tchk -negdelay \
	      -v $(lib_dir)/N16ADFP_StdCell.v \
	      $(root_dir)/$(sim_dir)/$(TB_FILE) \
	      -debug_access+all -full64 -diag=sdf:verbose \
	      +incdir+$(root_dir)/$(pr_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir) \
	      +define+PR+prog$(PROG)$(FSDB_DEF) \
	      +no_notifier \
	      +maxdelays \
	      +prog_path=$(root_dir)/$(sim_dir)/prog$(PROG); \
	) 2>&1 | tee log/pr$(PROG).log

rtl0:
	$(MAKE) rtl_sim PROG=0

rtl1:
	$(MAKE) rtl_sim PROG=1

rtl2:
	$(MAKE) rtl_sim PROG=2

rtl3:
	$(MAKE) rtl_sim PROG=3

rtl4:
	$(MAKE) rtl_sim PROG=4

rtl5:
	$(MAKE) rtl_sim PROG=5

rtl6:
	$(MAKE) rtl_sim PROG=6

rtl7:
	$(MAKE) rtl_sim PROG=7

rtl8:
	$(MAKE) rtl_sim PROG=8

rtl9:
	$(MAKE) rtl_sim PROG=9

rtl10:
	$(MAKE) rtl_sim PROG=10

rtl11:
	$(MAKE) rtl_sim PROG=11

# Utilities
nWave: | $(bld_dir)
	cd $(bld_dir); \
	nWave chip.fsdb &

verdi: | $(bld_dir)
	cd $(bld_dir); \
	verdi -ssf top.fsdb &

superlint: | $(bld_dir)
	cd $(bld_dir); \
	jg -superlint ../script/superlint.tcl &

vip_b: clean | $(bld_dir)
	cd $(bld_dir); \
	jg ../script/jg_bridge.tcl &

dv: | $(bld_dir) $(syn_dir)
	cp script/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	dc_shell -gui -no_home_init &

synthesize: | $(bld_dir) $(syn_dir)
	cp script/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	dc_shell -no_home_init -f ../script/synthesis.tcl | tee syn_compile.log

innovus: | $(bld_dir) $(pr_dir)
	cd $(bld_dir); \
	innovus

icc2: | $(pr_dir)
	make clean_pr; \
	cd $(pr_dir); \
	icc2_shell -file ../scripts/00_run.tcl

icc2_gui: | $(pr_dir)
	cd $(pr_dir); \
	icc2_shell -gui;

spyglass: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/Spyglass_CDC.tcl &

# Check file structure
BLUE  =\033[1;34m
RED   =\033[1;31m
NORMAL=\033[0m

check: clean
	@if [ -f StudentID ]; then \
		STUDENTID=$$(grep -v '^$$' StudentID); \
		if [ -z "$$STUDENTID" ]; then \
			echo -e "$(RED)Student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID_LEN=$$(expr length $$STUDENTID); \
			if [ $$ID_LEN -eq 9 ]; then \
				if [[ $$STUDENTID =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	else \
		echo -e "$(RED)StudentID file is not found$(NORMAL)"; \
		exit 1; \
	fi; \
	if [ -f StudentID2 ]; then \
		STUDENTID2=$$(grep -v '^$$' StudentID2); \
		if [ -z "$$STUDENTID2" ]; then \
			echo -e "$(RED)Second student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID2_LEN=$$(expr length $$STUDENTID2); \
			if [ $$ID2_LEN -eq 9 ]; then \
				if [[ $$STUDENTID2 =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Second student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Second student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Second student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	fi; \
	if [ $$(ls -1 *.docx 2>/dev/null | wc -l) -eq 0 ]; then \
		echo -e "$(RED)Report file is not found$(NORMAL)"; \
		exit 1; \
	elif [ $$(ls -1 *.docx 2>/dev/null | wc -l) -gt 1 ]; then \
		echo -e "$(RED)More than one docx file is found, please delete redundant file(s)$(NORMAL)"; \
		exit 1; \
	elif [ ! -f $${STUDENTID}.docx ]; then \
		echo -e "$(RED)Report file name should be $$STUDENTID.docx$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Report file name pass$(NORMAL)"; \
	fi; \
	if [ $$(basename $(PWD)) != $$STUDENTID ]; then \
		echo -e "$(RED)Main folder name should be \"$$STUDENTID\"$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Main folder name pass$(NORMAL)"; \
	fi

tar:
	STUDENTID=$$(basename $(PWD)); \
	cd ..; \
	tar cvf $$STUDENTID.tar $$STUDENTID

lines:
	find src include | xargs wc -l 2>&1 | tee log/total_lines.log


.PHONY: clean

clean_pr:
	rm -rf ./pr/icc2_ADFP_tsri/run; \
	mkdir ./pr/icc2_ADFP_tsri/run;

clean:
	rm -rf $(bld_dir); \
	rm -rf $(sim_dir)/prog*/result*.txt; \
	make -C $(sim_dir)/prog0/ clean; \
	make -C $(sim_dir)/prog1/ clean; \
	make -C $(sim_dir)/prog2/ clean; \
	make -C $(sim_dir)/prog3/ clean; \
	make -C $(sim_dir)/prog4/ clean; \
	make -C $(sim_dir)/prog5/ clean; \
	make -C $(sim_dir)/prog6/ clean; \
	make -C $(sim_dir)/prog7/ clean; \
	make -C $(sim_dir)/prog8/ clean; \
	make -C $(sim_dir)/prog9/ clean; \
	make -C $(sim_dir)/prog10/ clean; \