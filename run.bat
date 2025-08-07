cls
del arp_function.exe
cl arp_function.cpp /Fe:my_dpi.dll /LD /W0 ^
 /I "C:\Users\wasee\AppData\Local\Programs\Python\Python313\include" ^
 /I "%MTI_HOME%\include" ^
 /link /LIBPATH:"C:\Users\wasee\AppData\Local\Programs\Python\Python313\libs" ^
 python313.lib "%MTI_HOME%\win64\mtipli.lib"
vsim -c -do run.do