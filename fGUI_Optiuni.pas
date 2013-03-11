unit fGUI_Optiuni;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, smslabel, ExtCtrls, sPanel, sEdit, fMyLib, sCheckBox,
  sButton;

type
  TGUI_Optiuni = class(TForm)
    sPanel1: TsPanel;
    LTitlu: mslabelFX;
    eDenumire: TsEdit;
    LsubTitle: mslabelFX;
    mslabelFX1: mslabelFX;
    eCodFiscal: TsEdit;
    eNrRanduri: TsEdit;
    mslabelFX2: mslabelFX;
    eRegCom: TsEdit;
    mslabelFX3: mslabelFX;
    btSave: TsButton;
    btQuit: TsButton;
    sPanel2: TsPanel;
    mslabelFX4: mslabelFX;
    chDataListe: TsCheckBox;
    chForce: TsCheckBox;
    mslabelFX5: mslabelFX;
    sPanel3: TsPanel;
    mslabelFX6: mslabelFX;
    ePath: TsEdit;
    mslabelFX7: mslabelFX;
    eSQL_DB: TsEdit;
    lError: mslabelFX;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btQuitClick(Sender: TObject);
    procedure ePathExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GUI_Optiuni: TGUI_Optiuni;

implementation

uses Main;

{$R *.dfm}

procedure TGUI_Optiuni.btQuitClick(Sender: TObject);
begin
  modalResult := mrCancel;
end;

procedure TGUI_Optiuni.btSaveClick(Sender: TObject);
begin
  with MainForm.Options do begin
    Values['FIRMA_DEN'] := eDenumire.Text;
    Values['FIRMA_CODFISCAL'] := eCodFiscal.Text;
    Values['FIRMA_REG_COM'] := eRegCom.Text;
    if eNrRanduri.Text = '' then Values['RAND_MAX'] := '65'
    else Values['RAND_MAX'] := eNrRanduri.Text;
    Values['PATH'] := ePath.Text;
    MainForm.SQLSettings.Values['SQL_DB'] := eSQL_DB.Text;

    if chDataListe.Checked then Values['DATA_LIS'] := 'DA'
    else Values['DATA_LIS'] := 'NU';
    if chForce.Checked then Values['FORCE'] := 'DA'
    else Values['FORCE'] := 'NU';
  end;
  modalResult := mrOk;
end;

procedure TGUI_Optiuni.ePathExit(Sender: TObject);
begin
  if not DirectoryExists(ePath.Text) then begin
    ePath.SetFocus;
    lError.Caption := 'Directorul introdus nu exista. Corectati.';
  end else
    lError.Caption := '';
end;

procedure TGUI_Optiuni.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
  Key := UpCase(Key);
end;

procedure TGUI_Optiuni.FormShow(Sender: TObject);
begin
//
end;

end.
