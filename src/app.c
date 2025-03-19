/*******************************************************************************
* Implementation of the application
* Note that in a production codebase I would never use the
* C standard library for string handling or file handling.
* But I wanted to keep the code in this project to a minimum
* because it exists only to demonstrate the build process.
*******************************************************************************/

// todo: handle suppression of warnings in other toolchains as needed
#ifdef _MSC_VER
#pragma warning(push,0)
#endif

#include <stdio.h>
#include <string.h>

#if defined(_WIN32)
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#elif defined(__APPLE__) && defined(__MACH__)
#include <mach-o/dyld.h>
#else
// todo: handle other platforms
#error unsupported platform
#endif

// todo: handle suppression of warnings in other toolchains as needed
#ifdef _MSC_VER
#pragma warning(pop)
#endif

#define STR_CAPACITY(a) (long)((sizeof(a) / sizeof((a)[0])) - 1)
static char _msg_file_path[1024] = {0};
static char _msg_file_buffer[2048] = {0};
static const char _msg_file_subpath[] = "/assets/message.txt";
static const long _msg_file_path_cap = STR_CAPACITY(_msg_file_path);
static const long _msg_file_buffer_cap = STR_CAPACITY(_msg_file_buffer);
static const long _msg_file_subpath_len = STR_CAPACITY(_msg_file_subpath);

void app_run(void){
  long len = 0;

  // get the path of the running executable
  #if defined(_WIN32)
    DWORD result = GetModuleFileNameA(NULL, _msg_file_path, (DWORD)_msg_file_path_cap);
    if(result > 0){
      len = result;
    }
  #elif defined(__APPLE__) && defined(__MACH__)
    uint32_t path_len = (uint32_t)_msg_file_path_cap;
    if(_NSGetExecutablePath(_msg_file_path, &path_len) == 0){
      len = strlen(_msg_file_path);
    }
  #else
    // todo: handle other platforms
    #error unsupported platform
  #endif

  // find the last instance of a slash character in the path and terminate
  // the path there so that .e.g "some/path/my_app.exe" becomes "some/path"
  if((len > 1) && (len < _msg_file_path_cap)){
    for(long i = (len - 1); i > 0; --i){
      if(_msg_file_path[i] == '/' || _msg_file_path[i] == '\\'){
        len = i;
        break;
      }
    }
  }

  // append the message file subpath to the path so that
  // the path becomes .e.g "some/path/subpath"
  long remain = _msg_file_path_cap - len;
  if(remain >= _msg_file_subpath_len){
    #if defined(_WIN32)
      strcpy_s(_msg_file_path + len, remain, _msg_file_subpath);
    #else
      strlcpy(_msg_file_path + len, _msg_file_subpath, remain);
    #endif
    _msg_file_path[len + _msg_file_subpath_len] = 0;
  }

  // open the message file
  FILE* file = 0;
  #if defined(_WIN32)
    if(fopen_s(&file, _msg_file_path, "rb") != 0){
      file = 0;
    }
  #else
    file = fopen(_msg_file_path, "rb");
  #endif

  // load the message string the from message file
  if(file){
    int read_ok = 0;

    if(fseek(file, 0, SEEK_END) == 0){
      len = ftell(file);
      if(len > 0){
        if(fseek(file, 0, SEEK_SET) == 0){
          size_t read_len_remain = (size_t)len;

          if(len > _msg_file_buffer_cap){
            read_len_remain = (size_t)_msg_file_buffer_cap;
            printf("WARNING: entire file will not fit in buffer.\n");
          }

          size_t read_len = 0;
          for(;;){
            size_t r = fread(_msg_file_buffer, 1, read_len_remain, file);
            if(!r){
              break;
            }else if(r > read_len_remain){
              read_len += read_len_remain;
              read_len_remain = 0;
              break;
            }else{
              read_len += r;
              read_len_remain -= r;
            }
          }
          _msg_file_buffer[read_len] = 0;

          read_ok = (read_len == (size_t)len);
        }
      }
    }
    fclose(file);

    if(!read_ok){
      printf("WARNING: failed to read entire file.\n");
    }

  }else{
    printf("ERROR: failed to open file at path %s.\n", _msg_file_path);
  }

  // print the message string
  printf("%s", _msg_file_buffer);
}