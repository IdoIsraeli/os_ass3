#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/riscv.h"

int main()
{
    printf("Beginning of test\n");
    char *shared_mem = malloc(PGSIZE);
    int parent_pid = getpid();
    int pid = fork();

    if (pid == 0)
    {
        printf("Size of child process before mapping: %d\n", memsize());

        // Create shared memory mapping
        uint64 child_va = map_shared_pages(parent_pid, getpid(), (uint64)shared_mem, PGSIZE);
        printf("Size of child process after mapping: %d\n", memsize());

        strcpy((char *)child_va, "Hello daddy"); // Write to shared memory

        unmap_shared_pages(getpid(), child_va, PGSIZE);
        printf("After unmap_shared_pages the Size of child process: %d\n", memsize());

        char *child_mem = malloc(PGSIZE);

        child_mem[0] = 'a'; // use child_mem arbiterally to avoid compiler warning
        printf("After malloc, the Size of child process: %d\n", memsize());

        exit(0);
    }
    else
    {
        wait(0);
        printf("%s\n", shared_mem);
        free(shared_mem);
    }

    return 0;
}