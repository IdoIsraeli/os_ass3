#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int src_pid = getpid();

    char *shared_mem = sbrk(4096);     // Allocate shared memory
    strcpy(shared_mem, "Hello child"); // Write to shared memory

    int dest_pid = fork();
    if (dest_pid < 0)
    {
        // Fork failed
        printf("Fork failed\n");
        exit(1);
    }
    else if (dest_pid == 0)
    {
        // Step 4: Child process

        // Step 1: Initialize shared memory
        int dest_va = map_shared_pages(src_pid, dest_pid, shared_mem, 4096); // Assume this function exists and returns a pointer to shared memory
        if (dest_va == -1)
        {
            printf("Failed to map shared pages\n");
            exit(1);
        }
        printf("%s\n", dest_va); // Print the string from shared memory
        exit(0);                 // Exit child process
    }
    else
    {
        // Step 3: Parent process
        wait(0); // Wait for child to finish
    }

    // Step 5: Cleanup, if necessary
    // If map_shared_pages requires manual cleanup, do it here

    exit(0);
}