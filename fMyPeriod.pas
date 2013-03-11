unit fMyPeriod;

interface

uses
  SysUtils, DateUtils;

const
  psStart  = 0;
  psEnd    = 1;

type
  TMyPeriod = class(TObject)
  strict private
    fsDay: byte;
    fsMonth: byte;
    fsYear: smallInt;
    feDay: byte;
    feMonth: byte;
    feYear: smallInt;
    fcDay: byte;
    fcMonth: byte;
    fcYear: smallInt;
    function DoSetDate(Date: string; DateSelector: byte): byte; overload;
    function DoSetDate(Day, Month: byte; Year: smallInt; DateSelector: byte): byte; overload;
    function GetEof: boolean;
    function GetNoOfDays: integer;
    function GetNoOfMonths: integer;
  published
    property Eof: boolean read GetEof;
    property Days: integer read GetNoOfDays;
    property Months: integer read GetNoOfMonths;
    function SetSDate(Date: string; DateSelector: byte): byte;
    function SetDate(Day, Month: byte; Year: smallInt; DateSelector: byte): byte;
    function GetCurrentDate(const Length: byte = 8): string;
    function GetFirst(const Length: byte = 8): string;
    function GetNext(const Length: byte = 8): string;
    function GetPrev(const Length: byte = 8): string;
    function GetLast(const Length: byte = 8): string;
    procedure First;
    procedure Next;
    procedure Prev;
    procedure Last;
  end;

implementation

function TMyPeriod.GetEof: boolean;
begin
  if fcYear * 10000 + fcMonth * 100 + fcDay >
     feYear * 10000 + feMonth * 100 + feDay then Result := True
  else Result := False;
end;

function TMyPeriod.GetNoOfDays: integer;
begin
  if fsDay * fsMonth * fsYear * feDay * feMonth * feYear = 0 then Exit;
  try
    Result := DaysBetween(EncodeDate(feYear, feMonth, feDay), EncodeDate(fsYear, fsMonth, fsDay));
  except
    Result := 1;
  end;
end;

function TMyPeriod.GetNoOfMonths: integer;
begin
  Result := feYear * 12 + feMonth - fsYear * 12 - fsMonth + 1; 
end;

function TMyPeriod.DoSetDate(Date: string; DateSelector: byte): byte;
var
  aDay: byte;
  aMonth: byte;
  aYear: smallInt;
begin
  Result := 1;
  case Length(Date) of
    4 : begin
      aDay := 1;
      aMonth := StrToInt(Date[1] + Date[2]);
      if Date[3] = #57 then aYear := 1900 + StrToInt(Date[3] + Date[4])
      else aYear := 2000 + StrToInt(Date[3] + Date[4]);
    end;
    6 : begin
      aDay := StrToInt(Date[1] + Date[2]);
      aMonth := StrToInt(Date[3] + Date[4]);
      if Date[5] = #57 then aYear := 1900 + StrToInt(Date[5] + Date[6])
      else aYear := 2000 + StrToInt(Date[5] + Date[6]);
    end;
    8 : begin
      aDay := StrToInt(Date[1] + Date[2]);
      aMonth := StrToInt(Date[3] + Date[4]);
      aYear := StrToInt(Date[5] + Date[6] + Date[7] + Date[8]);
    end;
  end;
  if DoSetDate(aDay, aMonth, aYear, DateSelector) <> 0 then Exit;
  Result := 0
end;

function TMyPeriod.DoSetDate(Day, Month: byte; Year: smallInt; DateSelector: byte): byte;
begin
  Result := 1;
  if Day * Month * Year = 0 then Exit;

  if DateSelector = psStart then begin
      fsDay := Day;
      fsMonth := Month;
      fsYear := Year;
      fcDay := Day;
      fcMonth := Month;
      fcYear := Year;
  end;
  if DateSelector = psEnd then begin
      feDay := Day;
      feMonth := Month;
      feYear := Year;
  end;
  Result := 0
end;

{published methods}

function TMyPeriod.SetSDate(Date: string; DateSelector: byte): byte;
begin
  Result := DoSetDate(Date, DateSelector);
end;

function TMyPeriod.SetDate(Day, Month: byte; Year: smallInt; DateSelector: byte): byte;
begin
  Result := DoSetDate(Day, Month, Year, DateSelector);
end;

function TMyPeriod.GetCurrentDate(const Length: byte = 8): string;
begin
  Result := '';
  if Length <> 4 then
    Result := Chr(48 + fcDay div 10) + Chr(48 + fcDay mod 10);

  if Length = 10 then Result := Result + '.';

  Result := Result + Chr(48 + fcMonth div 10) + Chr(48 + fcMonth mod 10);

  if Length = 10 then Result := Result + '.';

  if Length >= 8 then begin
    if fcYear < 2000 then Result := Result + '19'
    else Result := Result + '20';
  end;
  
  Result := Result + Chr(48 + (fcYear mod 100) div 10) + Chr(48 + (fcYear mod 100) mod 10);
end;

function TMyPeriod.GetFirst(const Length: byte = 8): string;
begin
  First;
  Result := GetCurrentDate(Length);
end;

function TMyPeriod.GetNext(const Length: byte = 8): string;
begin
  Next;
  Result := GetCurrentDate(Length);
end;

function TMyPeriod.GetPrev(const Length: byte = 8): string;
begin
  Prev;
  Result := GetCurrentDate(Length);
end;

function TMyPeriod.GetLast(const Length: byte = 8): string;
begin
  Last;
  Result := GetCurrentDate(Length);
end;

procedure TMyPeriod.First;
begin
  fcDay := fsDay;
  fcMonth := fsMonth;
  fcYear := fsYear;
end;

procedure TMyPeriod.Next;
begin
  if GetEof then Exit;
  
  fcMonth := fcMonth + 1;
  if fcMonth = 13 then begin
    fcMonth := 1;
    Inc(fcYear)
  end
end;

procedure TMyPeriod.Prev;
begin
  {if fcYear * 10000 + fcMonth * 100 + fcDay =
     fsYear * 10000 + fsMonth * 100 + fsDay then Exit;      }

  Dec(fcMonth);
  if fcMonth = 0 then begin
    fcMonth := 12;
    Dec(fcYear)
  end
end;

procedure TMyPeriod.Last;
begin
  fcDay := feDay;
  fcMonth := feMonth;
  fcYear := feYear;
end;

end.

