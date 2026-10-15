PlusMemo by Electro-Concept Mauricie and Raymond Courteau used to be a commercial product but is now FREE!  The license is the extremely open MIT license.


PlusMemo is the coolest enhanced memo edit control for Delphi 2007 on up. Native VCL component, in standard and data aware versions, with the following main features:


* Automatic syntax highlighting: keywords, comments and custom syntaxing algorithms. You won't believe how simple it is to automatically and dynamically format your keywords!
* Rich set of free accessory components : gutter with line numbers, printer component with preview capability, live spell checker that works with Addict Spell Check, Url highlighter, Html highlighter, ...
* Mix any font style or background/foreground colors for parts of your text, and use two different fonts at your liking;
* No limit on text length. Handle 100MB easily on minimal systems
* Plus much more: multi-level Undo/Redo, drag and drop editing, text justification, column block selection, various properties and methods to interact at run time with the text content
* Not a true RTF component, but has RTF-like capabilities and can export RTF and HTML files.


User docs are available online here:
https://www.ecmqc.com/plusmemo/Docs/Content.html
I have also provided a .CHM file, and a PDF file in the DOCUMENTATION folder.


Within the SOURCE folder, you should find group projects:


"Delphi 2007 to XE.groupproj"		For Delphi versions from Delphi 2007 to Delphi XE
(base package name PlsMem)
"Delphi XE2 to 10dot3.groupproj"	For Delphi versions XE2 to Delphi 10.3 Rio
(base package name PMemo7)
"Delphi 10dot4 Up.groupproj"		For All versions from Delphi 10.4 Sydney on up
(base package name PlusMemo)


NOTE:  So that all three sets of packages can live in the same SOURCE folder, they have slightly different base package names.


In the SOURCE folder you will also find the associated .dpk and .dproj files for design and runtime packages.  And of the rest of the source files.  Note that the last one, "Delphi 10dot4 Up.groupproj" should work with all versions of Delphi 10.4 Sydney on up, including future versions unless Embarcadero makes a code-breaking change.


Notice that I'm not including .dpk, .dproj files for every version of Delphi.  I'm just including three sets of them.  For Delphi 10.4 and later, I use LIBSUFFIX AUTO, and the .dpk, .dproj files automatically work.


For the earlier compilers, LIBSUFFIX AUTO didn't exit. I put in the .dpk, and .dproj files placeholders of ????. You could just open the packages in your version of Delphi and update the LIBSUFFIX using the IDE.  But I decided to make it slightly easier for you and provided a simple command-line utility that will configure them for you.  You need to pick an appropriate LIBSUFFIX for your version of Delphi. For example, if you are using Delphi2007, you might use D2007 for your LIBSUFFIX.  In that case, use this command-line command:


ConfigPlusMemo D2007 PlsMem*.*


For Delphi XE2 to 10.3 Rio, the package base name is PMemo7.  So for example, to configure the packages for XE2, use this command:


ConfigPlusMemo XE2 PMemo7*.*


Note that I also included the source for the ConfigPlusMemo utility.  I compiled it with D2007 to keep the .EXE file small.  The suffix itself is arbitrary so long as it is unique for every version of Delphi that you have installed.  But using something appropriate for the compiler version is recommended.  As noted, when using 10.4 Sydney or later, it will pick the LIBSUFFIX automatically and you don't need to do this.


Once you open the groupproj for your version of Delphi, you should find four projects. The primary runtime project, the primary design-time project, a supplemental DB runtime project and a supplemental DB design-time project.  In PlusMemo 7.2 and earlier, the DB component wasn't even a standard install, you had to manually add it yourself if you wanted it.  Therefore, I don't think many people ever used it.  You can choose to install the DB packages or not.


The installation is dead simple.  Just compile the runtime package(s) as 32-bit and/or 64-bit as you require.  Then compile and install the design-time package(s).  The 64-bit design-time packages requires a 64-bit IDE, which requires Delphi 12.3 or later.  While, naturally, you can install the 32-bit design-time packages into the 32-bit IDE.


(Note specifically for Sydney:  In 10.4.0, the IDE did not understand the $LIBSUFFIX AUTO option, but the compiler did. So, it should work.  But the 10.4.0 IDE might make errors in the package files if you save them within the IDE.  I would suggest consider getting the 10.4.1 or 10.4.2 update that has full $LIBSUFFIX AUTO support and other fixes unless you have some reason not to.)


For even older versions of Delphi, see the "Legacy-7.2" folder. 


Note that the compiled output (.DCU files, etc.) will be different for different versions of Delphi, C++ Builder. So it is advisable to use different directories for different Delphi versions.


Note that when you install PlusMemo, the Delphi IDE will want to update the .dproj files to the version of Delphi that you are using.  Therefore I put extra copies of the package project files (*.dpk, *.dproj, *.groupproj) into the "Packages - backups" just for possible convenience.


There are files related to the Addict spell check component.  PMLiveSpell4, PMLiveSpellReg, ad4PlusMemoParser and adLiveSpellCheck4.  I've never used Addict and I believe it is discontinued.  They are not included in the PlusMemo packages by default.  Add them if you need them.  There is an open-source spell check component known as Hunspell which I've never used either.  Perhaps it can be integrated into PlusMemo but I have no experience.


Once installed, you might want to build the demo application in the "Notepad Plus (demo)" folder and experiment with it.
