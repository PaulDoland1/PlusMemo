In the "packages - backups" folder, you will find:

1. Generic packages PlusMemo, PlusMemo64.  Same as the ones in the SOURCE folder.  These are backups.
   These are intended for use with 10.4 Sydney and later. Even future versions.

2. Version-specific packages for Delphi 2006 through 10.3 Rio.  Ex: PMemo7Berlin
   To use, copy the correct ones for your copy of Delphi into the SOURCE folder.

Here in this folder, you will find Alternative generic packages: PMemo7.dpk, PMemo7_64.dpk
These should work with any version of Delphi, from Delphi 2006 on up. You just need to do the
following:

   a.  Copy PMemo7.dpk and/or PMemo7_64.dpk into the SOURCE folder.
   b.  Open the package in your version of Delphi.
   c.  Go to the project properties and find the Lib Suffix option.  
       (It is in different places in different versions)
   d.  Set the Lib Suffix to something appropriate for the version of Delphi you are using.
       Ex:  For Delphi 2006, you could set the Lib Suffix to D2006
       For versions of Delphi 10.4.1 Sydney or later, you could use $(AUTO) and that would
       be effectively the same thing as the PlusMemo, PlusMemo64 generic packages I provided.

For years, the packages have been named PMemo7xxx.  Using the $AUTO option creates bpl files
named something like PMemo70370.bpl.  I didn't like that, which is why I renamed them to
PlusMemo, so it now generates package names like PlusMemo0370. Ultimately it doesn't matter,
I just didn't like it.  But I chose to use the old name PMemo7 here because that was what
was always used in the old days.

I considered just these alternative generic packages which work with anything instead of the
other packages.  But I decided to give you all the options and let you decide. Should be effectively
the same.
