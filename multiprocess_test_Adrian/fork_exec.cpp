
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <unistd.h>

void usage(char* argv[]) {
  printf("Usage: %s <number of forks> <program>\n",argv[0]);
  exit(1);
}


int main(int argc, char* argv[]) {
  if (argc < 3) {
    usage(argv);
  }

  int num = atoi(argv[1]);
  if (num <= 0) {
    usage(argv);
  }



  int pid;
  for (int i = 0; i < num; i++) {
    pid = fork();
    if (pid == -1) {
      printf("fork failed\n!");
    }
    else if (pid != 0) {
      char* child_argv[128];

      int ci = 0;
      for (int i = 3; i < argc; i++,ci++) {
        child_argv[ci] = argv[i];
      }
      /*
      child_argv[ci] = (char*)" ";
      ci++;
      */
      child_argv[ci] = NULL;


      // child
      if (execv(argv[2], child_argv) == -1) {
        printf("Error in execv!\n");
        exit(1);
      }
      goto exit;
    }
  }


#ifdef ENABLE_WAIT
{
  int wait_seconds = num * 2;
  printf("waiting for %d seconds...\n",wait_seconds);
  
  unsigned int unslept = wait_seconds;
  while (unslept>0) {
    unslept = sleep(unslept);
  }
}
#endif


exit:

  return 0;
}
