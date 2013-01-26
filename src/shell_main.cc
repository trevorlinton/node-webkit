// Copyright (c) 2012 Intel Corp
// Copyright (c) 2012 The Chromium Authors
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell co
// pies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in al
// l copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IM
// PLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNES
// S FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WH
// ETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include "content/public/app/content_main.h"

#include "content/shell/shell_main_delegate.h"
#include "sandbox/win/src/sandbox_types.h"

#if defined(OS_WIN)
#include "base/command_line.h"
#include "base/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "chrome/common/zip.h"
#include "content/public/app/startup_helper_win.h"
#include "content/shell/shell_main_delegate.h"
#include "sandbox/win/src/sandbox_types.h"
#endif

#if defined(OS_MACOSX)
#include "shell_content_main.h"
#endif

#if defined(OS_WIN)
bool MakePathAbsolute(FilePath* file_path) {
  FilePath current_directory;
  if (!file_util::GetCurrentDirectory(&current_directory))
    return false;

  if (file_path->IsAbsolute())
    return true;

  if (current_directory.empty())
    return file_util::AbsolutePath(file_path);

  if (!current_directory.IsAbsolute())
    return false;

  *file_path = current_directory.Append(*file_path);
  return true;
}

// Attempts to extract the packaged applicaiton, nw.pak and any necessary
// dll's to be used later.
void ExtractPackage() {
  CommandLine *cmd = CommandLine::ForCurrentProcess();
  CommandLine::StringVector args = cmd->GetArgs();
  
  // First search to see if an arguement was passed in.
  // Second look for app.nw in our directory
  // Third see if our own executable contains a zip file.
  // Fourth set the containing directory as our working directory.
  FilePath search_files[] = { 
    (args.size() > 0) ? FilePath(args[0]) : FilePath(),
    cmd->GetProgram().DirName().Append(L"app.nw"),
    cmd->GetProgram(), 
    cmd->GetProgram().DirName() 
  };

  // Loop through each option, if its empty ignore it.  If its a directory
  // exit successfully, if its a file, try and unzip it, if any of those fail
  // keep moving.
  for(int i=0; i < 4; i++) {
    if(!search_files[i].empty()) {
      // Get a full path 
      MakePathAbsolute(&search_files[i]);

      // If the directory exists set it as the working directory and keep moving.
      if(file_util::DirectoryExists(search_files[i])) {
		    cmd->AppendSwitchASCII("working-directory",search_files[i].AsUTF8Unsafe());
		    return;
	    }

      // If this is a file, lets see if we can get a temporary directory and see if
      // we can unzip it.
      else if(file_util::PathExists(search_files[i])) {
        // Get a temporary directory
		    FilePath where;
        static scoped_ptr<base::ScopedTempDir> scoped_temp_dir;
		    file_util::CreateNewTempDirectory(L"nw", &where);
        scoped_temp_dir.reset(new base::ScopedTempDir());
        if(scoped_temp_dir->Set(where)) {
          // See if we can unzip the file. If so, extract it to the temporary dir
          // then set the working directory and exit.
          if(zip::Unzip(search_files[i], where)) {
            cmd->AppendSwitchASCII("working-directory",where.AsUTF8Unsafe());
            // TODO: Move DLL's to other directory.
            return;
          }
        }
	    }
    }
  }
}

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE, wchar_t*, int) {
  CommandLine::Init(__argc, __argv);
  
  // Only try and extract the package if we do not have a working directory.
  // Child processes should already have a working-directory passed in.
  if(!CommandLine::ForCurrentProcess()->HasSwitch("working-directory"))
    ExtractPackage();

  // Make sure the working directory is added as a dll directory.
  AddDllDirectory(CommandLine::ForCurrentProcess()->GetSwitchValueNative("working-directory").c_str());

  sandbox::SandboxInterfaceInfo sandbox_info = {0};
  content::InitializeSandboxInfo(&sandbox_info);
  content::ShellMainDelegate delegate;
  return content::ContentMain(instance, &sandbox_info, &delegate);
}

#else

int main(int argc, const char** argv) {
#if defined(OS_MACOSX)
  // Do the delegate work in shell_content_main to avoid having to export the
  // delegate types.
  return ::ContentMain(argc, argv);
#else
  content::ShellMainDelegate delegate;
  return content::ContentMain(argc, argv, &delegate);
#endif  // OS_MACOSX
}

#endif  // OS_POSIX
