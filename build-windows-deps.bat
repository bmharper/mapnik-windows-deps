@echo off
set ROOTDIR=%~dp0
set ROOTDIR=%ROOTDIR:~0,-1%
set OUTDIR=%ROOTDIR%\output\x64
set CYGWIN_BIN=C:\cygwin64\bin
mkdir %OUTDIR%

rem ######### Config #########

rem >>>> Visual Studio 2013 <<<<
rem set BOOST_MSVC_VER=msvc-12.0
rem call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
rem set CMAKE_MSVC_VER=Visual Studio 12 2013 Win64

rem >>>> Visual Studio 2015 <<<<
set BOOST_MSVC_VER=msvc-14.0
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
set CMAKE_MSVC_VER=Visual Studio 14 2015 Win64

rem ######### icu #########
:icu
copy /y icu\lib64\icudt.lib %OUTDIR%
copy /y icu\lib64\icuin.lib %OUTDIR%
copy /y icu\lib64\icuio.lib %OUTDIR%
copy /y icu\lib64\icule.lib %OUTDIR%
copy /y icu\lib64\iculx.lib %OUTDIR%
copy /y icu\lib64\icutu.lib %OUTDIR%
copy /y icu\lib64\icuuc.lib %OUTDIR%
copy /y icu\bin64\icudt56.dll %OUTDIR%
copy /y icu\bin64\icuin56.dll %OUTDIR%
copy /y icu\bin64\icuio56.dll %OUTDIR%
copy /y icu\bin64\icule56.dll %OUTDIR%
copy /y icu\bin64\iculx56.dll %OUTDIR%
copy /y icu\bin64\icutu55.dll %OUTDIR%
copy /y icu\bin64\icuuc56.dll %OUTDIR%

rem ######### Boost #########
:boost
rem I initially tried to clone https://github.com/boostorg/boost and then clone it's relevant submodules, but that
rem ended when I couldn't figure out why my "boost" subdirectory there seemed to be missing a lot of files.
rem So.. I just ended up using the downloaded .zip package of Boost 1.60.0
cd boost
call bootstrap
bjam toolset=%BOOST_MSVC_VER% --prefix=..\\boost-output --with-thread --with-filesystem --with-date_time --with-system --with-program_options --with-regex --with-chrono --disable-filesystem2 -sHAVE_ICU=1 -sICU_PATH=%ROOTDIR%\icu -sICU_LINK=%ROOTDIR%\icu\lib64\icuuc.lib release link=static install --build-type=complete
cd %ROOTDIR%
goto :eof

rem ######### webp #########
:webp
cd webp
nmake /f Makefile.vc CFG=release-static RTLIBCFG=static OBJDIR=output
copy /y output\release-static\x64\lib\libwebp.lib %OUTDIR%
cd %ROOTDIR%

rem ######### jpeg #########
:jpeg
cd jpeg
cmake -G "%CMAKE_MSVC_VER%"
msbuild jpeg-static.vcxproj /t:Build /p:Configuration=Release
copy /y release\jpeg-static.lib %OUTDIR%
cd %ROOTDIR%

rem ######### freetype #########
:freetype
cd freetype
mkdir build
cd build
cmake -G "%CMAKE_MSVC_VER%" ..
msbuild freetype.vcxproj /t:Build /p:Configuration=Release
copy /y Release\freetype.lib %OUTDIR%
cd %ROOTDIR%

rem ######### zlib #########
:zlib
cd zlib\contrib\masmx64
call bld_ml64.bat
cd ..\..
msbuild contrib\vstudio\vc12\zlibstat.vcxproj /t:Build /p:Configuration=Release
copy /y contrib\vstudio\vc12\x64\ZlibStatRelease\zlibstat.lib %OUTDIR%
cd %ROOTDIR%

rem ######### png #########
:png
cd png
cl /c /MP /I..\zlib /Ox /MD /GS png.c pngerror.c pngget.c pngmem.c pngpread.c pngread.c pngrio.c pngrtran.c pngrutil.c pngset.c pngtrans.c pngwio.c pngwrite.c pngwtran.c pngwutil.c 
lib /OUT:%OUTDIR%\png.lib png.obj pngerror.obj pngget.obj pngmem.obj pngpread.obj pngread.obj pngrio.obj pngrtran.obj pngrutil.obj pngset.obj pngtrans.obj pngwio.obj pngwrite.obj pngwtran.obj pngwutil.obj
cd %ROOTDIR%

rem ######### libpq #########
:libpq
rem The following error is normal:
rem NMAKE : fatal error U1073: don't know how to make 'libpq-dist.rc'
rem So long as you have libpq.lib, the build is satisfactory for us.
cd postgres\src\interfaces\libpq
nmake -f win32.mak
copy /y Release\libpq.lib %OUTDIR%
cd %ROOTDIR%

rem ######### pixman #########
:pixman
cd pixman
rem Makefile.win32:  MMX_VAR=off
make -f Makefile.win32 "CFG=release"
copy /y pixman\release\pixman-1.lib %OUTDIR%
cd %ROOTDIR%

rem ######### cairo #########
:cairo
cd cairo
rem Makefile.win32.features: CAIRO_HAS_FT_FONT=1
rem Makefile.win32.common:   CAIRO_LIBS += $(OUTDIR)/zlibstat.lib
rem                          CAIRO_LIBS += $(OUTDIR)/freetype.lib 
rem                          LIBPNG_PATH := $(top_builddir)/../png
rem                          CAIRO_LIBS += $(OUTDIR)/png.lib
set OLD_INCLUDE=%INCLUDE%
set INCLUDE=%INCLUDE%;%ROOTDIR%\zlib
set INCLUDE=%INCLUDE%;%ROOTDIR%\png
set INCLUDE=%INCLUDE%;%ROOTDIR%\pixman\pixman
set INCLUDE=%INCLUDE%;%ROOTDIR%\cairo\boilerplate
set INCLUDE=%INCLUDE%;%ROOTDIR%\cairo
set INCLUDE=%INCLUDE%;%ROOTDIR%\cairo\src
set INCLUDE=%INCLUDE%;%ROOTDIR%\freetype\include
%CYGWIN_BIN%\make -f Makefile.win32 "CFG=release"
set INCLUDE=%OLD_INCLUDE%
copy /y src\release\cairo.dll %OUTDIR%
copy /y src\release\cairo.lib %OUTDIR%
cd %ROOTDIR%

rem ######### libxml2 #########
:libxml2
cd libxml2\win32
cscript configure.js compiler=msvc prefix=%ROOTDIR%\libxml2 iconv=no icu=yes include=%ROOTDIR%\icu\include lib=%OUTDIR%
rem Makefile.msvc: LIBS = $(LIBS) icuuc.lib
nmake /f Makefile.msvc
copy /y bin.msvc\libxml2.dll %OUTDIR%
copy /y bin.msvc\libxml2.lib %OUTDIR%
cd %ROOTDIR%

rem ######### proj4 #########
:proj4
copy /y proj4-grids\* proj4\nad
cd proj4
nmake /f makefile.vc
copy /y src\proj.lib %OUTDIR%
cd %ROOTDIR%

