# cmd_global_functions
In my line of work I had to use some general functions quite often, so I put some of those in one file and use it as a function.

Two of the functions (getdate and datemath) were taken from ss64.com and are used to get a date in a desired format without depending on regional settings and also calculate dates (useful for getting previous business date or stuff like that).

PKZIPC and Tectia checks are functions to check for existence of proper software and use them properly. Doubt anyone will require those, but who knows.

Makemisdir and copyfile create missing directories and copy files. Yeah, simple, but functions has some extra output if you want that.

The most interesting function here is "choice". When we were migrating to Windows 7 we had issues becuase of old choice.com utillity used in Windows XP. It did not work in Windows 7 because it was 16-bit and company's build was 64-bit. Also Windows 7 has its own choice function integrated, but that does not work in Windows XP. Thus I wrote an alternative, which worked in both systems. It's not as versatile as Windows 7 version, but can be used if you need a system independent alternative.

At the bottom of the code there is some help and details on how to use this code.
