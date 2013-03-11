unit fGUI_FisaPartener;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBTables, Main, LASM, LCOMP, StrUtils,
  smslabel, sPanel, sEdit, sButton, sCheckBox, sComboBox, sLabel;

type
  TGUI_FisaPartener = class(TForm)
    Btn_Executa: TsButton;
    Btn_Renunta: TsButton;
    pOptions: TsPanel;
    pCont: TsPanel;
    q: TQuery;
    LTitlu: mslabelFX;
    pPeriod: TsPanel;
    EAn1: TsEdit;
    ELuna1: TsEdit;
    EZi1: TsEdit;
    EAn2: TsEdit;
    ELuna2: TsEdit;
    EZi2: TsEdit;
    LsubTitle: mslabelFX;
    pPartner: TsPanel;
    mslabelFX1: mslabelFX;
    EPartener: TsEdit;
    Btn_Partener: TsButton;
    cbMoneda: TsComboBox;
    Btn_Conturi: TsButton;
    ECont: TsEdit;
    mslabelFX2: mslabelFX;
    mslabelFX3: mslabelFX;
    chComponenta: TsCheckBox;
    chDefalcat: TsCheckBox;
    chSold: TsCheckBox;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Btn_ExecutaClick(Sender: TObject);
    procedure Btn_RenuntaClick(Sender: TObject);
    procedure ELuna1Change(Sender: TObject);
    procedure Btn_PartenerClick(Sender: TObject);
    procedure EPartenerKeyPress(Sender: TObject; var Key: Char);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
  private
    function GetPartners(PartialName: string): string;
  end;

var
  GUI_FisaPartener: TGUI_FisaPartener;

implementation

uses fMyPeriod, fFisaPartener, fMyLib, Listare, fGridForm;

{$R *.dfm}

procedure TGUI_FisaPartener.Btn_ExecutaClick(Sender: TObject);
var
  Perioada: TMyPeriod;
  r: integer;
  C: VM_Compiler;
  E: VM_LISTA;
  I: Integer;
  S: TStringList;
  t: string;
  p: string;
  listForm: TListForm;
begin
  if (EPartener.Text = '') and (ECont.Text = '') then begin
    ShowMessage('Nu aveti filtre. Operatia selectata va dura extrem de mult.' + #13 +
                'Se anuleaza.');
    Exit;             
  end;
  try
    try
      p := GetCurrentDir;
      SetCurrentDir(ExtractFilePath(Application.ExeName));
      DoSQL(q, 'USE MONDO');

      S := TStringList.Create;
      Perioada := TMyPeriod.Create;
      Perioada.SetDate(1, s2i(ELuna1.Text), s2i(EAn1.Text), psStart);
      Perioada.SetDate(s2i(EZi2.Text), s2i(ELuna2.Text), s2i(EAn2.Text), psEnd);

      t := Copy(EPartener.Text, 1, Pos('|', EPartener.Text) - 1);
      if t <> '' then S.CommaText := t;
      GetFisaPartener(q, S, ECont.Text, Perioada, r);


      S.Clear;
      C := VM_COMPILER.Create;
      C.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.LST');
      S.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.LST');
      I := C.Compile(GetCurrentDir + '\LISTE\LC_FISA_FC.COD');
      if I <> 0 then begin
         ShowMessage(C.ERR_MSG+C.ERR_TEXT);
         Exit;
      end;
      if C.IP > C.Inst.Count-1 then
        C.Ip := C.Inst.Count-1;

      E := VM_LISTA.Create;
      E.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.COD');
      if chComponenta.Checked then begin
        E.SetVAR_BOL('COMPONENTA', True);
        Perioada.First;
        Perioada.Prev;
        E.SetVAR_STR('LA_SOLD_P', Perioada.GetCurrentDate(4));
        E.SetVAR_STR('LA_SOLD_F', Perioada.GetLast(4));
      end else
        E.SetVAR_BOL('COMPONENTA', False);
      if chDefalcat.Checked then begin
        E.SetVAR_BOL('DEFALCAT', True);
        t := ', NRDE';
      end else begin
        E.SetVAR_BOL('DEFALCAT', False);
        t := '';
      end;
      DoSQL(q,
        'SELECT ' + E.GetSQL_FIELDS + ' ' +
        'FROM TMP_RUFC1 LEFT JOIN FUR USING(CODFUR) ' +
        'ORDER BY CONTFC, CONCAT(MID(DATAI,5,4),MID(DATAI,3,2),MID(DATAI,1,2))');
      E.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.COD');
      E.OUT_FILE_NAME := GetCurrentDir + '\LISTE\LC_FISA_FC.TXT';
      E.LDATASET := q;
      E.SetVAR_STR('FIRMA.DENUMIRE', MainForm.Options.Values['FIRMA_DEN']);
      E.SetVAR_STR('FIRMA.COD_FISCAL', MainForm.Options.Values['FIRMA_CODFISCAL']);
      E.SetVAR_STR('PERIOADA', RightStr('0' + EZi1.Text,2) + '.' + RightStr('0' + ELuna1.Text,2) + '.' + EAn1.Text + ' - ' +
                               RightStr('0' + EZi2.Text,2) + '.' + RightStr('0' + ELuna2.Text,2) + '.' + EAn2.Text);

      I := E.Exec(0);
      if I = 0 then begin
        listForm := TListForm.Create(Self);
        listForm.NumeLista := GetCurrentDir + '\LISTE\LC_FISA_FC.TXT';
        listForm.Start(0);
        listForm.Free;
      end;
      SetCurrentDir(p);
    finally
      C.Free;    
      S.Free;
      E.Free;
      Perioada.Free;
    end;
  except
    on e: Exception do ProcessException(e,'');
  end;
end;

function TGUI_FisaPartener.GetPartners(PartialName: string): string;
var
  f: TGridForm;
begin
  DoSQL(q, 'USE MONDO');
  try
    f := TGridForm.Create(Self);
    f.LTitlu.Caption := 'Selectare parteneri';
    Result := f.Start('SELECT DENFUR, COD_FISCAL, CODFUR FROM FUR ' +
            'WHERE DENFUR LIKE "%' + EPartener.Text + '%" ORDER BY DENFUR');
    if Result = '|' then Result := '';
  finally
    f.Free;
  end;
end;

procedure TGUI_FisaPartener.Btn_PartenerClick(Sender: TObject);
var
  s: string;
begin
  s := GetPartners(EPartener.Text);
  if s <> '' then EPartener.Text := s;
end;

procedure TGUI_FisaPartener.Btn_RenuntaClick(Sender: TObject);
begin
  Close;
end;

procedure PlusDay(D, M, Y: TEdit);
begin
  if D <> nil then begin

  end;
  if M = nil then Exit;
  if Y = nil then Exit;



end;

procedure TGUI_FisaPartener.ELuna1Change(Sender: TObject);
begin
  //
end;

procedure TGUI_FisaPartener.EditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then begin
    SelectNext(ActiveControl, True, True);
    Key := #0;
  end;
end;

procedure TGUI_FisaPartener.EPartenerKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then begin
    if (Pos('|',EPartener.Text) = 0) then begin
      Btn_PartenerClick(Self);
      SelectNext(ActiveControl, True, True);
    end else
      SelectNext(ActiveControl, True, True);
    Key := #0;
  end;
  if Key <> #0 then Key := UpCase(Key);  
end;

procedure TGUI_FisaPartener.FormCreate(Sender: TObject);
begin
  q.DatabaseName := MainForm.db.DatabaseName;
end;

procedure TGUI_FisaPartener.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
end;

end.
