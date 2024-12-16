# Custom_Linux_Shell
In this project, I developed a shell interpreter that mimics the Linux Shell. It is built from C, C++, Flex (a lexical analyzer), and Bison (a parser). It is able to parse and execute a variety of Linux commands (ls, pwd, cd) and supports common features such as command piping, file redirection, background processing, signal handling, subshells, wildcarding, and command history editing. 

This was one of my most impressive projects as I was able to successfully replicate a system as complex as the Linux shell from scratch. This required me to not only learn a lot of new systems concepts (process creation, inter-process communication, and command parsing) from textbooks and the internet but also implement them. It also is the longest project I've ever worked on, as it took three months of dedicated development to complete.

# Important Files
command.cc
This file defines the Command class, which manages the representation, execution, and cleanup of user commands, supporting complex operations like I/O redirection, forking, and background execution. 

read-line.c
This file implements a command-line input reader which allows the user to edit their commands through deleting characters, moving the cursor, and appending text.

shell.cc
This file implements the UI of the shell. It also sets up signal handlers to handle interruptions and clean up terminated child processes.

shell.l
This code defines a lexical analyzer for my custom shell language that can understand the commands and arguments within input text.

shell.y
This code defines the shell command grammer by defining the syntax and semantic rules for commands, arguments, input/output redirections, and pipes.
