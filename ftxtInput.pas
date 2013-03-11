unit ftxtInput;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, sEdit, ExtCtrls, sPanel, smslabel, Buttons, sSpeedButton;

type
  TtxtInput = class(TForm)
    LTitlu: mslabelFX;
    pInput: TsPanel;
    LsubTitle: mslabelFX;
    eInput: TsEdit;
    Btn_Ok: TsSpeedButton;
    Btn_Renunta: TsSpeedButton;
    procedure Btn_RenuntaClick(Sender: TObject);
    procedure Btn_OkClick(Sender: TObject);
  published
    function Start(Param: string): string;
  end;

var
  txtInput: TtxtInput;

implementation

{$R *.dfm}

procedure TtxtInput.Btn_OkClick(Sender: TObject);
begin
  modalResult := mrOk;
end;

procedure TtxtInput.Btn_RenuntaClick(Sender: TObject);
begin
  modalResult := mrCancel;
end;

function TtxtInput.Start(Param: string): string;
begin
  Result := '';
  if Param = 'S' then begin
    if ShowModal <> mrCancel then
      Result := eInput.Text;
  end;
end;

end.
