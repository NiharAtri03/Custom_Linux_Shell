#include <cstdio>
#include <signal.h>
#include <unistd.h>
#include <sys/wait.h>

#include "shell.hh"

int pid;
bool ctrlc = false;

extern "C" void disp( int sig )
{
  printf("\n");
  Shell::prompt();
  ctrlc = true;
}

extern "C" void zombie_handler(int sig){
  while(waitpid(-1, NULL, WNOHANG) > 0)
  if (pid > 0){
    printf("%d exited.\n", pid);
  }
}

/*int main()
{
	printf( "Type ctrl-c or \"exit\"\n");
    
    struct sigaction sa;
    sa.sa_handler = disp;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;

    if(sigaction(SIGINT, &sa, NULL)){
        perror("sigaction");
        exit(2);
    }

	for (;;) {
		
		char s[ 20 ];
		printf( "prompt>");
		fflush( stdout );
		fgets( s, 20, stdin );

		if ( !strcmp( s, "exit\n" ) ) {
			printf( "Bye!\n");
			exit( 1 );
		}
	}

	return 0;
}*/


int yyparse(void);

void Shell::prompt() {

  if (isatty(0)) {
    printf(":)>");
  }
  fflush(stdout);
}

int main(int argc, char **argv) {
    struct sigaction sa;
    sa.sa_handler = disp;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;

    if(sigaction(SIGINT, &sa, NULL)){
        perror("sigaction");
        exit(2);
    }

    struct sigaction zombie;
    zombie.sa_handler = zombie_handler;
    sigemptyset(&zombie.sa_mask);
    zombie.sa_flags = SA_RESTART;

    if(sigaction(SIGCHLD, &zombie, NULL)){
        perror("sigaction");
        exit(2);
    }

  std::string dollar = std::to_string(getpid());
  setenv("$", dollar.c_str(), 0);

  char buffer[300] = {0};
  realpath(argv[0], buffer);
  setenv("SHELL", buffer, 1);


  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
