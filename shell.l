%s func
%{

#include <cstring>
#include <stdio.h>
#include "y.tab.hh"
#include <unistd.h>

extern "C" char * read_line();

int mygetc(FILE * f) {
  static char *p;
  char ch;

   if (!isatty(0)) {
  // stdin is not a tty. Call real getc
    return getc(f);
  }

  // stdin is a tty. Call our read_line.
  if (p==NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;
}

#undef getc
#define getc(f) mygetc(f)




static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

%}

%option noyywrap


%%
include             BEGIN(func);

\n {
  return NEWLINE;
}


 
  /*yylval.cpp_string = new std::string(yytext);

  size_t matchFront = 0;
  size_t matchBack = 0;
 // std::string new_string = yylval.cpp_string->c_str();
  size_t index = 0;
  matchFront = yylval.cpp_string->find("${", index);

 while (matchFront != -1) {
    //matchFront = yylval.cpp_string->find("${", index);
    index = matchFront;
    matchBack = yylval.cpp_string->find("}", index) + 1;
    index = matchBack;
    fprintf(stderr, "%zu\n", matchFront);
    fprintf(stderr, "%zu\n", matchBack);

    *yylval.cpp_string = yylval.cpp_string->replace(matchFront, matchBack, "HIIIIII");
    matchFront = yylval.cpp_string->find("${", index);
    //fprintf(stderr, "%s\n", yylval.cpp_string->c_str());

  }

  //fprintf(stderr, "%s\n", new_string.c_str());


  //yylval.cpp_string = new std::string(yylval.cpp_string->substr(2, yylval.cpp_string->length() - 3));
  //yylval.cpp_string = new std::string(getenv(yylval.cpp_string->c_str()));

  return WORD;*/


[ \t] {
  /* Discard spaces and tabs */
}

\$\([^\n\$]*\)|\`[^\n\t\`]*\` {
  //std::string str = yytext;
  //printf("BEFORE %s", yylval.cpp_string->c_str());

  //const char* cstr = yylval.cpp_string->c_str(); 
   yylval.cpp_string = new std::string(yytext);

  if ((*yylval.cpp_string)[0] == '$') {
    yylval.cpp_string = new std::string(yylval.cpp_string->substr(2, yylval.cpp_string->length() - 3));
    //printf("AFTER $ 1 %s", yylval.cpp_string->c_str());
    (*yylval.cpp_string) += '\n';
    //printf("AFTER $ 2%s", yylval.cpp_string->c_str());
  } else {
    yylval.cpp_string = new std::string(yylval.cpp_string->substr(1, yylval.cpp_string->length() - 2).c_str());
    yylval.cpp_string->push_back('\n');
    //printf("AFTER `` %s", yylval.cpp_string->c_str());
  }
  //printf("%s", yylval.cpp_string->c_str());
  //const char* cstr = yylval.cpp_string->c_str(); 

  int din = dup(0);
  int dout = dup(1);
  int pin[2];
  int pout[2];
  pipe(pin);
  pipe(pout);



  /*dup2(pout[1], 1);
  close(pout[1]);
  dup2(pin[0],0);
  close(pin[0]);*/

  write(pin[1], yylval.cpp_string->c_str(), yylval.cpp_string->length());
  write(pin[1],"exit\n", 5);
  close(pin[1]);

  int ret2 = fork();

  if (ret2 == -1) { //error
    perror("fork");
    exit(1);
  } else if(ret2 == 0) { //in child process
      //fprintf(stderr, "IN CHILD");
      dup2(pout[1], 1);
      close(pout[1]);
      dup2(pin[0],0);
      close(pin[0]);

      char *args[2] = {"/proc/self/exe", NULL};
      //fprintf(stderr, "1");
      execvp("/proc/self/exe", args);
     // fprintf(stderr, "2");
      perror("execvp");
      //fprintf(stderr, "3");
      exit(1);
  }
  //fprintf(stderr,"LEFT THE CHILD");
  close(pout[1]);
  //fprintf(stderr, "REDIRECTION BEFORE WRITING");
  dup2(dout, 1);
  close(dout);
  dup2(din, 0);
  close(din);

  char buf[YY_BUF_SIZE] = {0};
  char one_char;
  int count = 0;


  //fprintf(stderr, "READING HERE");
  while (read(pout[0], &one_char, 1)) {
    if (one_char == '\n' /*|| one_char == '\t'*/){
      buf[count] = ' ';
      //printf("WRITING: %c\n", one_char);
    } else {
      buf[count] = one_char;
    }
    //printf("WRITING: %c\n", one_char);

    count++;
  }

  buf[count] = '\0';

  for (count = count - 1 - 18; count >= 0; count--) {
    myunputc(buf[count]);
  }
  close(pin[0]);
  close(pout[0]);
  close(pin[1]);
  close(pout[1]);
}



">" {
  return GREAT;
}


"<" {
  return LESS;
}

">>" {
  return GREATGREAT;
}

"|" {
  return PIPE;
}

">>&" {
  return GREATGREATAMPERSAND;
}

">&" {
  return GREATAMPERSAND;
}

"&" {
  return AMPERSAND;
}

"2>" {
  return TWOGREATER;
}

"source" {
  BEGIN(func);
}

<func>([^ \t\n]+) {
  //printf("bferjuguiwgr\n");
  //printf("%s\n", yytext);
  yyin = fopen(yytext, "r");
  if (!yyin) {
    perror("fopen failed");
  } else {
    BEGIN(INITIAL);
    yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));

    //fprintf(stderr, "HERE 1");
    //yyparse();
    //fprintf(stderr, "HERE 2");
    int ret = yyparse();
    if (ret == 1) {
      perror("yyparse failed");
    }

    yypop_buffer_state();

    if (!YY_CURRENT_BUFFER) {
      yyterminate();
    }
    //fclose(ptr);
    }
}

\"[^\"]*\" {
  yylval.cpp_string = new std::string(yytext);
  yylval.cpp_string = new std::string(yylval.cpp_string->substr(1, yylval.cpp_string->length() - 2));

  /* \\[^ nt][^ >\n\t\|]* {
  yylval.cpp_string = new std::string(yytext);
  size_t match;
  std::string new_string = "";
  int index = 0;
  do {
    match = yylval.cpp_string->find("\\", index);
    new_string = yylval.cpp_string->erase(index, index);
    fprintf(stderr, "match %zu\n", match);

  } while (match != -1);
 

}*/

  return WORD;
}



~[^ \n\t]* {
  yylval.cpp_string = new std::string(yytext);
  //yylval.cpp_string  = new std::string(getenv("HOME") + yylval.cpp_string->substr(1, yylval.cpp_string->size() - 1));
  if (yylval.cpp_string->compare("~") == 0) {
    yylval.cpp_string = new std::string(getenv("HOME"));
  } else if ((*yylval.cpp_string)[1] == '/') {
    yylval.cpp_string = new std::string(std::string(getenv("HOME")) + yylval.cpp_string->substr(1, yylval.cpp_string->size() - 1));
  } else {
    yylval.cpp_string = new std::string(std::string("/homes/" +  yylval.cpp_string->substr(1, yylval.cpp_string->size() - 1)));
  }
  //yylval.cpp_string = yylval.cpp_string->replace();


  return WORD;
}


[^ ~\t\n>\|][^ \t\n>\|]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);

  size_t matchFront = 0;
  size_t matchBack = 0;
  std::string new_string = "";
  size_t index = 0;
  matchFront = yylval.cpp_string->find("${", index);
  index = matchFront;
  matchBack = yylval.cpp_string->find("}", index) + 1;
  index = matchBack;


 while (matchFront != -1) {
    //matchFront = yylval.cpp_string->find("${", index);
    //fprintf(stderr, "%zu\n", matchFront);
    //fprintf(stderr, "%zu\n", matchBack);
    //printf("%s\n", yylval.cpp_string->substr(matchFront + 2, matchBack - 3 - matchFront).c_str());

    if (matchBack != -1 && getenv(yylval.cpp_string->substr(matchFront + 2, matchBack - 3 - matchFront).c_str()) != NULL) {
      yylval.cpp_string = new std::string(yylval.cpp_string->replace(matchFront, matchBack - matchFront, getenv(yylval.cpp_string->substr(matchFront + 2, matchBack - 3 - matchFront).c_str())));

      matchFront = yylval.cpp_string->find("${", index);
      index = matchFront;
      matchBack = yylval.cpp_string->find("}", index) + 1;
      index = matchBack;
    } else {
      break;
    }

    //fprintf(stderr, "%s\n", yylval.cpp_string->c_str());
  }



  return WORD;
}

