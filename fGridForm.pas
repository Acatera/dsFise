unit fGridForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, ExtCtrls, sPanel, StdCtrls, smslabel, DB, DBTables, sButton, sEdit;

type
  TGridForm = class(TForm)
    LTitlu: mslabelFX;
    sPanel1: TsPanel;
    sPanel2: TsPanel;
    g: TDBGrid;
    q: TQuery;
    ds: TDataSource;
    pCauta: TsPanel;
    eCauta: TsEdit;
    btCauta: TsButton;
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure gKeyPress(Sender: TObject; var Key: Char);
    procedure BeautifyColumns;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    function Start(SQL: string; const ResultFormat: string = ''): string;
  end;

var
  GridForm: TGridForm;
  wasSelected: boolean; //partener selected

implementation

uses fMyLib, Main;

{$R *.dfm}

function TGridForm.Start(SQL: string; const ResultFormat: string = ''): string;
var
  slRF: TStringList;
  i: integer;
begin
  slRF := TStringList.Create;
  slRF.Delimiter := '|';
  slRF.DelimitedText := ResultFormat;
  q.DatabaseName := MainForm.db.DatabaseName;
  q.SQL.Text := SQL;
  ShowModal;
  Result := '';
  if wasSelected then begin
    for i := 0 to slRF.Count - 1 do
      Result := Result + q.FieldByName(slRF[i]).AsString + '|';
    SetLength(Result, l(Result) - 1);
  end;
  slRF.Free;  
end;

procedure TGridForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
//  if Key = VK_F7 then
//    pCauta.Visible := not pCauta.Visible;
end;

procedure TGridForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
end;

procedure TGridForm.BeautifyColumns;
var
  I: Integer;
begin
  if q.RecordCount = 0 then Exit;
  for I := 0 to q.Fields.Count - 1 do begin
    g.Columns[i].Title.Caption := StringReplace(g.Columns[i].Title.Caption,'_', ' ', [rfReplaceAll]);
    g.Columns[i].Title.Font.Style := [fsBold];
  end;

end;

procedure TGridForm.FormShow(Sender: TObject);
begin
  wasSelected := false;
  DoSQL(q);
  BeautifyColumns
end;

procedure TGridForm.gKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then begin
    wasSelected := True;
    Close;
  end;
end;

end.
