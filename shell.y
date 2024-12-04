%code requires 
{
#include <string>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE LESS GREATGREAT PIPE GREATGREATAMPERSAND GREATAMPERSAND AMPERSAND TWOGREATER

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"
#include <regex.h>
#include <dirent.h>
#include <string.h>
#include <algorithm>


void yyerror(const char * s);
int yylex();
void expandwin(std::string *arg);
bool myCompare(std::string *one, std::string *two);
void expandWildcards(std::string *prefix, std::string *suffix, std::vector<std::string*>* arr);
%}

%%
goal:
  command_list
  ;

arg_list:
  arg_list WORD {
    //printf(" Yacc: insert argument \"%s\"\n", $2->c_str());
    //Command::_currentSimpleCommand->insertArgument( $2 );\
   //fprintf(stderr, "%s\n", $2->c_str());
   expandwin($2);
  }
  | /*empty string*/
  ;

cmd_and_args:
  WORD { //printf(" Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  arg_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

pipe_list:
  cmd_and_args | pipe_list PIPE cmd_and_args
  ;

io_modifier:
  GREATGREAT WORD { // appends stdout to the specified file
    //printf(" Yacc: insert append output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand.isAppend = true;
  }

  | GREAT WORD {        // overwrites stdout to the file
     //printf(" Yacc: insert overwrite output \"%s\"\n", $2->c_str());
     if (Shell::_currentCommand._outFile == NULL) {
       Shell::_currentCommand._outFile = $2;
     } else {
         printf("Ambiguous output redirect.\n");
     }
     //Shell::_currentCommand._isAppend = false;
  }
  | GREATGREATAMPERSAND WORD { // appends both stdout and stderr to the specified file
      //printf(" Yacc: insert append both error and out to file \"%s\"\n", $2->c_str());
      Shell::_currentCommand._outFile = $2;
      Shell::_currentCommand._errFile = $2;
      Shell::_currentCommand.isAppend = true;
      Shell::_currentCommand.isAppendError = true;

     /*printf(" Yacc: insert append error output \"%s\"\n", $2->c_str());
     Shell::_currentCommand._errFile = $2;
     Shell::_currentCommand.isAppendError = true;*/
  }
  | GREATAMPERSAND WORD { // overwrites both stdout and stderr to the specified file
     //printf(" Yacc: insert overwrite error and out to file \"%s\"\n", $2->c_str());
     Shell::_currentCommand._outFile = $2;
     Shell::_currentCommand._errFile = $2;
     //Shell::_currentCommand.isAppendError = false;
  }
  | LESS WORD {
     //printf(" Yacc: insert input file \"%s\"\n", $2->c_str());
     Shell::_currentCommand._inFile = $2;
  }
  | TWOGREATER WORD { // overwrites stderror to output file
     //printf(" Yacc: insert overwrite error output \"%s\"\n", $2->c_str());
     Shell::_currentCommand._errFile = $2;
  }
  ;

io_modifier_list:
  io_modifier_list io_modifier | /*empty*/
  ;

background_optional:
  AMPERSAND {
    //printf(" Yacc: insert background");
    Shell::_currentCommand._background = true;

  }
  | /*empty*/
  ;

command_line:
  pipe_list io_modifier_list background_optional NEWLINE {
    //printf(" Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE /*accept empty cmd line*/
  | error NEWLINE{yyerrok;}
  ; /*error recovery*/

command_list:
  command_line | command_list command_line
  ;



%%

bool myCompare(std::string *one, std::string *two) {
  return one->compare(*two) < 0;
}

void expandwin(std::string *arg) {
  //fprintf(stderr, "FIRST");
  /*if (arg->find('*') == -1 && arg->find('?') == -1) {
    //fprintf(stderr, "IN IF STATEMENT");
    Command::_currentSimpleCommand->insertArgument(arg);
    return;
  }
  //fprintf(stderr, "AFTER NOT * OR ?\n");
  char *reg = (char*) malloc(2 * arg->length() + 10);
  //char holder[1024] = {0};
  //sprintf(holder, "%s", arg->c_str());
  //char *a = holder;
  char *r = reg;
  *r = '^';
  r++;
  for (int i = 0; i < arg->length(); i++) {
    //fprintf(stderr, "%d\n", i);
    if (arg->at(i) == '*') {
      *r = '.';
      r++;
      *r = '*';
      r++;
    } else if (arg->at(i) == '?') {
      *r = '.';
      r++;
    } else if (arg->at(i) == '.') {
      *r = '\\';
      r++;
      *r = '.';
      r++;
    } else {
      *r = arg->at(i);
      r++;
    }
  }
  *r = '$';
  r++;
  *r = 0;



  regex_t re;
  int result = regcomp(&re, reg, REG_EXTENDED | REG_NOSUB);
  if (result != 0) {
    perror("regex is bad");
    return;
  }
  DIR* dir = opendir(".");
  if (dir == NULL) {
    perror("bad directory");
    return;
  }

  struct dirent *ent = readdir(dir);
  std::vector<std::string*> arr = std::vector<std::string*>();
i
  while (ent != NULL) {
    if (regexec(&re, ent->d_name, 1, NULL, 0) == 0) {
      if (reg[1] == '.') {
        if (ent->d_name[0] != '.') {
          arr.push_back(new std::string(strdup(ent->d_name)));
        }
      } else {
        arr.push_back(new std::string(strdup(ent->d_name)));
      }
      //Command::_currentSimpleCommand->insertArgument(new std::string(strdup(ent->d_name)));
    }

    ent = readdir(dir);
  }

  closedir(dir);
  regfree(&re);
  std::sort(arr.begin(), arr.end(), myCompare);*/

  std::vector<std::string*> arr = std::vector<std::string*>();

  expandWildcards(NULL, arg, &arr);

  if (arr.size() == 0) {
    Command::_currentSimpleCommand->insertArgument(new std::string(*arg));
  } else {
      std::sort(arr.begin(), arr.end(), myCompare);
      for (int i = 0; i < arr.size(); i++) {
        Command::_currentSimpleCommand->insertArgument(arr[i]);
      }
      arr.clear();
    }
    delete arg;

}

void expandWildcards(std::string *prefix, std::string *suffix, std::vector<std::string*>* arr) {
  //std::vector<std::string*> arr = std::vector<std::string*>();
  //fprintf(stderr, "1\n");
  //fprintf(stderr, "prefix: %s\n", prefix->c_str());
  //fprintf(stderr, "suffix: %s\n", suffix->c_str());

  if (suffix == NULL) {
    arr->push_back(new std::string(*prefix));
    return;
  }
  //fprintf(stderr, "Suffix: %s\n", suffix->c_str());
 // fprintf(stderr, "Prefix: %s\n", prefix);

  std::string *nextPrefix;


  //fprintf(stderr, "%s\n", nextPrefix->c_str());
  if (prefix != NULL) {
    nextPrefix = new std::string(*prefix);
  } else {
    nextPrefix = new std::string("");
  }

 // fprintf(stderr, "nextPrefix: %s\n", nextPrefix->c_str());

  //fprintf(stderr, "1.5\n");
  //fprintf(stderr, "%s\n", nextPrefix->c_str());
  //fprintf(stderr, "%s\n", suffix->c_str());


  if (suffix->at(0) == '/') {
    //fprintf(stderr, "1.6\n");
    *nextPrefix = *nextPrefix + '/';
     //fprintf(stderr, "1.7\n");
     suffix = new std::string(suffix->substr(1, suffix->length() - 1));
     //fprintf(stderr, "1.8\n");

  }
  //fprintf(stderr, "%s\n", nextPrefix->c_str());
  //fprintf(stderr, "2\n");



  std::string *component;
  size_t location = suffix->find('/');
  std::string *maybe_slash;
  if (location != -1) {
    component = new std::string(suffix->substr(0, location));
    suffix = new std::string(suffix->substr(location + 1));
    //fprintf(stderr, "\n Suffix in if statement: %s\n", suffix->c_str());
    maybe_slash = new std::string("/");
  } else {
      component = new std::string(*suffix);
      suffix = NULL;
      maybe_slash = new std::string("");
  }
  //fprintf(stderr, "%s\n", nextPrefix->c_str());
  //fprintf(stderr, "3\n");
  //fprintf(stderr, "\nSuffix: \n",suffix->c_str());

  if (component->find('*') == -1 && component->find('?') == -1) {
    *nextPrefix = *nextPrefix + *component + *maybe_slash;
    expandWildcards(nextPrefix, suffix, arr);
    delete nextPrefix;
    delete component;
    delete maybe_slash;
    return;
  }
  //fprintf(stderr, "4\n");
  //fprintf(stderr, "\n Suffix before regex conversion: %s\n", suffix->c_str());
  //fprintf(stderr, "4.5");

  //fprintf(stderr, "AFTER NOT * OR ?\n");
  char *reg = (char*) malloc(2 * component->length() + 10);
  //char holder[1024] = {0};
  //sprintf(holder, "%s", arg->c_str());
  //char *a = holder;
  char *r = reg;
  *r = '^';
  r++;
  for (int i = 0; i < component->length(); i++) {
    //fprintf(stderr, "%d\n", i);
    if (component->at(i) == '*') {
      *r = '.';
      r++;
      *r = '*';
      r++;
    } else if (component->at(i) == '?') {
      *r = '.';
      r++;
    } else if (component->at(i) == '.') {
      *r = '\\';
      r++;
      *r = '.';
      r++;
    } else {
      *r = component->at(i);
      r++;
    }
  }
  *r = '$';
  r++;
  *r = 0;

 // fprintf(stderr, "5\n");


  regex_t re;
  int result = regcomp(&re, reg, REG_EXTENDED | REG_NOSUB);
  if (result != 0) {
    perror("regex is bad");
    return;
  }

  DIR* dir;

  //fprintf(stderr, "6\n");

  if (nextPrefix->compare("") != 0) {
    dir = opendir(nextPrefix->c_str());
    //fprintf(stderr, "6.1\n");
  } else {
    dir = opendir(".");
    //fprintf(stderr, "6.2\n");
  }

  if (dir == NULL) {
   // perror("bad directory");
    return;
  }

  //fprintf(stderr, "%s\n", nextPrefix->c_str());

  struct dirent *ent = readdir(dir);
  //fprintf(stderr, "6.4\n");
  //std::vector<std::string*> arr = std::vector<std::string*>();

  //fprintf(stderr, "7\n");

  //fprintf(stderr, "Slash:%s\n", maybe_slash->c_str());

  std::string * temp;
  while (ent != NULL) {
    if (regexec(&re, ent->d_name, 1, NULL, 0) == 0) {
      if (reg[1] == '.') {
        if (ent->d_name[0] != '.') {
          temp = new std::string(*nextPrefix + std::string(ent->d_name) + *maybe_slash);
          expandWildcards(temp, suffix, arr);
          delete temp;
        }
      } else {
          temp = new std::string(*nextPrefix + std::string(ent->d_name) + *maybe_slash);
          expandWildcards(temp, suffix, arr);
          delete temp;
      }
      //Command::_currentSimpleCommand->insertArgument(new std::string(strdup(ent->d_name)));
    }

    ent = readdir(dir);
  }
  //fprintf(stderr, "8\n");
  //delete temp;
 //delete nextPrefix;
  //delete maybe_slash;
  closedir(dir);
  regfree(&re);
  free(reg);
  delete nextPrefix;
  delete component;
  delete maybe_slash;
  //delete temp;
}

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
