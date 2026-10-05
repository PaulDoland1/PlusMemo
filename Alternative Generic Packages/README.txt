In the "packages - backups" folder, you will find:

1. Generic package PlusMemo.dpk, .dproj.  They are same as in the SOURCE folder.
   These are backups.  These are intended for use with 10.4 Sydney and later.
   Even future versions!

2. Version-specific packages for Delphi 2006 through 10.3 Rio.  Ex: PMemo7Berlin
   To use, copy the correct ones for your copy of Delphi into the SOURCE folder.

Here in this folder, you will find an alternative generic packages: PMemo7.dpk, 
PlusMemo.dpk. They should work with any version of Delphi, from Delphi 2006 on up. 
They are identical except the name. For years, the packages have been named
PMemo7xxx. Using the $AUTO option creates bpl files named something like 
PMemo70370.bpl. I didn't like that, which is why I renamed my new generic
packages to PlusMemo.  Now generates package names like PlusMemo0370. Ultimately
it doesn't matter, I just preferred PlusMemo.  So here, I put both names, use
whichever you prefer.

So to use either of these with any version of Delphi, Delphi 2006 on up, you
just need to do the following:

   a.  Copy PMemo7.dpk or PlusMemo.dpk into the SOURCE folder.
   b.  We are rebuilding the .dproj file from scratch.  Delete PlusMemo.dproj from the SOURCE folder.
   c.  Open the package in your version of Delphi.
   d.  If your compiler supports 64-bit and you want to use 64-bit, add 64-bit platform.
   e.  Go to the project properties and find the Lib Suffix option.  
       (It is in different places in different versions)
   f.  Set the Lib Suffix to something appropriate for the version of Delphi you are using.
       Ex:  For Delphi 2006, you could set the Lib Suffix to D2006
       For versions of Delphi 10.4.1 Sydney or later, you could use $(AUTO) and that would
       be effectively the same thing as the PlusMemo generic packages I provided.
   g.  If using 64-bit, set the Lib Suffix for both 32-bit and 64-bit.
   h.  Go to project options, Delphi compiler.  Set unit output directory to:
       .\$(Platform)\$(Config)
   i.  Do this for both 32-bit and 64-bit if you are using both.
   j.  Compile. You can install the 32-bit into 32-bit IDE and the 64-bit into 64-bit IDE.

I considered just these alternative generic packages which work with anything
instead of the other packages.  But I decided to give you all the options and
let you decide. Should be effectively the same.
