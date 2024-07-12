#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/riscv.h"

int main()
{
    printf("Beginning of test\n");
    char *shared_mem = malloc(PGSIZE); // Allocate shared memory
    int parent_pid = getpid();
    int pid = fork();

    if (pid == 0)
    { // Child process
        // printf("Child PID: %d, Parent PID: %d\n", getpid(), parent_pid);
        printf("Size of child process before mapping: %d\n", memsize());

        // Create shared memory mapping
        uint64 child_va = map_shared_pages(parent_pid, getpid(), (uint64)shared_mem, PGSIZE);
        printf("Size of child process after mapping: %d\n", memsize());

        strcpy((char *)child_va, "Hello daddy"); // Write to shared memory

        // Unmap shared memory
        unmap_shared_pages(getpid(), child_va, PGSIZE);
        printf("After unmap_shared_pages\n");
        printf("Size of child process: %d\n", memsize());

        // Allocate new memory to show malloc works
        // char *child_mem = malloc(PGSIZE);
        // printf("After malloc\n");
        // printf("Size of child process: %d\n", memsize());

        exit(0);
    }
    else
    {                                                      // Parent process
        wait(0);                                           // Wait for child to complete
        printf("Shared memory content: %s\n", shared_mem); // Print shared memory content
        free(shared_mem);                                  // Clean up
    }

    return 0;
}