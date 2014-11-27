#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <ctype.h>  /* For isspace(). */
#include <stddef.h>  /* For size_t. */

#define MAX_BUFFER 4096

static void die(const char *message)
{
    perror(message);
    exit(1);
}

const char *getFileExtension(const char *fileName) {
    const char *dot = strrchr(fileName, '.');
    if(!dot || dot == fileName) return "";
    return dot + 1;
}

void remove_whitespace(char *str) {
    char *p;
    size_t len = strlen(str);

    for(p = str; *p; p ++, len --) {
        while(isspace(*p)) memmove(p, p+1, len--);
    }
}

int is_empty(const char *s) {
  while (*s != '\0') {
    if (!isspace(*s))
      return 0;
    s++;
  }
  return 1;
}


int main(int argc, char const *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "%s\n", "usage: ./preprocessor <jo program file> <pjo program file>");
        exit(1);
    }
    char *fileName = (char *) argv[1];
    char *outputFileName = (char *) argv[2];

    // check input file extension
    if (strcmp("jo", getFileExtension(fileName)) != 0)
    {
        die("file extension must be jo");
    }

    // check output file extension
    if (strcmp("pjo", getFileExtension(outputFileName)) != 0)
    {
        die("output file extension must be pjo");
    }

    FILE *input;
    if ((input = fopen(fileName, "r")) == NULL) {
        die("fopen() failed");
    }

    FILE *output;
    if ((output = fopen(outputFileName, "w")) == NULL) {
        die("fopen() failed");
    }

    char buffer[MAX_BUFFER];

    while (fgets(buffer, sizeof(buffer), input) != NULL) {

        size_t len = strlen(buffer) - 1;
        if (buffer[len] == '\n') {
            buffer[len] = '\0';
        }
        if (strstr(buffer, "*/") != NULL) {
            fprintf(output, "%s\n", buffer);
        }
        else if (strstr(buffer, "/*") != NULL) {
            fprintf(output, "%s\n", buffer);
        }
        else if (strstr(buffer, "func ") != NULL) {
            fprintf(output, "%s {\n", buffer);
        }
        else if (strstr(buffer, "int ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        }
/*        else if (strstr(buffer, "path ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        }
        else if (strstr(buffer, "dict ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        } */
        else if (strstr(buffer, "list ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        }
        else if (strstr(buffer, "string ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        }
        else if (strstr(buffer, "bool ") != NULL) {
            fprintf(output, "%s;\n", buffer);
        }
        else if (strstr(buffer, "for ") != NULL) {
            fprintf(output, "%s {\n", buffer);
        }
        else if ((strstr(buffer, "if (") != NULL || strstr(buffer, "if(") != NULL) && (strstr(buffer, ")") != NULL)) {
            fprintf(output, "%s {\n", buffer);
        }
        else if ((strstr(buffer, "if (") != NULL || strstr(buffer, "if(") != NULL) && (strstr(buffer, ")") == NULL)) {
            fprintf(output, "%s\n", buffer);
        }
        else if (strstr(buffer, ")") != NULL) {
            fprintf(output, "%s {\n", buffer);
        }
        else if (strstr(buffer, "else") != NULL) {
            int i;
            int counter = 0;
            for (i = 0; i < strlen(buffer); ++i)
            {
                if (buffer[i] == ' ') {
                    fprintf(output, "%c", buffer[i]);
                    counter++;
                }
            }
            fprintf(output, "} %s {\n", buffer + counter);
        }
        else if (strstr(buffer, "end") != NULL) {
            int i;
            for (i = 0; i < strlen(buffer); i++){
                if (buffer[i] == 'e') {
                    buffer[i] = '}';
                } else if (buffer[i] == 'n') {
                    buffer[i] = '\n';
                } else if (buffer[i] == 'd') {
                    buffer[i] = '\0';
                } else {

                }
            }
            fprintf(output, "%s", buffer);
        }
        else {
            if (is_empty(buffer)) {
                remove_whitespace(buffer);
                fprintf(output, "\n");
            } else {
                fprintf(output, "%s;\n", buffer);
            }
        }
    }
    fclose(input);
    fclose(output);
    return 0;
}