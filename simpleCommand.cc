#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <iostream>

#include "simpleCommand.hh"

SimpleCommand::SimpleCommand() {
  _arguments = std::vector<std::string *>();
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _arguments) {
    delete arg;
  }
}

void SimpleCommand::insertArgument( std::string * argument ) {
  // simply add the argument to the vector
  //std::string str = *argument;
  //int len = argument->length();
  for (int i = 0; i < argument->length(); i++){
    //printf("%d", argument->length());
    if ((*argument)[i] == '\\') {
      argument->erase(i,1);
    }
  }
  //for (size_t j = 0; j < (*argument).size(); j++) {
      //if ((*argument[i].c_str()) == 'a') {
        //printf("%s", argument[i].c_str());
      //}

    //}
  //}
  _arguments.push_back(argument);
}

// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _arguments) {
    std::cout << "\"" << *arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}
