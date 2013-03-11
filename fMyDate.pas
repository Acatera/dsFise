unit fMyDate;

interface
type
  TMyDate = class
  private
    fDate: string[4];
    fMonth: byte;
    fYear: smallInt;
    function DoConvert: string;
    function SwitchYearMonth(ADate: string): string;
  public
    constructor Create;
    function Convert(Month: Byte; Year: smallInt): string;
    function SetDate(Month: byte; Year: smallInt): byte;
    function StepUp: string;
    function StepDown: string;
    function GetDate: string;
    function EarlierThan(ADate: string): boolean;
    function LaterThan(ADate: string): boolean;
    function Equals(ADate: string): boolean;
  end;

implementation

constructor TMyDate.Create;
begin
  inherited;
  fMonth := 0;
  fYear := 0;
  fDate := '';
end;

function TMyDate.DoConvert: string;
begin
  if fMonth * fYear = 0 then Exit;
  Result := Chr(48 + fMonth div 10) + Chr(48 + fMonth mod 10);
  Result := Result + Chr(48 + (fYear mod 100) div 10) + Chr(48 + (fYear mod 100) mod 10);
end;

function TMyDate.SwitchYearMonth(ADate: string): string;
begin
  try
    Result := ADate[3] + ADate[4] + ADate[1] + ADate[2];
  except
    Result := '';
  end;
end;

function TMyDate.Convert(Month: Byte; Year: smallInt): string;
begin
  if Month * Year = 0 then Exit;
  Result := Chr(48 + Month div 10) + Chr(48 + Month mod 10);
  Result := Result + Chr(48 + (Year mod 100) div 10) + Chr(48 + (Year mod 100) mod 10);
end;

function TMyDate.SetDate(Month: byte; Year: smallInt): byte;
begin
  Result := 1;
  fMonth := 0;
  fYear := 0;
  if (Month < 13) then fMonth := Month;
  if (Year > 1970) and (Year < 2050) then fYear := Year;
  if fMonth * fYear <> 0 then
    Result := 0;
end;

function TMyDate.StepUp: string;
begin
  Inc(fMonth);
  if fMonth > 12 then begin
    fMonth := 1;
    Inc(fYear);
  end;
  Result := DoConvert;
end;

function TMyDate.StepDown: string;
begin
  Dec(fMonth);
  if fMonth < 1 then begin
    fMonth := 12;
    Dec(fYear);
  end;
  Result := DoConvert;
end;

function TMyDate.GetDate: string;
begin
  Result := DoConvert;
end;

function TMyDate.EarlierThan(ADate: string): boolean;
begin
  Result := False;
  if ADate = '' then Exit;
  Result := SwitchYearMonth(GetDate) < SwitchYearMonth(ADate);
end;

function TMyDate.LaterThan(ADate: string): boolean;
begin
  Result := False;
  if ADate = '' then Exit;
  Result := SwitchYearMonth(GetDate) > SwitchYearMonth(ADate);
end;

function TMyDate.Equals(ADate: string): boolean;
begin
  Result := False;
  if ADate = '' then Exit;
  Result := ADate = GetDate;
end;

end.
