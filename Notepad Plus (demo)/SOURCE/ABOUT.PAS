unit About;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TBitBtn;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

uses Main;
{$R *.DFM}

procedure TAboutBox.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:= caFree
end;

procedure TAboutBox.FormShow(Sender: TObject);
begin
  Version.Caption:= 'Version ' + FrmMain.PlusMemo1.Version
end;

end.
