COLOR_BLUE = '\033[0;93m'
COLOR_NONE = '\033[0m'
BOLD_ON = '\033[1m'
BOLD_OFF = '\033[0m'

VERILATOR_DIR = /usr/share/verilator

SIM_OBJS = target/sim/main.o
VERILATED_OBJ = target/rtl/verilated.o
MODEL_AR = target/rtl/Vrevolve__ALL.a
PROGRAMS = target/programs/fib

VERILATOR = verilator
VERILATOR_FLAGS = -O3 -sv +1800-2017ext+sv -Irtl -CFLAGS "-O3"

CXX = g++
CXXFLAGS = -O3
CXXINC = -I$(VERILATOR_DIR)/include -I$(VERILATOR_DIR)/include/vltstd -I./target/rtl

PROGRAM_CC = riscv64-linux-gnu-gcc
PROGRAM_CFLAGS = -O2 -nostdlib -fno-builtin -fno-stack-protector -fno-PIC -mcmodel=medany -march=rv32g -mabi=ilp32 -std=c99 -Wall
PROGRAM_CINC = -Iprograms/include

.PHONY: all sim build model model_dir driver driver_dir clean rebuild

all: build sim

sim:
	@echo ${COLOR_BLUE}[BUILD]${COLOR_NONE} ${BOLD_ON}Running simulation${BOLD_OFF}
	target/sim/sim

build: model driver program

rebuild: clean build

clean:
	@echo ${COLOR_BLUE}[BUILD]${COLOR_NONE} ${BOLD_ON}Cleaning all${BOLD_OFF}
	rm -rf target

# Build the RTL model
model: model_dir $(MODEL_AR)

model_dir:
	@echo ${COLOR_BLUE}[BUILD]${COLOR_NONE} ${BOLD_ON}Building RTL model${BOLD_OFF}
	@mkdir -p target/rtl

$(MODEL_AR): target/rtl/Vrevolve.mk
	cd target/rtl && make -f Vrevolve.mk && cd ../..

target/rtl/Vrevolve.mk: rtl/*.sv
	$(VERILATOR) $(VERILATOR_FLAGS) -cc -Mdir target/rtl rtl/revolve.sv

# Build the C++ driver
driver: driver_dir target/sim/sim

driver_dir:
	@echo ${COLOR_BLUE}[BUILD]${COLOR_NONE} ${BOLD_ON}Building C++ driver${BOLD_OFF}
	@mkdir -p target/sim

target/sim/sim: $(SIM_OBJS) $(VERILATED_OBJ) $(MODEL_AR)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(VERILATED_OBJ): $(VERILATOR_DIR)/include/verilated.cpp
	$(CXX) $(CXXFLAGS) -c $(CXXINC) -o $@ $<

target/sim/%.o: sim/%.cc target/rtl/Vrevolve.h
	$(CXX) $(CXXFLAGS) -c $(CXXINC) -o $@ $<

# Build the programs
program: program_dir $(PROGRAMS)

program_dir:
	@echo ${COLOR_BLUE}[BUILD]${COLOR_NONE} ${BOLD_ON}Building bare-metal programs${BOLD_OFF}
	@mkdir -p target/programs

target/programs/%: programs/%.c programs/common/*.* programs/include/*.*
	$(PROGRAM_CC) $(PROGRAM_CFLAGS) $(PROGRAM_CINC) -T programs/common/link.ld -o $@ $< programs/common/*.c

