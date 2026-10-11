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


You will also find the associated .dpk and .dproj files for design and runtime packages.  And of the rest of the source files.  Note that the last one, "Delphi 10dot4 Up.groupproj" should work with all versions of Delphi 10.4 Sydney on up, including future versions unless Embarcadero makes a code-breaking change.  Open the appropriate groupproj for your version of Delphi.


Once you open the groupproj, you should find four projects. The primary runtime project, the primary design-time project, a supplemental DB runtime project and a supplemental DB design-time project.  In 7.2 and earlier, the DB component wasn't even a standard install, you had to manually add it yourself if you wanted it.  Therefore, I don't think many people ever used it.  You can choose to install the DB packages or not.


The installation is dead simple.  Just compile the runtime package(s) as 32-bit and/or 64-bit as you require.  Then compile and install the design-time package(s).  The 64-bit design-time packages requires a 64-bit IDE, which requires Delphi 12.3 or later.  While, naturally, you can install the 32-bit design-time packages into the 32-bit IDE.


Note that with some older compilers, you might get an erroneous error that the package can't be found.  So that I don't have to have packages for every version of Delphi, I have coding in the .dpk and .dproj files that set the LIBSUFFIX based on compiler version.  And while it seems to in fact work with all versions of Delphi 2007 up, the earlier ones might generate an erroneous error. You can simply manually go to the Components menu option, install packages, and add the design BPLs.  Embarcadero made dealing with different versions of Delphi easier with the LIBSUFFIX AUTO option added in 10.4 Sydney. (It seems as if the build process for the older compilers is ignoring my PM_compilers.props file.  Or maybe I have that file coded wrong.  If I can figure it out, then we won't get the erroneous errors anymore.  In the meantime, you can ignore them and manually install the design packages.)


(Note specifically for Sydney:  In 10.4.0, the IDE did not understand the $LIBSUFFIX AUTO option, but the compiler did. So, it should work.  But the 10.4.0 IDE might make errors in the package files if you save them within the IDE.  I would suggest consider getting the 10.4.1 or 10.4.2 update that has full $LIBSUFFIX AUTO support and other fixes unless you have some reason not to.)


(NOTE:  So that all three sets of packages can live in the same SOURCE folder, they have slightly different base package names.)


For even older versions of Delphi, see the "Legacy-7.2" folder. 


Note that the compiled output (.DCU files, etc.) will be different for different versions of Delphi, C++ Builder. So it is advisable to use different directories for different Delphi versions.


Note that when you install PlusMemo, the Delphi IDE will want to update the .dproj files to the version of Delphi that you are using.  Therefore I put extra copies of the package project files into the "Packages - backups" just for possible convenience.


There are files related to the Addict spell check component.  PMLiveSpell4, PMLiveSpellReg, ad4PlusMemoParser and adLiveSpellCheck4.  I've never used Addict and I believe it is discontinued.  They are not included in the PlusMemo packages by default.  Add them if you need them.  There is an open-source spell check component known as Hunspell which I've never used either.  Perhaps it can be integrated into PlusMemo but I have no experience.


Once installed, you might want to build the demo application in the "Notepad Plus (demo)" folder and experiment with it.
