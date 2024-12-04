#include <cstdio>
#include <cstdlib>
#include <iostream>
#include "command.hh"
#include "shell.hh"
#include <cstring>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>


Command::Command() {
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
    isAppend = false;
    isAppendError = false;
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {

    _simpleCommands.push_back(simpleCommand);
}

void Command::clear() {
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands) {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();

    if (_outFile == _errFile) {
      if ( _outFile) {
        delete _outFile;
      }
      _outFile = NULL;
      _errFile = NULL;
    } else {

      if ( _outFile ) {
        delete _outFile;
      }
      _outFile = NULL;

      if ( _inFile ) {
        delete _inFile;
      }
      _inFile = NULL;

      if ( _errFile ) {
        delete _errFile;
      }
      _errFile = NULL;
    }

    isAppend = false;
    isAppendError = false;
    _background = false;
}

void Command::print() {
    printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for ( auto & simpleCommand : _simpleCommands ) {
        printf("  %-3d ", i++ );
        simpleCommand->print();
    }

    printf( "\n\n" );
    printf( "  Output       Input        Error        Background    Append     AppendError\n" );
    printf( "  ------------ ------------ ------------ ------------  -------    ----------- \n" );
    printf( "  %-12s %-12s %-12s %-12s %-12s %-12s\n",
            _outFile?_outFile->c_str():"default",
            _inFile?_inFile->c_str():"default",
            _errFile?_errFile->c_str():"default",
            _background?"YES":"NO",
            isAppend?"YES":"NO",
            isAppendError?"YES":"NO");
    printf( "\n\n" );
}

void Command::execute() {

    ctrlc = false;
    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }

    // Print contents of Command data structure
    if (isatty(0)){
      print();
    }

    if (strcmp((_simpleCommands[0]->_arguments[0]->c_str()), "exit") == 0) {
      printf("Have an ok day :/\n");
      exit(1);
    }

    if (strcmp((_simpleCommands[0]->_arguments[0]->c_str()), "setenv") == 0) {
      int se;
      if (_simpleCommands[0]->_arguments.size() != 3) {
        fprintf(stderr, "Enter a valid number of commands :(\n");
      } else {
        se = setenv(_simpleCommands[0]->_arguments[1]->c_str(), _simpleCommands[0]->_arguments[2]->c_str(), 1);
      }

      if (se == -1) {
        perror("error with setenv");
        exit(1);
      }

      clear();
      Shell::prompt();
      return;

    }

    if (strcmp((_simpleCommands[0]->_arguments[0]->c_str()), "unsetenv") == 0) {
      int use;

      use = unsetenv(_simpleCommands[0]->_arguments[1]->c_str());

      if (use == -1) {
        perror("error with unsetenv");
        exit(1);
      }

      clear();
      Shell::prompt();
      return;

    }


    /*if (strcmp((_simpleCommands[0]->_arguments[0]->c_str()), "cd") == 0) {

      int cd;
      if (_simpleCommands[0]->_arguments.size() == 1) {
        cd = chdir(getenv("HOME"));
      } else {
          cd = chdir(_simpleCommands[0]->_arguments[1]->c_str());
      }

      if (cd == -1) {
        fprintf(stderr, "cd: can't cd to %s", _simpleCommands[0]->_arguments[1]->c_str());
      }
      clear();
      Shell::prompt();
      return;

    }*/

    int defaultin = dup(0);
    int defaultout = dup(1);
    int defaulterr = dup(2);

    int fd_in;
    if (_inFile != NULL) {
      fd_in = open(_inFile->c_str(), O_RDONLY, 0664);
      if (fd_in < 0) {
        fprintf(stderr, "%s is not a valid infile\n", _inFile->c_str());
        clear();
        Shell::prompt();
        return;
      }
      //dup2(fd_in, 0);
      //close(fd_in);
    } else { // added this + changed fd name
      fd_in = dup(defaultin);
    }

    /*if (_outFile != NULL) {
      int fd;
      if (isAppend) {
        fd = open(_outFile->c_str(), O_CREAT | O_WRONLY | O_APPEND,  0664);
      } else {
          fd = open(_outFile->c_str(), O_CREAT | O_WRONLY | O_TRUNC,  0664);
      }

      if (fd < 0) {
        perror("outfile");
        exit(1);
      }

      dup2(fd, 1);
      close(fd);

    }*/

    if (_errFile != NULL) {
      int fd;

      // check to see if same, if theyre the same set the flag append, if you still want to truncate, delete the file and recreate it

      if (_errFile == _outFile || isAppendError) {
        if (_errFile == _outFile && !isAppendError) {
          remove(_errFile->c_str());
        }
          fd = open(_errFile->c_str(), O_CREAT | O_WRONLY | O_APPEND,  0664);
      } else {
          fd = open(_errFile->c_str(), O_CREAT | O_WRONLY | O_TRUNC,  0664);


      }

      /*if (isAppendError) {
        fd = open(_errFile->c_str(), O_CREAT | O_WRONLY | O_APPEND,  0664);
      } else {
          fd = open(_errFile->c_str(), O_CREAT | O_WRONLY | O_TRUNC,  0664);
      }*/

      if (fd < 0) {
        perror("error file");
        exit(1);
      }

      dup2(fd, 2);
      close(fd);
    }




    int ret;
    int fd_out;
    //std::string last_arg = new std::string();

    for (int i = 0; i < (int) _simpleCommands.size(); i++) {

      dup2(fd_in, 0);
      close(fd_in);
      if (i == ((int) _simpleCommands.size()) - 1){ // Last simple command

        setenv("_", _simpleCommands[i]->_arguments[_simpleCommands[i]->_arguments.size() - 1]->c_str(), 1);

        if (_outFile != NULL) {
          if (isAppend || (_outFile == _errFile)) {
            fd_out = open(_outFile->c_str(), O_CREAT | O_WRONLY | O_APPEND,  0664);
          } else {
            fd_out = open(_outFile->c_str(), O_CREAT | O_WRONLY | O_TRUNC,  0664);
          }

          if (fd_out < 0) {
            perror("outfile");
            exit(1);
          }

          dup2(fd_out, 1);
          close(fd_out);

      } else { // Use default output
          fd_out=dup(defaultout);
        }
      } else {
          int fdpipe[2];
          pipe(fdpipe);
          fd_out = fdpipe[1];
          fd_in = fdpipe[0];
      }
      dup2(fd_out, 1);
      close(fd_out);

    if (strcmp((_simpleCommands[i]->_arguments[0]->c_str()), "cd") == 0) {

      int cd;
      if (_simpleCommands[i]->_arguments.size() == 1) {
        cd = chdir(getenv("HOME"));
      } else {
          cd = chdir(_simpleCommands[i]->_arguments[1]->c_str());
      }

      if (cd == -1) {
        fprintf(stderr, "cd: can't cd to %s", _simpleCommands[i]->_arguments[1]->c_str());
      }
      dup2(defaultin, 0);
      dup2(defaultout, 1);
      dup2(defaulterr, 2);
      close(defaultin);
      close(defaultout);
      close(defaulterr);
      clear();
      Shell::prompt();
      return;

    }


      ret = fork();
      if (ret == -1) { // error
        perror("fork");
        exit(1);
      } else if (ret == 0) { // this is the child process
          if (strcmp((_simpleCommands[i]->_arguments[0]->c_str()), "printenv") == 0) { //detect printenv
            char **environment = environ;

            while (*environment != NULL) {
              printf("%s\n", *environment);
              environment++;
            }

            exit(0);
          }


          char **args = new char *[_simpleCommands[i]->_arguments.size() + 1];


          for (int j = 0; j <(int) _simpleCommands[i]->_arguments.size(); j++) {
            args[j] = (char *) _simpleCommands[i]->_arguments[j]->c_str();
          }

          args[_simpleCommands[i]->_arguments.size()] = NULL;




          execvp(_simpleCommands[i]->_arguments[0]->c_str(), args);


          perror("execvp");
          exit(1);
      }

    }

      if (!_background) {
        // wait for last process
        pid = -999999;
        int status;
        waitpid(ret, &status, 0);
        std::string ree = std::to_string(WEXITSTATUS(status));
        setenv("?", ree.c_str(), 1);
       } else {
         pid = ret;
         std::string pid2 = std::to_string(pid);
         setenv("!", pid2.c_str(), 1);
       }


    dup2(defaultin, 0);
    dup2(defaultout, 1);
    dup2(defaulterr, 2);
    close(defaultin);
    close(defaultout);
    close(defaulterr);

    // For every simple command fork a new process
    // Setup i/o redirection
    // and call exec

    // Clear to prepare for next command
    clear();

    // Print new prompt
    if (!ctrlc) {
      Shell::prompt();
    } else {
      ctrlc = false;
    }
}

SimpleCommand * Command::_currentSimpleCommand;
