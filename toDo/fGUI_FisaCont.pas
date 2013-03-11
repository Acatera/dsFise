unit fGUI_FisaCont;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, StdCtrls, Buttons, PngSpeedButton, LCOMP, LASM,
  Auxiliary, Main, StrUtils, StForm, sEdit, sCheckBox, sComboBox, SLabel,
  sSpeedButton, smslabel, Constants, sButton, ExtCtrls, sPanel;

type
  TGUI_FisaCont = class(TStdForm)
    Btn_Ok: TsSpeedButton;
    Btn_Renunta: TsSpeedButton;
    cbTip: TsComboBox;
    chSalt: TsCheckBox;
    chIncludeCont: TsCheckBox;
    ECont: TsEdit;
    EAnul1: TsEdit;
    ELuna1: TsEdit;
    EZiua1: TsEdit;
    EAnul2: TsEdit;
    ELuna2: TsEdit;
    EZiua2: TsEdit;
    STitle: mslabelFX;
    sPerioada: mslabelFX;
    mslabelFX1: mslabelFX;
    mslabelFX2: mslabelFX;
    sPanel1: TsPanel;
    sPanel2: TsPanel;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Btn_RenuntaClick(Sender: TObject);
    procedure Btn_OkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EnterExit(Sender: TObject; IsEnter: boolean);
    procedure EPerioadaKeyPress(Sender: TObject; var Key: Char);
    procedure EPerioadaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EEnter(Sender: TObject);
    procedure EExit(Sender: TObject);
    procedure MyEditBtnClick(Sender: TObject);
    function CheckDate(Sender: TObject): boolean;
    procedure ControlKeyPress(Sender: TObject; var Key: Char);
    procedure EContEnter(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbTipKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    function Start(Options: integer; FRMFile: string): integer;
    { Public declarations }
  end;

var
  GUI_FisaCont: TGUI_FisaCont;
  Optiuni: TStringList;
  FRMName: string;
  Lista1: Widestring;
  Lista2: Widestring;
  Lista3: Widestring;
  Lista4: Widestring;
  Conturi: Widestring;

implementation

uses
  Common, SQLData, MyDLG, List, CForm, Listare, ActGeneral, SQLCommon, RecPLC;

{$R *.dfm}

function TLCFisaCont.Start(Options: integer; FRMFile: string): integer;
begin
  Self.EditBtn.OnClick := MyEditBtnClick;
  Self.Tag := Options;
  FRMName := FRMFile;
  Optiuni := TStringList.Create;
  if FileExists('STRUCT\' + FRMFile) then
    Optiuni.LoadFromFile('STRUCT\' + FRMFile);
  Optiuni.Text := MyCustomReplaceVars(Optiuni.Text, Copy(SLunaAn, 1, 2), Copy(SLunaAn, 3, 2));
  SetForm(Self, Optiuni);
  Result := ShowModal;
end;

procedure TLCFisaCont.MyEditBtnClick(Sender: TObject);
begin
  EditBtnClick(Sender);
  if FileExists('STRUCT\' + FRMName) then
    Optiuni.LoadFromFile('STRUCT\' + FRMName);
  Optiuni.Text := MyCustomReplaceVars(Optiuni.Text, Copy(SLunaAn, 1, 2), Copy(SLunaAn, 3, 2));
  SetForm(Self, Optiuni);
end;

procedure TLCFisaCont.Btn_OkClick(Sender: TObject);
const
  COD = 'STRUCT\LISTE\LC_FISA_CONT.COD';
var
  C: VM_Compiler;
  AVM: VM_LISTA;
  I: Integer;
  S: TStringList;

  Luna: string;
  An: string;

  SQL: string;
  Where: string;
  From: string;
  Order: string;

  NUME_COD: string;
  MyParamCheck: boolean;
begin
  MyParamCheck := MySQL.QTemp.ParamCheck;
  MySQL.QTemp.ParamCheck := False;

  MySQL.SQLExec('DROP TABLE IF EXISTS TMP_NOTE' + SStatie);
  MySQL.SQLExec(
    'CREATE TABLE IF NOT EXISTS TMP_NOTE' + SStatie + ' (' +
      '`NRN` char(3) default NULL,' +
      '`TIPN` char(3) default NULL,' +
      '`FELN` char(2) default NULL,' +
      '`NRDI` bigint(10) NOT NULL default 0,' +
      '`DATAI` char(8) default NULL,' +
      '`EXPLIC` char(50) default NULL,' +
      '`FURCLI` char(15) default NULL,' +
      '`LUCRARE` char(15) default NULL,' +
      '`DEBIT` char(9) default NULL,' +
      '`CREDIT` char(9) default NULL,' +
      '`SUMA` double(17,2) NOT NULL default 0.00,' +
      '`SUMA_VAL` double(17,2) NOT NULL default 0.00, ' +
      '`INTIES` char(1) default NULL,' +
      '`TIP_VAL` char(3) default NULL,' +
      '`K_REP` double(15,8) default NULL, ' +
      '`GESTIUNE` char(6) NOT NULL default "",' +
      '`SRC` char(4) NOT NULL default "",' +
      'KEY `DEBIT` (`DEBIT`),' +
      'KEY `CREDIT` (`CREDIT`),' +
      'KEY `DBCR` (`DEBIT`,`CREDIT`)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=latin1;');
  {MySQL.SQLExec(
    'INSERT INTO TMP_NOTE' + SStatie + ' (NRN, TIPN, FELN, DATAN, EXPLIC, DEBIT, CREDIT, SUMA, ' +
        'SUMA_VAL, TIP_VAL, NROP, GESTIUNE, SRC, INTIES) ' +
      'SELECT R.NRN, "NC" TIPN, R.FELN, DATAI, ' +
        'IF(LEFT(UPPER(R.EXPLICN),4)="C.V." OR R.NRN = 25,R.EXPLICNT,R.EXPLICN) EXPLIC, R.DEBIT, R.CREDIT, ' +
        'SUM(R.SUMA) SUMA, SUM(R.SUMA_VAL) SUMA_VAL, R.TIP_VAL, R.POZ NROP, GEST, "RULA" SRC, INTIES ' +
      'FROM RULA' + SLunaAn + ' R ' +
      'WHERE TIPDI <> "+" ' +
      'GROUP BY R.INTIES, R.NRN, R.DEBIT, R.CREDIT, ' +
        'IF(LEFT(UPPER(R.EXPLICN),4)="C.V." OR R.NRN = 25,R.EXPLICNT,R.EXPLICN), GEST'); }
  SQL := '';
  Luna := RightStr('0' + ELuna1.Text,2);
  An := RightStr(EAnul1.Text,2);
  while (An + Luna) <= (RightStr(EAnul2.Text,2) + RightStr('0' + ELuna2.Text,2)) do begin
    SQL := SQL +
      'SELECT NRN, TIPDI, FELN, NRDI, DATAI, ' +
        'IF(LEFT(UPPER(EXPLICN),4)="C.V." OR NRN = 25,EXPLICN,EXPLICN) EXPLIC, FURCLI, DEBIT, CREDIT, ' +
        'SUM(SUMA) SUMA, SUM(SUMA_VAL) SUMA_VAL, TIP_VAL, GEST, "RULA" SRC, IF(INTIES MOD 2 = 1,1,2) INTIES, LUCRARE ' +
      'FROM RULA' + Luna + An + ' ' +
      'WHERE (TIPDI <> "+") AND (ANULAT <> "A") ' +
      'GROUP BY NRN, NRDI, DATAI, DEBIT, CREDIT, FURCLI, GEST, LUCRARE ' +
      'UNION ALL ';
    Luna := RightStr('0' + i2s(s2i(Luna) + 1),2);
    if Luna = '13' then begin
      Luna := '01';
      An := RightStr('0' + i2s(s2i(An) + 1),2);
    end;
  end;
  SQL := Copy(SQL, 1, Length(SQL) - 10);
  MySQL.SQLExec(
    'INSERT INTO TMP_NOTE' + SStatie + ' (NRN, TIPN, FELN, NRDI, DATAI, EXPLIC, FURCLI, DEBIT, CREDIT, SUMA, ' +
        'SUMA_VAL, TIP_VAL, GESTIUNE, SRC, INTIES, LUCRARE) ' +
       SQL);

  NUME_COD := GetSQLSegment(Optiuni, 'COD', 0);
  if NUME_COD = '' then
    NUME_COD := COD;
  AVM := MVM_LISTA.Create;
  AVM.OUT_FILE_NAME := 'LIST' + SStatie + '.TXT';
  if not MyFileExists(ChangeFileExt(NUME_COD, '.LST')) then
    begin
      FMyDlg.Start('Fisierul ' + ChangeFileExt(NUME_COD, '.LST') + ' nu exista !', M_ERROK);
      Exit;
    end;

  if Sender = nil then
    Insert('XLS', NUME_COD, Length(Nume_COD) - 3);
  CheckCompiledCod(ChangeFileExt(NUME_COD, '.LST'), NUME_COD);
  AVM.LoadFromFile(NUME_COD);
  LoadDefaultVars(AVM);

  AVM.SetVAR_STR('DATA_LISTE', Optiuni.Values['DATA_LISTE']);
  AVM.SetVAR_STR('DATA_LISTARII', FormatDateTime('dd/mm/yyyy', Now));
  AVM.SetVAR_STR('LUNA_LITERE', LowerCase(Luni[StrToInt(ELuna1.Text)]));
  AVM.SetVAR_STR('ANUL', EAnul1.Text);
  AVM.SetVAR_STR('LLAA', RightStr('0' + ELuna1.Text,2) + RightStr(EAnul1.Text,2));

  Conturi := GetConturiFiltrate(ECont.Text);

  if chSalt.Checked then AVM.SetVAR_STR('CU_SALT', 'DA') else AVM.SetVAR_STR('CU_SALT', 'NU');
  if chIncludeCont.Checked then
    begin
      if Conturi <> '' then
        Where := '(CONT IN (' + Conturi + '))'
      else
        Where := '';  
    end
  else
    begin
      if Conturi = '' then
        Where := '(LEFT(CONT,3) NOT IN (' + Lista3 + ')) AND (LEFT(CONT,4) NOT IN (4426,4427)) '
      else
        Where := '(LEFT(CONT,3) NOT IN (' + Lista3 + ')) AND (LEFT(CONT,4) NOT IN (4426,4427)) AND (CONT IN (' + Conturi + ')) ';
    end;


  case cbTip.ItemIndex of
    0: begin //ANALITICA
        SQL :=
          'SELECT ' +
            'NRN, TIPN, FELN, NRDI, DATAI, EXPLIC, "" COD_FISCAL, FURCLI, DENFUR, DEBIT CONT, CREDIT CONT_COR, ' +
            'SUMA DEBIT, 0 CREDIT, SUMA_VAL DB_VAL, 0 CR_VAL, TIP_VAL, INTIES ' +
          'FROM TMP_NOTE' + SStatie + ' LEFT JOIN FUR ON FURCLI = CODFUR ' +
          'WHERE DEBIT IN (' + Conturi + ') ' +
            'UNION ALL ' +
          'SELECT ' +
            'NRN, TIPN, FELN, NRDI, DATAI, EXPLIC, "" COD_FISCAL, FURCLI, DENFUR, CREDIT CONT, DEBIT CONT_COR, ' +
            '0 DEBIT, SUMA CREDIT, 0 DB_VAL, SUMA_VAL CR_VAL, TIP_VAL, INTIES ' +
          'FROM TMP_NOTE' + SStatie + ' LEFT JOIN FUR ON FURCLI = CODFUR ' +
          'WHERE CREDIT IN (' + Conturi + ') ';
      end;
    1: begin
        {Query.SQL.Text := 'SET @SOLD := 0';
        Query.ExecSQL;}
        SQL := '';
        Luna := RightStr('0' + ELuna1.Text, 2);
        An := RightStr(EAnul1.Text,2);
        while (An + Luna) <= (RightStr(EAnul2.Text, 2) + RightStr('0' + ELuna2.Text, 2)) do begin
          SQL := SQL +
            'SELECT "" DENFUR, "" COD_FISCAL, "" CODFUR, DEBIT CONT, DENC, TIPC, DATAI DATAN, NRDI NRN, DEND, TIPDI TIPN, ' +
              'EXPLICN EXPLIC, CREDIT CONT_COR, SUMA DB, 0 CR ' +
            'FROM RULA' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON DEBIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE TIPDI <> "+" ' +
            'UNION ALL ' +
            'SELECT "" DENFUR, "" COD_FISCAL, "" CODFUR, CREDIT CONT, DENC, TIPC, DATAI DATAN, NRDI NRN, DEND, TIPDI TIPN, ' +
              'EXPLICN EXPLIC, DEBIT CONT_COR, 0 DB, SUMA CR ' +
            'FROM RULA' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON CREDIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE TIPDI <> "+" ' +
            'UNION ALL ';
            {'SELECT DEBIT CONT, DENC, TIPC, DATAI DATAN, NRDI NRN, DEND, TIPDI TIPN, EXPLICN EXPLIC, CREDIT CONT_COR, SUMA DB, 0 CR ' +
            'FROM RMAT' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON DEBIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE TIPDI <> "+" ' +
            'UNION ALL ' +
            'SELECT CREDIT CONT, DENC, TIPC, DATAI DATAN, NRDI NRN, DEND, TIPDI TIPN, EXPLICN EXPLIC, DEBIT CONT_COR, 0 DB, SUMA CR ' +
            'FROM RMAT' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON CREDIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE TIPDI <> "+" ' +
            'UNION ALL ';}
          Luna := RightStr('0' + IntToStr(StrToInt(Luna) + 1), 2);
          if Luna = '13' then begin
            Luna := '01';
            An := RightStr('0' + IntToStr(StrToInt(An) + 1), 2);
          end;
        end;
        SQL := Copy(SQL, 1, Length(SQL) - 10);
        {MySQL.SQLOpen(
          'SELECT ' +
            AVM.GetSQL_FIELDS + ' ' +
          'FROM (' +
            SQL +
            ') TEMP ' +
          Where +
          'ORDER BY CONT, CONCAT(MID(DATAN,5,4),MID(DATAN,3,2),MID(DATAN,1,2)), IF(NRN=0,999999999999,NRN), CONT_COR, EXPLIC');}
       end;
    2: begin
        AVM.SetVAR_STR('PE_CODFUR', 'DA');
        SQL := '';
        Luna := RightStr('0' + ELuna1.Text, 2);
        An := RightStr(EAnul1.Text,2);
        while (An + Luna) <= (RightStr(EAnul2.Text, 2) + RightStr('0' + ELuna2.Text, 2)) do begin
          SQL := SQL +
            'SELECT ' +
              'FURCLI, DATAI DATAN, TIPDI TIPN, NRDI NRN, EXPLICN EXPLIC, DEBIT CONT, CREDIT CONT_COR, DEND, ' +
              'DENC, TIPC, SUMA DB, 0 CR ' +
            'FROM RULA' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON DEBIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE ANULAT <> "A" ' +
            'UNION ALL ' +
            'SELECT ' +
              'FURCLI, DATAI DATAN, TIPDI TIPN, NRDI NRN, EXPLICN EXPLIC, CREDIT CONT, DEBIT CONT_COR, DEND, ' +
              'DENC, TIPC, 0 DB, SUMA CR ' +
            'FROM RULA' + Luna + An + ' LEFT JOIN PLC' + Luna + An + ' ON CREDIT = CONT LEFT JOIN TIPD ON TIPDI = TIPD ' +
            'WHERE ANULAT <> "A" ' +
            'UNION ALL ';
          Luna := RightStr('0' + IntToStr(StrToInt(Luna) + 1), 2);
          if Luna = '13' then begin
            Luna := '01';
            An := RightStr('0' + IntToStr(StrToInt(An) + 1), 2);
          end;
        end;
        SQL := Copy(SQL, 1, Length(SQL) - 10);
        {MySQL.SQLOpen(
          'SELECT ' +
            AVM.GetSQL_FIELDS + ' ' +
          'FROM (' +
            SQL +
            ') TEMP LEFT JOIN FUR ON FURCLI = CODFUR ' +
          //Where +
          'ORDER BY CONT, CONCAT(MID(DATAN,5,4),MID(DATAN,3,2),MID(DATAN,1,2)), IF(NRN=0,999999999999,NRN), CONT_COR, EXPLIC');}
      end;
  end;
  Where := Where + GetSQLSegment(Optiuni, 'WHERE', 0);
  From := GetSQLSegment(Optiuni, 'FROM', cbTip);
  Order := GetSQLSegment(Optiuni, 'ORDERBY', cbTip);

  if Order <> '' then
    Order := 'ORDER BY ' + Order;
  if Where <> '' then
    Where := 'AND ' + Where;

  MySQL.SQLOpen(
    'SELECT ' +
      AVM.GetSQL_FIELDS + ' ' +
    'FROM (' +
      SQL +
      ') TEMP ' + From + ' ' +
    'WHERE (1=1) ' + Where + ' ' +
    Order);

  if MySQL.QTemp.RecordCount = 0 then begin
    FMyDLG.Start('Nu aveti inregistrata nici o nota contabila.', M_INFO+M_OK);
    Exit;
  end;
  AVM.LDATASET := MySQL.QTemp;
  I := AVM.Exec(0);
  MySQL.QTemp.Close;
  if I = 0 then
    begin
      Application.CreateForm(TListForm, ListForm);
      ListForm.FixedCol0 := 0;
      ListForm.NumeLista := 'LIST' + SStatie + '.TXT';
      //    ListForm.STime.Caption := FormatFloat('0.00 sec.',TT.GetTime/1000);
      ListForm.Start(LIST_CAN_RELIST);
      ListForm.Free;
    end;
  MySQL.QTemp.ParamCheck := MyParamCheck;
end;

procedure TLCFisaCont.Btn_RenuntaClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TLCFisaCont.cbTipKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_END then
    Exit;
end;

procedure TLCFisaCont.ControlKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    SelectNext(ActiveControl, True, True)
  else if Key = #27 then
    modalResult := mrCancel;
end;

procedure TLCFisaCont.EPerioadaKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key in [':'..'~']) then begin
    Key := #0;
    Exit;
  end;
  ControlKeyPress(Sender, Key);
end;

function TLCFisaCont.CheckDate(Sender: TObject): boolean;
begin
  Result := True;
  if TComponent(Sender).Tag = 1 then
    if Length(EAnul1.Text) > 4 then
      begin
        Result := False;
        Exit;
      end;
    if ELuna1.Text > '12' then
      begin
        Result := False;
        Exit;
      end;
    if EZiua1.Text > UltimaZi(ELuna1.Text + Copy(EAnul1.Text,3,2), True, True) then
      begin
        Result := False;
        Exit;
      end;
  if TComponent(Sender).Tag = 2 then
    if Length(EAnul2.Text) > 4 then
      begin
        Result := False;
        Exit;
      end;
    if ELuna2.Text > '12' then
      begin
        Result := False;
        Exit;
      end;
    if EZiua2.Text > UltimaZi(ELuna2.Text + Copy(EAnul2.Text,3,2), True, True) then
      begin
        Result := False;
        Exit;
      end;
end;

procedure TLCFisaCont.EExit(Sender: TObject);
begin
  if CheckDate(Sender) <> True then begin
    //FMyDLG.Start('Verificati ca data introdusa sa fie valida!', M_ERROK);
    Exit;
  end;
  EnterExit(Sender, False);
end;

procedure TLCFisaCont.EContEnter(Sender: TObject);
var
  FPLC : TFActGeneral;
begin
  //ECont.Text := strRep(ECont.Text, '|', '|'+Chr(13)+Chr(10));
  Application.CreateForm(TFActGeneral, FPLC);
  FPLC.SelItem := TMyItem.Create('PLC00','CONT');
  FPLC.SelItem.MyData.Values['CONT'] := ECont.Text;
  FPLC.SelItem.GetItem;
  FPLC.FRecType := TFRecPLC;
  FPLC.Start(DS_MULTI_SELECT+DS_INITIAL);
  ECont.Text := FPLC.MultiSelect.Text;
  ECont.Text := strRep(ECont.Text, Chr(13)+Chr(10), '');
  if ECont.Text = '' then
    ECont.Text := 'TOATE';
  FPLC.Free;
  Conturi := GetConturiFiltrate(ECont.Text);
  SelectNext(ActiveControl, True, True);
end;

procedure TLCFisaCont.EEnter(Sender: TObject);
begin
  EnterExit(Sender, True);
end;

procedure TLCFisaCont.EPerioadaKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_End then
    Btn_OkClick(Self);
end;

procedure TLCFisaCont.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MySQL.SQLExec('DROP TABLE IF EXISTS TMP_NOTE' + SStatie);
end;

procedure TLCFisaCont.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_END then
    begin
      Btn_OkClick(Sender);
      Key := 0;
    end;
end;

procedure TLCFisaCont.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then ModalResult := mrCancel;
end;

procedure TLCFisaCont.FormShow(Sender: TObject);
begin
  STitle.Width := ClientWidth;
  MySQL.SQLOpen(
    'SELECT ' +
      'CONT,' +
      'IF(TIPC="NU", "L4",' +
        'IF(TIPC="A" OR (TIPC="B" AND LEFT(CONT,1)="8"),"L1",' +
          'IF(TIPC="P" OR TIPC="B","L2",""))) LISTA ' +
    'FROM PLC' + SLunaAn + ' ' +
    'GROUP BY LEFT(CONT,3) ' +
    'ORDER BY CONT');
  Lista1 := '';
  Lista2 := '';
  Lista3 := '';
  Lista4 := '';
  while not MySQL.QTemp.Eof do begin
    if MySQL.QTemp.FieldByName('LISTA').AsString = 'L1' then
      Lista1 := Lista1 + '","' + MySQL.QTemp.FieldByName('CONT').AsString;
    if MySQL.QTemp.FieldByName('LISTA').AsString = 'L2' then
      Lista2 := Lista2 + '","' + MySQL.QTemp.FieldByName('CONT').AsString;
    if MySQL.QTemp.FieldByName('LISTA').AsString = 'L4' then
      Lista1 := Lista4 + '","' + MySQL.QTemp.FieldByName('CONT').AsString;
    MySQL.QTemp.Next;  
  end;
  Delete(Lista1,1,2);
  Lista1 := Lista1 + '"';
  Delete(Lista2,1,2);
  Lista2 := Lista2 + '"';
  Delete(Lista4,1,2);
  Lista4 := Lista4 + '"';
  Lista3 := Lista1 + ',' + Lista2;
end;

procedure TLCFisaCont.EnterExit(Sender: TObject; IsEnter: boolean);
var
  T: TComponent;
begin
  T := TComponent(Sender);
  if not Assigned(T) then Exit;
  if (T is msLabelFX) then
    begin
      if IsEnter then
        begin
          msLabelFX(T).Kind.KindType := ktCustom;
          msLabelFX(T).Kind.Color := COLOR_ENTER;
        end
      else
        begin
          msLabelFX(T).Kind.KindType := ktSkin;
        end;
    end
  else if not ((T is TsComboBox) or (T is TsButton)) then
    begin
      if IsEnter then
        EControlEnter(Sender)
      else
        EControlExit(Sender);
    end
  else if T is TsComboBox then begin
    if IsEnter then   
      TsCombobox(T).DroppedDown := True
    else
      TsCombobox(T).DroppedDown := False
  end;
end;

end.
