PlusMemo by Electro-Concept Mauricie and Raymond Courteau used to be a commercial product but is now FREE!  The license is the extremely open MIT license.

PlusMemo is the coolest enhanced memo edit control for Delphi 2009 on up. Native VCL component, in standard and data aware versions, with the following main features:

* Automatic syntax highlighting: keywords, comments and custom syntaxing algorithms. You won't believe how simple it is to automatically and dynamically format your keywords!
* Rich set of free accessory components : gutter with line numbers, printer component with preview capability, live spell checker that works with Addict Spell Check, Url highlighter, Html highlighter, ...
* Mix any font style or background/foreground colors for parts of your text, and use two different fonts at your liking;
* No limit on text length. Handle 100MB easily on minimal systems
* Plus much more: multi-level Undo/Redo, drag and drop editing, text justification, column block selection, various properties and methods to interact at run time with the text content

User docs are available online here:
https://www.ecmqc.com/plusmemo/Docs/Content.html
I have also provided a .CHM file, and a PDF file in the DOCUMENTATION folder.

Within the SOURCE folder, there are packages PlusMemo and PlusMemo64.  These should install in any version of Delphi or C++ Builder, 10.4 Syndey or later for either 32 bit or 64 bit.  It has been tested up to Delphi 13 Florence but the packages are designed to hopefully install in future versions as well unless Embarcadero makes a code-breaking change.

Thus it should just be a matter of opening the included PlusMemo.dproj or PlusMemo64.dproj from the SOURCE folder into any version of Delphi 10.4 Sydney or later and compiling. Then add the SOURCE directory to your library search in Delphi/C++ Builder.

(Note specifically for Sydney:  In 10.4.0, the IDE did not understand the $LIBSUFFIX AUTO option, but the compiler did. So, it should work.  But unless you have a reason not to, you should consider getting the 10.4.1 or 10.4.2 update that has full $LIBSUFFIX AUTO support and other fixes)

For versions from D2009 to 10.3 Rio, you will find old-style project files for each version of Delphi in the “Packages – backups” folder. Copy the version for your compiler from into the SOURCE folder.  Open that package into your version of Delphi and install.  Add the SOURCE folder to your library path.

For versions even older than D2009, packages are not provided.  But you probably can build the packages yourself.  The Pascal code should be compatible as far back as Delphi 6.

Note that the compiled output (.DCU files, etc.) will be different for different versions of Delphi, C++ Builder. So it is advisable to use different directories for different Delphi versions. The same is true if you use both 32 bit and 64 bit and the compiled output is different.

Note that when you install PlusMemo, the Delphi IDE will want to update the PlusMemo.dproj and PlusMemo64.dproj files to the version of Delphi that you are using.  Therefore I put extra copies of the PlusMemo and PlusMemo64 project files into the "Packages - backups" just for possible convenience.

The default installation does NOT include the DB-aware version of PlusMemo. I don't know if many people use it.  But it exists. According to Raymond, to use the DB-aware version, you just need to add Plusdb.pas and Plusdb.dcr to the packages. But you also need to add some of the Delphi DB packages and for some reason I had trouble with that.  So I just left them out like Raymond did.  I may try to revisit this in the future if requested.

Once installed, you might want to build the demo application in the Notepad Plus (demo)" folder and experiment with it.

