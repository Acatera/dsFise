unit fNetwork;

interface

uses SysUtils, ActiveX, ComObj, Variants;

function GetWin32_NetworkAdapterMACList: string;

implementation

function GetWin32_NetworkAdapterMACList: string;
const
  WbemUser            ='';
  WbemPassword        ='';
  WbemComputer        ='localhost';
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator : OLEVariant;
  FWMIService   : OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject   : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;
  s: string;
begin;
  Result := '';
  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService   := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2', WbemUser, WbemPassword);
  FWbemObjectSet:= FWMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapterConfiguration','WQL',wbemFlagForwardOnly);
  oEnum         := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
  while oEnum.Next(1, FWbemObject, iValue) = 0 do begin
    if VarIsStr(FWbemObject.MACAddress) then
      Result := Result + String(FWbemObject.MACAddress) + '|';
    FWbemObject:=Unassigned;
  end;
end;

end.
