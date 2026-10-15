program ConfigPlusMemo;

{$APPTYPE CONSOLE}

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
  SR: TSearchRec;
  FileExt: string;

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
      ExitCode := 1;
      Exit;
    end;

    FileContent := TStringList.Create;
    try
      { 4. Iterate through all file parameters provided }
      for I := 2 to ParamCount do
      begin
        FileParam := ParamStr(I);
        BaseDir := ExtractFilePath(FileParam);

        if FindFirst(FileParam, faAnyFile - faDirectory, SR) = 0 then
        begin
          try
            repeat
              FilePath := BaseDir + SR.Name;
              FileExt := LowerCase(ExtractFileExt(FilePath));

              { 5. Filter for .dproj and .dpk files only }
              if (FileExt = '.dproj') or (FileExt = '.dpk') then
              begin
                ProcessFile(FilePath, ReplacementStr, FileContent);
              end
              else
              begin
                { 6. Log skipped files with the updated specific reason }
                Writeln('Skipped (only processing .dpk and .dproj files): ', FilePath);
              end;

            until FindNext(SR) <> 0;
          finally
            FindClose(SR);
          end;
        end;
      end;
    finally
      FileContent.Free;
    end;

  except
    on E: Exception do
    begin
      Writeln('An unexpected error occurred: ', E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
