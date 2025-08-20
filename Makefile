SHELL := /bin/bash
RTL_DIR := hw/rtl
TB_DIR  := hw/tb
BUILD   := build

VERILATOR := $(shell command -v verilator 2>/dev/null)
IVERILOG  := $(shell command -v iverilog 2>/dev/null)
VVP       := $(shell command -v vvp 2>/dev/null)
VERIBLE   := $(shell command -v verible-verilog-lint 2>/dev/null)

.PHONY: tools lint sim_fsm clean

tools:
	@echo "== Tool check =="
	@which git || (echo "git not found"; exit 1)
	@which make || (echo "make not found"; exit 1)
	@if [ -n "$(VERILATOR)" ]; then echo "verilator OK: $$($(VERILATOR) --version | head -n1)"; else echo "verilator not found (optional)"; fi
	@if [ -n "$(IVERILOG)" ]; then echo "iverilog OK: $$($(IVERILOG) -V | head -n1)"; else echo "iverilog not found (optional)"; fi
	@if [ -n "$(VERIBLE)" ]; then echo "verible-verilog-lint OK: $$($(VERIBLE) --version | head -n1)"; else echo "verible-verilog-lint not found (optional)"; fi

lint:
	@if [ -z "$(VERIBLE)" ]; then echo "verible-verilog-lint not installed; skipping lint for now."; exit 0; fi
	@$(VERIBLE) $(RTL_DIR)/*.sv $(TB_DIR)/*.sv || true

sim_fsm: $(TB_DIR)/tb_fsm_example.sv $(RTL_DIR)/fsm_example.sv
	@mkdir -p $(BUILD)
	@if [ -n "$(VERILATOR)" ]; then \
	  OUTBIN="$(abspath $(BUILD))/sim_fsm"; \
	  echo "[Verilator] Building binary..."; \
	  $(VERILATOR) -sv -Wall --binary --top-module tb_fsm_example \
	    $(TB_DIR)/tb_fsm_example.sv $(RTL_DIR)/fsm_example.sv \
	    -o $$OUTBIN && \
	  echo "[Verilator] Running..." && $$OUTBIN; \
	elif [ -n "$(IVERILOG)" ]; then \
	  echo "[Icarus] Compiling..."; \
	  $(IVERILOG) -g2012 -o $(BUILD)/tb_fsm.vvp $(TB_DIR)/tb_fsm_example.sv $(RTL_DIR)/fsm_example.sv && \
	  echo "[Icarus] Running..." && $(VVP) $(BUILD)/tb_fsm.vvp; \
	else \
	  echo "Neither iverilog nor verilator found. Please install one."; exit 1; \
	fi


clean:
	@rm -rf $(BUILD) obj_dir
