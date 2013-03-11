unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, DB, DBTables, StdCtrls, DateUtils,
  sSkinManager, ExtCtrls, sPanel, sMemo, sEdit, sButton, sLabel, sAlphaListBox, fMyPeriod, ComCtrls, acProgressBar,
  smslabel, sCheckBox, sComboBox, Buttons, PngSpeedButton, ZipForge;

type
  TMainForm = class(TForm)
    q: TQuery;
    db: TDatabase;
    sPanel1: TsPanel;
    SM: TsSkinManager;
    sPanel2: TsPanel;
    btPartener: TsButton;
    pbGlobal: TsProgressBar;
    pbFile: TsProgressBar;
    lFile: mslabelFX;
    btCont: TsButton;
    pPeriod: TsPanel;
    LsubTitle: mslabelFX;
    EAn1: TsEdit;
    ELuna1: TsEdit;
    EZi1: TsEdit;
    EAn2: TsEdit;
    ELuna2: TsEdit;
    EZi2: TsEdit;
    pPartner: TsPanel;
    mslabelFX1: mslabelFX;
    EPartener: TsEdit;
    Btn_Partener: TsButton;
    pCont: TsPanel;
    mslabelFX2: mslabelFX;
    Btn_Conturi: TsButton;
    ECont: TsEdit;
    pOptions: TsPanel;
    chComponenta: TsCheckBox;
    chDefalcat: TsCheckBox;
    chSold: TsCheckBox;
    sPanel3: TsPanel;
    chIncludeCont: TsCheckBox;
    chSalt: TsCheckBox;
    mslabelFX3: mslabelFX;
    cbTip: TsComboBox;
    sPanel4: TsPanel;
    btOptions: TPngSpeedButton;
    btImporta: TsButton;
    LStatia: mslabelFX;
    LFirma: mslabelFX;
    cbFirme: TsComboBox;
    btAddFirma: TPngSpeedButton;
    mDebug: TsMemo;
    ZF: TZipForge;
    procedure btImportaClick(Sender: TObject);
    procedure btPartenerClick(Sender: TObject);
    procedure btContClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Btn_PartenerClick(Sender: TObject);
    procedure EPartenerKeyPress(Sender: TObject; var Key: Char);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure btOptionsClick(Sender: TObject);
    procedure EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbFirmeChange(Sender: TObject);
    procedure btAddFirmaClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
  private
    function LoadDBF(FileName: String; const AProgressBar: TProgressBar = nil; const ROWS: byte = 60): integer;
    function InitDB(dbName: string; const AutoAdd: boolean = true): TStringList;
    function VerifyDBName(dbName: string): string;
    function GetLastImport(FileName: string): string;
    function GetPartners(PartialName: string): string;
    function GetNextFreeTerminalNumber: integer;
    function GetTerminalNumber: string;
    procedure Update;
  published
    Options: TStringList;
    SQLSettings: TStringList;
  end;

var
  MainForm: TMainForm;
  myPeriod: TMyPeriod;
  skipVerify: boolean;
  slImportedTables: TStringList;
  slExistingTables: TStringList;
  bStandAlone: boolean;

implementation

uses
  fFise, fGridForm, LASM, LCOMP, Listare, fGUI_Optiuni, fNetwork, ftxtInput, fMyDate, fMyLib, fMyDBFLoader, BMAUpdate;

{$R *.dfm}

function TMainForm.VerifyDBName(dbName: string): string;
begin
  try
    Randomize;
    if dbName = '' then dbName := 'rnd' + i2s(Random(1000))
    else if dbName[1] in ['0'..'9'] then
      dbName := 'f' + dbName;     
    Result := dbName;
    if DoSQL(q, 'SHOW TABLES IN `' + dbName + '` LIKE "GENERAL"') > 0 then
      Result := 'fise' + Result;
  finally
  end;
end;

function TMainForm.InitDB(dbName: string; const AutoAdd: boolean = true): TStringList;
var
  c: string;
begin
  //if DoSQL(q, 'SELECT * FROM SETARI') = -1 then btAddFirmaClick(nil);
  Result := TStringList.Create;
  if DoSQL(q, 'CREATE DATABASE IF NOT EXISTS ' + dbName) < 0 then Exit;
  if DoSQL(q, 'USE ' + dbName) <> 0 then Exit;
  DoSQL(q, 'CREATE TABLE IF NOT EXISTS STATUS (' +
             '`FILENAME` char(255) NOT NULL default "", ' +
             '`LASTSIZE` int NOT NULL default 0, ' +
             '`LASTUPDATE` datetime NOT NULL default "01-01-1970", ' +
             'PRIMARY KEY (`FILENAME`)' +
           ') ENGINE=InnoDB DEFAULT CHARSET=latin1');
  DoSQL(q, 'CREATE TABLE IF NOT EXISTS SETARI (' +
             '`STATIE` bigint(4) NOT NULL default 1, ' +                               
             '`MAC` char(20) NOT NULL default "00-00-00-00-00-00", ' +
             '`RAND_MAX` int(2) NOT NULL default 0, ' +
             '`FIRMA_DEN` char(40) NOT NULL default "", ' +
             '`FIRMA_CODFISCAL` char(15) NOT NULL default "", ' +
             '`FIRMA_REG_COM` char(15) NOT NULL default "", ' +
             '`DAT_LIS` char(2) NOT NULL default "", ' +
             '`PATH` char(255) NOT NULL default "" '+
           ') ENGINE=InnoDB DEFAULT CHARSET=latin1');
  DoSQL(q, 'SHOW CREATE TABLE SETARI');
  c := q.Fields[1].AsString;
  if not inStr('`MAC`', c) then
    DoSQL(q, 'ALTER TABLE `SETARI` ADD COLUMN `MAC` char(20) NOT NULL default "00-00-00-00-00-00" AFTER `STATIE`');
  if DoSQL(q, 'SELECT * FROM SETARI') < 1 then
    if AutoAdd then btAddFirmaClick(nil);
  DoSQL(q, 'SELECT CONCAT(FILENAME, "=", LASTUPDATE, "|", LASTSIZE) FROM STATUS');
  while not q.Eof do begin
    Result.Add(q.Fields[0].AsString);
    q.Next;
  end;
  skipVerify := True;
end;

function TMainForm.GetLastImport(FileName: string): string;
var
  s: string;
begin
  Result := '';
  if FileName = '' then Exit;
  s := slImportedTables.Values[FileName];
  if s = '' then Result := '1970-01-01 00:00:00'
  else
    Result := Copy(s, 1, Pos('|', s) - 1);
end;

function TMainForm.LoadDBF(FileName: String; const AProgressBar: TProgressBar = nil; const ROWS: byte = 60): integer;
var
  dbLoader: TMyDBFLoader;
  fa: integer;
  s: string;
  v: string;
{$IFDEF LOAD_FROM_FILE}
  myfs: TFileStream;
{$ENDIF}
begin
  Result := -1;
  if FileName = '' then Exit;
  FileName := StringReplace(FileName, '.DBF','',[rfReplaceAll, rfIgnoreCase]);
  if not FileExists(FileName + '.DBF') then Exit;
  if not skipVerify then Exit;

  fa := FileAge(FileName + '.DBF');
  if fa > -1 then s := FormatDateTime('yyyy-mm-dd hh:nn:ss', FileDateToDateTime(fa));

  if (s = GetLastImport(ExtractFileName(FileName))) and (Options.Values['FORCE'] <> 'DA') then begin
    if AProgressBar <> nil then AProgressBar.Position := AProgressBar.Max;
    Exit;
  end;

  dbLoader := TMyDBFLoader.Create;
  dbLoader.AssignDBF(FileName);

  if AProgressBar <> nil then begin
    AProgressBar.Position := 0;
    AProgressBar.Max := 20;//dbLoader.RecordCount;
  end;
  DoSQL(q, 'DELETE FROM STATUS WHERE FILENAME="' + ExtractFileName(FileName) + '"');
  DoSQL(q, 'DROP TABLE IF EXISTS ' + dbLoader.dbName);
  DoSQL(q, dbLoader.GetSQLHeader);
  v := '';
  while not dbLoader.Eof do begin
  {$IFDEF LOAD_FROM_FILE}
    v := v + dbLoader.GetSQLValues(ROWS) + '|#|';
  {$ELSE}
    v := dbLoader.GetSQLValues(ROWS);
    if v <> '' then
      if DoSQL(q, 'INSERT INTO ' + dbLoader.dbName + '  VALUES ' + v) = -1 then Break;
  {$ENDIF}
    if AProgressBar <> nil then begin
      if AProgressBar.Position + (ROWS) > AProgressBar.Max then
        AProgressBar.Position := AProgressBar.Max
      else
      {$IFDEF LOAD_FROM_FILE}
        if dbLoader.RecNo > (AProgressBar.Position + 1) * (dbLoader.RecordCount * 5 / 100) then
          AProgressBar.Position := AProgressBar.Position + 1;
      {$ELSE}
        AProgressBar.Position := AProgressBar.Position + (ROWS);
      {$ENDIF}
      Application.ProcessMessages;
    end;
  end;
{$IFDEF LOAD_FROM_FILE}
  if v <> '' then begin
    try
      if not DirectoryExists(Options.Values['PATH'] + '\TempExp') then begin
        {$IOChecks Off}
        MkDir('TempExp');
        if IOResult <> 0 then Exit;
        {$IOChecks On}
      end;
      if FileExists(Options.Values['PATH'] + '\TempExp\' + dbLoader.dbName + '.dmp') then
        DeleteFile(Options.Values['PATH'] + '\TempExp\' + dbLoader.dbName + '.dmp');
      if l(v) >= 3 then
        SetLength(v, l(v) - 3);
      myfs := TFileStream.Create(Options.Values['PATH'] + '\TempExp\' + dbLoader.dbName + '.dmp', fmCreate);
      myfs.Write(v[1], l(v));
    finally
      myfs.Free;
    end;
    DoSQL(q, 'LOAD DATA LOCAL INFILE "' + StringReplace(Options.Values['PATH'], '\', '\\', [rfReplaceAll]) + '\\TempExp\\' + dbLoader.dbName + '.dmp" ' +
             'INTO TABLE ' + dbLoader.dbName + ' ' +
             'FIELDS TERMINATED BY "|" LINES TERMINATED BY "|#|"');
  end;
{$ENDIF}
  DoSQL(q, 'INSERT INTO STATUS (FILENAME, LASTSIZE, LASTUPDATE) VALUES ("' +
              ExtractFileName(FileName) + '", ' + i2s(fileSize(FileName + '.DBF')) + ', "' + s + '")');
  Result := dbLoader.RecordCount;
  dbLoader.Free;
end;

procedure TMainForm.btAddFirmaClick(Sender: TObject);
var
  f: TGUI_Optiuni;
  dbNameValid: boolean;
begin
  try
    f := TGUI_Optiuni.Create(Self);
    with f do begin
      LTitlu.Caption := 'Adaugare firma';
      eDenumire.Text := '';
      eCodFiscal.Text := '';
      eRegCom.Text := '';
      eNrRanduri.Text := '65';
      ePath.Text := '';
      eSQL_DB.Text := '';
      if Sender = nil then begin
        if SQLSettings.Values['SQL_DB'] <> 'mysql' then begin
          eSQL_DB.Text := SQLSettings.Values['SQL_DB'];
          eSQL_DB.Enabled := False; //DBName must remain the same
        end;
        eCodFiscal.Text := Options.Values['FIRMA_CODFISCAL'];
        if eCodFiscal.Text <> '' then
          eCodFiscal.Enabled := False;
        ePath.Text := Options.Values['PATH'];
        if not bStandAlone then ePath.Enabled := False;
      end;
      if f.ShowModal = mrCancel then begin
        if Sender <> nil then Exit
        else begin
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;
      end;
      dbNameValid := False;
      SQLSettings.Values['SQL_DB'] := VerifyDBName(SQLSettings.Values['SQL_DB']);
      if SQLSettings.Values['SQL_DB'] <> '' then begin
        InitDB(SQLSettings.Values['SQL_DB'], false);
        DoSQL(q, 'DELETE FROM SETARI WHERE STATIE = ' + Options.Values['STATIE']);
        DoSQL(q, 'INSERT INTO SETARI (STATIE, MAC, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH) VALUES (' +
               Options.Values['STATIE'] + ', "' + Options.Values['MAC'] + '", ' + Options.Values['RAND_MAX'] + ', ' +
               '"' + Options.Values['FIRMA_DEN'] + '", ' +
               '"' + Options.Values['FIRMA_CODFISCAL'] + '", ' +
               '"' + Options.Values['FIRMA_REG_COM'] + '", ' +
               '"' + Options.Values['DAT_LIS'] + '", ' +
               '"' + StringReplace(Options.Values['PATH'], '\', '\\', [rfReplaceAll]) + '")');
//        Options.Values['STATIE'] := '1';
        SQLSettings.Values[Options.Values['FIRMA_CODFISCAL']] := SQLSettings.Values['SQL_DB'];
      end;
    end;
  finally
    f.Free;
  end;
end;

procedure TMainForm.btContClick(Sender: TObject);
var
  C: VM_Compiler;
  E: VM_LISTA;
  I: Integer;
  S: TStringList;
  SQL: string;
  Perioada: TMyPeriod;
  t: string;
  rec: integer;
begin
  if (ECont.Text = '') and bStandAlone then begin
    ShowMessage('Nu aveti filtre. Operatia selectata va dura extrem de mult.' + #13 + 'Se anuleaza.');
    Exit;
  end;
  btImportaClick(btCont);
  
  try
    Options.Values['CONT'] := ECont.Text;
    S := TStringList.Create;
    Perioada := TMyPeriod.Create;
    if bStandAlone then begin
      Perioada.SetDate(1, s2i(ELuna1.Text), s2i(EAn1.Text), psStart);
      Perioada.SetDate(s2i(EZi2.Text), s2i(ELuna2.Text), s2i(EAn2.Text), psEnd);
      GetFisaCont(q, S, ECont.Text, Perioada, rec, s2i(Options.Values['STATIE']));
    end else begin
      t := Options.Values['PERIOADA'];
      if t = '' then begin
        ShowMessage('Parametrul /perioada invalid.');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
        Exit;
      end else if Pos('-', t) = 0  then begin
        ShowMessage('Parametrul /perioada invalid.'#13'Exemplu: /perioada=0212-0412');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
        Exit;
      end;
      Perioada.SetSDate(Copy(t, 1, Pos('-', t) - 1), psStart);
      Perioada.SetSDate(UltimaZi(Copy(t, Pos('-', t) + 1), False, True) + Copy(t, Pos('-', t) + 1), psEnd);
      if Options.Values['CONT'] = '' then begin
        ShowMessage('Parametrul /cont invalid.'#13'Exemplu: /cont=462.01');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
        Exit;
      end;
      GetFisaCont(q, S, Options.Values['CONT'], Perioada, rec, s2i(Options.Values['STATIE']));
    end;

    S.Clear;
    C := VM_COMPILER.Create;
    C.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_CONT.LST');
    S.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_CONT.LST');
    I := C.Compile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_CONT.COD');
    if I <> 0 then begin
       ShowMessage(C.ERR_MSG+C.ERR_TEXT);
       Exit;
    end;
    if C.IP > C.Inst.Count-1 then
      C.Ip := C.Inst.Count-1;

    E := VM_LISTA.Create;
    E.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_CONT.COD');

    if not bStandAlone then begin
      t := Options.Values['PARAM_FP'];
      if t = '' then begin
        ShowMessage('Parametrul /param_fc invalid.'#13'Exemplu: /param_fc=1');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
        Exit;
      end;
      if l(t) <> 1 then begin
        ShowMessage('Parametrul /param_fc invalid.'#13'Exemplu: /param_fc=1');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
        Exit;
      end;
      if t[1] = '1' then //salt de pagina
        E.SetVAR_STR('CU_SALT', 'DA')
      else
        E.SetVAR_STR('CU_SALT', 'NU');
    end else begin
      if chSalt.Checked then E.SetVAR_STR('CU_SALT', 'DA') else E.SetVAR_STR('CU_SALT', 'NU');
    end;
    {if chIncludeCont.Checked then
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
      end;  }

    E.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_CONT.COD');
    E.OUT_FILE_NAME := Options.Values['PATH'] + '\LC_FISA_CONT' + Options.Values['STATIE'] + '.TXT';
    E.SetVAR_STR('DATA_LISTE', Options.Values['DAT_LIS']);
    E.SetVAR_STR('DATA_LISTARII', FormatDateTime('dd/mm/yyyy', Now));
    E.SetVAR_STR('LUNA_LITERE', LowerCase(Luni[StrToInt(ELuna1.Text)]));
    E.SetVAR_STR('ANUL', EAn1.Text);
    E.SetVAR_STR('LLAA', Perioada.GetFirst(4));

    E.SetVAR_NUM('RAND_MAX', s2i(MainForm.Options.Values['RAND_MAX']));
    E.SetVAR_STR('FIRMA.DENUMIRE', MainForm.Options.Values['FIRMA_DEN']);
    E.SetVAR_STR('FIRMA.COD_FISCAL', MainForm.Options.Values['FIRMA_CODFISCAL']);
    E.SetVAR_STR('PERIOADA', Perioada.GetFirst(10) + ' - ' + Perioada.GetLast(10));

    DoSQL(q,  'SELECT ' + E.GetSQL_FIELDS + ' ' +
              'FROM (' +
                'SELECT ' +
                  'TIPC, DENC, DEND, NRN, TIPN, FELN, NRDI, DATAI, EXPLIC, "" COD_FISCAL, FURCLI, DENFUR, DEBIT CONT, CREDIT CONT_COR, ' +
                  'SUMA DEBIT, 0 CREDIT, SUMA_VAL DB_VAL, 0 CR_VAL, TIP_VAL, INTIES ' +
                'FROM TMP_NOTE' + Options.Values['STATIE'] + ' LEFT JOIN FUR ON FURCLI = CODFUR LEFT JOIN TIPD ON TIPN=TIPD ' +
                'WHERE DEBIT = "' + Options.Values['CONT'] + '" ' +
                  'UNION ALL ' +
                'SELECT ' +
                  'TIPC, DENC, DEND, NRN, TIPN, FELN, NRDI, DATAI, EXPLIC, "" COD_FISCAL, FURCLI, DENFUR, CREDIT CONT, DEBIT CONT_COR, ' +
                  '0 DEBIT, SUMA CREDIT, 0 DB_VAL, SUMA_VAL CR_VAL, TIP_VAL, INTIES ' +
                'FROM TMP_NOTE' + Options.Values['STATIE'] + ' LEFT JOIN FUR ON FURCLI = CODFUR LEFT JOIN TIPD ON TIPN=TIPD ' +
                'WHERE CREDIT = "' + Options.Values['CONT'] + '") TEMP ' +
                'ORDER BY CONCAT(MID(DATAI,5,4),MID(DATAI,3,2),MID(DATAI,1,2)), NRDI, INTIES');

    if q.RecordCount = 0 then begin
      ShowMessage('Nu aveti inregistrata nici o nota contabila.');
      Exit;
    end;
    E.LDATASET := q;
    I := E.Exec(0);
    if I = 0 then begin
      listForm := TListForm.Create(Self);
      listForm.NumeLista := Options.Values['PATH'] + '\LC_FISA_CONT' + Options.Values['STATIE'] + '.TXT';
      listForm.Start(LIST_CAN_RELIST);
      listForm.Free;
    end;
  finally
    Perioada.Free;
    S.Free;
    C.Free;
    E.Free;
  end;

  {case cbTip.ItemIndex of
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
          Luna := RightStr('0' + IntToStr(StrToInt(Luna) + 1), 2);
          if Luna = '13' then begin
            Luna := '01';
            An := RightStr('0' + IntToStr(StrToInt(An) + 1), 2);
          end;
        end;
        SQL := Copy(SQL, 1, Length(SQL) - 10);
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
        end;
  end;    }
end;

procedure TMainForm.Btn_PartenerClick(Sender: TObject);
var
  s: string;
begin
  s := GetPartners(EPartener.Text);
  if s <> '' then EPartener.Text := s;
end;

procedure TMainForm.btOptionsClick(Sender: TObject);
var
  f: TGUI_Optiuni;
begin
  try
    f := TGUI_Optiuni.Create(Self);
    with f do begin
      eDenumire.Text := Options.Values['FIRMA_DEN'];
      eCodFiscal.Text := Options.Values['FIRMA_CODFISCAL'];
      eRegCom.Text := Options.Values['FIRMA_REG_COM'];
      eNrRanduri.Text := Options.Values['RAND_MAX'];
      ePath.Text := Options.Values['PATH'];
      //ePath.Enabled := False;
      eSQL_DB.Text := SQLSettings.Values['SQL_DB'];
      eSQL_DB.Enabled := False;
      if Options.Values['DATA_LIS'] = 'DA' then chDataListe.Checked := True;
      if Options.Values['FORCE'] = 'DA' then chForce.Checked := True;
      f.Tag := 0;
      if f.ShowModal <> mrCancel then begin
        DoSQL(q, 'DELETE FROM SETARI WHERE STATIE = ' + Options.Values['STATIE']);
        DoSQL(q, 'INSERT INTO SETARI (STATIE, MAC, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH) VALUES (' +
               Options.Values['STATIE'] + ', "' + Options.Values['MAC'] + '", ' + Options.Values['RAND_MAX'] + ', ' +
               '"' + Options.Values['FIRMA_DEN'] + '", ' +
               '"' + Options.Values['FIRMA_CODFISCAL'] + '", ' +
               '"' + Options.Values['FIRMA_REG_COM'] + '", ' +
               '"' + Options.Values['DAT_LIS'] + '", ' +
               '"' + StringReplace(Options.Values['PATH'], '\', '\\', [rfReplaceAll]) + '")');
        SQLSettings.Values[Options.Values['FIRMA_CODFISCAL']] := SQLSettings.Values['SQL_DB'];
      end;
    end;
  finally
    f.Free;
  end;
end;

procedure TMainForm.btPartenerClick(Sender: TObject);
var
  Ctr1, Ctr2, Freq, Overhead: int64;
  R: extended;
  recCount: integer;

  Perioada: TMyPeriod;
  rec: integer;
  C: VM_Compiler;
  E: VM_LISTA;
  I: Integer;
  S: TStringList;
  t: string;
  p: string;
//  listForm: TListForm;
begin
  if (EPartener.Text = '') and (ECont.Text = '') and bStandAlone then begin
    ShowMessage('Nu aveti filtre. Operatia selectata va dura extrem de mult.' + #13 + 'Se anuleaza.');
    Exit;
  end;
  if ECont.Text <> '' then
    if DoSQL(q, 'SELECT DISTINCT CONT FROM PLC00 ' +
                'WHERE (ANALITIC <> "") AND (LOCATE("9", TIP_SOC)) AND (LEFT("' + ECont.Text + '", LENGTH(CONT)) = CONT) ' +
                'ORDER BY LENGTH(CONT)') = 0 then
      ShowMessage('Contul introdus nu are urmarire.');

  btImportaClick(btPartener);

  try
    try
      p := GetCurrentDir;
      SetCurrentDir(Options.Values['EXE_PATH']);

      Perioada := TMyPeriod.Create;
      S := TStringList.Create;

      if bStandAlone then begin
        Perioada.SetDate(1, s2i(ELuna1.Text), s2i(EAn1.Text), psStart);
        Perioada.SetDate(s2i(EZi2.Text), s2i(ELuna2.Text), s2i(EAn2.Text), psEnd);
        Options.Values['CODFUR'] := Copy(EPartener.Text, 1, Pos('|', EPartener.Text) - 1);
        Options.Values['CONT'] := ECont.Text;
        GetFisaPartener(q, Options.Values['CODFUR'], Options.Values['CONT'], Perioada, rec, s2i(Options.Values['STATIE']));
      end else begin
        t := Options.Values['PERIOADA'];
        if t = '' then begin
          ShowMessage('Parametrul /perioada invalid.');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end else if Pos('-', t) = 0  then begin
          ShowMessage('Parametrul /perioada invalid.'#13'Exemplu: /perioada=0212-0412');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;
        Perioada.SetSDate(Copy(t, 1, Pos('-', t) - 1), psStart);
        Perioada.SetSDate(UltimaZi(Copy(t, Pos('-', t) + 1), False, True) + Copy(t, Pos('-', t) + 1), psEnd);
        if Options.Values['CONT'] = '' then begin
          ShowMessage('Parametrul /cont invalid.'#13'Exemplu: /cont=462.01');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;
        if Options.Values['CODFUR'] = '' then begin
          ShowMessage('Parametrul /codfur invalid.'#13'Exemplu: /codfur=RO123456789');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;
        GetFisaPartener(q, Options.Values['CODFUR'], Options.Values['CONT'], Perioada, rec, s2i(Options.Values['STATIE']));
      end;


      S.Clear;
      C := VM_COMPILER.Create;
      C.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_FC.LST');
      S.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_FC.LST');
      I := C.Compile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_FC.COD');
      if I <> 0 then begin
         ShowMessage(C.ERR_MSG+C.ERR_TEXT);
         Exit;
      end;
      if C.IP > C.Inst.Count-1 then
        C.Ip := C.Inst.Count-1;

      E := VM_LISTA.Create;
      E.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_FC.COD');

      if not bStandAlone then begin
        p := Options.Values['PARAM_FP'];
        if p = '' then begin
          ShowMessage('Parametrul /param_fp invalid.'#13'Exemplu: /param_fp=101');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;
        if l(p) <> 3 then begin
          ShowMessage('Parametrul /param_fp invalid.'#13'Exemplu: /param_fp=101');
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
          Exit;
        end;

        if p[1] = '1' then begin //defalcat pe incasari
          E.SetVAR_BOL('DEFALCAT', True);
          t := ', NRDE, DATAE';
        end else begin
          E.SetVAR_BOL('DEFALCAT', False);
          t := '';
        end;

        if p[2] = '1' then begin //componenta
          E.SetVAR_BOL('COMPONENTA', True);
          Perioada.First;
          Perioada.Prev;
          E.SetVAR_STR('LA_SOLD_P', Perioada.GetCurrentDate(4));
          E.SetVAR_STR('LA_SOLD_F', Perioada.GetLast(4));
        end else
          E.SetVAR_BOL('COMPONENTA', False);           

        if p[3] = '1' then //salt de pagina
          E.SetVAR_STR('CU_SALT', 'DA')
        else
          E.SetVAR_STR('CU_SALT', 'NU');
      end else begin
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
          t := ', NRDE, DATAE';
        end else begin
          E.SetVAR_BOL('DEFALCAT', False);
          t := '';
        end;
      end;
      DoSQL(q,
        'SELECT ' + E.GetSQL_FIELDS + ' ' +
        'FROM TMP_RUFC' + Options.Values['STATIE'] + ' LEFT JOIN FUR USING(CODFUR) ' +
        'GROUP BY CODFUR, NRDI, DATAI' + t + ', CONTFC, NRN ' +
        'ORDER BY CONTFC, DENFUR, CODFUR, CONCAT(MID(DATAI,5,4),MID(DATAI,3,2),MID(DATAI,1,2)), NRDI, NRDE');
      E.LoadFromFile(Options.Values['EXE_PATH'] + '\LISTE\LC_FISA_FC.COD');
      E.OUT_FILE_NAME := Options.Values['PATH'] + '\LC_FISA_FC' + Options.Values['STATIE'] + '.TXT';
      E.LDATASET := q;

      E.SetVAR_NUM('RAND_MAX', s2i(MainForm.Options.Values['RAND_MAX']));
      E.SetVAR_STR('FIRMA.DENUMIRE', MainForm.Options.Values['FIRMA_DEN']);
      E.SetVAR_STR('FIRMA.COD_FISCAL', MainForm.Options.Values['FIRMA_CODFISCAL']);
      E.SetVAR_STR('PERIOADA', Perioada.GetFirst(10) + ' - ' + Perioada.GetLast(10));
      E.SetVAR_STR('CODFUR', Options.Values['CODFUR']);
      E.SetVAR_STR('CONT', Options.Values['CONT']);

      I := E.Exec(0);
      if I = 0 then begin
        listForm := TListForm.Create(Self);
        listForm.NumeLista := Options.Values['PATH'] + '\LC_FISA_FC' + Options.Values['STATIE'] + '.TXT';
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

procedure TMainForm.cbFirmeChange(Sender: TObject);
begin
  try
    //DoSQL(q, 'UPDATE SETARI SET STATIE = IF(STATIE < 1, 1, STATIE - 1)'); //db is still the same
    SQLSettings.Values['SQL_DB'] := cbFirme.Text;
    DoSQL(q, 'USE ' + cbFirme.Text);
    InitDB(cbFirme.Text, false);
    GetTerminalNUmber;
    if DoSQL(q, 'SELECT STATIE, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' +
                 'FROM SETARI WHERE MAC="' + Options.Values['MAC'] + '"') > 0 then begin
      Options.Values['RAND_MAX'] := q.FieldByName('RAND_MAX').AsString;
      Options.Values['FIRMA_DEN'] := UpperCase(q.FieldByName('FIRMA_DEN').AsString);
      Options.Values['FIRMA_CODFISCAL'] := UpperCase(q.FieldByName('FIRMA_CODFISCAL').AsString);
      Options.Values['FIRMA_REG_COM'] := UpperCase(q.FieldByName('FIRMA_REG_COM').AsString);
      Options.Values['DATA_LIS'] := UpperCase(q.FieldByName('DAT_LIS').AsString);
      Options.Values['PATH'] := UpperCase(q.FieldByName('PATH').AsString);
      Options.Values['STATIE'] := UpperCase(q.FieldByName('STATIE').AsString);
//      DoSQL(q, 'UPDATE SETARI SET STATIE = STATIE + 1');
//      if Options.Values['STATIE'] = '0' then Options.Values['STATIE'] := '1';
    end else begin
      Options.Values['STATIE'] := GetTerminalNumber;
      if (SQLSettings.Values['USE_DEFAULTS']<>'') then begin
        DoSQL(q, 'INSERT INTO SETARI (STATIE, MAC, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH) ' +
                    'SELECT ' +
                      '"' + Options.Values['STATIE'] + '", "' + Options.Values['MAC'] + '", ' +
                      'RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' + 
                    'FROM SETARI ' +
                    'WHERE MAC = "00-00-00-00-00-00"');
        if DoSQL(q, 'SELECT STATIE, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' +
                 'FROM SETARI WHERE MAC="' + Options.Values['MAC'] + '"') > 0 then begin
          Options.Values['RAND_MAX'] := q.FieldByName('RAND_MAX').AsString;
          Options.Values['FIRMA_DEN'] := UpperCase(q.FieldByName('FIRMA_DEN').AsString);
          Options.Values['FIRMA_CODFISCAL'] := UpperCase(q.FieldByName('FIRMA_CODFISCAL').AsString);
          Options.Values['FIRMA_REG_COM'] := UpperCase(q.FieldByName('FIRMA_REG_COM').AsString);
          Options.Values['DATA_LIS'] := UpperCase(q.FieldByName('DAT_LIS').AsString);
          Options.Values['PATH'] := UpperCase(q.FieldByName('PATH').AsString);
        end;           
      end else begin
        btAddFirmaClick(nil); ///VERIFICA!!!!!!!!!!!!!!!!!!!!!!
      end;
    end;
    LStatia.Caption := 'Statia: ' + Options.Values['STATIE'];
  except
    on e: Exception do ProcessException(e,'');
  end;
end;

procedure TMainForm.btImportaClick(Sender: TObject);
var
  s: string;
  Ctr1, Ctr2, Freq, Overhead: int64;
  R: extended;
  t: double;
  recCount: integer;
  totalRec: integer;
  slFiles: TStringList;
  i: byte;
  p: string;
  sql: string;
//  mem: cardinal;
begin
  if bStandAlone then
    Self.ClientHeight := 419;
  p := GetCurrentDir;
  SetCurrentDir(Options.Values['PATH']);
  myPeriod := TMyPeriod.Create;
  myPeriod.Free;
  myPeriod := TMyPeriod.Create;
  if bStandAlone then begin
    myPeriod.SetDate(s2i(EZi1.Text), s2i(ELuna1.Text), s2i(EAn1.Text), psStart);
    myPeriod.SetDate(s2i(EZi2.Text), s2i(ELuna2.Text), s2i(EAn2.Text), psEnd);
  end else begin
    s := Options.Values['PERIOADA'];
    if s = '' then begin
      ShowMessage('Parametru /perioada invalid.');
      Application.Terminate;
      Options.Values['TERMINATING'] := '1';
      Exit;
    end else if Pos('-', s) = 0  then begin
      ShowMessage('Parametru /perioada invalid.'#13'Exemplu: /perioada=0212-0412.');
      Application.Terminate;
      Options.Values['TERMINATING'] := '1';
      Exit;
    end;
    myPeriod.SetSDate(Copy(s, 1, Pos('-', s) - 1), psStart);
    myPeriod.SetSDate(Copy(s, Pos('-', s) + 1), psEnd);
  end;

  slExistingTables := GetTableList(q, SQLSettings.Values['SQL_DB']);

  slFiles := TStringList.Create;
  slFiles.Add('RMAT'); slFiles.Add('RULA'); slFiles.Add('RNIR');
  slFiles.Add('PLFC'); slFiles.Add('FRES'); slFiles.Add('PLC');

  if (TCOmponent(Sender).Name = 'btCont') or (Options.Values['TIP_LISTA'] = 'FC') then begin
    slFiles.Add('RMTR'); slFiles.Add('RMIF');
  end;

  pbGlobal.Max := myPeriod.Months * slFiles.Count + 4;

  pbGlobal.Position := 0;
  t := 0;
  totalRec := 0;
  slImportedTables := InitDB(SQLSettings.Values['SQL_DB'], bStandAlone);
  myPeriod.First;
  while not myPeriod.Eof do begin
    for i := 0 to slFiles.Count - 1 do begin
      QueryPerformanceFrequency(Freq); QueryPerformanceCounter(Ctr1); QueryPerformanceCounter(Ctr2);
      Overhead := Ctr2 - Ctr1; QueryPerformanceCounter(Ctr1);
      lFile.Caption := 'Importing ' + slFiles[i] + myPeriod.GetCurrentDate(4) + '.DBF';
//      mem := GetMemoryUsed;
    {$IFDEF LOAD_FROM_FILE}
      recCount := LoadDBF(Options.Values['PATH'] + '\' + slFiles[i] + myPeriod.GetCurrentDate(4), pbFile, 1);
    {$ELSE}
      recCount := LoadDBF(Options.Values['PATH'] + '\' + slFiles[i] + myPeriod.GetCurrentDate(4), pbFile);
    {$ENDIF}
//      if mem <> (GetMemoryUsed) then
//        ShowMessage('Leaks: ' + i2s(GetMemoryUsed - mem) + ' bytes');
      if (SQLSettings.Values['SQL_'+slFiles[i]] <> '') then begin
        sql := StringReplace(SQLSettings.Values['SQL_'+slFiles[i]], '$LUNA', Copy(myPeriod.GetCurrentDate(4), 1, 2), [rfReplaceAll, rfIgnoreCase]);
        sql := StringReplace(sql, '$AN', Copy(myPeriod.GetCurrentDate(4), 3, 2), [rfReplaceAll, rfIgnoreCase]);
        DoSQL(q, sql);
      end;
      if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
      QueryPerformanceCounter(Ctr2); R := ((Ctr2 - Ctr1) - Overhead) / Freq; t := t + Round(R*100000)/100000;
      mDebug.Lines.Add(slFiles[i] + myPeriod.GetCurrentDate(4) + ': ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
      pbGlobal.Position := pbGlobal.Position + 1;
      Application.ProcessMessages;
    end;
    myPeriod.Next;
  end;
  myPeriod.First;
  myPeriod.Prev;
  {FRESALLAA}
  lFile.Caption := 'Importing FRES' + myPeriod.GetCurrentDate(4) + '.DBF';
  recCount := LoadDBF(Options.Values['PATH'] + '\FRES' + myPeriod.GetCurrentDate(4) + '.DBF', pbFile);
  if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
  mDebug.Lines.Add('FRES' + myPeriod.GetCurrentDate(4) + ': ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
  pbGlobal.Position := pbGlobal.Position + 1;
  {FRESALLAA}
  {TIPD}
  lFile.Caption := 'Importing TIPD.DBF';
  recCount := LoadDBF(Options.Values['PATH'] + '\TIPD.DBF', pbFile);
  if recCount <> -1 then DoSQL(q, 'ALTER TABLE TIPD ADD INDEX `TIPD` (`TIPD`)');
  if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
  mDebug.Lines.Add('TIPD: ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
  pbGlobal.Position := pbGlobal.Position + 1;
  {TIPDI}
  {PLC00}
  lFile.Caption := 'Importing PLC00.DBF';
  recCount := LoadDBF(Options.Values['PATH'] + '\PLC00.DBF', pbFile);
  if recCount <> -1 then
    DoSQL(q, 'ALTER TABLE PLC00 ADD INDEX `CONT` (`CONT`)');
  if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
  mDebug.Lines.Add('PLC00: ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
  pbGlobal.Position := pbGlobal.Position + 1;
  {PLC00}
  {FUR}
  lFile.Caption := 'Importing FUR.DBF';
  recCount := LoadDBF(Options.Values['PATH'] + '\FUR.DBF', pbFile);
  if recCount <> -1 then
    DoSQL(q, 'ALTER TABLE FUR ADD INDEX `CODFUR` (`CODFUR`)');
  if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
  mDebug.Lines.Add('FUR: ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
  pbGlobal.Position := pbGlobal.Max;
  {FUR}
  mDebug.Lines.Add('---------------------------------');
  mDebug.Lines.Add('Total imported: ' + i2s(totalRec) + ' rec. :' + FloatToStr(t) + ' seconds');
  mDebug.Lines.Add('---------------------------------');
  lFile.Caption := '';

  myPeriod.Free;
  slFiles.Free;
  slImportedTables.Free;
  slExistingTables.Free;
  Options.Values['FORCE'] := 'NU';

  SetCurrentDir(p);
  if bStandAlone then
    Self.ClientHeight := 272;
end;

procedure TMainForm.EditKeyPress(Sender: TObject; var Key: Char);
var
  l: byte;
  s: string;
begin
  if Sender = nil then Exit;
  if Key = #13 then begin
    SelectNext(ActiveControl, True, True);
    Key := #0;
  end;
end;

procedure TMainForm.EPartenerKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then begin
    if (Pos('|',EPartener.Text) = 0) then begin
      Btn_PartenerClick(Self);
    end;
    SelectNext(ActiveControl, True, True);
    Key := #0;
  end;
  if Key <> #0 then Key := UpCase(Key);
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if not bStandAlone then begin
    if Options.Values['SHOW'] = '1' then Exit;

    if Options.Values['TIP_LISTA'] = 'FP' then
      btPartenerClick(nil)
    else if Options.Values['TIP_LISTA'] = 'FC' then
      btContClick(nil)
    else
      ShowMessage('Parametrul /tip_lista este invalid');
    Close;
    Options.Values['TERMINATING'] := '1';
    Exit;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SQLSettings.SaveToFile(Options.Values['EXE_PATH'] + '\setari.ini');
end;

function TMainForm.GetNextFreeTerminalNumber: integer;
var
  I: Integer;
begin
  Result := 1;
  if not db.Connected then Exit;
  DoSQL(q, 'SELECT STATIE FROM SETARI WHERE MAC <> "00-00-00-00-00-00" ORDER BY STATIE');
  i := 1;
//  while not q.Eof do begin
//    if not q.Locate('STATIE', i2s(i), []) then begin
  while q.Locate('STATIE', i2s(i), []) do begin
    inc(i);
//    Break;
//  end else begin
//    q.Next;
//  end;
  end;
  Result := i;                                       
end;

function TMainForm.GetTerminalNumber: string;
var
  AForm: TtxtInput;
  slTemp: tStringList;
  i: integer;
  s: string;
begin
  try
    slTemp := tStringList.Create;
    Options.Values['MAC_LIST'] := GetWin32_NetworkAdapterMACList;
    if SQLSettings.Values['ASK_FOR_TERMINAL_ID'] <> '' then
      Options.Values['MAC_LIST'] := '';
    if Options.Values['MAC_LIST'] <> '' then begin
      slTemp.Sorted := True;
      slTemp.Duplicates := dupIgnore;
      slTemp.Delimiter := '|';
      slTemp.DelimitedText := Options.Values['MAC_LIST'];
      i := DoSQL(q, 'SELECT MAC, STATIE FROM SETARI ORDER BY MAC');
      if i > 0 then begin
        i := 0;
        while not q.Eof do begin
          if inStr(q.Fields[0].AsString, Options.Values['MAC_LIST']) then begin
            i := q.Fields[1].AsInteger;
            break;
          end else begin
            q.Next;
          end;
        end;
      end;
      if i = 0 then
        i := GetNextFreeTerminalNumber;
      Options.Values['MAC'] := Copy(Options.Values['MAC_LIST'], 1, Pos('|', Options.Values['MAC_LIST']) - 1);
      Options.Values['STATIE'] := i2s(i);
      InitDB(SQLSettings.Values['SQL_DB']);//Verify if terminal is intitiated
      Result := i2s(i);
    end else 
      //Cause an exception which will move to the except branch and ask for terminal ID
      RaiseEx('EMACNotFound','Could not identify any MAC adresses.');
    slTemp.Free;
  except
    AForm := TtxtInput.Create(Self); //Ask user for terminal number
    with AForm do begin
      LTitlu.Caption := 'Statia';
      LsubTitle.Caption := 'Numarul statiei';
      eInput.Left := LsubTitle.Left + LsubTitle.Width + 5;
      eInput.Width := pInput.Width - eInput.Left - eInput.Top;
    end;
    s := AForm.Start('S');
    AForm.Free;
    if GetDigits(s) = 0 then begin
      Options.Values['TERMINATING'] := '1'; //Anything besides empty string will stop the program
      Exit;
    end else
      Result := s;
  end;
end;

procedure TMainForm.Update;
var
  DoRestart: boolean;
  s: string;
begin
  DoRestart := False;
  Application.CreateForm(TFBMAUpdate, FBMAUpdate);
  with FBMAUpdate do begin
    URLDescarcare := 'http://appsupdates.dsoft.ro/fisectb/dsfise.exe';
    CaleFinalaFisier := Application.ExeName;
    Vizibil := True;
    Intrebare := bStandAlone;
    Aplicatie := 'Listare Fise';
    URLVerificare := 'http://appsupdates.dsoft.ro/ver.php?APP=fisectb/dsfise.exe';
    //http://appsupdates.dsoft.ro/ver.php?APP=exportwb/browse.zip
    //raspunsul primit este 0.0.0.0_hhmmsszzllaaaa
    VerificareStr := GetExeVer(Application.ExeName);
    MesajEroare := 'Eroare la actualizare !';
    MesajNoRights := 'Nu aveti dreptul sa actualizati !';
    MesajNotNecesar := '';
    DoRestart := Actualizare <> '';
    URLDescarcare := 'http://appsupdates.dsoft.ro/fisectb/dsfise.zip';
    CaleFinalaFisier := ChangeFileExt(Application.ExeName,'.zip');
    Vizibil := True;
    Intrebare := bStandAlone;
    Aplicatie := 'Listare Fise';
    URLVerificare := 'http://appsupdates.dsoft.ro/ver.php?APP=fisectb/dsfise.zip';
    //http://appsupdates.dsoft.ro/ver.php?APP=exportwb/browse.zip
    //raspunsul primit este 0.0.0.0_hhmmsszzllaaaa
    VerificareStr := SQLSettings.Values['LST_DATE'];
    MesajEroare := 'Eroare la actualizare !';
    MesajNoRights := 'Nu aveti dreptul sa actualizati !';
    MesajNotNecesar := '';
    s := Actualizare;
    if s <> '' then begin
      DoRestart := True;
      SQLSettings.Values['LST_DATE'] := s;
      SQLSettings.SaveToFile(Options.Values['EXE_PATH'] + '\setari.ini');
      ZF.BaseDir := ExtractFilePath(Application.ExeName);
      ZF.FileName := CaleFinalaFisier;
      ZF.OpenArchive;
      ZF.ExtractFiles;
      ZF.CloseArchive;
    end;

    if DoRestart then begin
      Options.Values['TERMINATING'] := 'R';
      Application.Terminate;
      Abort;
    end;
    Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  slParams: TStringList;
  I: Integer;
  allOk: boolean;
  s: string;

begin
  {Init tStringLists}
  SQLSettings := TStringList.Create;
  Options := TStringList.Create;
  slParams := TStringList.Create;
  {Init tStringLists}

  Caption := 'Listare fise v' + GetExeVer(Application.ExeName) + '. Contact 0721.218972';

  {GetPaths}
  Options.Values['EXE_PATH'] := ExtractFilePath(Application.ExeName);
  SQLSettings.LoadFromFile(Options.Values['EXE_PATH'] + '\setari.ini');
  {GetPaths}

  {Check if standalone}
  if ParamCount = 0 then bStandAlone := True
  else bStandAlone := false;                        
  {Check if standalone}

  {Compile list of params}
  for I := 1 to ParamCount - 1 do
    Options.Values['PARAMS'] := Options.Values['PARAMS'] + ' ' + ParamStr(i);
  {Compile list of params}

  {Update}
  Update;
  SQLSettings.Clear;
  {Update}

  {Load parameters}
  if not bStandAlone then begin //Called with params
    Self.ClientHeight := 72;
    sPanel4.Visible := False;
    pPeriod.Visible := False;
    pCont.Visible := False;
    pPartner.Visible := False;
    pOptions.Visible := False;
    sPanel3.Visible := False;
    sPanel2.Align := alTop;
    sPanel1.Align := alTop;

    s := '';
    Options.Values['PATH'] := GetCurrentDir;
    for I := 1 to ParamCount do begin
      slParams.Add(UpperCase(ParamStr(I)));
      s := s + UpperCase(ParamStr(I));
    end;
    DoLogging(s, True);

    {Translate params into Options}
    try
      allOk := true;
      if slParams.IndexOf('/SHOW') <> -1 then
        Options.Values['SHOW'] := '1';

      if slParams.Values['/CODFISCAL'] = '' then begin
        RaiseEx('EPrelParams','Eroare la preluarea /codfiscal');
        Exit;
      end
        else Options.Values['FIRMA_CODFISCAL'] := slParams.Values['/CODFISCAL'];

      if slParams.Values['/PERIOADA'] = '' then begin
        RaiseEx('EPrelParams','Eroare la preluarea /perioada');
        Exit;
      end
        else Options.Values['PERIOADA'] := slParams.Values['/PERIOADA'];

      if slParams.Values['/CONT'] = '' then begin
        RaiseEx('EPrelParams','Eroare la preluarea /cont');
        Exit;
      end
        else Options.Values['CONT'] := slParams.Values['/CONT'];

      if (slParams.Values['/CODFUR'] = '') and (slParams.Values['/TIP_LISTA'] = 'FP') then begin
        RaiseEx('EPrelParams','Eroare la preluarea /codfur');
        Exit;
      end
        else Options.Values['CODFUR'] := slParams.Values['/CODFUR'];

      if slParams.Values['/TIP_LISTA'] = '' then begin
        RaiseEx('EPrelParams','Eroare la preluarea /tip_lista');
        Exit;
      end
        else Options.Values['TIP_LISTA'] := slParams.Values['/TIP_LISTA'];

      if Options.Values['TIP_LISTA'] = 'FP' then begin
        if slParams.Values['/PARAM_FP'] = '' then begin
          RaiseEx('EPrelParams','Eroare la preluarea /param_fp');
          Exit;
        end
          else Options.Values['PARAM_FP'] := slParams.Values['/PARAM_FP'];
      end else
        if Options.Values['TIP_LISTA'] = 'FC' then begin
          if slParams.Values['/PARAM_FC'] = '' then begin
            RaiseEx('EPrelParams','Eroare la preluarea /param_fc');
            Exit;
          end
            else Options.Values['PARAM_FC'] := slParams.Values['/PARAM_FC'];
      end else
        begin
          RaiseEx('EPrelParams','Valoarea /tip_lista invalida');
          Exit;
        end
    except
      on E: Exception do begin
        ProcessException(E, '');
        Application.Terminate;
        Options.Values['TERMINATING'] := '1';
      end;
    end;

    {Select DB based on CODFISCAL}
    if FileExists(Options.Values['EXE_PATH'] + '\setari.ini') then begin
      SQLSettings.LoadFromFile(Options.Values['EXE_PATH'] + '\setari.ini');
      db.AliasName := SQLSettings.Values['SQL_ALIAS'];
      db.DatabaseName := 'mysql';
      db.Params.Clear;
      db.Params.Add('USER NAME=' + SQLSettings.Values['SQL_USER']);
      if SQLSettings.Values['SQL_PASSWORD'] <> '' then
        db.Params.Add('PASSWORD=' + SQLSettings.Values['SQL_PASSWORD']);
      db.LoginPrompt := False;
      db.Connected := True;
      q.DatabaseName := 'mysql';
      SQLSettings.Values['SQL_DB'] := ''; //reset in case of parametrized run
      if SQLSettings.Values[Options.Values['FIRMA_CODFISCAL']] <> '' then
        SQLSettings.Values['SQL_DB'] := SQLSettings.Values[Options.Values['FIRMA_CODFISCAL']]; //Grab sql_db from ini
      if SQLSettings.Values['SQL_DB'] = '' then begin
        SQLSettings.Values['SQL_DB'] := 'mysql';
        btAddFirmaClick(nil);
        if Options.Values['TERMINATING'] <> '' then Exit;
      end else begin
        InitDB(SQLSettings.Values['SQL_DB']);
      end;
      try
        q.DatabaseName := db.DatabaseName;
        DoSQL(q, 'USE ' + SQLSettings.Values['SQL_DB']);
        if DoSQL(q, 'SELECT ' +
                      'STATIE, RAND_MAX, FIRMA_DEN, FIRMA_REG_COM, DAT_LIS, PATH ' +
                    'FROM SETARI') > 0 then begin
          Options.Values['RAND_MAX'] := q.FieldByName('RAND_MAX').AsString;
          Options.Values['FIRMA_DEN'] := UpperCase(q.FieldByName('FIRMA_DEN').AsString);
//          Options.Values['FIRMA_CODFISCAL'] := UpperCase(q.FieldByName('FIRMA_CODFISCAL').AsString);
          Options.Values['FIRMA_REG_COM'] := UpperCase(q.FieldByName('FIRMA_REG_COM').AsString);
          Options.Values['DATA_LIS'] := UpperCase(q.FieldByName('DAT_LIS').AsString);
          Options.Values['PATH'] := UpperCase(q.FieldByName('PATH').AsString);
          Options.Values['STATIE'] := UpperCase(q.FieldByName('STATIE').AsString);
          DoSQL(q, 'UPDATE SETARI SET STATIE = STATIE + 1');
          if Options.Values['STATIE'] = '0' then Options.Values['STATIE'] := '1';
        end else
          btAddFirmaClick(nil);
      finally
      end;
    end;
    {/Select DB based on CODFISCAL}
    {/Translate params into Options}
  end else begin //Called without params
    if FileExists(GetCurrentDir + '\setari.ini') then begin
      slParams.LoadFromFile(GetCurrentDir + '\setari.ini');
      SQLSettings.AddStrings(slParams);
      
      {Set up DB}
      db.AliasName := SQLSettings.Values['SQL_ALIAS'];
      db.DatabaseName := SQLSettings.Values['SQL_DB'];
      db.Params.Clear;
      db.Params.Add('USER NAME=' + SQLSettings.Values['SQL_USER']);
      if SQLSettings.Values['SQL_PASSWORD'] <> '' then
        db.Params.Add('PASSWORD=' + SQLSettings.Values['SQL_PASSWORD']);
      db.LoginPrompt := False;
      {/Set up DB}
      
      try
        db.Connected := True;
        if not db.Connected then begin ShowMessage('Eroare la conectare:' + SQLSettings.Values['SQL_DB']); Exit; end;
        q.DatabaseName := db.DatabaseName;
        SQLSettings.Values['SQL_DB'] := VerifyDBName(SQLSettings.Values['SQL_DB']);
        DoSQL(q, 'CREATE DATABASE IF NOT EXISTS ' + SQLSettings.Values['SQL_DB']);
        DoSQL(q, 'USE ' + SQLSettings.Values['SQL_DB']); //I can start grabbing the terminal number
        InitDB(SQLSettings.Values['SQL_DB'], false);
        Options.Values['STATIE'] := GetTerminalNumber;
        if Options.Values['STATIE'] = '' then begin
          Application.Terminate;
          Options.Values['TERMINATING'] := '1';
        end;
        if DoSQL(q, 'SELECT STATIE, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' +
                    'FROM SETARI WHERE STATIE = ' + Options.Values['STATIE']) > 0 then begin
          Options.Values['RAND_MAX'] := q.FieldByName('RAND_MAX').AsString;
          Options.Values['FIRMA_DEN'] := UpperCase(q.FieldByName('FIRMA_DEN').AsString);
          Options.Values['FIRMA_CODFISCAL'] := UpperCase(q.FieldByName('FIRMA_CODFISCAL').AsString);
          Options.Values['FIRMA_REG_COM'] := UpperCase(q.FieldByName('FIRMA_REG_COM').AsString);
          Options.Values['DATA_LIS'] := UpperCase(q.FieldByName('DAT_LIS').AsString);
          Options.Values['PATH'] := UpperCase(q.FieldByName('PATH').AsString);
          Options.Values['STATIE'] := UpperCase(q.FieldByName('STATIE').AsString);
        end else begin
        {Settings need to intiated}
//        Options.Values['STATIE'] := GetTerminalNumber;
          if (SQLSettings.Values['USE_DEFAULTS']<>'') then begin
            DoSQL(q, 'INSERT INTO SETARI (STATIE, MAC, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH) ' +
                        'SELECT ' +
                          '"' + Options.Values['STATIE'] + '", "' + Options.Values['MAC'] + '", ' +
                          'RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' + 
                        'FROM SETARI ' +
                        'WHERE MAC = "00-00-00-00-00-00"');
            if DoSQL(q, 'SELECT STATIE, RAND_MAX, FIRMA_DEN, FIRMA_CODFISCAL, FIRMA_REG_COM, DAT_LIS, PATH ' +
                     'FROM SETARI WHERE MAC="' + Options.Values['MAC'] + '"') > 0 then begin
              Options.Values['RAND_MAX'] := q.FieldByName('RAND_MAX').AsString;
              Options.Values['FIRMA_DEN'] := UpperCase(q.FieldByName('FIRMA_DEN').AsString);
              Options.Values['FIRMA_CODFISCAL'] := UpperCase(q.FieldByName('FIRMA_CODFISCAL').AsString);
              Options.Values['FIRMA_REG_COM'] := UpperCase(q.FieldByName('FIRMA_REG_COM').AsString);
              Options.Values['DATA_LIS'] := UpperCase(q.FieldByName('DAT_LIS').AsString);
              Options.Values['PATH'] := UpperCase(q.FieldByName('PATH').AsString);
            end;           
          end else begin
            btAddFirmaClick(nil); ///VERIFICA!!!!!!!!!!!!!!!!!!!!!!
          end;
//          btAddFirmaClick(nil);
        end;
        LStatia.Caption := 'Statia: ' + Options.Values['STATIE'];
      finally
      end;
    end;
  end;
  {Load parameters}
  slParams.Free;
  {remaining initializations}
//  Options.Values['FORCE'] := 'DA';
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: integer;
  J: integer;
  Ctr1, Ctr2, Freq, Overhead: int64;
  R: extended;
  t: double;
  recCount: integer;
  totalRec: integer;
  slPerformance: TStringList;
begin
  if (Key = VK_F2) and (ssCtrl in Shift) then begin
    if Self.ClientHeight = 419 then begin
      Self.ClientHeight := 272;
    end else begin
      Self.ClientHeight := 419;
      mDebug.Lines.Add('----------Options---------');
      mDebug.Lines.AddStrings(Options);
      mDebug.Lines.Add('----------Options---------');
      mDebug.Lines.Add('-------SQLSetttings-------');
      mDebug.Lines.AddStrings(SQLSettings);
      mDebug.Lines.Add('-------SQLSetttings-------');
    end;
  end;
  {if (Key = VK_F3) and (ssCtrl in Shift) then begin
    if Self.ClientHeight = 419 then begin
      Self.ClientHeight := 272;
    end else begin
      slImportedTables := InitDB(SQLSettings.Values['SQL_DB'], bStandAlone);
      Self.ClientHeight := 419;
      SetCurrentDir(Options.Values['PATH']);
      slPerformance := TStringList.Create;
      for j := 1 to 50 do begin
        for I := 1 to 5 do begin
          QueryPerformanceFrequency(Freq); QueryPerformanceCounter(Ctr1); QueryPerformanceCounter(Ctr2);
          Overhead := Ctr2 - Ctr1; QueryPerformanceCounter(Ctr1);

          lFile.Caption := 'Importing FUR.DBF';
          recCount := LoadDBF('D:\DSOFT\MONDO\FRES1110', nil, I);

          if recCount = -1 then recCount := 0; totalRec := totalRec + recCount;
          QueryPerformanceCounter(Ctr2); R := ((Ctr2 - Ctr1) - Overhead) / Freq; t := t + Round(R*100000)/100000;
          sMemo1.Lines.Add(i2s(I) + ':FUR: ' + i2s(recCount) + ' rec. :' + FloatToStr(Round(R*100000)/100000) + ' seconds');
          if slPerformance.Values[i2s(I)] = '' then
            slPerformance.Values[i2s(I)] := FloatToStr(Round(R*100000)/100000)
          else
            slPerformance.Values[i2s(I)] := FloatToStr(StrToFloat(slPerformance.Values[i2s(I)]) + Round(R*100000)/100000);
          //pbGlobal.Position := pbGlobal.Position + 1;
          Application.ProcessMessages;
        end;
      end;
      sMemo1.Lines.Add('-----------------');
      sMemo1.Lines.AddStrings(slPerformance);
      sMemo1.Lines.Add('-----------------');
      slPerformance.Free;
      slImportedTables.Free;
    end;
  end;  }
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  D: word;
  M: word;
  Y: word;
  slTemp: TStringList;
  slFirme: TStringList;
begin
  if not bStandAlone then Exit;
  try
    DoSQL(q, 'SHOW DATABASES');
    slTemp := TStringList.Create;
    slFirme := TStringList.Create;
    while not q.Eof do begin
      slTemp.Add(q.Fields[0].AsString);
      q.Next;
    end;
    d := 0;
    while d < slTemp.Count do begin
      DoSQL(q, 'SHOW TABLES IN ' + slTemp[d] + ' LIKE "GENERAL"');
      if q.RecordCount = 0 then begin
        DoSQL(q, 'SHOW TABLES IN ' + slTemp[d] + ' LIKE "SETARI"');
        if q.RecordCount <> 0 then begin
          slFirme.Add(UpperCase(slTemp[d]));
        end;
      end;
      Inc(d);
    end;
    cbFirme.Items := slFirme;
    cbFirme.ItemIndex := slFirme.IndexOf(SQLSettings.Values['SQL_DB']);
  finally
    slTemp.Free;
    slFirme.Free;
  end;
  DecodeDate(Now, Y, M, D);
  ELuna1.Text := '1';
  EAn1.Text := i2s(Y);
  ELuna2.Text := i2s(M);
  EAn2.Text := i2s(Y);
end;

function TMainForm.GetPartners(PartialName: string): string;
var
  f: TGridForm;
begin
  try
    f := TGridForm.Create(Self);
    f.LTitlu.Caption := 'Selectare parteneri';
    Result := f.Start('SELECT DENFUR, COD_FISCAL, CODFUR FROM FUR ' +
            'WHERE DENFUR LIKE "%' + EPartener.Text + '%" ORDER BY DENFUR', 'CODFUR|DENFUR');
    if Result = '|' then Result := '';
  finally
    f.Free;
  end;
end;

procedure TMainForm.EditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Sender = nil then Exit;
  if TEdit(Sender).Tag = 2 then begin
  if Key > 32  then
    if s2i(TEdit(Sender).Text) > 12 then begin
      TEdit(Sender).SelectAll;
      Key := 0;
    end;
  end;
end;

procedure TMainForm.EditExit(Sender: TObject);
begin
  if Sender = nil then Exit;
  if TEdit(Sender).Tag = 2 then begin
    if s2i(TEdit(Sender).Text) > 12  then TEdit(Sender).SetFocus;
  end;
  if TEdit(Sender).Tag = 4 then begin
    if l(TEdit(Sender).Text) > 4  then TEdit(Sender).SetFocus;
  end;
end;

end.

