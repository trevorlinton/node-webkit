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
#include "base/threading/thread_restrictions.h"
#include "third_party/zlib/google/zip.h"
#include "third_party/zlib/zlib.h"
#include "content/nw/src/api/app/app.h"
#include "third_party/modp_b64/modp_b64.h"
#include "base/file_util.h"
#include "base/files/memory_mapped_file.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/values.h"
#include "content/nw/src/api/api_messages.h"
#include "content/nw/src/breakpad_linux.h"
#include "content/nw/src/browser/native_window.h"
#include "content/nw/src/browser/net_disk_cache_remover.h"
#include "content/nw/src/nw_package.h"
#include "content/nw/src/nw_shell.h"
#include "content/nw/src/shell_browser_context.h"
#include "content/nw/src/common/shell_switches.h"
#include "content/common/view_messages.h"
#include "content/public/common/renderer_preferences.h"
#include "content/public/browser/web_contents.h"
#include "content/public/browser/render_process_host.h"
#include "content/nw/src/net/util/embed_utils.h"
#if defined(OS_WIN)
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <stdio.h>
#elif defined(OS_MACOSX)
#include <Carbon/Carbon.h>
#endif

#if defined(MSDOS) || defined(OS2) || defined(WIN32) || defined(__CYGWIN__)
#  include <fcntl.h>
#  include <io.h>
#  define SET_BINARY_MODE(file) _setmode(_fileno(file), O_BINARY)
#else
#  define SET_BINARY_MODE(file)
#endif

#define CHUNK 16384

using base::MessageLoop;
using content::Shell;
using content::ShellBrowserContext;
using content::RenderProcessHost;

namespace nwapi {

namespace {

#if defined(OS_WIN)

long GetIdleTime()
{
    LASTINPUTINFO lii;
    memset(&lii, 0, sizeof(lii));

    lii.cbSize = sizeof(lii);
    ::GetLastInputInfo(&lii);

    DWORD currentTickCount = GetTickCount();
    long idleTicks = currentTickCount - lii.dwTime;

    return (int)idleTicks;
}

struct MonitorDevice {
   std::wstring cardName;
   std::wstring deviceName;
   std::wstring cardType;
   std::wstring deviceType;
   int x;
   int y;
   int x_work;
   int y_work;
   int width;
   int height;
   int width_work;
   int height_work;
   bool isPrimary;
   bool isDisabled;
   bool isSLM;
   int colorDepth;
   float scaleFactor;
   bool isMirror;
   bool isRemovable;
};

RECT getViewingMonitorsBounds(std::vector<MonitorDevice> displays) {
   RECT result;
   result.left = LONG_MAX;
   result.top = LONG_MAX;
   result.bottom = LONG_MIN;
   result.right = LONG_MIN;

   MonitorDevice disp;

   for (unsigned i=0;i<displays.size();++i)
   {
      disp = displays[i];
      if (! disp.isSLM && ! disp.isDisabled)
      {
         result.left = std::min((int)result.left, disp.x);
         result.top = std::min((int)result.top, disp.y);
         result.right = std::max((int)result.right, disp.x + disp.width);
         result.bottom = std::max((int)result.bottom, disp.y + disp.height);
      }
   }

   return result;
}

POINT getNextDisplayPosition(std::vector<MonitorDevice> displays) {
   POINT result;
   result.x = LONG_MIN;
   result.y = LONG_MIN;

   MonitorDevice disp;

   for (unsigned i=0;i<displays.size();++i)
   {
      disp = displays[i];
      if (! disp.isDisabled)
      {
         if ((disp.x + disp.width) > result.x)
            result.x = disp.x + disp.width;
            result.y = disp.y;
      }
   }
   return result;
}

void updateMonitorRect(MonitorDevice * display) {
  DEVMODE dm;
  ZeroMemory(&dm, sizeof(dm));
  dm.dmSize = sizeof(dm);
  std::wstring cardName = display->cardName.c_str();

  if (EnumDisplaySettingsEx(cardName.c_str(), ENUM_CURRENT_SETTINGS, &dm, 0) == FALSE)
	  EnumDisplaySettingsEx(cardName.c_str(), ENUM_REGISTRY_SETTINGS, &dm, 0);
  display->x = dm.dmPosition.x;
  display->y = dm.dmPosition.y;
  display->width = dm.dmPelsWidth;
  display->height = dm.dmPelsHeight;
}

void updateMonitorRects(std::vector<MonitorDevice> * displays) {
   for(unsigned int i=0;i<displays->size();++i)
      updateMonitorRect(&(displays->at(i)));
}

std::vector<MonitorDevice> getMonitorInfo()
{
  std::vector<MonitorDevice> displays;
	DISPLAY_DEVICE dd;
	dd.cb = sizeof(dd);
	DWORD dev = 0; // device index

	while (EnumDisplayDevices(0, dev, &dd, 0))
	{
    MonitorDevice thisDev;
    DISPLAY_DEVICE ddMon;
    DEVMODE dm;
    DWORD devMon = 0;
    HMONITOR hm = 0;
		MONITORINFO mi;

		// get information about the monitor attached to this display adapter. dualhead cards
		// and laptop video cards can have multiple monitors attached
		ZeroMemory(&ddMon, sizeof(ddMon));
		ddMon.cb = sizeof(ddMon);
		
		// please note that this enumeration may not return the correct monitor if multiple monitors
		// are attached. this is because not all display drivers return the ACTIVE flag for the monitor
		// that is actually active
		while(EnumDisplayDevices(dd.DeviceName, devMon, &ddMon, 0)) {
			if(ddMon.StateFlags & DISPLAY_DEVICE_ACTIVE) break;
			devMon++;
		}

		if(!*ddMon.DeviceString) {
			EnumDisplayDevices(dd.DeviceName, 0, &ddMon, 0);
			if (!*ddMon.DeviceString) lstrcpy(ddMon.DeviceString, (L"Default Monitor"));
		}

		// get information about the display's position and the current display mode
		ZeroMemory(&dm, sizeof(dm));
		dm.dmSize = sizeof(dm);
		if(EnumDisplaySettingsEx(dd.DeviceName, ENUM_CURRENT_SETTINGS, &dm, 0) == FALSE)
			EnumDisplaySettingsEx(dd.DeviceName, ENUM_REGISTRY_SETTINGS, &dm, 0);

		// get the monitor handle and workspace
		ZeroMemory(&mi, sizeof(mi));
		mi.cbSize = sizeof(mi);

		if(dd.StateFlags & DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) {
			// display is enabled. only enabled displays have a monitor handle
			POINT pt = { dm.dmPosition.x, dm.dmPosition.y };
			hm = MonitorFromPoint(pt, MONITOR_DEFAULTTONULL);
			if (hm) {
        GetMonitorInfo(hm, &mi);
      }

      thisDev.deviceType = std::wstring(ddMon.DeviceString);
      thisDev.cardType = std::wstring(dd.DeviceString);
      thisDev.deviceName = std::wstring(ddMon.DeviceName);
      thisDev.cardName = std::wstring(dd.DeviceName);
      thisDev.x = dm.dmPosition.x;
      thisDev.y = dm.dmPosition.y;
      thisDev.width = dm.dmPelsWidth;
      thisDev.height = dm.dmPelsHeight;
      thisDev.x_work = mi.rcWork.left;
      thisDev.y_work = mi.rcWork.top;
      thisDev.width_work = mi.rcWork.right - mi.rcWork.left;
      thisDev.height_work = mi.rcWork.bottom - mi.rcWork.top;
      thisDev.isPrimary = (dd.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) != 0;
      thisDev.isDisabled = !(dd.StateFlags & DISPLAY_DEVICE_ATTACHED_TO_DESKTOP);
      thisDev.isRemovable = (dd.StateFlags & DISPLAY_DEVICE_REMOVABLE);
      thisDev.isSLM = false;
      thisDev.isMirror = (dd.StateFlags & DISPLAY_DEVICE_MIRRORING_DRIVER);
      thisDev.colorDepth = dm.dmBitsPerPel;

      if(!(thisDev.deviceType.length()==0)) displays.push_back(thisDev);
    }
    dev++;
	}

	return displays;
}
#elif defined(OS_MACOSX)
long GetIdleTime()
    {
        // some of the code for this was from:
        // http://ryanhomer.com/blog/2007/05/31/detecting-when-your-cocoa-application-is-idle/
        CFMutableDictionaryRef properties = 0;
        CFTypeRef obj;
        mach_port_t masterPort;
        io_iterator_t iter;
        io_registry_entry_t curObj;

        IOMasterPort(MACH_PORT_NULL, &masterPort);

        /* Get IOHIDSystem */
        IOServiceGetMatchingServices(masterPort, IOServiceMatching("IOHIDSystem"), &iter);
        if (iter == 0)
        {
            return -1;
        }
        else
        {
            curObj = IOIteratorNext(iter);
        }
        if (IORegistryEntryCreateCFProperties(curObj, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS && properties != NULL)
        {
            obj = CFDictionaryGetValue(properties, CFSTR("HIDIdleTime"));
            CFRetain(obj);
        }
        else
        {
            return -1;
        }

        uint64_t tHandle = 0;
        if (obj)
        {
            CFTypeID type = CFGetTypeID(obj);

            if (type == CFDataGetTypeID())
            {
                CFDataGetBytes((CFDataRef) obj, CFRangeMake(0, sizeof(tHandle)), (UInt8*) &tHandle);
            }
            else if (type == CFNumberGetTypeID())
            {
                CFNumberGetValue((CFNumberRef)obj, kCFNumberSInt64Type, &tHandle);
            }
            else
            {
                // error
                tHandle = 0;
            }

            CFRelease(obj);

            tHandle /= 1000000; // return as milliseconds
        }
        else
        {
            tHandle = -1;
        }

        CFRelease((CFTypeRef)properties);
        IOObjectRelease(curObj);
        IOObjectRelease(iter);
        return (long)tHandle;
    }
#endif

int _defgzip(FILE *source, FILE *dest, int level)
{
    int ret = 0, flush = 0;
    unsigned have = 0;
    z_stream strm = z_stream();
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];

    /* allocate deflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    ret = deflateInit2(&strm, level,Z_DEFLATED,16+MAX_WBITS,8,Z_DEFAULT_STRATEGY);
    if (ret != Z_OK)
        return ret;

    /* compress until end of file */
    do {
        strm.avail_in = fread(in, 1, CHUNK, source);
        if (ferror(source)) {
            (void)deflateEnd(&strm);
            return Z_ERRNO;
        }
        flush = feof(source) ? Z_FINISH : Z_NO_FLUSH;
        strm.next_in = in;

        /* run deflate() on input until output buffer not full, finish
           compression if all of source has been read in */
        do {
            strm.avail_out = CHUNK;
            strm.next_out = out;
            ret = deflate(&strm, flush);    /* no bad return value */
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            have = CHUNK - strm.avail_out;
            if (fwrite(out, 1, have, dest) != have || ferror(dest)) {
                (void)deflateEnd(&strm);
                return Z_ERRNO;
            }
        } while (strm.avail_out == 0);
        assert(strm.avail_in == 0);     /* all input will be used */

        /* done when last data in file processed */
    } while (flush != Z_FINISH);
    assert(ret == Z_STREAM_END);        /* stream will be complete */

    /* clean up and return */
    (void)deflateEnd(&strm);
    return Z_OK;
}

// Get render process host.
RenderProcessHost* GetRenderProcessHost() {
  RenderProcessHost* render_process_host = NULL;
  std::vector<Shell*> windows = Shell::windows();
  for (size_t i = 0; i < windows.size(); ++i) {
    if (!windows[i]->is_devtools()) {
      render_process_host = windows[i]->web_contents()->GetRenderProcessHost();
      break;
    }
  }

  return render_process_host;
}

void GetRenderProcessHosts(std::set<RenderProcessHost*>& rphs) {
  RenderProcessHost* render_process_host = NULL;
  std::vector<Shell*> windows = Shell::windows();
  for (size_t i = 0; i < windows.size(); ++i) {
    if (!windows[i]->is_devtools()) {
      render_process_host = windows[i]->web_contents()->GetRenderProcessHost();
      rphs.insert(render_process_host);
    }
  }
}

}  // namespace

// static
void App::Call(const std::string& method,
               const base::ListValue& arguments) {
  if (method == "Quit") {
    Quit();
    return;
  } else if (method == "CloseAllWindows") {
    CloseAllWindows();
    return;
  } else if (method == "CrashBrowser") {
    int* ptr = NULL;
    *ptr = 1;
  }
  NOTREACHED() << "Calling unknown method " << method << " of App";
}


// static
void App::Call(Shell* shell,
               const std::string& method,
               const base::ListValue& arguments,
               base::ListValue* result) {
  base::ThreadRestrictions::SetIOAllowed(true);
  if (method == "GetDataPath") {
    ShellBrowserContext* browser_context =
      static_cast<ShellBrowserContext*>(shell->web_contents()->GetBrowserContext());
    result->AppendString(browser_context->GetPath().value());
    return;
  } else if (method == "GetEmbeddedResource") {
    std::string str;
    std::string out;
    arguments.GetString(0,&str);
    arguments.GetString(1,&out);
    embed_util::FileMetaInfo info;
    if(embed_util::Utility::GetFileInfo(str,&info) &&
       embed_util::Utility::GetFileData(&info))
    {
#ifdef OS_WIN
      file_util::WriteFile(base::FilePath(std::wstring(out.begin(),out.end())),(char *)info.data,info.data_size);
#else
      file_util::WriteFile(base::FilePath(out),(char *)info.data,info.data_size);
#endif
    }
    return;
  } else if (method == "SetUserAgent") {
    nw::Package* package = shell->GetPackage();
    std::string user_agent;
    arguments.GetString(0,&user_agent);
    package->root()->GetString(switches::kmUserAgent, &user_agent);
    shell->web_contents()->SetUserAgentOverride(user_agent);
    return;
  } else if (method == "GetIdleTime") {
    result->AppendInteger(GetIdleTime());
    return;
  } else if (method == "GetScreens") {
    std::stringstream ret (std::stringstream::in | std::stringstream::out);
#if defined(OS_WIN)
    std::vector<MonitorDevice> devices = getMonitorInfo();
    for(size_t i=0; i < devices.size(); i++) {
      MonitorDevice device = devices[i];
      if(i==0) ret << "{"; else ret << ",{";

      ret << "\"bounds\":{\"x\":" << device.x << ", \"y\":" << device.y << ", \"width\":" << device.width << ", \"height\":" << device.height << "}";
      ret << ",\"workarea\":{\"x\":" << device.x_work << ", \"y\":" << device.y_work << ", \"width\":" << device.width_work << ", \"height\":" << device.height_work << "}";
      ret << ",\"colorDepth\":" << device.colorDepth;
      ret << ",\"scaleFactor\":" << 1;
      ret << ",\"isPrimary\":" << (device.isPrimary ? "true" : "false");
      ret << ",\"isMirrored\":" << (device.isMirror ? "true" : "false");
      ret << ",\"isBuiltIn\":" << ((!device.isRemovable) ? "true" : "false");
      ret << ",\"isAsleep\":" << (device.isDisabled ? "true" : "false");
      ret << ",\"isActive\":" << ((!device.isDisabled) ? "true" : "false");
      ret << "}";
    }
    result->AppendString("["+ret.str()+"]");

#elif defined(OS_MACOSX)
    int display_count = 0;
    CGDirectDisplayID online_displays[128];
    CGDisplayCount online_display_count = 0;

    if (CGGetOnlineDisplayList(arraysize(online_displays), online_displays, &online_display_count) != kCGErrorSuccess) {
        result->AppendString("[]");
        return;
    }

    for (CGDisplayCount online_display_index = 0; online_display_index < online_display_count; ++online_display_index)
    {
      CGDirectDisplayID online_display = online_displays[online_display_index];

      ++display_count;
      CGRect bounds = CGDisplayBounds(online_display);
      CGDisplayModeRef mode = CGDisplayCopyDisplayMode(online_display);
      int depth = 0;
      CFStringRef encoding = CGDisplayModeCopyPixelEncoding(mode);
      if (CFStringCompare(encoding, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) depth = 32;
      else if (CFStringCompare( encoding, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) depth = 16;
      else if(CFStringCompare( encoding, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) depth = 8;

      if(display_count==1) ret << "{"; else ret << ",{";

      ret << "\"bounds\":{\"x\":" << bounds.origin.x << ", \"y\":" << bounds.origin.y << ", \"width\":" << bounds.size.width << ", \"height\":" << bounds.size.height << "}";
      if(CGDisplayIsMain(online_display))
        ret << ",\"workarea\":{\"x\":" << bounds.origin.x << ", \"y\":" << (bounds.origin.y+22) << ", \"width\":" << bounds.size.width << ", \"height\":" << (bounds.size.height-22) << "}";
      else
        ret << ",\"workarea\":{\"x\":" << bounds.origin.x << ", \"y\":" << bounds.origin.y << ", \"width\":" << bounds.size.width << ", \"height\":" << bounds.size.height << "}";
      ret << ",\"colorDepth\":" << depth;
      ret << ",\"scaleFactor\":1,";
      ret << ",\"isPrimary\":" << (CGDisplayIsMain(online_display) ? "true" : "false");
      ret << ",\"isMirrored\":" << (CGDisplayIsInMirrorSet(online_display) ? "true" : "false");
      ret << ",\"isBuiltIn\":" << (CGDisplayIsBuiltin(online_display) ? "true" : "false");
      ret << ",\"isAsleep\":" << (CGDisplayIsAsleep(online_display) ? "true" : "false");
      ret << ",\"isActive\":" << (CGDisplayIsActive(online_display) ? "true" : "false");
      ret << "}";
      CFRelease(encoding);
      CGDisplayModeRelease(mode);
    }
    result->AppendString("["+ret.str()+"]");
#endif
    return;
  } else if (method == "GetArgv") {
    CommandLine* command_line = CommandLine::ForCurrentProcess();
    CommandLine::StringVector argv = command_line->original_argv();
    for (unsigned i = 1; i < argv.size(); ++i)
      result->AppendString(argv[i]);
    return;
  } else if (method == "Zip") { 
    std::string zipdir;
    std::string zipfile;
    arguments.GetString(0,&zipdir);
    arguments.GetString(1,&zipfile);
    result->AppendBoolean(zip::Zip(base::FilePath::FromUTF8Unsafe(zipdir), base::FilePath::FromUTF8Unsafe(zipfile), true));
    return;
  } else if (method == "Unzip") {
    std::string zipfile;
    std::string zipdir;
    arguments.GetString(0,&zipfile);
    arguments.GetString(1,&zipdir);
    result->AppendBoolean(zip::Unzip(base::FilePath::FromUTF8Unsafe(zipfile), base::FilePath::FromUTF8Unsafe(zipdir)));
    return;
  } else if (method=="Notify") {
	  std::string title;
	  std::string text;
	  std::string subtitle;
	  bool sound;
	  
	  arguments.GetString(0,&title);
	  arguments.GetString(1,&text);
	  arguments.GetString(2,&subtitle);
	  arguments.GetBoolean(3,&sound);
	  
	  shell->window()->Notify(title,text,subtitle,sound);
	  return;
  } else if (method == "Gzip") {
	  std::string ssrc = "";
	  std::string sdst = "";
    
	  arguments.GetString(0,&ssrc);
	  arguments.GetString(1,&sdst);

    FILE *src = fopen(ssrc.c_str(), "r");
    if(src==NULL) {
      DLOG(ERROR) << "Cannot open for read " << ssrc << " IO ERROR: " << strerror(0);
      result->AppendBoolean(false);
      return;
    }

    FILE *dst = fopen(sdst.c_str(), "a+"); // this must remain a+, not w+

    if(dst==NULL) {
      DLOG(ERROR) << "Cannot open for read/write/trunc " << ssrc << " IO ERROR: " << strerror(0);
      result->AppendBoolean(false);
      fclose(src);
      return;
    }

    SET_BINARY_MODE(src);
    SET_BINARY_MODE(dst);

    if(_defgzip(src,dst,Z_DEFAULT_COMPRESSION) == Z_OK)
      result->AppendBoolean(true);
    else
      result->AppendBoolean(false);

    fflush(dst);
    fclose(src);
    fclose(dst);
    return;
  } else if (method == "Ungzip") {
	  std::string ssrc;
	  std::string sdst;
	  unsigned char buffer[0x1000];
	  int bytes_read = 1, bytes_written = 1, eof = 0;
	  
	  arguments.GetString(0,&ssrc);
	  arguments.GetString(1,&sdst);
	
#if defined(OS_WIN)
    int src;
    int dst;
    _sopen_s(&src,ssrc.c_str(), _O_RDONLY, _SH_DENYNO, _S_IREAD);
	  _sopen_s(&dst,sdst.c_str(), _O_WRONLY|_O_CREAT|_O_TRUNC, _SH_DENYNO, _S_IWRITE);
#else
	  int src = open(ssrc.c_str(), O_RDONLY);
	  int dst = open(sdst.c_str(), O_WRONLY|O_CREAT|O_TRUNC,S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
#endif
	  gzFile zSrc = gzdopen(src, "r");
	  if(gzbuffer(zSrc, 0x1000)==-1) {
		  result->AppendBoolean(false);
		  return;
	  }
	  
	  if(zSrc == NULL || dst == -1) {
		  result->AppendBoolean(false);
		  return;
	  }
	  
	  while(eof == 0 &&
			bytes_read > 0 &&
			bytes_written > 0) {
		  bytes_read = gzread(zSrc,&buffer,0x1000);
#if defined(OS_WIN)
		  bytes_written = _write(dst,&buffer,bytes_read);
#else
		  bytes_written = write(dst,&buffer,bytes_read);
#endif
		  eof = gzeof(zSrc);
	  }
#if defined(OS_WIN)
	  _close(dst);
#else
	  close(dst);
#endif
	  gzclose(zSrc);
	  result->AppendBoolean(eof==1);
	  return;
  } else if (method == "ClearCache") {
    ClearCache(GetRenderProcessHost());
    return;
  } else if (method == "GetPackage") {
    result->AppendString(shell->GetPackage()->package_string());
    return;
  } else if (method == "SetCrashDumpDir") {
    std::string path;
    arguments.GetString(0, &path);
    result->AppendBoolean(SetCrashDumpPath(path.c_str()));
    return;
  }

  NOTREACHED() << "Calling unknown sync method " << method << " of App";
}

// static
void App::CloseAllWindows(bool force) {
  std::vector<Shell*> windows = Shell::windows();

  for (size_t i = 0; i < windows.size(); ++i) {
    // Only send close event to browser windows, since devtools windows will
    // be automatically closed.
    if (!windows[i]->is_devtools()) {
      // If there is no js object bound to the window, then just close.
      if (force || windows[i]->ShouldCloseWindow())
        // we used to delete the Shell object here
        // but it should be deleted on native window destruction
        windows[i]->window()->Close();
    }
  }
  if (force) {
    // in a special force close case, since we're going to exit the
    // main loop soon, we should delete the shell object asap so the
    // render widget can be closed on the renderer side
    windows = Shell::windows();
    for (size_t i = 0; i < windows.size(); ++i) {
      if (!windows[i]->is_devtools())
        delete windows[i];
    }
  }
}

// static
void App::Quit(RenderProcessHost* render_process_host) {
  // Send the quit message.
  int no_use;
  if (render_process_host) {
    render_process_host->Send(new ViewMsg_WillQuit(&no_use));
  }else{
    std::set<RenderProcessHost*> rphs;
    std::set<RenderProcessHost*>::iterator it;

    GetRenderProcessHosts(rphs);
    for (it = rphs.begin(); it != rphs.end(); it++) {
      RenderProcessHost* rph = *it;
      DCHECK(rph != NULL);

      rph->Send(new ViewMsg_WillQuit(&no_use));
    }
    CloseAllWindows(true);
  }
  // Then quit.
  MessageLoop::current()->PostTask(FROM_HERE, MessageLoop::QuitClosure());
}

// static
void App::EmitOpenEvent(const std::string& path) {
  std::set<RenderProcessHost*> rphs;
  std::set<RenderProcessHost*>::iterator it;

  GetRenderProcessHosts(rphs);
  for (it = rphs.begin(); it != rphs.end(); it++) {
    RenderProcessHost* rph = *it;
    DCHECK(rph != NULL);

    rph->Send(new ShellViewMsg_Open(path));
  }
}

// static
void App::EmitReopenEvent() {
  std::set<RenderProcessHost*> rphs;
  std::set<RenderProcessHost*>::iterator it;

  GetRenderProcessHosts(rphs);
  for (it = rphs.begin(); it != rphs.end(); it++) {
    RenderProcessHost* rph = *it;
    DCHECK(rph != NULL);

    rph->Send(new ShellViewMsg_Reopen());
  }
}

void App::ClearCache(content::RenderProcessHost* render_process_host) {
  render_process_host->Send(new ShellViewMsg_ClearCache());
  nw::RemoveHttpDiskCache(render_process_host->GetBrowserContext(),
                          render_process_host->GetID());
}

}  // namespace nwapi
