#define _POSIX_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <signal.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define PIPE_RTL "target/lockstep.pipe1"
#define PIPE_ISA "target/lockstep.pipe2"

struct sim_driver {
    FILE *file;
    pid_t pid;
    uint64_t num_instrs;
    uint64_t last_num_instrs;   // for timeout check
};

struct sim_trace {
    uint64_t pc;
    int reg;
    uint64_t value;
    
    uint64_t last_pc;
};

static struct sim_driver sim_rtl, sim_isa;

static void terminate(int code)
{
    if (sim_rtl.pid) {
        kill(sim_rtl.pid, SIGTERM);
        sim_rtl.pid = 0;
    }
    
    if (sim_isa.pid) {
        kill(sim_isa.pid, SIGTERM);
        sim_isa.pid = 0;
    }
    
    if (sim_rtl.file) {
        fclose(sim_rtl.file);
        sim_rtl.file = NULL;
    }
    
    if (sim_isa.file) {
        fclose(sim_isa.file);
        sim_isa.file = NULL;
    }
    
    exit(code);
}

static void init_sim(struct sim_driver *s)
{
    memset(s, 0, sizeof(struct sim_driver));
}

static void open_pipe(struct sim_driver *s, const char *name)
{
    s->file = fopen(name, "r");
    if (!s->file) {
        fprintf(stderr, "Unable to open pipe @ %s\n", name);
        perror("fopen");
        terminate(-1);
    }
}

static void launch_sim(struct sim_driver *s, const char *file, char *args[])
{
    pid_t pid = fork();
    if (pid == -1) {
        fprintf(stderr, "Unable to launch sim @ %s\n", file);
        perror("fork");
        terminate(-1);
    }
    
    // child
    else if (pid == 0) {
        execvp(file, args);
        fprintf(stderr, "Unable to launch sim @ %s\n", file);
        perror("exec");
        terminate(-1);
    }
    
    // parent
    s->pid = pid;
}

static int parse_trace(struct sim_driver *s, struct sim_trace *t)
{
    t->last_pc = t->pc;
    
    static char buf[512];
    if (!fgets(buf, 512, s->file)) {
        return -1;
    }
    
    char *str = buf;
    str = strstr(str, "PC");
    if (!str || !sscanf(str, "PC @ %lx", &t->pc)) {
        return -1;
    }
    
    int wb_valid = 0, wb_reg = 0;
    uint64_t wb_value = 0;
    
    str = strstr(str, "WB");
    if (!str || sscanf(str, "WB Valid: %d @ %d = %lx",
                       &wb_valid, &wb_reg, &wb_value) != 3
    ) {
        return -1;
    }
    
    t->reg = wb_valid && wb_reg ? wb_reg : -1;
    t->value = wb_valid && wb_reg ? wb_valid : 0;
    
    s->num_instrs++;
    return 0;
}

static int diff_trace(struct sim_trace *rtl, struct sim_trace *sim)
{
    if (rtl->pc != sim->pc) return 1;
    if (rtl->reg != sim->reg) return 1;
    if (rtl->value != sim->value) return 1;
    return 0;
}

static void print_trace(const char *name, struct sim_trace *t)
{
    fprintf(stderr, "%s: PC @ %lx | Reg @ %d = %lx | Last PC @ %lx\n",
            name, t->pc, t->reg, t->value, t->last_pc);
}

static void drive()
{
    struct sim_trace trace_rtl, trace_isa;
    uint64_t num_instrs = 0;
    
    printf("Lockstep simulation started\n");
    
    while (1) {
        parse_trace(&sim_rtl, &trace_rtl);
        parse_trace(&sim_isa, &trace_isa);
        
        if (++num_instrs % 1000000 == 0) {
            printf("Num instrs: %lu\n", num_instrs);
        }
        
        if (diff_trace(&trace_rtl, &trace_isa)) {
            fprintf(stderr, "Trace diff\n");
            print_trace("RTL", &trace_rtl);
            print_trace("ISA", &trace_isa);
            
            terminate(-1);
        }
    }
}

static void check_timeout(const char *name, struct sim_driver *s)
{
    if (s->num_instrs == s->last_num_instrs) {
        fprintf(stderr, "%s timed out @ instr #%lu\n", name, s->num_instrs);
        terminate(-1);
    }
    
    s->last_num_instrs = s->num_instrs;
}

static void timer_handler(int sig_num)
{
    check_timeout("RTL", &sim_rtl);
    check_timeout("ISA", &sim_isa);
    
    signal(SIGALRM, timer_handler);
    alarm(2);
}

static void sigint_handler(int sig_num)
{
    fprintf(stderr, "Lockstep simulation interrupted by user\n");
    terminate(0);
}

int main(int argc, char *argv[])
{
    init_sim(&sim_rtl);
    init_sim(&sim_isa);
    
    char *args_rtl[] = {
        "target/sim/sim",
        "--kernel", "target/sbi/sbi",
        "--log-file", "none",
        "--log-level", "0",
        "--commit-file", PIPE_RTL,
        "--uart-out", "none",
        "--ctrl-dump", "none",
        "--ctrl-out", "none",
        "--clint-div", "0",
        NULL
    };
    char *args_isa[] = {
        "target/sim/sim",
        "--kernel", "target/sbi/sbi",
        "--log-file", "none",
        "--log-level", "0",
        "--commit-file", PIPE_ISA,
        "--uart-out", "none",
        "--ctrl-dump", "none",
        "--ctrl-out", "none",
        "--clint-div", "0",
        "--trace", NULL
    };
    
    launch_sim(&sim_rtl, "target/sim/sim", args_rtl);
    launch_sim(&sim_isa, "target/sim/sim", args_isa);
    
    signal(SIGINT, sigint_handler);
    signal(SIGALRM, timer_handler);
    alarm(5);
    
    open_pipe(&sim_rtl, PIPE_RTL);
    open_pipe(&sim_isa, PIPE_ISA);
    
    drive();
    
    terminate(0);
    return 0;
}

