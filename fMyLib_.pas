unit fMyLib;

interface

uses
  Variants, SysUtils, DBTables, Classes, Forms;

const
  LuniScurte: array[1..12] of string[3] =
    ('Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Noi', 'Dec');
  Luni: array[1..12] of string =
    ('Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie', 'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie');

type
  TKeyPressEvent = procedure(Sender: TObject; var Key: Char) of object;
  EErrorChecking = class(Exception);
  TMyForm = class(TForm)
  private
    FKeyPreview: boolean;
    FOnKeyPress: TKeyPressEvent;
  published
    property KeyPreview: Boolean read FKeyPreview write FKeyPreview
      default True;
    procedure KeyPress(var Key: Char); dynamic;
  end;

//Error checking
procedure RaiseEx(EType, EMessage: string);

//Shortcuts
function i2s(AValue: Variant): string;
function s2i(AValue: string): Variant;
function iif(Cond: boolean; Val1, Val2: Variant): Variant;
function l(Value: string): integer;

//MySQL
function DoSQL(AQuery: TQuery; const SQL: string = ''): integer;
function GetTableList(AQuery: TQuery; const dbName: string = ''): TStringList;
procedure DoLogging(Event: string; const IsSQL: boolean = false);
procedure ProcessException(E: Exception; const Data: string = '');

//File Utils                                           
function fileSize(FileName: string): integer;

//DateUtils
function UltimaZi(LunaAn:string; const An4Cifre: boolean = false; const DoarZiua: boolean = False):string;

//StringUtils
function InStr(SubString, Target: string; const CaseSensitive: boolean = false): boolean;
//Returns true if substring exists within target
function GetDigits(AValue: string): integer;
//Supresses all the alphanumeric characters in the string except digits and returns that number

implementation

procedure TMyForm.KeyPress(var Key: Char);
begin
  if Key = #27 then begin Self.Free; Exit; end;
  if Assigned(FOnKeyPress) then FOnKeyPress(Self, Key);
end;

procedure RaiseEx(EType, EMessage: string);
var
  E: EErrorChecking;
begin
  E := EErrorChecking.CreateFmt('ErrProcVer:%s - %s', [EType, EMessage]);
  raise E;
end;

function i2s(AValue: Variant): string;
begin
  try Result := IntToStr(AValue); except end;
end;

function s2i(AValue: string): Variant;
begin
  try Result := StrToInt(AValue); except end;
end;

function iif(Cond: boolean; Val1, Val2: Variant): Variant;
begin
  if Cond then Result := Val1
  else Result := Val2;
end;

function l(Value: string): integer;
begin
  Result := Length(Value);
end;

function DoSQL(AQuery: TQuery; const SQL: string = ''): integer;
var
  s: string;
begin
  Result := -1;
  if AQuery = nil then Exit;
  if SQL = '' then s := AQuery.SQL.Text
  else s := SQL;
  try
    if Pos(Trim(Copy(s, 1, Pos(' ', s))), 'SELECT|SHOW|DESCRIBE') <> 0  then begin
      AQuery.SQL.Text := s;
      AQuery.Open;
      Result := AQuery.RowsAffected;
    end else begin
      AQuery.SQL.Text := s;
      AQuery.ExecSQL;
      Result := AQuery.RowsAffected;
    end;
    DoLogging(s);
  except
    on E: Exception do begin
      ProcessException(E, s);
      AQuery.Close;
    end;
  end;
  //if Result = -1 then Result := 0;
end;

function GetTableList(AQuery: TQuery; const dbName: string = ''): TStringList;
var
  s: string;
begin
  Result := TStringList.Create;
  if AQuery = nil then begin RaiseEx('GetTableList','AQuery is nil'); Exit end;
  s := '';
  if dbName <> '' then s := ' IN ' + dbName;

  DoSQL(AQuery, 'SHOW TABLES' + s);
  while not AQuery.Eof do begin
    Result.Add(UpperCase(AQuery.Fields[0].AsString));
    AQuery.Next;
  end;
end;

procedure DoLogging(Event: string; const IsSQL: boolean = false);
var
  myfs: TFileStream;
begin
  if not IsSQL then Exit;
  Event := Event + #10#13;
  if FileExists(ExtractFilePath(Application.ExeName) + '\log.txt') then
    myfs := TFileStream.Create(ExtractFilePath(Application.ExeName) + '\log.txt', fmOpenWrite)
  else
    myfs := TFileStream.Create(ExtractFilePath(Application.ExeName) + '\log.txt', fmCreate);
  myfs.Seek(myfs.Size, soFromBeginning);  
  myfs.Write(Event[1], Length(Event));
  myfs.Free;
end;

procedure ProcessException(E: Exception; const Data: string = '');
var
  s: string;
begin
  s := E.Message + Data;
  DoLogging(s, True);
end;

function fileSize(FileName: string): integer;
var
  myfs: TFileStream;
begin
  Result := -1;
  if FileName = '' then Exit;
  myfs := TFileStream.Create(FileName, fmShareDenyNone);
  Result := myfs.Size;
  myfs.Free;
end;

function UltimaZi(LunaAn:string; const An4Cifre: boolean = false; const DoarZiua: boolean = False):string;
var
  Luna: word;
  An: word;
begin
  if Length(LunaAn) > 4 then
    raise Exception.CreateFmt('Formatul datei este invalid: ''%s''. Corect: LLAA.', [LunaAn]);
  Luna := StrToInt(Copy(LunaAn,1,2));
  An := StrToInt(Copy(LunaAn,3,2));
  if Luna = 2 then  //if(( year % 4 == 0 && year % 100 != 0 ) || year % 400 = 0 )
    if (((An mod 4) = 0) and ((An mod 100) <> 0)) or ((An mod 400) = 0) then Result := '29'
    else Result := '28' + LunaAn
  else
    if (Luna < 8) then
      if((Luna mod 2) = 0) then Result := '30' + LunaAn
      else Result := '31' + LunaAn
    else if((Luna mod 2) = 0) then Result := '31' + LunaAn
      else Result := '30' + LunaAn;
  if An4Cifre then
    Result := Copy(Result, 1, 4) + '20' + Copy(Result,5,2);
  if DoarZiua then
    Result := Copy(Result, 1, 2);
end;

function InStr(SubString, Target: string; const CaseSensitive: boolean = false): boolean;
begin
  Result := False;
  if CaseSensitive then begin
    if Pos(SubString, Target) <> 0 then
      Result := True;
  end else begin
    if Pos(UpperCase(SubString), UpperCase(Target)) <> 0 then
      Result := True;
  end;
end;

function GetDigits(AValue: string): integer;
var
  i: integer;
  le: integer;
begin
  Result := 0;
  i := 1;
  le := l(AValue);
  while i <= le do begin
    if (byte(AValue[i]) >= 48) and (byte(AValue[i]) <= 57) then
      Result := Result  * 10 + byte(AValue[i]) - 48;
    Inc(i);
  end;
end;

end.
