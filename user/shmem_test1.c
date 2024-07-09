#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/riscv.h"

int main()
{
    char *shared_mem = malloc(PGSIZE);
    strcpy(shared_mem, "Hello child");
    int parent_pid = getpid();
    int pid = fork();
    if (pid == 0)
    {
        // struct proc *parent_proc = find_proc(parent_pid);
        // struct proc *child_proc = find_proc(getpid());

        uint64 child_va = map_shared_pages(parent_pid, getpid(), (uint64)shared_mem, PGSIZE);
        printf("%s\n", (char *)child_va);
        exit(0);
    }
    else if (pid > 0)
    {
        wait(0);
        free(shared_mem);
    }
    return 0;
}