unit Fisa_FC;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBTables, Main, LASM, LCOMP, StrUtils,
  Auxiliary;

type
  TFisaFC = class(TForm)
    chComponenta: TCheckBox;
    chDefalcat: TCheckBox;
    chSold: TCheckBox;
    Btn_Corectare: TButton;
    ECont: TLabeledEdit;
    Btn_Conturi: TButton;
    EPartener: TLabeledEdit;
    Btn_Partener: TButton;
    Btn_Executa: TButton;
    Btn_Renunta: TButton;
    Panel2: TPanel;
    Panel1: TPanel;
    Panel3: TPanel;
    LMoneda: TLabel;
    cbMoneda: TComboBox;
    EAn1: TEdit;
    ELuna1: TEdit;
    EZi1: TEdit;
    LPerioada: TLabel;
    Titlu: TLabel;
    EAn2: TEdit;
    ELuna2: TEdit;
    EZi2: TEdit;
    Query: TQuery;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Btn_ExecutaClick(Sender: TObject);
    procedure Btn_RenuntaClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FisaFC: TFisaFC;

implementation

{$R *.dfm}

procedure TFisaFC.Btn_ExecutaClick(Sender: TObject);
var
  C: VM_Compiler;
  I: Integer;
  S: TStringList;
  E: VM_LISTA;
  J: Double;
  Where: string;
  ALuna: string;
  AAn: string;
  LLAA: string;
  Temp: string;
begin
  if CheckAndUpdateLST('LC_FISA_FC', 'LISTE\LC_FISA_FC') <> 0 then begin ShowMessage('Eroare la verificare lista'); Exit; end;

  S := TStringList.Create;
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
  C.Free;

  E := VM_LISTA.Create;
  E.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.COD');
  E.SetVAR_STR('DATA_LISTE', Optiuni.Values['DATA_LISTE']);
  E.SetVAR_STR('DATA_LISTARII', FormatDateTime('dd/mm/yyyy', Now));

  if chComponenta.Checked then
    E.SetVAR_BOL('COMPONENTA', True)
  else
    E.SetVAR_BOL('COMPONENTA', False);
  if chDefalcat.Checked then begin
    E.SetVAR_BOL('DEFALCAT', True);
    Temp := ', NRDE';
  end else begin
    E.SetVAR_BOL('DEFALCAT', False);
    Temp := '';
  end;
  

  ALuna := RightStr('0' + IntToStr(StrToInt(ELuna1.Text) - 1),2);
  AAn := RightStr(EAn1.Text,2);
  if ALuna = '00' then begin
    ALuna := '12';
    AAn := RightStr(IntToStr(StrToInt(AAn) - 1),2); 
  end;

  E.SetVAR_STR('ALUNA', ALuna);
  E.SetVAR_STR('AAN', AAn);
  E.SetVAR_STR('LUNA', RightStr('0' + ELuna2.Text,2));
  E.SetVAR_STR('AN', RightStr(EAn2.Text,2));

  Query.SQL.Text :=
    'DROP TABLE IF EXISTS TMP_RFC';
  Query.ExecSQL;
  Query.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS TMP_RFC (' +
      '`EXPLICN` char(40) NOT NULL default "",' +
      '`FURCLI` char(15) NOT NULL default "",' +
      '`TIPDI` char(2) NOT NULL default "",' +
      '`NRN` char(3) NOT NULL default "",' +
      '`GEST` char(8) NOT NULL default "",' +
      '`NRDI` bigint(20) NOT NULL default 0,' +
      '`DATAI` char(8) NOT NULL default "",' +
      '`DEBIT` char(9) NOT NULL default "",' +
      '`CREDIT` char(9) NOT NULL default "",' +
      '`SUMA` double(22,2) NOT NULL default 0.00,' +
      '`SUMA_VAL` double(22,2) NOT NULL default 0.00,' +
      'KEY `AUX` (`CREDIT`,`DEBIT`,`FURCLI`)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=latin1';
  Query.ExecSQL;

  ELuna1.Tag := StrToInt(ELuna1.Text);
  ELuna2.Tag := StrToInt(ELuna2.Text);
  EAn1.Tag := StrToInt(EAn1.Text);
  EAn2.Tag := StrToInt(EAn2.Text);
  LLAA := RightStr('0' + IntToStr(ELuna1.Tag), 2) + RightStr(IntToStr(EAn1.Tag), 2);

  for I := 1 to (EAn2.Tag - EAn1.Tag) * 12 - ELuna1.Tag + ELuna2.Tag + 1 do begin
    Query.SQL.Text :=
      'INSERT INTO TMP_RFC (EXPLICN, FURCLI, TIPDI, NRN, GEST, NRDI, DATAI, DEBIT, CREDIT, SUMA, SUMA_VAL) ' +
        'SELECT EXPLICN, FURCLI, TIPDI, NRN, GEST, NRDI, DATAI, DEBIT, CREDIT, SUM(SUMA) SUMA, SUM(SUMA_VAL) SUMA_VAL ' +
        'FROM RMAT' + LLAA + ' ' +
        'GROUP BY NRDI' + Temp + ', DATAI, FURCLI, NRN UNION ALL ' + //Temp is for payment details
        'SELECT EXPLICN, FURCLI, TIPDI, NRN, GEST, NRDI, DATAI, DEBIT, CREDIT, SUM(SUMA) SUMA, SUM(SUMA_VAL) SUMA_VAL ' +
        'FROM RULA' + LLAA + ' ' +
        'WHERE TIPDI <> "+" ' +
        'GROUP BY NRDI' + Temp + ', DATAI, FURCLI, NRN';
    Query.ExecSQL;

    ELuna1.Tag := ELuna1.Tag + 1;
    if ELuna1.Tag > 12 then begin
      ELuna1.Tag := 1;
      EAn1.Tag := EAn1.Tag + 1;
    end;
    LLAA := RightStr('0' + IntToStr(ELuna1.Tag), 2) + RightStr(IntToStr(EAn1.Tag), 2);
  end;

  if chSold.Checked then begin
    Query.SQL.Text :=
      'SELECT ' +
        'GROUP_CONCAT(''"'',CODFUR,''"'') ' +
      'FROM ' +
         '(SELECT DEBIT, CONT, SUM(IF(DEBIT=CONT,SUMA,-SUMA)) SOLD, CODFUR ' +
         'FROM TMP_RFC LEFT JOIN FUR ON CODFUR=FURCLI LEFT JOIN TMP_PLC ON (DEBIT=CONT) OR (CREDIT=CONT) ' +
         'WHERE DENC IS NOT NULL ' +
         'GROUP BY FURCLI, CONT) TEMP ' +
      'WHERE SOLD=0';
   Query.Open;   
   if not Query.Eof then 
     Where := ' AND CODFUR NOT IN (' + Query.Fields[0].AsString + ')'
   else
     Where := '';  
  end;

  Query.SQL.Text :=
    'SELECT ' +
      'COD_FISCAL, DENFUR, CONTB, DENB, IF(DEBIT=CONT, DEBIT, CREDIT) CONT, EXPLICN, NRDI, DATAI,' +
      'IF(DEBIT=CONT, CREDIT, DEBIT) CONT_COR,' +
      'IF(DEBIT=CONT, SUMA,0) DEBIT,' +
      'IF(CREDIT=CONT, SUMA, 0) CREDIT ' +
    'FROM TMP_RFC LEFT JOIN FUR ON CODFUR=FURCLI LEFT JOIN TMP_PLC ON (DEBIT=CONT) OR (CREDIT=CONT) ' +
    'WHERE DENC IS NOT NULL ' +
    'ORDER BY DENFUR';
  Query.SQL.Text :=
    'SELECT ' + E.GetSQL_FIELDS + ' ' +
    'FROM TMP_RFC LEFT JOIN FUR ON CODFUR=FURCLI LEFT JOIN TMP_PLC ON (DEBIT=CONT) OR (CREDIT=CONT) LEFT JOIN TIPD ON TIPDI = TIPD ' +
    'WHERE DENC IS NOT NULL ' + Where +
    'ORDER BY IF(DEBIT=CONT, DEBIT, CREDIT), DENFUR, CONCAT(MID(DATAI,5,4),MID(DATAI,3,2),MID(DATAI,1,2)), ' +
      'IF(DEBIT=CONT,IF(TIPC="A",0,1),IF(TIPC="P",0,1))';
  Query.Open;

  E.LoadFromFile(GetCurrentDir + '\LISTE\LC_FISA_FC.COD');
  E.OUT_FILE_NAME := GetCurrentDir + '\LISTE\LC_FISA_FC.TXT';
  E.LDATASET := Query;
  E.SetVAR_STR('FIRMA.DENUMIRE', 'S.C. David Software S.R.L.');
  E.SetVAR_STR('FIRMA.COD_FISCAL', 'R1819101');
  E.SetVAR_STR('PERIOADA', RightStr('01' + EZi1.Text,2) + '.' + RightStr('00' + ELuna1.Text,2) + '.' + EAn1.Text + ' - ' +
                           RightStr('01' + EZi2.Text,2) + '.' + RightStr('00' + ELuna2.Text,2) + '.' + EAn2.Text);
  I := E.Exec(0);
  if I = 0 then

  Query.Close;
  E.Free;
end;

procedure TFisaFC.Btn_RenuntaClick(Sender: TObject);
begin
  Close;
end;

procedure TFisaFC.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
end;

end.
