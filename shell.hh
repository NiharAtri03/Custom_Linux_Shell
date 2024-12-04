#ifndef shell_hh
#define shell_hh

#include "command.hh"
extern bool ctrlc;
extern int pid;




struct Shell {

  static void prompt();

  static Command _currentCommand;
};

#endif
