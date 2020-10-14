COLOR_MSG = '\033[0;93m'
COLOR_ITEM = '\033[0;34m'
COLOR_PASS = '\033[0;32m'
COLOR_FAIL = '\033[0;31m'
COLOR_NONE = '\033[0m'
BOLD_ON = '\033[1m'
BOLD_OFF = '\033[0m'


RAMDISK = /ramdisk
TARGET = target

SIM_FLAGS ?=
ifdef TRACE
SIM_FLAGS += --trace
endif

DTC = dtc
CC = gcc
CFLAGS = -O3 -g -Wall -std=c99
CXX = g++
CXXFLAGS = -O3 -g -Wall -std=c++11

VERILATOR = verilator
VERILATOR_FLAGS = -O3 -sv +1800-2017ext+sv -Irtl -CFLAGS "-O3"
VERILATOR_DIR = /usr/share/verilator
VERILATOR_MODEL_AR = $(TARGET)/rtl/Vrevive__ALL.a

SIM_OBJ_LIST = main.o base.o as.o mem.o ctrl.o sim.o cmd.o load.o rtl.o trace.o clint.o uart.o
SIM_OBJ_TOP = top.o
SIM_OBJ_VERILATED = verilated.o
SIM_OBJS = $(addprefix $(TARGET)/sim/, $(SIM_OBJ_LIST) $(SIM_OBJ_TOP) $(SIM_OBJ_VERILATED))
SIM_CXXFLAGS_TOP = $(CXXFLAGS) -faligned-new
SIM_CXXFLAGS_VERILATED = $(CXXFLAGS) -Wno-sign-compare
SIM_CXXINC = -I$(VERILATOR_DIR)/include -I$(VERILATOR_DIR)/include/vltstd -I$(TARGET)/rtl -Icommon/include -Isim/include

SBI_OBJ_LIST = start.o entry.o sbi.o printf.o trap.o timer.o uart.o ecall.o boot.o vmlinux.o dtb.o initrd.o
SBI_OBJS = $(addprefix $(TARGET)/sbi/, $(SBI_OBJ_LIST))
SBI = $(TARGET)/sbi/sbi
SBI_CC = riscv64-linux-gnu-gcc
SBI_CFLAGS = -O2 -nostdlib -fno-builtin -fno-stack-protector -fno-PIC -mcmodel=medany -march=rv32g -mabi=ilp32 -std=c99 -Wall
SBI_LD = riscv64-linux-gnu-ld
SBI_LDFLAGS = -m elf32lriscv_ilp32 -static
SBI_OBJCOPY = riscv64-linux-gnu-objcopy
SBI_CINC = -Icommon/include -Isbi

PROGRAM_SRC = tests/programs
PROGRAM_LIST = towers fib qsort rsort
ifdef TRACE
PROGRAM_LIST += clint
endif
PROGRAMS = $(addprefix $(TARGET)/programs/, $(PROGRAM_LIST))
PROGRAM_CC = riscv64-linux-gnu-gcc
PROGRAM_CFLAGS = -O2 -g3 -nostdlib -fno-builtin -fno-stack-protector -fno-PIC -mcmodel=medany -march=rv32gc -mabi=ilp32 -std=c99 -Wall
PROGRAM_CINC = -Icommon/include -I$(PROGRAM_SRC)/include

TEST_SRC = tests/simple
TEST_LIST = stop mem mul mem_mul div
TESTS = $(addprefix $(TARGET)/simple/, $(TEST_LIST))
TEST_AS = riscv64-linux-gnu-gcc
TEST_ASFLAGS = -O2 -nostdlib -fno-builtin -fno-stack-protector -fno-PIC -mcmodel=medany -march=rv32g -mabi=ilp32 -std=c99 -Wall
TEST_ASINC = -Icommon/include -I$(TEST_SRC)/include

COMPLIANCE_SRC = tests/compliance
include $(COMPLIANCE_SRC)/rv32i/Makefile.inc
include $(COMPLIANCE_SRC)/rv32im/Makefile.inc
include $(COMPLIANCE_SRC)/rv32imc/Makefile.inc
include $(COMPLIANCE_SRC)/rv32Zifencei/Makefile.inc
include $(COMPLIANCE_SRC)/rv32Zicsr/Makefile.inc
COMPLIANCES = $(addprefix $(TARGET)/compliance/rv32i/, $(COMPLIANCE_RV32I)) \
              $(addprefix $(TARGET)/compliance/rv32i/, $(COMPLIANCE_RV32I_PRIV)) \
              $(addprefix $(TARGET)/compliance/rv32im/, $(COMPLIANCE_RV32IM)) \
              $(addprefix $(TARGET)/compliance/rv32imc/, $(COMPLIANCE_RV32IMC)) \
              $(addprefix $(TARGET)/compliance/rv32Zifencei/, $(COMPLIANCE_RV32ZIFENCEI)) \
              $(addprefix $(TARGET)/compliance/rv32Zicsr/, $(COMPLIANCE_RV32ZICSR))
COMPLIANCE_AS = riscv64-linux-gnu-gcc
COMPLIANCE_ASFLAGS = -O2 -nostdlib -fno-builtin -fno-stack-protector -fno-PIC -mcmodel=medany -mabi=ilp32 -std=c99 -Wall
COMPLIANCE_ASFLAGS_I = $(COMPLIANCE_ASFLAGS) -march=rv32i
COMPLIANCE_ASFLAGS_IM = $(COMPLIANCE_ASFLAGS) -march=rv32im
COMPLIANCE_ASFLAGS_IMC = $(COMPLIANCE_ASFLAGS) -march=rv32imc
COMPLIANCE_ASINC = -Icommon/include -I$(COMPLIANCE_SRC)/include


.PHONY: all build clean rebuild mkdir_target \
        build_model mkdir_model \
        sim build_sim mkdir_sim \
        programs run_program build_program mkdir_program \
        run_test build_test mkdir_test \
        compliance build_compliance mkdir_compliance

all: build compliance programs

build: mkdir_target build_utils build_model build_sim build_sbi \
       build_program build_test build_compliance

rebuild: clean build

clean:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Cleaning all${BOLD_OFF}
	rm -rf $(TARGET)/*

mkdir_target:
	@if [ "$(shell mount | grep ' '$(RAMDISK)' ')" = "" ]; then \
		echo ${COLOR_MSG}[ERROR]${COLOR_NONE} ${BOLD_ON}Unable to find ramdisk @ $(RAMDISK)${BOLD_OFF}; \
		exit 1; \
	elif [ "$(shell readlink $(TARGET))" != "$(RAMDISK)/revive/target" ]; then \
		echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Setting up $(TARGET)${BOLD_OFF}; \
		rm -f $(TARGET); \
		mkdir -p $(RAMDISK)/revive/target && \
		ln -s $(RAMDISK)/revive/target $(TARGET) && \
		rm -rf $(TARGET)/* && \
		mkfifo $(TARGET)/uart.pipe1 && mkfifo $(TARGET)/uart.pipe2; \
	elif [ ! -d "$(RAMDISK)/revive/target" ]; then \
		echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Setting up $(TARGET)${BOLD_OFF}; \
		mkdir -p $(RAMDISK)/revive/target && \
		mkfifo $(TARGET)/uart.pipe1 && mkfifo $(TARGET)/uart.pipe2; \
	fi


################################################################################
# Build utils
#
build_utils: mkdir_utils $(TARGET)/utils/bin2c $(TARGET)/utils/term

mkdir_utils:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building utils${BOLD_OFF}
	@mkdir -p $(TARGET)/utils

$(TARGET)/utils/bin2c: common/utils/bin2c.c
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CC) $(CFLAGS) -o $@ $<

$(TARGET)/utils/term: common/utils/term.cc
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CXX) $(CXXFLAGS) -lpthread -o $@ $<

term: $(TARGET)/utils/term
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(TARGET)/utils/term


################################################################################
# Build RTL model
#
build_model: mkdir_model $(VERILATOR_MODEL_AR)

mkdir_model:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building RTL model${BOLD_OFF}
	@mkdir -p $(TARGET)/rtl

$(VERILATOR_MODEL_AR): $(TARGET)/rtl/Vrevive.mk
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	cd $(TARGET)/rtl && make -f Vrevive.mk && cd ../..

$(TARGET)/rtl/Vrevive.mk: rtl/*.sv rtl/*/*.sv rtl/*/*.svh rtl/*/*/*.sv
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(VERILATOR) $(VERILATOR_FLAGS) -cc -Mdir $(TARGET)/rtl rtl/revive.sv


################################################################################
# Build and run C++ simulator
#
sim:
	@echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Running simulation${BOLD_OFF}
	$(TARGET)/sim/sim $(SIM_FLAGS)

build_sim: mkdir_sim $(TARGET)/sim/sim

mkdir_sim:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building simulation driver${BOLD_OFF}
	@mkdir -p $(TARGET)/sim

$(TARGET)/rtl/Vrevive.h: build_model

$(TARGET)/sim/sim: $(SIM_OBJS) $(VERILATOR_MODEL_AR)
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CXX) $(CXXFLAGS) -lpthread -o $@ $^

$(TARGET)/sim/$(SIM_OBJ_VERILATED): $(VERILATOR_DIR)/include/verilated.cpp
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CXX) $(SIM_CXXFLAGS_VERILATED) -c $(SIM_CXXINC) -o $@ $<

$(TARGET)/sim/$(SIM_OBJ_TOP): sim/top.cc sim/include/*.hh $(TARGET)/rtl/Vrevive.h
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CXX) $(SIM_CXXFLAGS_TOP) -c $(SIM_CXXINC) -o $@ $<

$(TARGET)/sim/%.o: sim/%.cc sim/include/*.hh $(TARGET)/rtl/Vrevive.h
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(CXX) $(CXXFLAGS) -c $(SIM_CXXINC) -o $@ $<


################################################################################
# SBI
#
build_sbi: mkdir_sbi $(SBI)

mkdir_sbi:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building miniSBI${BOLD_OFF}
	@mkdir -p $(TARGET)/sbi

$(TARGET)/sbi/vmlinux.c: $(TARGET)/sbi/vmlinux.bin
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(TARGET)/utils/bin2c --bin $< --c $@ --symbol vmlinux --align 16777216 --section .payload.vmlinux

$(TARGET)/sbi/vmlinux.bin: sbi/payload/vmlinux
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_OBJCOPY) -O binary $< $@

$(TARGET)/sbi/dtb.c: $(TARGET)/sbi/soc.dtb
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(TARGET)/utils/bin2c --bin $< --c $@ --symbol dtb --align 8 --section .payload.dtb

$(TARGET)/sbi/soc.dtb: sbi/payload/soc.dts
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(DTC) -I dts -O dtb -o $@ $<

$(TARGET)/sbi/initrd.c: sbi/payload/initramfs.cpio.gz
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(TARGET)/utils/bin2c --bin $< --c $@ --symbol initrd --align 8 --section .payload.initrd

$(SBI): $(SBI_OBJS) sbi/link.ld
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_LD) $(SBI_LDFLAGS) -T sbi/link.ld -o $@ $(SBI_OBJS)

$(TARGET)/sbi/vmlinux.o: $(TARGET)/sbi/vmlinux.c
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

$(TARGET)/sbi/dtb.o: $(TARGET)/sbi/dtb.c
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

$(TARGET)/sbi/initrd.o: $(TARGET)/sbi/initrd.c
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

$(TARGET)/sbi/start.o: sbi/start.S
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

$(TARGET)/sbi/entry.o: sbi/entry.S
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

$(TARGET)/sbi/%.o: sbi/%.c sbi/*.h
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(SBI_CC) $(SBI_CFLAGS) $(SBI_CINC) -c -o $@ $<

boot: build
	@echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Booting${BOLD_OFF};
	$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(SBI) --log-file none --log-level 0 --commit-file none


################################################################################
# Complex programs
#
programs: build
	@echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Running complex programs${BOLD_OFF};
	@mkdir -p $(TARGET)/programs/outputs;
	@for name in $(PROGRAM_LIST); do \
		echo -n ${BOLD_ON}$$name${BOLD_OFF}; \
		echo -n " @ "$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/programs/$$name; \
		$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/programs/$$name --log-file none --commit-file none > $(TARGET)/stdout.txt && \
		mv $(TARGET)/stdout.txt $(TARGET)/programs/outputs/$$name.stdout && \
		mv $(TARGET)/out.txt $(TARGET)/programs/outputs/$$name.out && \
		mv $(TARGET)/dump.txt $(TARGET)/programs/outputs/$$name.dump && \
		common/utils/diff_out.py $(TARGET)/programs/outputs/$$name.out $(PROGRAM_SRC)/ref/$$name.out; \
		if [ $$? = 0 ]; then \
			echo " "${BOLD_ON}[${COLOR_PASS}PASS${COLOR_NONE}]${BOLD_OFF}; \
		else \
			echo " "${BOLD_ON}[${COLOR_FAIL}FAIL${COLOR_NONE}]${BOLD_OFF}; \
		fi; \
	done;

run_program: build
	# Usage: RUN=name make run_program
	@echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Running complex program: $(RUN)${BOLD_OFF};
	$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/programs/$(RUN)

build_program: mkdir_program $(PROGRAMS)

mkdir_program:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building bare-metal programs${BOLD_OFF}
	@mkdir -p $(TARGET)/programs

$(TARGET)/programs/%: $(PROGRAM_SRC)/%.c $(PROGRAM_SRC)/libc/*.* $(PROGRAM_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(PROGRAM_CC) $(PROGRAM_CFLAGS) $(PROGRAM_CINC) -T $(PROGRAM_SRC)/libc/link.ld -static -o $@ $< $(PROGRAM_SRC)/libc/*.c $(PROGRAM_SRC)/libc/*.S


################################################################################
# Simple assembly tests
#
run_test: build
	# Usage: RUN=name make run_test
	@echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Running simple test: $(RUN)${BOLD_OFF};
	$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/simple/$(RUN) --cycles 500

build_test: mkdir_test $(TESTS)

mkdir_test:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building simple tests${BOLD_OFF}
	@mkdir -p $(TARGET)/simple

$(TARGET)/simple/%: $(TEST_SRC)/%.S $(TEST_SRC)/lib/*.* $(TEST_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(TEST_AS) $(TEST_ASFLAGS) $(TEST_ASINC) -T $(TEST_SRC)/lib/link.ld -static -Wl,--build-id=none -o $@ $< $(TEST_SRC)/lib/*.S


################################################################################
# Build and run compliance tests
#
define run_compliance_tests
	echo ${COLOR_MSG}[ SIM ]${COLOR_NONE} ${BOLD_ON}Running $(1) compliance tests${BOLD_OFF};
	mkdir -p $(TARGET)/compliance/$(2)/outputs;
	for name in $(3); do \
		echo -n ${BOLD_ON}$(1)/$$name${BOLD_OFF}; \
		echo -n " @ "$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/compliance/$(2)/$$name; \
		$(TARGET)/sim/sim $(SIM_FLAGS) --kernel $(TARGET)/compliance/$(2)/$$name --log-file none --commit-file none > $(TARGET)/stdout.txt && \
		mv $(TARGET)/stdout.txt $(TARGET)/compliance/$(2)/outputs/$$name.stdout && \
		mv $(TARGET)/out.txt $(TARGET)/compliance/$(2)/outputs/$$name.out && \
		mv $(TARGET)/dump.txt $(TARGET)/compliance/$(2)/outputs/$$name.dump && \
		common/utils/diff_compliance.py $(TARGET)/compliance/$(2)/outputs/$$name.dump $(COMPLIANCE_SRC)/$(2)/references/$$name.reference_output; \
		if [ $$? = 0 ]; then \
			echo " "${BOLD_ON}[${COLOR_PASS}PASS${COLOR_NONE}]${BOLD_OFF}; \
		else \
			echo " "${BOLD_ON}[${COLOR_FAIL}FAIL${COLOR_NONE}]${BOLD_OFF}; \
		fi; \
	done;
endef

compliance: build compliance_rv32i compliance_rv32im compliance_rv32imc \
            compliance_rv32Zifencei compliance_rv32Zicsr compliance_rv32i_priv

compliance_rv32i:
	@$(call run_compliance_tests,RV32I,rv32i,$(COMPLIANCE_RV32I))

compliance_rv32i_priv:
ifdef TRACE
	@$(call run_compliance_tests,RV32I_PRIV,rv32i,$(COMPLIANCE_RV32I_PRIV))
endif

compliance_rv32im:
	@$(call run_compliance_tests,RV32IM,rv32im,$(COMPLIANCE_RV32IM))

compliance_rv32imc:
	@$(call run_compliance_tests,RV32IMC,rv32imc,$(COMPLIANCE_RV32IMC))

compliance_rv32Zifencei:
	@$(call run_compliance_tests,RV32Zifencei,rv32Zifencei,$(COMPLIANCE_RV32ZIFENCEI))

compliance_rv32Zicsr:
ifdef TRACE
	@$(call run_compliance_tests,RV32Zicsr,rv32Zicsr,$(COMPLIANCE_RV32ZICSR))
endif

build_compliance: mkdir_compliance $(COMPLIANCES)

mkdir_compliance:
	@echo ${COLOR_MSG}[BUILD]${COLOR_NONE} ${BOLD_ON}Building compliance tests${BOLD_OFF}
	@mkdir -p $(TARGET)/compliance/rv32i
	@mkdir -p $(TARGET)/compliance/rv32im
	@mkdir -p $(TARGET)/compliance/rv32imc
	@mkdir -p $(TARGET)/compliance/rv32Zifencei
	@mkdir -p $(TARGET)/compliance/rv32Zicsr

$(TARGET)/compliance/rv32i/%: $(COMPLIANCE_SRC)/rv32i/src/%.S $(COMPLIANCE_SRC)/lib/*.* $(COMPLIANCE_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(COMPLIANCE_AS) $(COMPLIANCE_ASFLAGS_I) $(COMPLIANCE_ASINC) -T $(COMPLIANCE_SRC)/lib/link.ld -o $@ $< $(COMPLIANCE_SRC)/lib/*.S

$(TARGET)/compliance/rv32im/%: $(COMPLIANCE_SRC)/rv32im/src/%.S $(COMPLIANCE_SRC)/lib/*.* $(COMPLIANCE_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(COMPLIANCE_AS) $(COMPLIANCE_ASFLAGS_IM) $(COMPLIANCE_ASINC) -T $(COMPLIANCE_SRC)/lib/link.ld -o $@ $< $(COMPLIANCE_SRC)/lib/*.S

$(TARGET)/compliance/rv32imc/%: $(COMPLIANCE_SRC)/rv32imc/src/%.S $(COMPLIANCE_SRC)/lib/*.* $(COMPLIANCE_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(COMPLIANCE_AS) $(COMPLIANCE_ASFLAGS_IMC) $(COMPLIANCE_ASINC) -T $(COMPLIANCE_SRC)/lib/link.ld -o $@ $< $(COMPLIANCE_SRC)/lib/*.S

$(TARGET)/compliance/rv32Zifencei/%: $(COMPLIANCE_SRC)/rv32Zifencei/src/%.S $(COMPLIANCE_SRC)/lib/*.* $(COMPLIANCE_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(COMPLIANCE_AS) $(COMPLIANCE_ASFLAGS_I) $(COMPLIANCE_ASINC) -T $(COMPLIANCE_SRC)/lib/link.ld -o $@ $< $(COMPLIANCE_SRC)/lib/*.S

$(TARGET)/compliance/rv32Zicsr/%: $(COMPLIANCE_SRC)/rv32Zicsr/src/%.S $(COMPLIANCE_SRC)/lib/*.* $(COMPLIANCE_SRC)/include/*.*
	@echo -n ${BOLD_ON}$@${BOLD_OFF}" @ "
	$(COMPLIANCE_AS) $(COMPLIANCE_ASFLAGS_I) $(COMPLIANCE_ASINC) -T $(COMPLIANCE_SRC)/lib/link.ld -o $@ $< $(COMPLIANCE_SRC)/lib/*.S

