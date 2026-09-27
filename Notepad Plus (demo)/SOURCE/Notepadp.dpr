program Notepadp;

uses
  Forms,
  About in 'ABOUT.PAS' {AboutBox},
  Main in 'Main.pas' {FrmMain};

{$R *.RES}
begin
  Application.Title := 'Notepad Plus';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
