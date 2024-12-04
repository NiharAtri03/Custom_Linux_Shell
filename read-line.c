#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MAX_BUFFER_LINE 2048

extern void tty_raw_mode(void);

int rel_pos;
// Buffer where line is stored
int line_length;
char line_buffer[MAX_BUFFER_LINE];

int history_index = 0;
char * history [] = {
  "ls -al | grep x", 
  "ps -e",
  "cat read-line-example.c",
  "vi hello.c",
  "make",
  "ls -al | grep xxx | grep yyy"
};
int history_length = sizeof(history)/sizeof(char *);

void read_line_print_usage()
{
  char * usage = "\n"
    " ctrl-?       Print usage\n"
    " Ctrl-H       Removes the character at the position before the cursor\n"
    " Ctrl-D       Removes the character at the cursor\n"
    " Ctrl-A       The cursor moves to the beginning of the line\n"
    " Ctrl-E       The cursor moves to the end of the line\n"
    " left arrow   Moves cursor to the left\n"
    " right arrow  Moves cursor to the right\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {

  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  rel_pos = 0;

  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32 && ch < 127) {
      // It is a printable character

      if (rel_pos == line_length) { // at end of the line
        // Do echo
        write(1,&ch,1);

        // If max number of character reached return.
        if (line_length==MAX_BUFFER_LINE-2) {
          break;
        }

        // add char to buffer.
        line_buffer[line_length]=ch;

        rel_pos++;
        //if (rel_pos == line_length) {
        line_length++;
        //}
      } else { // in middle of the line
        write(1,&ch,1);

        // If max number of character reached return.
        if (line_length==MAX_BUFFER_LINE-2) {
          break;
        }


        //char rightCharacters[MAX_BUFFER_LINE];
        int j = rel_pos;

        while (j < line_length) {
          //write(1, &rightCharacters[j], 1);
          /*rightCharacters[j] = line_buffer[i];
          j++;*/
          write(1, &line_buffer[j], 1);
          j++;
        }

        for (int i = line_length; i > rel_pos; i--) {
          //line_buffer[i] = line_buffer[i - 1];
          line_buffer[i] =  line_buffer[i - 1];
        }
        j = rel_pos;

        while (j < line_length) {
         char a = 8;
         write(1, &a, 1);
         /* char a = rightCharacters[j];
          write(1, &a, 1);*/
          j++;
        }
        line_buffer[rel_pos]=ch;

        rel_pos++;
        line_length++;
      }
    }
    else if (ch==10) {
      // <Enter> was typed. Return line

      // Print newline
      write(1,&ch,1);

      break;
    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    }


    // BACKSPACE
    else if (ch == 8 || ch == 127) {
      // <backspace> was typed. Remove previous character read.
    if (rel_pos == 0 || line_length == 0) {
      continue;
    } else {
      // Go back one character
      ch = 8;
      write(1,&ch,1);
     // rel_pos--;
      int j = 0;

      //char rightCharacters[MAX_BUFFER_LINE];

      for (int i = rel_pos; i < line_length; i++) {
         //rightCharacters[j] = line_buffer[i];
         //char a = rightCharacters[j];
         write(1, &line_buffer[i], 1);
         //j++;
      }
      //rightCharacters[j + 1] = '\0';

      for (int i = rel_pos; i < line_length; i++) {
          //line_buffer[i] = line_buffer[i - 1];
        line_buffer[i - i] =  line_buffer[i];
      }

     
      /*for (int i = rel_pos; i <
      //while (rightCharacters[j] != '\0') {
         char a = rightCharacters[j];
         write(1, &a, 1);
          char a = rightCharacters[j];
          write(1, &a, 1);*/
         

     /*char a = 8;
     for (int i = rel_pos; i <= line_length; i++) {
      write(1, &a, 1);

     }*/


      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // Go back one character
      ch = 8;
      for (int i = 0; i < line_length - rel_pos + 1; i++) {
        write(1, &ch, 1);
      }

      // Remove one character from buffer
      line_length--;
      rel_pos--;
    }
  }

    //DELETE
    else if (ch == 4) {
      if ((line_length == 0 || rel_pos == 0) || (rel_pos >= line_length)) {
        continue;
      } else {
        for (int i = rel_pos; i < line_length - 1; i++) {
          line_buffer[i] = line_buffer[i + 1];
          write(1, &line_buffer[i], 1);
        }

      line_buffer[line_length - 1] = line_buffer[line_length];
      char z = ' ';
      write(1, &z, 1);

      char y = 8;
      for (int i = rel_pos; i < line_length; i++) {
        write(1, &y, 1);
      }
      line_length--;
      }
    }

    else if (ch == 1) { // home key at front
      for (int i = rel_pos; i > 0; i--) {
        char a = 8;
        write(1, &a, 1);
        rel_pos--;
      }
    } else if (ch == 5) { // end key at end
        while (rel_pos != line_length) {
          char a = line_buffer[rel_pos];
          write(1, &a, 1);
          rel_pos++;
     }
    } else if (ch==27) {
      // Escape sequence. Read two chars more

      char ch1; 
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);
      if (ch1==91 && ch2==65) {
	// Up arrow. Print next line in history.

	// Erase old line
	// Print backspaces
	int i = 0;
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}

	// Print spaces on top
	for (i =0; i < line_length; i++) {
	  ch = ' ';
	  write(1,&ch,1);
	}

	// Print backspaces
	for (i =0; i < line_length; i++) {
	  ch = 8;
	  write(1,&ch,1);
	}	

	// Copy line from history
	strcpy(line_buffer, history[history_index]);
	line_length = strlen(line_buffer);
	history_index=(history_index+1)%history_length;

	// echo line
	write(1, line_buffer, line_length);
      } else if (ch1 == 91 && ch2 == 68) { // left arrow
          if (rel_pos > 0) {
            char a = 8;
            write(1, &a, 1);
            rel_pos--;
          }
      } else if (ch1 == 91 && ch2 == 67) { // right arrow
          if (rel_pos < line_length) {
            ch = 27;
            write(1, &ch, 1);
            write(1, &ch1, 1);
            write(1, &ch2, 1);
            rel_pos++;
          }
      }
    }

  }

  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;

  return line_buffer;
}

