unit fMyDBFLoader;

interface

uses
  SysUtils, Classes;

type
  TDBFDetails = record
    recCount: LongWord;
    headerLen: Word;
    rowLen: Word;
  end;

  TDBFColumn = class(TCollectionItem)
  private
    fName: ShortString;
    fType: Char;
    fLength: Byte;
    fDecimal: Byte;
    function GetName: string;
    procedure SetName(Value: string);
    procedure SetType(Value: Char);
  published
    property Decimal: byte read fDecimal write fDecimal;
    property FieldType: Char read fType write SetType;
    property Length: byte read fLength write fLength;
    property Name: String read GetName write SetName;
  end;

  TDBFColumns = class(TCollection)
  private
    function GetColumn(Index: Integer): TDBFColumn;
    procedure SetColumn(Index: Integer; Value: TDBFColumn);
  public
    property Items[Index: Integer]: TDBFColumn read GetColumn write SetColumn; default;
    function Add: TDBFColumn;
  published
    constructor Create;
  end;

  TMyDBFLoader = class(TObject)
  private
    myfs: TFileStream;
    fColumns: TDBFColumns;
    fDBFName: string;
    fDBFDetails: TDBFDetails;
    fEof: boolean;
    fheaderLen: Word;
    frecNo: LongWord;
    frecCount: LongWord;
    frowLen: Word;
    frowData: string;
    function DoSetDBFName(AFileName: string): byte;
    function GetDBFDetails: TDBFDetails;
    function GetEof: boolean;
    function ConvertToSQL(Value: string): string;
    function ConvertToFile(Value: string): string;
    function TranslateType(Index: Byte): string;
    function TranslateDefaultValue(Index: Byte): string;
    function GetDBFName: string;
    function SQLString(Value: string; const DoQuotes: boolean = true): string;
  public
    property Columns: TDBFColumns read fColumns;
    property DBFDetails : TDBFDetails read GetDBFDetails;
    property dbName: string read GetDBFName;
    property Eof: boolean read GetEof;
    property RecordCount: LongWord read frecCount;
    property RecNo: LongWord read frecNo;

    constructor Create;
    destructor Destroy; override; 
    function AssignDBF(AFileName: string): byte;
    function GetRows(Ammount: byte; const FromBegining: boolean = False): string;
    function GetSQLHeader: string;
    function GetSQLValues(Ammount: Word; const FromBegining: boolean = False): string;
    function GetRawData: string;
    procedure First;
    procedure Next;
    procedure Prev;
    procedure Last;
  end;

implementation

function TDBFColumn.GetName: String;
begin
  Result := String(fName);
end;

procedure TDBFColumn.SetName(Value: String);
begin
  if Value <> '' then fName := Copy(Trim(Value), 1, 10);
end;

procedure TDBFColumn.SetType(Value: Char);
begin
  if Value = '' then Exit;
  if UpCase(Value) in ['C','D','F','L','M','N'] then
    fType := UpCase(Value);
end;

constructor TDBFColumns.Create;
begin
  inherited Create(TDBFColumn);
end;

function TDBFColumns.Add: TDBFColumn;
begin
  Result := TDBFColumn(inherited Add);
  Exit;
  GetColumn(0);  //Otherwise you get function was eliminated by linker  while debugging:)
end;

function TDBFColumns.GetColumn(Index: Integer): TDBFColumn;
begin
  Result := TDBFColumn(inherited Items[Index]);
end;

procedure TDBFColumns.SetColumn(Index: Integer; Value: TDBFColumn);
begin
  Items[Index].Assign(Value);
end;

constructor TMyDBFLoader.Create;
begin
  inherited;
  fDBFName := '';
  frowData := '';
  fColumns := TDBFColumns.Create;
end;

destructor TMyDBFLoader.Destroy;
begin
  if myfs <> nil then
    FreeAndNil(myfs);
  inherited Destroy;
end;

function TMyDBFLoader.ConvertToSQL(Value: string): string;
var
  i: Word;
  s: string;
begin
  i := 0;
  if Value = '' then begin Result := ''; Exit; end;
  Result := '(';
  while Value[1] = '*' do begin
    Delete(Value,1,frowLen); //Trim deleted rows
    if Value = '' then Exit;
  end;
  Delete(Value, 1, 1);
  while Value <> '' do begin
    if fColumns[i].FieldType = 'C' then    Result := Result + SQLString(Trim(Copy(Value, 1, fColumns[i].Length))) + ',';
    if fColumns[i].FieldType = 'D' then    Result := Result + '"' + Trim(Copy(Value, 1, fColumns[i].Length)) + '",';
    if fColumns[i].FieldType = 'F' then begin
      s := Trim(Copy(Value, 1, fColumns[i].Length - fColumns[i].Decimal));
      if s = '' then s := '0' + DecimalSeparator + '00';
      Result := Result + s + ',';
    end;
    if fColumns[i].FieldType = 'L' then    Result := Result + '"' + Trim(Copy(Value, 1, 1)) + '",';
    if fColumns[i].FieldType = 'N' then begin
      s := Trim(Copy(Value, 1, fColumns[i].Length));
      if s = '' then s := '0';
      Result := Result + s + ',';
    end;
    Delete(Value, 1, fColumns[i].Length);
    Inc(i);
    if (i = fColumns.Count) and (Value <> '') then begin
      i := 0; //reset the count;
      while Value[1] = '*' do begin
        Delete(Value,1,frowLen); //Trim deleted rows
        if Value = '' then Break;
      end;
      if Value <> '' then begin
        Delete(Value, 1, 1);
        Result := Copy(Result, 1, Length(Result) - 1) + '), (';
      end;
    end;
  end;
  Result := Copy(Result, 1, Length(Result) - 1) + ')';
end;

function TMyDBFLoader.ConvertToFile(Value: string): string;
var
  i: Word;
  s: string;
begin
  i := 0;
  if Value = '' then begin Result := ''; Exit; end;
  Result := '';
  while Value[1] = '*' do begin //Trim deleted rows
    Delete(Value,1,frowLen);
    if Value = '' then Exit;
  end;
  Delete(Value, 1, 1);
  while Value <> '' do begin
    if fColumns[i].FieldType in  ['C','D','L'] then       
      Result := Result + SQLString(Trim(Copy(Value, 1, fColumns[i].Length)), False) + '|';
    if fColumns[i].FieldType = 'F' then begin
      s := Trim(Copy(Value, 1, fColumns[i].Length - fColumns[i].Decimal));
      if s = '' then s := '0' + DecimalSeparator + '00';
      Result := Result + s + '|';
    end;
    if fColumns[i].FieldType = 'N' then begin
      s := Trim(Copy(Value, 1, fColumns[i].Length));
      if s = '' then s := '0';
      Result := Result + s + '|';
    end;
    Delete(Value, 1, fColumns[i].Length);
    Inc(i);
    if (i = fColumns.Count) and (Value <> '') then begin
      i := 0; //reset the count;
      while Value[1] = '*' do begin
        Delete(Value,1,frowLen); //Trim deleted rows
        if Value = '' then Break;
      end;
      if Value <> '' then begin
        Delete(Value, 1, 1);
        Result := Copy(Result, 1, Length(Result) - 1) + '|#|';
      end;
    end;
  end;
  Result := Copy(Result, 1, Length(Result) - 1);
end;

function TMyDBFLoader.TranslateType(Index: Byte): string;
var
  fieldType: char;
begin
  fieldType := fColumns[Index].FieldType;

  if fieldType = 'C' then Result := 'char';
  if fieldType = 'D' then Result := 'date';
  if fieldType = 'F' then Result := 'double';
  if fieldType = 'L' then Result := 'char';
  if fieldType = 'N' then begin
    if fColumns[Index].fDecimal = 0 then Result := 'int'
    else Result := 'double';
  end;
end;

function TMyDBFLoader.TranslateDefaultValue(Index: Byte): string;
var
  fieldType: char;
begin
  fieldType := fColumns[Index].FieldType;

  if fieldType = 'C' then Result := '""';
  if fieldType = 'D' then Result := '"01-01-1970"';
  if fieldType = 'F' then Result := '0.00';
  if fieldType = 'L' then Result := '""';
  if fieldType = 'N' then begin
    if fColumns[Index].fDecimal = 0  then Result := '0'
    else Result := '0.00';
  end;
end;

function TMyDBFLoader.GetDBFName: string;
begin
  Result := Copy(fDBFName, 1, Length(fDBFName) - 4);
end;

function TMyDBFLoader.GetEof: boolean;
begin
  if (frecNo > frecCount) or (frecCount = 0) then Result := True
  else Result := False;
end;

function TMyDBFLoader.DoSetDBFName(AFileName: string): byte;
begin
  Result := 1;
  if FileExists(AFileName) then begin
    Result := 0;
    fDBFName := AFileName;
  end;
end;

{public methods}

function TMyDBFLoader.AssignDBF(AFileName: string): byte;
var
  bt: Byte;
  recCount: LongWord;
  headerLen: Word;
  rowLen: Word;
  Buffer: array[1..32] of Char;
  myColumn: TDBFColumn;
begin
  Result := 1;
  if AFileName = '' then Exit;
  if Pos('.DBF', UpperCase(AFileName)) = 0 then AFileName := AFileName + '.DBF';
  Result := DoSetDBFName(ExtractFileName(AFileName));
  if Result <> 0 then Exit; //DBF does not exist - Exit;

  myfs := TFileStream.Create(AFileName, fmOpenRead+fmShareDenyNone);

  myfs.Read(bt, 1);
  Result := 2;
  if bt > 3 then Exit; //dBase 7 selected - Exit;

  myfs.Seek(4, soFromBeginning);
  myfs.Read(recCount, 4);
  myfs.Read(headerLen, 2);
  myfs.Read(rowLen, 2);

//  if (recCount * headerLen * rowLen) = 0 then Exit;

  frecCount := recCount;
  fheaderLen := headerLen;
  frowLen := rowLen;

  //Load header
  myfs.Seek(32, soFromBeginning);
  for bt := 1 to ((headerLen - 1) div 32) - 1 do begin
    myfs.Read(Buffer, 32);
    myColumn := fColumns.Add;
    with myColumn do begin
      Name := Trim(Buffer[1] + Buffer[2] + Buffer[3] +
                   Buffer[4] + Buffer[5] + Buffer[6] +
                   Buffer[7] + Buffer[8] + Buffer[9] +
                   Buffer[10]);   //Name for the field is less than 10 chars
      FieldType := Buffer[12];    //'C','D','F','L','M','N'
      Length := Ord(Buffer[17]);  //Total bytes of the field
      Decimal := Ord(Buffer[18]); //Ammount of decimal bytes
    end;
  end;
  myfs.Seek(fheaderLen, soFromBeginning);
  Result := 0; //All ok
end;

function TMyDBFLoader.SQLString(Value: string; const DoQuotes: boolean = true): string;
var
  b: boolean;
begin
  b := False;
  Result := '';
  while Value <> ''  do begin
    if Value[1] = '\' then Result := Result + '\';
    if Value[1] = '"' then begin Result := Result + '\'; b := true; end;
    Result := Result + Value[1];
    Delete(Value,1,1);
  end;
  if DoQuotes then
    if b then Result := '''' + Result + ''''
    else Result := '"' + Result + '"';
end;

function TMyDBFLoader.GetDBFDetails: TDBFDetails;
var
  myDetails: TDBFDetails;
begin
  with myDetails do begin
    recCount := frecCount;
    headerLen := fheaderLen;
    rowLen := frowLen;
  end;
  Result := myDetails;
end;
    
function TMyDBFLoader.GetRows(Ammount: byte; const FromBegining: boolean = False): string;
begin
  if FromBegining then myfs.Seek(0, soFromBeginning);
  if Ammount > frecCount  then Exit;
end;

function TMyDBFLoader.GetSQLHeader: string;
var
  i: Word;
begin
  Result := 'CREATE TABLE ' + Copy(fDBFName, 1, Length(fDBFName) - 4) + ' (';
  for i := 0 to fColumns.Count - 1 do begin
    Result := Result + '`' + fColumns[i].fName + '` ' + TranslateType(i);
    if fColumns[i].FieldType <> 'D' then begin
      Result := Result + '(' + IntToStr(fColumns[i].fLength);
      if fColumns[i].fDecimal <> 0 then
        Result := Result + ',' + IntToStr(fColumns[i].fDecimal);
      Result := Result + ')';
    end;
    Result := Result + ' NOT NULL DEFAULT ' +
              TranslateDefaultValue(i) + ',';
  end;
  Result := Copy(Result, 1, Length(Result) - 1) + ') ENGINE=InnoDB DEFAULT CHARSET=latin1';
end;

function TMyDBFLoader.GetSQLValues(Ammount: Word; const FromBegining: boolean = False): string;
var
  rows: LongWord;
begin
  if FromBegining then myfs.Seek(fheaderLen, soFromBeginning);
  //if (Ammount > frecCount) then Exit;
  if FromBegining then rows := Ammount
  else begin
    if Ammount > (frecCount - frecNo) then
      rows := frecCount - frecNo
    else rows := Ammount;
  end;
  SetLength(Result, rows * frowLen);
  myfs.Read(Result[1], rows * frowLen);
  {$IFDEF LOAD_FROM_FILE}
    Result := ConvertToFile(Result);
  {$ELSE}
    Result := ConvertToSQL(Result);
  {$ENDIF}
  frecNo := frecNo + rows;
  if rows <> Ammount then Inc(frecNo);
end;

function TMyDBFLoader.GetRawData: string;
begin
  Result := frowData;
end;

procedure TMyDBFLoader.First;
begin
  myfs.Seek(fheaderLen, soFromBeginning);
  frecNo := 1;
  SetLength(frowData, frowLen);
  myfs.Read(frowData[1], frowLen);
end;

procedure TMyDBFLoader.Next;
begin
  if Eof then Exit;
  SetLength(frowData, frowLen);
  myfs.Read(frowData[1], frowLen);
  Inc(frecNo);
end;

procedure TMyDBFLoader.Prev;
begin
  myfs.Seek(fheaderLen + (frecNo - 2) * frowLen, soFromBeginning);
  SetLength(frowData, frowLen);
  myfs.Read(frowData[1], frowLen);
  Dec(frecNo);
end;

procedure TMyDBFLoader.Last;
begin
  myfs.Seek(fheaderLen + (frecCount - 1) * frowLen, soFromBeginning);
  frecNo := frecCount;
  SetLength(frowData, frowLen);
  myfs.Read(frowData[1], frowLen);//
end;

end.
