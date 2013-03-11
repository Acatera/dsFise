unit LASM;

interface

uses
  Classes, dB, dbTables;

const
  // Erori
  ERR_INVALID_OPCODE      = -5;
  ERR_STACK_ADR_UNDERFLOW = -10;
  ERR_STACK_NUM_UNDERFLOW = -11;
  ERR_STACK_STR_UNDERFLOW = -12;
  ERR_STACK_BOOL_UNDERFLOW = -13;
  ERR_STACK_ADR_OVERFLOW = -15;
  ERR_STACK_NUM_OVERFLOW = -16;
  ERR_STACK_STR_OVERFLOW = -17;
  ERR_STACK_BOOL_OVERFLOW = -18;
  // Lista instructiuni
  ISTOP                 =       01;
  IRET                  =       02;
  IJMP                  =       03;
  IJMPF                 =       04;
  ICALL                 =       05;
  ICALLT                =       06;
  ISET_WIDTH            =       10;
  IALLOC_LINES          =       11;
  IWRITE_TEXT           =       20;
  IWRITE_HEADER         =       21;
  IWRITE                =       22;
  IINSERT_Y             =       23;
  IFLUSH                =       24;
  ISET_TEXT_XY          =       30;
  ISET_TEXT_INTXY       =       31;
  ISET_HEADER_XY        =       32;
  ISET_SVARIABLE        =       33;
  ISET_PLUSSVARIABLE    =       34;
  ISPUSH                =       35;
  ISPLUS_POP            =       36;
  ISFIELDPUSH           =       37;
  ISPUSHRIGHT           =       38;
  ISPUSHVAR             =       39;
  ISCOPY_XY             =       40;
  ISFORMAT1_XY          =       41;
  ISFORMAT2_XY          =       42;
  ISPUSHHEADER          =       43;
  ISPUSHBUFFER          =       44;
  ISPUSHCENTER          =       45;
  IHEADER_TEXT          =       46;
  ISPUSHTEXT            =       47;
  ISFIELDXPUSH          =       48;
  ISPUSHLITERE          =       49;
  ISPUSHSQLSTRING       =       50;
  ISPUSHVERIFYIBAN      =       51;
  ISPUSHVERIFYCUI       =       52;
  ISPUSHVERIFYCNP       =       53;
  ISPUSHFILEEXISTS      =       54;
  ISET_NVARIABLE        =       60;
  ISET_OPNVARIABLE      =       61;
  INPUSH                =       62;
  INOP_POP              =       63;
  INFIELDPUSH           =       64;
  INPUSHLEN             =       65;
  INPUSHVAR             =       66;
  ISET_ANVARIABLE       =       67;
  ISET_OPANVARIABLE     =       68;
  IANPUSHVAR            =       69;
  ISET_XANVARIABLE      =       70;
  ISET_XOPANVARIABLE    =       71;
  IXANPUSHVAR           =       72;
  ISORT_ANVAR           =       73;
  INFIELDXPUSH          =       74;
  INPUSHROUND           =       75;
  INPUSHDIFDATA         =       76;
  INPUSHPOS             =       77;
  ISDELETE_XY           =       78;
  ISTEST_OP             =       80;
  INTEST_OP             =       81;
  IBOOL_OP              =       82;
  IBOOL_NOT             =       83;
  IBOOLPUSH             =       84;
  IBOOLPUSHVAR          =       85;
  ISET_BVARIABLE        =       86;
  IMONEY                =       98;
  INOP                  =       99;
  IREAD_NEXT            =      100;
  IREAD_NEXTX           =      101;
  ISQLEXECX             =      102;
  ISQLOPENX             =      103;
  IREAD_FIRST           =      104;
  IREAD_FIRSTX          =      105;

const
  BUF_FLUSH     = 16384;
  ADRESA_MAX    =  80;
  NUM_MAX       =  80;
  STR_MAX       =  80;
  BOOL_MAX      =  80;
  NUM_VMAX      = 255;
  STR_VMAX      = 255;
  BOOL_VMAX     = 255;
  COD_MAX       = 65000;
  EOL : STRING[2] = #13#10;

type
  TADRESA = integer;
  PADRESA = ^TADRESA;
  PINT    = ^INTEGER;
  TNUM    = double;
  PNUM    = ^TNUM;
  TSTR    = string;
  PSTR    = ^TSTR;
  TBOOL   = byte;
  THEADER = record
    SIGN: Array[0..3] of AnsiChar;
    Versiune1, Versiune2, AA : Integer;
    CodSize, VarSize, B, C : Integer;
  end;
  VM_LISTA = class(TObject)
    STIVA_ADRESE : Array[0..ADRESA_MAX] of TADRESA;
    STIVA_NUM    : Array[0..NUM_MAX] of TNUM;
    STIVA_STR    : Array[0..STR_MAX] of TSTR;
    STIVA_BOOL   : Array[0..BOOL_MAX] of TBOOL;
    VAR_NUM      : Array[0..NUM_VMAX] of TNUM;
    VAR_STR      : Array[0..STR_VMAX] of TSTR;
    VAR_BOOL     : Array[0..BOOL_VMAX] of TBOOL;
    VAR_ANUM     : Array[0..NUM_VMAX] of TNUM;
    COD          : Array[0..COD_MAX] of byte;
    CS,SP_ADR, SP_NUM, SP_STR, SP_BOOL : Integer;
    COD_HEADER : THEADER;
  // LISTA si variabilele pentru ea
    LISTA_FILE : TFileStream;
    WIDTH, RECINDEX : Integer;
    TEXT_BUF : String;
    HEADER, FIRSTHEADER, BUFFER : AnsiString;
    LDATASET : TDATASET;
    XDATASET : Array[1..3] of TQuery;
    NUME_VAR : TStringList;
  public
    OUT_FILE_NAME : String;
    COD_RESULT : Integer;
    procedure QUICKSORT(ASOURCE,ADEST,ALEN : Integer);
    function SetVAR_NUM(const ANumeVar : string; const AValue : double) : Integer;
    function SetVAR_STR(const ANumeVar, AValue : string) : Integer;
    function SetVAR_BOL(const ANumeVar : string; const AValue : Boolean) : Integer;
    function GetVAR_NUM(const ANumeVar : string; var AValue : double) : Integer;
    function GetVAR_STR(const ANumeVar : string; var AValue : string) : Integer;
    function GetVAR_BOL(const ANumeVar : string; var AValue : Boolean) : Integer;
    function GetSQL_FIELDS : String;
    function LoadFromFile(const AFileName : string) : Integer;
    function WriteToFile(Amount : Integer): Integer;
    function Exec(const Adresa : Integer) : Integer;
    constructor Create;
    destructor Destroy; override;
    function TestLicense : boolean; virtual;
  end;

implementation

uses
  SysUtils, Forms, Common, CUI, CNP, IBAN, MyDLg, Windows;

const
  Spatii : String[250] =
   '                                                  '+
   '                                                  '+
   '                                                  '+
   '                                                  '+
   '                                                  ';
  // Pentru conversia numere -> litere
  GEN_MASCULIN = 1;
  GEN_FEMININ  = 2;
  GEN_NEUTRU = 3;
  Cifre : array[1..9] of String[6] =
  ('unu',
   'doi',
   'trei',
   'patru',
   'cinci',
   'sase',
   'sapte',
   'opt',
   'noua');
  Prefix11_19 : array[1..9] of String =
  ('un',
   'doi',
   'trei',
   'pai',
   'cinci',
   'sai',
   'sapte',
   'opt',
   'noua');
  NrZeci : array[1..9] of String =
  ('zece',
   'douazeci',
   'treizeci',
   'patruzeci',
   'cincizeci',
   'saizeci',
   'saptezeci',
   'optzeci',
   'nouazeci');

function MyFileExists(const FileName: string) : boolean;
var
  Handle: THandle;
  FindData: TWin32FindData;
begin
  Handle := FindFirstFile(PChar(FileName), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(Handle);
    if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      Result := True;
      exit;
    end;
  end;
  Result := False;
end;

function Get3(Nr, Gen : Integer): String;
var
  S : String;
  Sute, Zeci, UCifra : Integer;
begin
  S := '';
  if Nr = 1 then begin  // doar la unitati
    Result := 'unu'; exit;
  end;
  Sute := Nr div 100;
  if Sute >= 3 then S := Cifre[Sute] + 'sute'
  else if Sute = 2 then S := 'douasute'
  else if Sute = 1 then S := 'osuta';
  Zeci := Nr mod 100;
  UCifra := Zeci mod 10;
  if (Zeci > 10) and (Zeci < 20) then begin
    S := S + Prefix11_19[Zeci-10] + 'sprezece';
    Result := S; Exit;
  end;
  if Zeci >= 10 then S := S + NrZeci[Zeci div 10 ];
  if UCifra = 0 then begin
    Result := S; exit;
  end;
  if Zeci > 20 then S := S + 'si';
  if (UCifra > 2) or (Gen = GEN_MASCULIN)then
    S := S + Cifre[UCifra]
  else if UCifra = 1 then
    if (Gen = GEN_FEMININ) then S := S + 'una'
    else S := S + 'unu'
  else S := S + 'doua';
  Result := s;
end;

function NumarToLitere(Nr : Int64) : String;
var
  s : String;
  Unitati, Mii, Milioane, Miliarde : Integer;
begin
  if Nr = 0 then begin
    Result := 'zero'; exit;
  end;
  if Nr = 1 then begin
    Result := 'un'; exit;
  end;
  Unitati := Nr mod 1000;  Nr := Nr div 1000;
  Mii := Nr mod 1000;      Nr := Nr div 1000;
  Milioane := Nr mod 1000; Nr := Nr div 1000;
  Miliarde := Nr mod 1000;
  if Miliarde <> 0 then begin
    if Miliarde = 1 then S := 'unmiliard'
    else begin
      S := Get3(Miliarde, GEN_NEUTRU);
      if ((Miliarde Mod 100) > 19) or (Miliarde MOD 100 = 0) then
        S := S + 'de';
      S := S + 'milioane';
    end;
  end;
  if Milioane <> 0  then begin
    if Milioane = 1 then S := S + 'unmilion'
    else begin
      S := S + Get3(Milioane, GEN_NEUTRU);
      if ((Milioane Mod 100) > 19) or (Milioane MOD 100 = 0) then
        S := S + 'de';
      S := S + 'milioane';
    end;
  end;
  if Mii <> 0 then begin
    if Mii = 1 then S := S + 'omie'
    else begin
      S := S + Get3(Mii, GEN_FEMININ);
      if ((Mii MOD 100) > 19) or (Mii MOD 100 = 0) then
        S := S + 'de';
      S := S + 'mii';
    end;
  end;
  if Unitati <> 0 then begin
    S := S + Get3(Unitati, GEN_MASCULIN);
    if ((Unitati mod 100) > 19) or ((Unitati mod 100) = 0) then
      S := S + 'de';
  end else S := S + 'de';
  Result := S;
end;

function Spaces(Nr : Integer) : String;
begin
  if Nr <= 0 then begin
    Result := '';
    exit;
  end else begin
    SetLength(Result, Nr);
    FillChar(Result[1],Nr,' ');
  end;
end;

function DuplicateChar(Ch : Char; Nr : Integer) : String;
begin
  if Nr <= 0 then begin
    Result := '';
    exit;
  end else begin
    SetLength(Result, Nr);
    FillChar(Result[1], Nr, Ch);
  end;
end;

{ VM_LISTA }

constructor VM_LISTA.Create;
begin
  CS := 0;
  SP_ADR := 0;  SP_NUM := 0;
  SP_STR := 0;  SP_BOOL := 0;
  LISTA_FILE := nil;
  NUME_VAR := TStringList.Create;
  XDATASET[1] := TQuery.Create(Application);
  XDATASET[2] := TQuery.Create(Application);
  XDATASET[3] := TQuery.Create(Application);
end;

destructor VM_LISTA.Destroy;
begin
  XDATASET[3].Close;
  XDATASET[3].Free;
  XDATASET[2].Close;
  XDATASET[2].Free;
  XDATASET[1].Close;
  XDATASET[1].Free;
  NUME_VAR.Free;
  if Assigned(LISTA_FILE) then LISTA_FILE.Free;
  inherited Destroy;
end;

function VM_LISTA.TestLicense : boolean;
begin
  Result := TRUE;
end;

procedure VM_LISTA.QUICKSORT(ASOURCE,ADEST,ALEN : Integer);
var
  I, J, K : Integer;
  Val : Double;
  S : String;
begin
  K := 0;
  S := SPACES(ALEN);
  for I := 0 to ALEN-1 do begin
    Val := -9999999999;
    for J := 0 to ALEN-1 do if (S[J+1] = ' ') and (VAR_ANUM[ASOURCE-J]>VAL) then begin
      K := J;
      Val := VAR_ANUM[ASOURCE-K];
    end;
    VAR_ANUM[ADEST-I] := K;
    S[K+1] := '1';
  end;
end;

function VM_LISTA.Exec(const Adresa: Integer): Integer;
var
  X, Y : Integer;
  B : Boolean;
begin
  Result := -1;
  if not Assigned(LDataSet) then VAR_BOOL[1] := Byte(TRUE)
  else VAR_BOOL[1] := Byte(LDataSet.EOF);
  CS := Adresa;
  repeat
  case COD[CS] of
  ISTOP:begin
          X := PADRESA(@COD[CS+1])^;
          if X = 0 then WriteToFile(Length(Buffer));
          LISTA_FILE.Free;
          LISTA_FILE := nil;
          Result := X;
          break;
        end;
  IRET:begin
          Dec(SP_ADR);
          if (SP_ADR < 0) then begin
            Result := ERR_STACK_ADR_UNDERFLOW;
            exit;
          end;
          CS := STIVA_ADRESE[SP_ADR];
        end;
  IJMP: CS := PADRESA(@COD[CS+1])^;
  IJMPF:begin
          Dec(SP_BOOL);
          if (SP_BOOL < 0) then begin
            Result := ERR_STACK_BOOL_UNDERFLOW;
            exit;
          end;
          if Boolean(STIVA_BOOL[SP_BOOL]) then CS := CS + 5
          else CS := PADRESA(@COD[CS+1])^;
        end;
  ICALL:begin
          STIVA_ADRESE[SP_ADR] := CS+5;
          CS := PADRESA(@COD[CS+1])^;
          Inc(SP_ADR);
          if (SP_ADR > ADRESA_MAX) then begin
            Result := ERR_STACK_ADR_OVERFLOW;
            exit;
          end;
        end;
  ICALLT:begin
          Dec(SP_BOOL);
          if (SP_BOOL < 0) then begin
            Result := ERR_STACK_BOOL_UNDERFLOW;
            exit;
          end;
          if Boolean(STIVA_BOOL[SP_BOOL]) then begin
            STIVA_ADRESE[SP_ADR] := CS+5;
            CS := PADRESA(@COD[CS+1])^;
            Inc(SP_ADR);
            if (SP_ADR > ADRESA_MAX) then begin
              Result := ERR_STACK_ADR_OVERFLOW;
              exit;
            end;
          end else CS := CS + 5;
        end;
  ISET_WIDTH:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          WIDTH := Trunc(STIVA_NUM[SP_NUM])+2;
          Inc(CS);
        end;
  IALLOC_LINES:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          X := Trunc(STIVA_NUM[SP_NUM]);
          SetLength(TEXT_BUF, X * WIDTH);
          FillChar(TEXT_BUF[1], Length(TEXT_BUF), ' ');
          for Y := 1 to X do
            Move(EOL[1],TEXT_BUF[Y*WIDTH-1],2);
          Inc(CS);
        end;
  IWRITE_TEXT:
        begin
          BUFFER := BUFFER+TEXT_BUF;
          Inc(CS);
        end;
  IWRITE_HEADER:
        begin
          BUFFER := BUFFER+HEADER;
          Inc(CS);
        end;
  IWRITE:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          BUFFER := BUFFER+STIVA_STR[SP_STR];
          Inc(CS);
        end;
  IINSERT_Y:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Insert(STIVA_STR[SP_STR],BUFFER,Length(BUFFER)+1+WIDTH *
            Trunc(STIVA_NUM[SP_NUM]));
          Inc(CS);
        end;
  IFLUSH:
        begin
          if Length(Buffer) > BUF_FLUSH+2048 then WriteToFile(BUF_FLUSH);
          Inc(CS);
        end;
  ISET_TEXT_XY:
        begin
          SP_NUM := SP_NUM - 2;
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Move(STIVA_STR[SP_STR][1], TEXT_BUF[
            WIDTH * (Trunc(STIVA_NUM[SP_NUM])-1) + Trunc(STIVA_NUM[SP_NUM+1])],
            Length(STIVA_STR[SP_STR]));
          Inc(CS);
        end;
  ISET_TEXT_INTXY:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Move(STIVA_STR[SP_STR][1], TEXT_BUF[
            WIDTH * (PINT(@COD[CS+1])^-1) + PINT(@COD[CS+5])^],
            Length(STIVA_STR[SP_STR]));
          CS := CS + 9;
        end;
  ISET_HEADER_XY:
        begin
          SP_NUM := SP_NUM - 2;
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Move(STIVA_STR[SP_STR][1], HEADER[
            WIDTH * (Trunc(STIVA_NUM[SP_NUM])-1) + Trunc(STIVA_NUM[SP_NUM+1])],
            Length(STIVA_STR[SP_STR]));
          Inc(CS);
        end;
  ISDELETE_XY:
        begin
          SP_NUM := SP_NUM - 2;
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          Delete(VAR_STR[COD[CS+1]],Trunc(STIVA_NUM[SP_NUM]),Trunc(STIVA_NUM[SP_NUM+1]));
          CS := CS + 2;
        end;
  ISET_SVARIABLE:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          VAR_STR[COD[CS+1]] := STIVA_STR[SP_STR];
          CS := CS + 2;
        end;
  ISET_PLUSSVARIABLE:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          VAR_STR[COD[CS+1]] := VAR_STR[COD[CS+1]]+STIVA_STR[SP_STR];
          CS := CS + 2;
        end;
  ISPUSH:
        begin
          STIVA_STR[SP_STR] := PCHAR(@COD[CS+2]);
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS:=CS+3+Cod[CS+1];
        end;
  ISPLUS_POP:
        begin
          Dec(SP_STR);
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := STIVA_STR[SP_STR-1]+STIVA_STR[SP_STR];
          Inc(CS);
        end;
  ISFIELDPUSH:
        begin
          STIVA_STR[SP_STR] := LDataSet.Fields[COD[CS+1]].AsString;
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  ISFIELDXPUSH:
        begin
          Inc(CS);
          STIVA_STR[SP_STR] := XDataSet[COD[CS]].Fields[COD[CS+1]].AsString;
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  ISPUSHRIGHT:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := Spaces(Trunc(STIVA_NUM[SP_NUM])-
            Length(STIVA_STR[SP_STR-1]))+STIVA_STR[SP_STR-1];
          Inc(CS);
        end;
  ISPUSHCENTER:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := Spaces((Trunc(STIVA_NUM[SP_NUM])-
            Length(STIVA_STR[SP_STR-1])) DIV 2)+STIVA_STR[SP_STR-1];
          Inc(CS);
        end;
  ISPUSHVAR:
        begin
          STIVA_STR[SP_STR] := VAR_STR[COD[CS+1]];
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS:=CS+2;
        end;
  ISCOPY_XY:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          SP_NUM := SP_NUM-2;
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := Copy(STIVA_STR[SP_STR-1],Trunc(STIVA_NUM[SP_NUM]),
            Trunc(STIVA_NUM[SP_NUM+1]));
          Inc(CS);
        end;
  ISFORMAT1_XY:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
{          STR(STIVA_NUM[SP_NUM]:PINT(@COD[CS+1])^:PINT(@COD[CS+5])^,
            STIVA_STR[SP_STR]);}
          X := PINT(@COD[CS+1])^;
          Y := PINT(@COD[CS+5])^;
          if Y = 0 then
            STIVA_STR[SP_STR] := FormatFloat('0', STIVA_NUM[SP_NUM])
          else
            STIVA_STR[SP_STR] := FormatFloat('0.'+
            DuplicateChar('0',Y), STIVA_NUM[SP_NUM]);
          STIVA_STR[SP_STR] := Spaces(X - Length(STIVA_STR[SP_STR]))
            + STIVA_STR[SP_STR];
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS := CS + 9;
        end;
  ISFORMAT2_XY:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          X := PINT(@COD[CS+1])^;
          Y := PINT(@COD[CS+5])^;
          if Y = 0 then
            STIVA_STR[SP_STR] := FormatFloat(',0', STIVA_NUM[SP_NUM])
          else
            STIVA_STR[SP_STR] := FormatFloat(',0.'+
            DuplicateChar('0',Y), STIVA_NUM[SP_NUM]);
          STIVA_STR[SP_STR] := Spaces(X - Length(STIVA_STR[SP_STR]))
            + STIVA_STR[SP_STR];
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          CS := CS + 9;
        end;
  ISPUSHTEXT:
        begin
          STIVA_STR[SP_STR] := TEXT_BUF;
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  ISPUSHHEADER:
        begin
          STIVA_STR[SP_STR] := HEADER;
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  ISPUSHBUFFER:
        begin
          STIVA_STR[SP_STR] := BUFFER;
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  IHEADER_TEXT:
        begin
          Header := Text_Buf; Inc(CS);
        end;
  ISPUSHLITERE:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR] := NumarToLitere(Trunc(STIVA_NUM[SP_NUM]));
          Inc(SP_STR);
          if (SP_STR > STR_MAX) then begin
            Result := ERR_STACK_STR_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  ISPUSHVERIFYIBAN:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := IntToStr(VerifyIBAN(STIVA_STR[SP_STR-1]));
          Inc(CS);
        end;
  ISPUSHVERIFYCUI:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := IntToStr(VerifyCUI(STIVA_STR[SP_STR-1]));
          Inc(CS);
        end;
  ISPUSHVERIFYCNP:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := IntToStr(VerifyCNP(STIVA_STR[SP_STR-1]));
          Inc(CS);
        end;
  ISPUSHFILEEXISTS:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          if MyFileExists(STIVA_STR[SP_STR-1]) then
            STIVA_STR[SP_STR-1] := 'DA' else
            STIVA_STR[SP_STR-1] := 'NU';
          Inc(CS);
        end;
  ISPUSHSQLSTRING:
        begin
          if (SP_STR < 1) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_STR[SP_STR-1] := SQLString(STIVA_STR[SP_STR-1]);
          Inc(CS);
        end;
  ISET_NVARIABLE:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          VAR_NUM[COD[CS+1]] := STIVA_NUM[SP_NUM];
          CS := CS + 2;
        end;
  ISET_OPNVARIABLE:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          case COD[CS+2] of
          1: VAR_NUM[COD[CS+1]] := VAR_NUM[COD[CS+1]] + STIVA_NUM[SP_NUM];
          2: VAR_NUM[COD[CS+1]] := VAR_NUM[COD[CS+1]] - STIVA_NUM[SP_NUM];
          3: VAR_NUM[COD[CS+1]] := VAR_NUM[COD[CS+1]] * STIVA_NUM[SP_NUM];
          4: VAR_NUM[COD[CS+1]] := VAR_NUM[COD[CS+1]] / STIVA_NUM[SP_NUM];
          5: VAR_NUM[COD[CS+1]] := TRUNC(VAR_NUM[COD[CS+1]]) MOD TRUNC(STIVA_NUM[SP_NUM]);
          end;
          CS := CS + 3;
        end;
  INPUSH:
        begin
          STIVA_NUM[SP_NUM] := PNUM(@COD[CS+1])^;
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          CS := CS + 1 +SizeOf(Double);
        end;
  INOP_POP:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 1) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          case COD[CS+1] of
          1: STIVA_NUM[SP_NUM-1] := STIVA_NUM[SP_NUM-1] + STIVA_NUM[SP_NUM];
          2: STIVA_NUM[SP_NUM-1] := STIVA_NUM[SP_NUM-1] - STIVA_NUM[SP_NUM];
          3: STIVA_NUM[SP_NUM-1] := STIVA_NUM[SP_NUM-1] * STIVA_NUM[SP_NUM];
          4: STIVA_NUM[SP_NUM-1] := STIVA_NUM[SP_NUM-1] / STIVA_NUM[SP_NUM];
          5: STIVA_NUM[SP_NUM-1] := TRUNC(STIVA_NUM[SP_NUM-1]) MOD TRUNC(STIVA_NUM[SP_NUM]);
          end;
          CS := CS + 2;
        end;
  INFIELDPUSH:
        begin
          STIVA_NUM[SP_NUM] := LDataSet.Fields[COD[CS+1]].AsFloat;
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  INFIELDXPUSH:
        begin
          Inc(CS);
          STIVA_NUM[SP_NUM] := XDataSet[COD[CS]].Fields[COD[CS+1]].AsFloat;
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  INPUSHPOS:
        begin
          Dec(SP_STR,2);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_NUM[SP_NUM] := Pos(STIVA_STR[SP_STR], STIVA_STR[SP_STR+1]);
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  INPUSHDIFDATA:
        begin
          Dec(SP_STR,2);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          try
            if (STIVA_STR[SP_STR] = '') or (STIVA_STR[SP_STR+1] = '')
              then STIVA_NUM[SP_NUM] := -1
            else
            STIVA_NUM[SP_NUM] :=
            EncodeDate(StrToInt(Copy(STIVA_STR[SP_STR],5,4)),
              StrToInt(Copy(STIVA_STR[SP_STR],3,2)),
              StrToInt(Copy(STIVA_STR[SP_STR],1,2))) -
            EncodeDate(StrToInt(Copy(STIVA_STR[SP_STR+1],5,4)),
              StrToInt(Copy(STIVA_STR[SP_STR+1],3,2)),
              StrToInt(Copy(STIVA_STR[SP_STR+1],1,2)));
          except
            if FMyDlg.Start('Data invalida : '+STIVA_STR[SP_STR]+'/'+STIVA_STR[SP_STR+1],M_ERROK+M_CANCEL)
              <> M_OK then begin
              Result := ERR_STACK_NUM_OVERFLOW;
              exit;
            end;
            STIVA_NUM[SP_NUM] := -1;
          end;
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  INPUSHLEN:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          STIVA_NUM[SP_NUM] := Length(STIVA_STR[SP_STR]);
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          Inc(CS);
        end;
  INPUSHROUND:
        begin
          if (SP_NUM < 1) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_NUM[SP_NUM-1] := ROUND(STIVA_NUM[SP_NUM-1]+0.0001);
          Inc(CS);
        end;
  INPUSHVAR:
        begin
          STIVA_NUM[SP_NUM] := VAR_NUM[COD[CS+1]];
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          CS:=CS+2;
        end;
  ISET_ANVARIABLE:
        begin
          if (SP_NUM < 2) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          SP_NUM := SP_NUM-2;
          VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] := STIVA_NUM[SP_NUM];
          CS:=CS+2;
        end;
  ISET_XANVARIABLE:
        begin
          if (SP_NUM < 1) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          Dec(SP_NUM);
          VAR_ANUM[COD[CS+1]] := STIVA_NUM[SP_NUM];
          CS := CS + 2;
        end;
  ISET_OPANVARIABLE:
        begin
          if (SP_NUM < 2) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          SP_NUM := SP_NUM-2;
          case COD[CS+2] of
          1: VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] :=
               VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] + STIVA_NUM[SP_NUM];
          2: VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] :=
               VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] - STIVA_NUM[SP_NUM];
          3: VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] :=
               VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] * STIVA_NUM[SP_NUM];
          4: VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] :=
               VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] / STIVA_NUM[SP_NUM];
          5: VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])] :=
            TRUNC(VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM+1])]) MOD TRUNC(STIVA_NUM[SP_NUM]);
          end;
          CS := CS + 3;
        end;
  ISET_XOPANVARIABLE:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          case COD[CS+2] of
          1: VAR_ANUM[COD[CS+1]] := VAR_ANUM[COD[CS+1]] + STIVA_NUM[SP_NUM];
          2: VAR_ANUM[COD[CS+1]] := VAR_ANUM[COD[CS+1]] - STIVA_NUM[SP_NUM];
          3: VAR_ANUM[COD[CS+1]] := VAR_ANUM[COD[CS+1]] * STIVA_NUM[SP_NUM];
          4: VAR_ANUM[COD[CS+1]] := VAR_ANUM[COD[CS+1]] / STIVA_NUM[SP_NUM];
          5: VAR_ANUM[COD[CS+1]] := TRUNC(VAR_ANUM[COD[CS+1]]) MOD TRUNC(STIVA_NUM[SP_NUM]);
          end;
          CS := CS + 3;
        end;
  IANPUSHVAR:
        begin
          if (SP_NUM < 1) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          STIVA_NUM[SP_NUM-1] := VAR_ANUM[COD[CS+1]-Trunc(STIVA_NUM[SP_NUM-1])];
          CS:=CS+2;
        end;
  IXANPUSHVAR:
        begin
          STIVA_NUM[SP_NUM] := VAR_ANUM[COD[CS+1]];
          Inc(SP_NUM);
          if (SP_NUM > NUM_MAX) then begin
            Result := ERR_STACK_NUM_OVERFLOW;
            exit;
          end;
          CS:=CS+2;
        end;
  ISORT_ANVAR:
        begin
          Dec(SP_NUM);
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          QUICKSORT(COD[CS+1],COD[CS+2],Trunc(STIVA_NUM[SP_NUM]));
          CS := CS+3;
        end;
  ISTEST_OP:
        begin
          SP_STR := SP_STR - 2;
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          X := CompareText(STIVA_STR[SP_STR], STIVA_STR[SP_STR+1]);
          case COD[CS+1] of
          1:    B := X = 0;
          2:    B := X <> 0;
          3:    B := X < 0;
          4:    B := X > 0;
          5:    B := X <= 0;
          6:    B := X >= 0;
          else  B := X = 0;
          end;
          STIVA_BOOL[SP_BOOL] := Byte(B);
          Inc(SP_BOOL);
          if (SP_BOOL) > BOOL_MAX then begin
            Result := ERR_STACK_BOOL_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  INTEST_OP:
        begin
          SP_NUM := SP_NUM - 2;
          if (SP_NUM < 0) then begin
            Result := ERR_STACK_NUM_UNDERFLOW;
            exit;
          end;
          case COD[CS+1] of
          1:    B := STIVA_NUM[SP_NUM] = STIVA_NUM[SP_NUM+1];
          2:    B := STIVA_NUM[SP_NUM] <> STIVA_NUM[SP_NUM+1];
          3:    B := STIVA_NUM[SP_NUM] < STIVA_NUM[SP_NUM+1];
          4:    B := STIVA_NUM[SP_NUM] > STIVA_NUM[SP_NUM+1];
          5:    B := STIVA_NUM[SP_NUM] <= STIVA_NUM[SP_NUM+1];
          6:    B := STIVA_NUM[SP_NUM] >= STIVA_NUM[SP_NUM+1];
          else  B := STIVA_NUM[SP_NUM] = STIVA_NUM[SP_NUM+1];
          end;
          STIVA_BOOL[SP_BOOL] := Byte(B);
          Inc(SP_BOOL);
          if (SP_BOOL) > BOOL_MAX then begin
            Result := ERR_STACK_BOOL_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  IBOOL_OP:
        begin
          Dec(SP_BOOL);
          if SP_BOOL < 1 then begin
            Result := ERR_STACK_BOOL_UNDERFLOW;
            exit;
          end;
          case COD[CS+1] of
          1:  STIVA_BOOL[SP_BOOL-1] := STIVA_BOOL[SP_BOOL-1] OR STIVA_BOOL[SP_BOOL];
          2:  STIVA_BOOL[SP_BOOL-1] := STIVA_BOOL[SP_BOOL-1] AND STIVA_BOOL[SP_BOOL];
          3:  STIVA_BOOL[SP_BOOL-1] := STIVA_BOOL[SP_BOOL-1] XOR STIVA_BOOL[SP_BOOL];
          else STIVA_BOOL[SP_BOOL-1] := STIVA_BOOL[SP_BOOL-1] OR STIVA_BOOL[SP_BOOL];
          end;
          CS := CS + 2;
        end;
  IBOOL_NOT:
        begin
          if SP_BOOL < 1 then begin
            Result := ERR_STACK_BOOL_UNDERFLOW;
            exit;
          end;
          STIVA_BOOL[SP_BOOL-1] := STIVA_BOOL[SP_BOOL-1] XOR 1;
          Inc(CS);
        end;
  IBOOLPUSH:
        begin
          STIVA_BOOL[SP_BOOL] := COD[CS+1];
          Inc(SP_BOOL);
          if SP_BOOL > BOOL_MAX then begin
            Result := ERR_STACK_BOOL_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  IBOOLPUSHVAR:
        begin
          STIVA_BOOL[SP_BOOL] := VAR_BOOL[COD[CS+1]];
          Inc(SP_BOOL);
          if SP_BOOL > BOOL_MAX then begin
            Result := ERR_STACK_BOOL_OVERFLOW;
            exit;
          end;
          CS := CS + 2;
        end;
  ISET_BVARIABLE:
        begin
          Dec(SP_BOOL);
          if SP_BOOL < 0 then begin
            Result := ERR_STACK_BOOL_UNDERFLOW;
            exit;
          end;
          VAR_BOOL[COD[CS+1]] := STIVA_BOOL[SP_BOOL];
          CS := CS + 2;
        end;
  INOP:   Inc(CS);
  IMONEY: begin
            if TestLicense then Inc(CS)
            else COD[CS] := ISTOP;
          end;
  IREAD_NEXT:
        begin
          LDataSet.Next;
          VAR_BOOL[1] := Byte(LDataSet.EOF);
          Inc(CS);
          //SET EOF
        end;
  IREAD_NEXTX:
        begin
          Inc(CS);
          XDataSet[Cod[CS]].Next;
          VAR_BOOL[1+Cod[CS]] := Byte(XDataSet[Cod[CS]].EOF);
          Inc(CS);
          //SET EOF
        end;
   IREAD_FIRST:
        begin
          LDataSet.First;
          VAR_BOOL[1] := Byte(LDataSet.EOF);
          Inc(CS);
          //SET EOF
        end;
  IREAD_FIRSTX:
        begin
          Inc(CS);
          XDataSet[Cod[CS]].First;
          VAR_BOOL[1+Cod[CS]] := Byte(XDataSet[Cod[CS]].EOF);
          Inc(CS);
          //SET EOF
        end;
  ISQLEXECX:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Inc(CS);
          XDataSet[Cod[CS]].SQL.Text := STIVA_STR[SP_STR];
          try
            XDataSet[Cod[CS]].Close;
            XDataSet[Cod[CS]].DataBaseName := TDBDataset(LDataSet).DatabaseName;
            XDataSet[Cod[CS]].ExecSQL;
            VAR_BOOL[1+Cod[CS]] := Byte(TRUE);
          except
            VAR_BOOL[1+Cod[CS]] := Byte(FALSE);
          end;
          Inc(CS);
        end;
  ISQLOPENX:
        begin
          Dec(SP_STR);
          if (SP_STR < 0) then begin
            Result := ERR_STACK_STR_UNDERFLOW;
            exit;
          end;
          Inc(CS);
          XDataSet[Cod[CS]].SQL.Text := STIVA_STR[SP_STR];
          try
            XDataSet[Cod[CS]].Close;
            XDataSet[Cod[CS]].DataBaseName := TDBDataset(LDataSet).DatabaseName;
            XDataSet[Cod[CS]].Open;
            VAR_BOOL[1+Cod[CS]] := Byte(XDataSet[Cod[CS]].EOF);
          except
            VAR_BOOL[1+Cod[CS]] := Byte(FALSE);
          end;
          Inc(CS);
        end;
  else begin
        Result := ERR_INVALID_OPCODE;
        exit;
       end;
  end;
  until false;
end;

function VM_LISTA.GetSQL_FIELDS: String;
var
  I : Integer;
begin
  Result := NUME_VAR.Values['SQL_FIELDS'];
  if Result = '' then begin
    I := NUME_VAR.IndexOf('SQL_FIELDS=');
    if I<>-1 then NUME_VAR.Delete(I);
    GetVAR_STR('SQL_FIELDS', Result);
  end;
end;

function VM_LISTA.GetVAR_BOL(const ANumeVar: string;
  var AValue: Boolean): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit
  else AValue := Boolean(VAR_BOOL[Result]);
end;

function VM_LISTA.GetVAR_NUM(const ANumeVar: string;
  var AValue: double): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit
  else AValue := VAR_NUM[Result];
end;

function VM_LISTA.GetVAR_STR(const ANumeVar : String; var AValue: string): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit
  else AValue := VAR_STR[Result];
end;

function VM_LISTA.LoadFromFile(const AFileName: string): Integer;
var
  AFile : TFileStream;
  I : Integer;
  T : String;
begin
  Result := -1;
  try    AFile := TFileStream.Create(AFileName, fmOpenRead+fmShareDenyNone);
  except exit;
  end;
  try
    if AFile.Read(COD_Header, SizeOf(COD_Header)) <> SizeOf(COD_Header) then I := -1
    else I := 0;
  except
    I := -1;
  end;
  if I = 0 then begin
    try
      if AFile.Read(Cod, COD_Header.CodSIZE) <> COD_Header.CodSIZE then I := -1
      else I := 0;
    except
      I := -1;
    end;
  end;
  if I = 0 then begin
    SetLength(T, COD_HEADER.VarSize);
    try
      if AFile.Read(T[1], COD_HEADER.VarSize) <> COD_HEADER.VarSize then I := -1
      else I := 0;
    except
      I := -1;
    end;
  end;
  if I = 0 then NUME_VAR.Text := T;
  AFile.Free;
  Result := I;
end;

function VM_LISTA.SetVAR_BOL(const ANumeVar: string;
  const AValue: Boolean): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit
  else VAR_BOOL[Result] := Byte(AValue);
end;

function VM_LISTA.SetVAR_NUM(const ANumeVar: string;
  const AValue: double): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit
  else VAR_NUM[Result] := AValue;
end;

function VM_LISTA.SetVAR_STR(const ANumeVar, AValue: string): Integer;
begin
  Result := StrToIntDef(NUME_VAR.Values[ANumeVar],-1);
  if Result = -1 then exit;
  VAR_STR[Result] := AValue;
end;

function VM_LISTA.WriteToFile(Amount : Integer): Integer;
var
  I : Integer;
begin
  Result := -1;
  if OUT_FILE_Name = '' then begin
    Result := Amount;
    if Result <> 0 then FMyDlg.Start('OUT_FILE_NAME nedefinita pentru lista !',M_ERROK);
    exit;
  end else begin
    if LISTA_FILE = nil then
    try    LISTA_FILE := TFileStream.Create(OUT_File_Name, fmCreate);
    except exit;
    end;
    try I := LISTA_FILE.Write(BUFFER[1], Amount);
        if I = Amount then Result := 0;
        Delete(BUFFER,1,I);
    except
    end;
  end;
end;

end.


