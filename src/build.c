/*******************************************************************************
* Includes all code that will be built for this project
*******************************************************************************/

// todo: handle suppression of warnings in other toolchains
// note: these are only needed when compiling with extended warnings enabled
#ifdef _MSC_VER
#pragma warning(disable:4324) // 'struct_name' : structure was padded due to __declspec(align())
#pragma warning(disable:4820) // 'bytes' bytes padding added after construct 'member_name'
#pragma warning(disable:4710) // 'function' : function not inlined
#pragma warning(disable:4711) // function 'function' selected for inline expansion
#pragma warning(disable:4740) // 'function' : function marked as __forceinline not inlined
#pragma warning(disable:5045) // Compiler will insert Spectre mitigation for memory load if /Qspectre switch specified
#endif

// include the code that need to be built
#include "app.c"
#include "main.c"