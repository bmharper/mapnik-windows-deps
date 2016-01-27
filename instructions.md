
The following instructions are for building Mapnik 64-bit with Visual Studio 2013 (aka msvc-120, aka version 12.0).
I tried to compile on VS 2015, but ICU 5.6 (and 4.8) both failed with a lot of errors. On VS 2013 however, ICU
compiles out of the box.

The following instructions are for building Mapnik 64-bit with Visual Studio 2015 (aka msvc-140, aka version 14.0).

* Install CMake 2.8.8 or higher (for libjpeg-turbo, which needs version 2.8 or higher)

* Open icu\source\allinone\allinone.sln and allow VS to upgrade the project.
Switch to Release, x64.
Remove the /Za (C++, Language, Disable Language Extensions) switch from all projects that fail to compile.
Build Solution.

* Run build-windows-deps.bat

# Notes

Patched postgres with postgres_workaround_for_msvc2015_issue_v2.patch, which is necessary for building on VS 2015.
