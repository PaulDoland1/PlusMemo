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


You will also find the associated .dpk and .dproj files for design and runtime packages.  And of the rest of the source files.  Note that the last one, "Delphi 10dot4 Up.groupproj" should work with all versions of Delphi 10.4 Sydney on up, including future versions unless Embarcadero makes a code-breaking change.  Open the appropriate groupproj for your version of Delphi.  Compile the runtime package as 32-bit and/or 64-bit as you require.  Then compile the design-time package as 32-bit and/or 64-bit as you require.  You can install the 32-bit design-time package into a 32-bit IDE.  You can install the 64-bit design-time package into a 64-bit IDE.  This requires Delphi 12.3 or later.


The procedure is almost the same for the older versions of Delphi.  But you have to do one additional step.  When you open "Delphi 2006 to XE.groupproj" or "Delphi XE2 to 10dot3.groupproj" you will see the names of the packages as "PMemo7Run????" and "PMemo7Des????".  Go to the project options for PMemo7Run????.bpl.  Go to Description.  Delete "????" from "LIB Suffix".  Select Target as All Configurations.  Set "LIB Suffix" to something appropriate for your version of Delphi. For example, if you are running Delphi 2009, a good choice would be "D2009".  You should see the package name change to PMemo7Run.bpl.  Repeat this procedure for PMemo7Des.bpl.  


(Note specifically for Sydney:  In 10.4.0, the IDE did not understand the $LIBSUFFIX AUTO option, but the compiler did. So, it should work.  But the 10.4.0 IDE might make errors in the package files if you save them within the IDE.  I would suggest consider getting the 10.4.1 or 10.4.2 update that has full $LIBSUFFIX AUTO support and other fixes unless you have some reason not to.)


(NOTE:  So that all three sets of packages can live in the same SOURCE folder, they have slightly different base package names.)

For even older versions of Delphi, see the "Legacy-7.2" folder. 


Note that the compiled output (.DCU files, etc.) will be different for different versions of Delphi, C++ Builder. So it is advisable to use different directories for different Delphi versions.


Note that when you install PlusMemo, the Delphi IDE will want to update the .dproj files to the version of Delphi that you are using.  Therefore I put extra copies of the package project files into the "Packages - backups" just for possible convenience.


The default installation does NOT include the DB-aware version of PlusMemo. I don't know if many people use it.  It was always left out of the default install so I left it out also.  If you want to use it, add PlusDb.pas to the runtime package and PlusDbReg.pas to the design-time package.  The IDE will tell you it needs to add some DB related packages.


There are files related to the Addict spell check component.  PMLiveSpell4, PMLiveSpellReg, ad4PlusMemoParser and adLiveSpellCheck4.  I've never used Addict and I believe it is discontinued.  They are not included in the PlusMemo packages by default.  Add them if you need them.  There is an open-source spell check component known as Hunspell which I've never used either.  Perhaps it can be integrated into PlusMemo but I have no experience.


Once installed, you might want to build the demo application in the "Notepad Plus (demo)" folder and experiment with it.
