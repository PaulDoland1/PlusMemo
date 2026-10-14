program ConfigPlusMemo;

{$APPTYPE CONSOLE}
{$SetPEFlags 1} // Keeps size around 90KB by stripping relocation data

uses
  SysUtils,
  Classes;

{ Processes an individual file, replacing '????' with the replacement string }
procedure ProcessFile(const FilePath, ReplacementStr: string; FileContent: TStringList);
var
  OriginalText: string;
  ModifiedText: string;
begin
  try
    FileContent.LoadFromFile(FilePath);
    OriginalText := FileContent.Text;

    // Replace four consecutive question marks with the replacement string
    ModifiedText := StringReplace(OriginalText, '????', ReplacementStr, [rfReplaceAll]);

    // Only write to disk if a change actually occurred
    if OriginalText <> ModifiedText then
    begin
      FileContent.Text := ModifiedText;
      FileContent.SaveToFile(FilePath);
      Writeln('Updated: ', FilePath);
    end
    else
    begin
      Writeln('Skipped (no "????" found): ', FilePath);
    end;
  except
    on E: Exception do
      Writeln('Error processing file (', FilePath, '): ', E.Message);
  end;
end;

var
  ReplacementStr: string;
  FileParam: string;
  BaseDir: string;
  FilePath: string;
  FileContent: TStringList;
  I: Integer;
  UserResponse: string;
  SR: TSearchRec;
  FilesFound: Boolean;

begin
  try
    { 1. Validate that we have enough arguments }
    if ParamCount < 2 then
    begin
      Writeln('ConfigPlusMemo Error: Missing arguments.');
      Writeln('Usage: ConfigPlusMemo <replacement_string> <file_spec1> [file_spec2 ...]');
      ExitCode := 1;
      Exit;
    end;

    { 2. Get the replacement string }
    ReplacementStr := ParamStr(1);

    { 3. Safety Check: Did they pass a filename as the string? }
    if FileExists(ReplacementStr) then
    begin
      Writeln('ConfigPlusMemo Error: It looks like you forgot to provide the substitution string!');
      Writeln('The first argument "', ReplacementStr, '" is an existing file.');
      Writeln('Aborting to protect your files from accidental corruption.');
      ExitCode := 1;
      Exit;
    end;

    { 4. Interactive Confirmation Prompt }
    Write('Set package suffix to: "', ReplacementStr, '"? Confirm Y/N: ');
    Readln(UserResponse);

    { Check user response (Handles 'n', 'N', or completely empty inputs) }
    UserResponse := UpperCase(Trim(UserResponse));
    if (UserResponse <> 'Y') and (UserResponse <> 'YES') then
    begin
      Writeln('Operation cancelled by user.');
      ExitCode := 0;
      Exit;
    end;

    Writeln; // Clear line for readability

    { 5. Process files and wildcards once confirmed }
    FileContent := TStringList.Create;
    try
      for I := 2 to ParamCount do
      begin
        FileParam := ParamStr(I);
        BaseDir := ExtractFilePath(FileParam);
        FilesFound := False;

        { Find all files matching the criteria (supports literals or wildcards like *.dpk) }
        if FindFirst(FileParam, faAnyFile and not faDirectory, SR) = 0 then
        begin
          try
            repeat
              FilesFound := True;
              FilePath := BaseDir + SR.Name;
              ProcessFile(FilePath, ReplacementStr, FileContent);
            until FindNext(SR) <> 0;
          finally
            FindClose(SR);
          end;
        end;

        if not FilesFound then
        begin
          Writeln('Skipping (no files matched specification): ', FileParam);
        end;
      end;

    finally
      FileContent.Free;
    end;

  except
    on E: Exception do
    begin
      Writeln('An unexpected error occurred: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.

