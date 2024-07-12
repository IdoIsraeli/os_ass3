#include "kernel/types.h"
#include "user/user.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "kernel/fcntl.h"

#include "kernel/crypto.h"

int main(void)
{
  if (open("console", O_RDWR) < 0)
  {
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0); // stdout
  dup(0); // stderr

  printf("crypto_srv: starting\n");

  // TODO: implement the cryptographic server here
  // Check the PID of the server process and exit if it is not 2.
  if (getpid() != 2)
  {
    printf("crypto_srv: not running as PID 2\n");
    exit(1);
  }
  void *addr;
  uint64 dst_size;

  while (1)
  {
    if (take_shared_memory_request(&addr, &dst_size) != 0)
    {
      // failed to take shared memory request
      continue;
    }
    struct crypto_op *op = (struct crypto_op *)addr;

    memcpy(op, addr, dst_size);
    if (op->state == CRYPTO_OP_STATE_INIT && (op->type == CRYPTO_OP_TYPE_DECRYPT || op->type == CRYPTO_OP_TYPE_ENCRYPT))
    {
      // do in place xor encryption/decryption
      for (int i = 0; i < op->data_size; i++)
      {
        op->payload[op->key_size + i] ^= op->payload[i % op->key_size];
      }
      asm volatile("fence rw,rw" : : : "memory");
      op->state = CRYPTO_OP_STATE_DONE;

      int remove_res = remove_shared_memory_request(addr, dst_size);
      if (remove_res != 0)
      {
        printf("crypto_srv: failed to remove shared memory request\n");
        asm volatile("fence rw,rw" : : : "memory");
        op->state = CRYPTO_OP_STATE_ERROR;
      }
    }
    else
    {
      printf("crypto_srv: invalid operation\n");
    }
  }
  // REMEMBER TO FREE THE MEMORY OF MALLOC

  exit(0);
}
