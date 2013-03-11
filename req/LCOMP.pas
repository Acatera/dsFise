unit LCOMP;

interface

uses
  CLASSES, LASM;

const
  FIRST_VAR     = 250;

  ERR_EMPTY_FILE         =   -1;
  ERR_INVALID_OPCODE     =  -10;
  ERR_LEFT_PARANTHESE    =  -11;
  ERR_RIGHT_PARANTHESE   =  -12;
  ERR_EGAL_EXPECTED      =  -14;
  ERR_PLUS_EXPECTED      =  -15;
  ERR_AMPERSAND_EXPECTED =  -16;
  ERR_INVALID_NUMBER     =  -17;
  ERR_INVALID_NVAR       =  -18;
  ERR_INVALID_TEXT       =  -19;
  ERR_APOSTROF_EXPECTED  =  -20;
  ERR_INVALID_SVAR       =  -21;
  ERR_COMMA_EXPECTED     =  -22;
  ERR_WHILE_MISSING      =  -23;
  ERR_INVALID_CONDITIE   =  -24;
  ERR_BOOL_VAR_EXPECTED  =  -25;
  ERR_OPERATOR_EXPECTED  =  -26;
  ERR_BOOL_OP_EXPECTED   =  -27;
  ERR_ELSE_WITH_NO_IF    =  -28;
  ERR_RAW_END            =  -29;
  ERR_SPACE_EXPECTED     =  -30;
  ERR_DUPLICATE_NAME     =  -31;
  ERR_INVALID_BVAR       =  -32;
  ERR_INVALID_ADR        =  -33;
  ERR_WRITE_COD_FILE     =  -34;
  ERR_INVALID_ANVAR      =  -35;

type
  VM_COMPILER = class(TObject)
    INST, SRELOC : TStringList;
    SADR, SVAR, ANVAR, NVAR, BVAR, SQL_FIELDS: TStrings;
    COD : Array[0..COD_MAX] of BYTE;
    CS, IP, IWHILE, IIF, ISQL : Integer;
    ERR_MSG, ERR_TEXT : String;
    HEADER : THeader;
  private
    function GetBVar(const AVar : String) : Integer;
    function GetNVar(const AVar : String) : Integer;
    function GetANVar(const AVar : String; const DIM_MAX : Integer) : Integer;
    function GetSVar(const AVar : String) : Integer;
    function GET_FIELD(const AFieldName : String) : Integer;
    function EncodeText(AText : String) : Integer;
    function EncodeNumber(AText : String) : Integer;
    function EncodeConditie(AText : String) : Integer;
    function Encode : Integer;
  public
    function LoadFromFile(const AFileName : string) : Integer;
    function Compile(const AOutFileName : string) : Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  function GetClosedBracket(const AText : String) : Integer;
  function Get_Closed_Bracket(const AText: String; const ParantezaDeschisa,
    ParantezaInchisa : char; const Start : Integer): Integer;

implementation

uses
  SysUtils;

{ VM_COMPILER }

constructor VM_COMPILER.Create;
begin
  SADR := TStringList.Create;
  SVAR := TStringList.Create;
  NVAR := TStringList.Create;
  ANVAR := TStringList.Create;
  BVAR := TStringList.Create;
  INST := TStringList.Create;
  SRELOC := TStringList.Create;
  SQL_FIELDS := TStringList.Create;
end;

destructor VM_COMPILER.Destroy;
begin
  SQL_FIELDS.Free;
  SRELOC.Free;
  INST.Free;
  BVAR.Free;
  ANVAR.Free;
  NVAR.Free;
  SVAR.Free;
  SADR.Free;
  inherited Destroy;
end;

function VM_COMPILER.LoadFromFile(const AFileName: string): Integer;
begin
  Inst.Clear;
  try
    Inst.LoadFromFile(AFileName);
    Result := 0;
  except
    Result := -1;
  end;
  ISQL := 0;
end;

function Get_Closed_Bracket(const AText: String; const ParantezaDeschisa,
  ParantezaInchisa : char; const Start : Integer): Integer;
var
  I, J : Integer;
begin
  J := 1;
  for I := Start to Length(AText) do
    if AText[I] = ParantezaDeschisa then Inc(J)
    else if AText[I] = ParantezaInchisa then begin
      Dec(J);
      if J=0 then break;
    end;
  if J = 0 then Result := I
  else Result := -1;
end;

function GetClosedBracket(const AText: String): Integer;
begin
  Result := Get_Closed_Bracket(AText,'(',')',1);
end;

function VM_COMPILER.Encode: Integer;
var
  Buf, Temp, AVar : String;
  Ch : Char;
  X,Y,I,J,K,L,SAVE_CS : Integer;
  IFile : TStringList;
begin
  Buf := Trim(Inst.Strings[IP]);
  Result := 0;
  repeat
    if (Buf = '') or (Buf[1] = '/') then exit;
    case Upcase(Buf[1]) of
    '[':  begin
            Delete(Buf,1,1);
            X := Pos(']', Buf);
            if X = 0 then begin
              ERR_MSG := 'Lipseste paranteza dreapta "]" !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE; exit;
            end;
            SetLength(Buf,X-1);
            Result := 0;
            if SAdr.IndexOfName(UpperCase(Buf)) = -1 then
              SAdr.Add(UpperCase(Buf)+'='+IntToStr(CS))
            else begin
              if SAdr.IndexOfName('_'+UpperCase(Buf)) = -1 then
                SAdr.Add('_'+UpperCase(Buf)+'='+IntToStr(CS))
                else begin
                  ERR_MSG := 'Subrutina declarata de doua ori !';
                  ERR_TEXT := Buf;
                  Result := ERR_DUPLICATE_NAME;
                end;
              COD[CS] := IRET;
              Inc(CS);
            end;
            Delete(Buf,1,X);
          end;
    '@':  begin
            if (Length(Buf)=1) or (Buf[2] <> '@') then begin
              ERR_MSG := 'Lipseste @ de la variabila booleana !';
              ERR_TEXT := Buf;
              Result := ERR_INVALID_BVAR; exit;
            end;
            X := POS('=', Buf);
            if X = 0 then begin
              ERR_MSG := 'Lipseste "=" de atribuire la variabila booleana !';
              ERR_TEXT := Buf;
              Result := ERR_EGAL_EXPECTED; exit;
            end;
            Temp := UpperCase(Copy(Buf,3,X-3));
            Temp := Trim(Temp);
            Delete(Buf,1,X);
            Buf := Trim(Buf);
            J := ENCODECONDITIE(Buf);
            if J <> 0 then begin
              Result := J; exit;
            end;
            COD[CS] := ISET_BVARIABLE;
            J := GETBVAR(Temp);
            if J = -1 then begin
              ERR_MSG := 'Variabila nu e de tip boolean !';
              ERR_TEXT := Temp;
              Result := ERR_INVALID_BVAR; exit;
            end;
            COD[CS+1] := J;
            CS := CS + 2;
            exit;
          end;
    '%':  begin
            X := POS('=', Buf);
            if X = 0 then begin
              ERR_MSG := 'Lipseste "=" de atribuire !';
              ERR_TEXT := Buf;
              Result := ERR_EGAL_EXPECTED; exit;
            end;
            Temp := UpperCase(Copy(Buf,2,X-2));
            if Copy(Temp,1,1) = '%' then begin
              CH := '0'; Delete(Temp,1,1);
            end else if Copy(Temp,1,1) = '_' then begin
              CH := '2'; Delete(Temp,1,1);
            end else CH := '1';
            Temp := Trim(Temp);
            Delete(Buf,1,X);
            Buf := Trim(Buf);
            J := 0;
            if (CH = '1') and (Copy(Buf,1,1)='+') then J := 1;
            if ((CH = '0') or (CH = '2')) and (Buf<>'') and (Buf[1] in ['+','-','*','/','^']) then J := 1;
            if ((CH = '0') or (CH = '2')) then I := EncodeNumber(Copy(Buf,J+1,Length(Buf)-J))
            else I := EncodeText(Copy(Buf,J+1,Length(Buf)-J));
            if I <> 0 then begin
              Result := I; exit;
            end;
            if CH = '0' then begin
              if J = 0 then COD[CS] := ISET_NVARIABLE
              else COD[CS] := ISET_OPNVARIABLE;
              I := GetNVar(Temp);
              COD[CS+1] := I;
              if J = 1 then begin
                case Buf[1] of
                '+':      COD[CS+2] := 1;
                '-':      COD[CS+2] := 2;
                '*':      COD[CS+2] := 3;
                '/':      COD[CS+2] := 4;
                '^':      COD[CS+2] := 5;
                end;
                Inc(CS);
              end;
            end else if Ch = '1' then begin
              if J = 0 then COD[CS] := ISET_SVARIABLE
              else COD[CS] := ISET_PLUSSVARIABLE;
              I := GetSVar(Temp);
              COD[CS+1] := I;
            end else if Ch = '2' then begin
              I := Pos('[', Temp);
              if I = 0 then begin
                ERR_MSG := 'Lipseste "[" din declaratia array !';
                ERR_TEXT := Temp;
                Result := ERR_LEFT_PARANTHESE;
                exit;
              end;
              if Copy(Temp,Length(Temp),1) <> ']' then begin
                ERR_MSG := 'Lipseste "]" din declaratia array !';
                ERR_TEXT := Temp;
                Result := ERR_RIGHT_PARANTHESE;
                exit;
              end;
              AVar := Copy(Temp,1,I-1);
              Delete(Temp,1,I);
              SetLength(Temp, Length(Temp)-1);
              I := Pos(',', Temp);
              if I = 0 then Y := -1
              else begin
                Y := StrToIntDef(Trim(Copy(Temp,1,I-1)),-1);
                if Y = -1 then begin
                  ERR_MSG := 'Constanta numerica invalida !';
                  ERR_TEXT := Temp;
                  Result := ERR_INVALID_NUMBER;
                  exit;
                end;
                Delete(Temp,1,I);
              end;
              Temp := Trim(Temp);
              X := StrToIntDef(Temp,-1);
              if X = -1 then begin
                SAVE_CS := EncodeNumber(Temp);
                if SAVE_CS <> 0 then begin
                  Result := SAVE_CS; exit;
                end;
              end;
              if (X <> -1) then
                if J = 0 then COD[CS] := ISET_XANVARIABLE
                else COD[CS] := ISET_XOPANVARIABLE
              else
                if J = 0 then COD[CS] := ISET_ANVARIABLE
                else COD[CS] := ISET_OPANVARIABLE;
              Y := GetANVar(AVAR,Y);
              if Y = -1 then begin
                ERR_MSG := 'Nu ati specificat dimensiunea max. array !';
                ERR_TEXT := Buf;
                Result := ERR_INVALID_ANVAR; exit;
              end;
              if X <> -1 then COD[CS+1] := Y - X
              else COD[CS+1] := Y;
              if J = 1 then begin
                case Buf[1] of
                '+':      COD[CS+2] := 1;
                '-':      COD[CS+2] := 2;
                '*':      COD[CS+2] := 3;
                '/':      COD[CS+2] := 4;
                '^':      COD[CS+2] := 5;
                end;
                Inc(CS);
              end;
            end;
            CS := CS + 2;
            if I = -1 then begin
              if CH = '0' then begin
                ERR_MSG := 'Variabila nu e de tip numeric !';
                ERR_TEXT := Temp;
                Result := ERR_INVALID_NVAR
              end else begin
                ERR_MSG := 'Variabila nu e de tip string !';
                ERR_TEXT := Temp;
                Result := ERR_INVALID_SVAR;
              end;
              exit;
            end;
            exit;
          end;
    'A':  begin
            if UpperCase(Buf) <> 'ABORT' then begin
              ERR_MSG := 'Instructiune necunoscuta !';
              ERR_TEXT := Buf;
              Result := ERR_INVALID_OPCODE
            end else begin
              COD[CS] := IRET;
              Inc(CS);
            end;
            exit;
          end;
    'D':  if (UpperCase(Copy(Buf,1,6)) = 'DELETE') then begin
            Delete(Buf,1,6);
            if (Buf = '') or (Buf[1] <> '(') then begin
              ERR_MSG := 'Lipseste "(" din declararea procedurii DELETE !';
              ERR_TEXT := Buf;
              Result := ERR_LEFT_PARANTHESE;
              exit;
            end;
            Delete(Buf,1,1);
            I := GetClosedBracket(Buf);
            if I = -1 then begin
              ERR_MSG := 'Lipseste ")" din declararea  procedurii DELETE !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE;
              exit;
            end;
            if (Buf = '') or (Buf[1] <> '%') then begin
              ERR_MSG := 'Lipseste "%" din declararea  procedurii DELETE !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE;
              exit;
            end;
            Delete(Buf,1,1);
            Dec(I);
            J := Pos(',', Buf);
            if (J = 0) or (J > I) then begin
              ERR_MSG := 'Lipseste "," din declararea procedurii DELETE !';
              ERR_TEXT := Buf;
              Result := ERR_COMMA_EXPECTED;
              exit;
            end;
            L := GetSVar(Copy(Buf,1,J-1));
            Delete(Buf,1,J);
            I := I - J;

            J := Pos(',', Buf);
            if (J = 0) or (J > I) then begin
              ERR_MSG := 'Lipseste a doua "," din declararea procedurii DELETE !';
              ERR_TEXT := Buf;
              Result := ERR_COMMA_EXPECTED;
              exit;
            end;
            K := EncodeNumber(Trim(Copy(Buf,1,J-1)));
            if K <> 0 then begin
              Result := K; exit;
            end;
            Delete(Buf,1,J);
            I := I - J;

            K := EncodeNumber(Trim(Copy(Buf,1,I-1)));
            if K <> 0 then begin
              Result := K; exit;
            end;
            Delete(Buf,1,I);
            Cod[CS] := ISDELETE_XY;
            COD[CS+1] := L;
            Inc(CS,2);
          end;
    'E', 'J':
      if (UpperCase(Copy(Buf,1,4)) = 'EXEC') or
         (UpperCase(Copy(Buf,1,4)) = 'JUMP') then begin
        if UpCase(Buf[1]) = 'E' then Cod[CS] := ICALL
        else Cod[CS] := IJMP;
        X := Pos('[', Buf);
        if X = 0 then begin
          ERR_MSG := 'Lipseste "[" din declaratia adresei !';
          ERR_TEXT := Buf;
          Result := ERR_LEFT_PARANTHESE
        end else begin
          Y := Pos(']', Buf);
          if (Y = 0) or (Y<=X+1) then begin
            ERR_MSG := 'Lipseste "]" din declaratia adresei !';
            ERR_TEXT := Buf;
            Result := ERR_RIGHT_PARANTHESE
          end else begin
            SRELOC.Add(UpperCase(Copy(Buf,X+1,Y-X-1))+'='+IntToStr(CS+1));
            CS := CS + 5;
          end;
        end;
        exit;
      end else if UpperCase(Copy(Buf,1,4))='ELSE' then begin
        Y := 0;
        for X := IIF downto 1 do if SAdr.IndexOfName('ELSE'+IntToStr(X)) = -1
          then begin
            Y := X; break;
          end;
        if Y = 0 then begin
          ERR_MSG := 'Lipseste IF corespunzator acestei instructiuni ELSE !';
          ERR_TEXT := Buf;
          Result := ERR_ELSE_WITH_NO_IF;
          exit;
        end;
        Cod[CS] := IJMP;
        Cod[CS+1] := 1; Cod[CS+2] := 2;
        Cod[CS+3] := 3; Cod[CS+4] := 4;
        SReloc.Add('ENDIF'+IntToStr(Y)+'='+IntToStr(CS+1));
        CS := CS+5;
        SAdr.Add('ELSE'+IntToStr(Y)+'='+IntToStr(CS));
        Delete(Buf,1,4);
        Buf := Trim(Buf);
        if (Buf <> '') and (Buf[Length(Buf)]=';') then begin
          SetLength(Buf,Length(Buf)-1);
          Inst[IP] := 'ENDIF';
          Dec(IP);
        end;
      end else if UpperCase(Copy(Buf,1,5))='ENDIF' then begin
        Y := 0;
        for X := IIF downto 1 do if SAdr.IndexOfName('ENDIF'+IntToStr(X)) = -1
          then begin
            Y := X; break;
          end;
        if Y = 0 then begin
          ERR_MSG := 'Lipseste IF pentru acest ENDIF !';
          ERR_TEXT := Buf;
          Result := ERR_ELSE_WITH_NO_IF;
          exit;
        end;
        if SAdr.IndexOfName('ELSE'+IntToStr(Y)) = -1 then
          SAdr.Add('ELSE'+IntToStr(Y)+'='+IntToStr(CS));
        SAdr.Add('ENDIF'+IntToStr(Y)+'='+IntToStr(CS));
        exit;
      end else begin
          ERR_MSG := 'Instructiune necunoscuta !';
          ERR_TEXT := Buf;
          Result := ERR_INVALID_OPCODE;
          exit;
        end;
    'F': if UpperCase(Buf)='FLUSH' then begin
           COD[CS] := IFLUSH; Inc(CS);
           exit;
         end else if UpperCase(Copy(Buf,1,5))='FIRST' then begin
           if (Length(Buf) >= 6) and (Buf[6] in ['1','2','3']) then
           begin
             COD[CS] := IREAD_FIRSTX;
             Inc(CS);
             COD[CS] := Byte(Buf[6])-48;
           end else COD[CS] := IREAD_FIRST;
           Inc(CS); exit;
         end else begin
            ERR_MSG := 'Instructiune necunoscuta !';
            ERR_TEXT := Buf;
            Result := ERR_INVALID_OPCODE;
            exit;
          end;
    'H','T':
         if (UpperCase(Buf) = 'HEADER=TEXT') then begin
           Cod[CS] := IHEADER_TEXT; Inc(CS);
           exit;
         end else if (UpperCase(Copy(Buf,1,7)) = 'HEADER[') or
           (UpperCase(Copy(Buf,1,5)) = 'TEXT[') then begin
           Ch := UpCase(Buf[1]);
           if Ch = 'H' then X := 7 else X := 5;
           Delete(Buf,1,X);
           X := Pos(']', Buf);
           if X = 0 then begin
             ERR_MSG := 'Lipseste "]" din declaratie !';
             ERR_TEXT := Buf;
             Result := ERR_RIGHT_PARANTHESE;
             exit;
           end;
           Y := Pos(',', Buf);
           if (Y = 0) or (Y > X) then begin
             ERR_MSG := 'Lipseste "," dintre cele doua numere!';
             ERR_TEXT := Buf;
             Result := ERR_COMMA_EXPECTED;
             exit;
           end;
           I := StrToIntDef(Copy(Buf,1,Y-1),-1);
           J := StrToIntDef(Copy(Buf,Y+1,X-Y-1),-1);
           //TEXT[intX,intY]
           if (I<>-1) and (J<>-1) and (Ch='T') then Ch := '0'
           else begin
             I := EncodeNumber(Copy(Buf,1,Y-1));
             if I <> 0 then begin
               Result := I; exit;
             end;
             I := EncodeNumber(Copy(Buf,Y+1,X-Y-1));
             if I <> 0 then begin
               Result := I; exit;
             end;
           end;
           Delete(Buf,1,X);
           Buf := Trim(Buf);
           if (Buf = '') or (Buf[1] <> '=') then begin
             ERR_MSG := 'Lipseste "=" de atribuire !';
             ERR_TEXT := Buf;
             Result := ERR_EGAL_EXPECTED;
             exit;
           end;
           Delete(Buf,1,1);
           Buf := Trim(Buf);
           Result := EncodeText(Buf);
           if CH = 'T' then Cod[CS] := ISET_TEXT_XY
           else if CH = 'H' then Cod[CS] := ISET_HEADER_XY
           else if CH = '0' then begin
             Cod[CS] := ISET_TEXT_INTXY;
             Move(I, COD[CS+1], SizeOf(Integer));
             Move(J, COD[CS+5], SizeOf(Integer));
             CS := CS + 8;
           end;
           Inc(CS);
           exit;
         end else begin
           ERR_MSG := 'Instructiune necunoscuta !';
           ERR_TEXT := Buf;
           Result := ERR_INVALID_OPCODE;
           exit;
         end;
    'I': begin
           if UpperCase(Copy(Buf,1,8)) = 'INCLUDE(' then begin
             Delete(Buf,1,8);
             if Copy(Buf,Length(Buf),1) <> ')' then begin
               ERR_MSG := 'Lipseste "]" !';
               ERR_TEXT := Buf;
               Result := ERR_RIGHT_PARANTHESE;        exit;
             end;
             SetLength(Buf,Length(Buf)-1);
             Buf := Trim(Buf);
             IFile := TStringList.Create;
             try      IFile.LoadFromFile(Buf);
             except
               ERR_MSG := 'Fisier negasit !';
               ERR_TEXT := Buf;
               Result := ERR_EMPTY_FILE;
             end;
             for X := IFile.Count-1 downto 0 do
               Inst.Insert(IP+1,IFile.Strings[X]);
             Buf := '';
             IFile.Free;
           end else if UpperCase(Copy(Buf,1,7)) = 'INSERT[' then begin
             X := POS(']', Buf);
             if X = 0 then begin
               ERR_MSG := 'Lipseste "]" !';
               ERR_TEXT := Buf;
               Result := ERR_RIGHT_PARANTHESE;        exit;
             end;
             Y := EncodeNumber(Copy(Buf,8,X-8));
             if Y <> 0 then begin
               Result := Y; exit;
             end;
             Delete(Buf,1,X);
             if (Buf = '') or (Buf[1] <> '=') then begin
               ERR_MSG := 'Lipseste "=" de atribuire !';
               ERR_TEXT := Buf;
               Result := ERR_EGAL_EXPECTED;
               exit;
             end;
             Delete(Buf,1,1);
             Result := EncodeText(Buf);
             Cod[CS] := IINSERT_Y;
             Inc(CS);
             exit;
           end else if (UpperCase(Copy(Buf,1,2))='IF') then begin
             Delete(Buf,1,2);
             Buf := Trim(Buf);
             if (Buf = '') or (Buf[1] <> '(') then begin
               ERR_MSG := 'Lipseste "(" din instructiunea IF (conditie) !';
               ERR_TEXT := Buf;
               Result := ERR_LEFT_PARANTHESE;  exit;
             end;
             Delete(Buf,1,1);
             X := GetClosedBracket(Buf);
             if X = -1 then begin
               ERR_MSG := 'Lipseste ")" din instructiunea IF !';
               ERR_TEXT := Buf;
               Result := ERR_RIGHT_PARANTHESE;  exit;
             end;
             Y := EncodeConditie(Copy(Buf,1,X-1));
             if Y <> 0 then begin
               Result := Y; exit;
             end;
             Delete(Buf,1,X);
             Inc(IIF);
             COD[CS] := IJMPF;
             SReloc.Add('ELSE'+IntToStr(IIF)+'='+IntToStr(CS+1));
             CS := CS + 5;
             Buf := Trim(Buf);
             if Copy(Buf,Length(Buf),1) = ';' then
             begin
               SetLength(Buf,Length(Buf)-1);
               Inst[IP] := 'ENDIF';
               Dec(IP);
             end;
           end else begin
             ERR_MSG := 'Instructiune necunoscuta !';
             ERR_TEXT := Buf;
             Result := ERR_INVALID_OPCODE;
             exit;
           end;
         end;
    'L': begin
           if UpperCase(Copy(Buf,2,4))='INES' then begin
             X := Pos('=',Buf);
             if X = 0 then begin
               ERR_MSG := 'Lipseste "=" de atribuire !';
               ERR_TEXT := Buf;
               Result := ERR_EGAL_EXPECTED;
             end else begin
               Result := EncodeNumber(Copy(Buf,X+1,Length(Buf)-X));
               COD[CS] := IALLOC_LINES;
               Inc(CS);
             end;
             exit;
           end else begin
             ERR_MSG := 'Instructiune necunoscuta !';
             ERR_TEXT := Buf;
             Result := ERR_INVALID_OPCODE;
             exit;
           end;
         end;
    'M': if UpperCase(Buf)='MONEY' then begin
           COD[CS] := IMONEY; Inc(CS);
           exit;
         end else begin
            ERR_MSG := 'Instructiune necunoscuta !';
            ERR_TEXT := Buf;
            Result := ERR_INVALID_OPCODE;
            exit;
          end;
    'R': if UpperCase(Copy(Buf,1,9))='READ_NEXT' then begin
           if (Length(Buf) >= 10) and (Buf[10] in ['1','2','3']) then
           begin
             COD[CS] := IREAD_NEXTX;
             Inc(CS);
             COD[CS] := Byte(Buf[10])-48;
           end else COD[CS] := IREAD_NEXT;
           Inc(CS); exit;
         end else if UpperCase(Copy(Buf,1,3))='RAW' then begin
           Delete(Buf,1,3);
           if Buf='' then Buf := '1';
           X := StrToIntDef(Buf,-1);
           if X = -1 then begin
             ERR_MSG := 'Constanta numerica invalida !';
             ERR_TEXT := Buf;
             Result := ERR_INVALID_NUMBER;
             exit;
           end;
           repeat
             Inc(IP);
             if IP >= Inst.Count then begin
               ERR_MSG := 'Lipseste instructiunea RAWEND !';
               ERR_TEXT := Buf;
               Result := ERR_RAW_END;
               exit;
             end;
             Buf := Inst.Strings[IP];
             if UpperCase(Buf) = 'RAWEND' then begin
               Result := 0; exit;
             end;
             COD[CS] := ISPUSH;
             Cod[CS+1] := Length(Buf);
             SAVE_CS := CS;
             CS := CS + 3 + Cod[CS+1];
             COD[CS-1] :=0;
             COD[CS] := ISET_TEXT_INTXY;
             Y := 1;
             Move(X, COD[CS+1], SizeOf(Integer));
             Move(Y, COD[CS+5], SizeOf(Integer));
             CS := CS + 9;
             repeat
               Y := Pos('~', BUF);
               if Y = 0 then break;
               Temp := Copy(BUF, Y+1, Length(Buf)-Y);
               I := Pos(' ', Temp);
               if I = 0 then begin
                 ERR_MSG := 'Lipseste un spatiu la sfarsitul declaratiei "~" !';
                 ERR_TEXT := Temp;
                 Result := ERR_SPACE_EXPECTED;
                 exit;
               end;
               SetLength(Temp,I-1);
               J := EncodeText(Temp);
               if J <> 0 then begin
                 Result := J; exit;
               end;
               COD[CS] := ISET_TEXT_INTXY;
               Move(X,COD[CS+1],SizeOf(Integer));
               Move(Y,COD[CS+5],SizeOf(Integer));
               CS := CS + 9;
               for J := 0 to I-1 do Buf[Y+J] := ' ';
             until false;
             Move(Buf[1],COD[SAVE_CS+2], Length(Buf));
             Inc(X);
           until false;
           Result := 0;
         end else begin
           ERR_MSG := 'Instructiune necunoscuta !';
           ERR_TEXT := Buf;
           Result := ERR_INVALID_OPCODE;
           exit;
         end;
    'S': if UpperCase(Copy(Buf,1,5))='SORT(' then begin
           Delete(Buf,1,5);
           I := Pos(',',Buf);
           if I = 0 then begin
              ERR_MSG := 'Lipseste virgula "," din instructiunea SORT !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE; exit;
           end;
           X := GETANVAR(UpperCase(Copy(Buf,1,I-1)),-1);
           if X = -1 then begin
              ERR_MSG := 'Nu ati specificat dimensiunea max. array !';
              ERR_TEXT := Buf;
              Result := ERR_INVALID_ANVAR; exit;
           end;
           Delete(Buf,1,I);
           I := Pos(',',Buf);
           if I = 0 then begin
              ERR_MSG := 'Lipseste virgula "," din instructiunea SORT !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE; exit;
           end;
           Y := GETANVAR(UpperCase(Copy(Buf,1,I-1)),-1);
           if Y = -1 then begin
              ERR_MSG := 'Nu ati specificat dimensiunea max. array !';
              ERR_TEXT := Buf;
              Result := ERR_INVALID_ANVAR; exit;
           end;
           Delete(Buf,1,I);
           I := Pos(')',Buf);
           if I = 0 then begin
              ERR_MSG := 'Lipseste paranteza dreapta ")" !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE; exit;
           end;
           I := EncodeNumber(Trim(Copy(Buf,1,I-1)));
           if I <> 0 then begin
             Result := I; exit;
           end;
           COD[CS] := ISORT_ANVAR;
           COD[CS+1] := X;
           COD[CS+2] := Y;
           CS := CS + 3;
           exit;
         end else if UpperCase(Copy(Buf,1,9))='SQLFIELD(' then begin
           Delete(Buf,1,9);
           Buf := Trim(Buf);
           I := Pos(')',Buf);
           if I = 0 then begin
              ERR_MSG := 'Lipseste paranteza dreapta ")" !';
              ERR_TEXT := Buf;
              Result := ERR_RIGHT_PARANTHESE; exit;
           end;
           Temp := Copy(Buf,1,I-1);
           Delete(Buf,1,I);
           Buf := Trim(Buf);
           if Copy(Buf,1,1)<>'=' then begin
              ERR_MSG := 'Lipseste "=" de la definirea campului SQL !';
              ERR_TEXT := Buf;
              Result := ERR_EGAL_EXPECTED; exit;
           end;
           Delete(Buf,1,1);
           Buf := Trim(Buf);
           I := GET_FIELD(Temp);
           SQL_FIELDS.VALUES['__SQLDEF'+IntToStr(I)] := Buf;
           exit;
         end else if (UpperCase(Copy(Buf,1,7))='SQLEXEC') or (UpperCase(Copy(Buf,1,7))='SQLOPEN')
         then begin
           if Length(Buf) < 10 then begin
             ERR_MSG := 'Instructiune SQL prea scurta !';
             ERR_TEXT := Buf;
             Result := ERR_LEFT_PARANTHESE;
             exit;
           end;
           if not(Buf[8] in ['1','2','3']) then begin
             ERR_MSG := 'Lipseste "1","2" sau "3" din declaratia SQL !';
             ERR_TEXT := Temp;
             Result := ERR_LEFT_PARANTHESE;
             exit;
           end;
           if Buf[9] <> '(' then begin
             ERR_MSG := 'Lipseste "(" din declaratia SQL !';
             ERR_TEXT := Temp;
             Result := ERR_LEFT_PARANTHESE;
             exit;
           end;
           if Copy(Buf,Length(Buf),1) <> ')' then begin
             ERR_MSG := 'Lipseste ")" din declaratia SQL !';
             ERR_TEXT := Temp;
             Result := ERR_LEFT_PARANTHESE;
             exit;
           end;
           Result := EncodeText(Copy(Buf,10,Length(Buf)-10));
           if UpCase(Buf[4]) = 'O' then Cod[CS] := ISQLOPENX
           else Cod[CS] := ISQLEXECX;
           Cod[CS+1] := Byte(Buf[8])-48;
           CS := CS + 2;
           exit;
         end else begin
           ERR_MSG := 'Instructiune necunoscuta !';
           ERR_TEXT := Buf;
           Result := ERR_INVALID_OPCODE;
           exit;
         end;
    'V': if UpperCase(Copy(Buf,1,3))='VER' then begin
           Delete(Buf,1,3);
           Header.Versiune1 := StrToIntDef(Buf,1);
           Result := 0;
           exit;
         end else begin
           ERR_MSG := 'Instructiune necunoscuta !';
           ERR_TEXT := Buf;
           Result := ERR_INVALID_OPCODE;
           exit;
         end;
    'W': begin
           if UpperCase(Buf)='WRITE_TEXT' then begin
             COD[CS] := IWRITE_TEXT; Inc(CS); exit;
           end;
           if UpperCase(Buf)='WRITE_HEADER' then begin
             COD[CS] := IWRITE_HEADER; Inc(CS); exit;
           end;
           if UpperCase(Copy(Buf,1,6))='WRITE_' then begin
             EncodeText(Copy(Buf,7,Length(Buf)-6));
             COD[CS] := IWRITE; Inc(CS); exit;
           end;
           if UpperCase(Copy(Buf,1,8))='WHILEEND' then begin
             Y := 0;
             for X := IWhile downto 1 do
               if SAdr.IndexOfName('WHILEEND'+IntToStr(X)) = -1 then begin
                 Y := X; break;
               end;
             if Y = 0 then begin
               ERR_MSG := 'Lipseste instructiunea WHILE pt. aceasta WHILEEND !';
               ERR_TEXT := Buf;
               Result := ERR_WHILE_MISSING;
               exit;
             end;
             COD[CS] := IJMP;
             X := StrToIntDef(SAdr.Values['WHILE'+IntToStr(Y)],-1);
             if X = -1 then begin
               ERR_MSG := 'Lipseste inst. WHILE !';
               ERR_TEXT := Buf;
               Result := ERR_WHILE_MISSING;
               exit;
             end;
             Move(X, COD[CS+1], SizeOf(Integer));
             Inc(CS, 5);
             SAdr.Add('WHILEEND'+IntToStr(Y)+'='+IntToStr(CS));
             exit;
           end;
           if UpperCase(Copy(Buf,1,5))='WHILE' then begin
             Inc(IWhile);
             SAdr.Add('WHILE'+IntToStr(IWhile)+'='+IntToStr(CS));
             Delete(Buf,1,5);
             Buf := TrimLeft(Buf);
             if (Buf = '') or (Buf[1]<>'[') then begin
               ERR_MSG := 'Lipseste "[" din sintaxa WHILE [conditie] !';
               ERR_TEXT := Buf;
               Result := ERR_LEFT_PARANTHESE;
               exit;
             end;
             Delete(Buf,1,1);
             X := Pos(']', Buf);
             if X = 0 then begin
               ERR_MSG := 'Lipseste "]" din sintaxa WHILE [conditie] !';
               ERR_TEXT := Buf;
               Result := ERR_RIGHT_PARANTHESE;
               exit;
             end;
             Y := ENCODECONDITIE(Copy(Buf,1,X-1));
             if Y <> 0 then begin
               Result := Y; exit;
             end;
             Delete(Buf,1,X);
             COD[CS] := IJMPF;
             COD[CS+1] := 1; COD[CS+2] := 2;
             COD[CS+3] := 3; COD[CS+4] := 4;
             SRELOC.Add('WHILEEND'+IntToStr(IWhile)+'='+IntToStr(CS+1));
             Inc(CS, 5);
           end;
           if UpperCase(Copy(Buf,2,4))='IDTH' then begin
             X := Pos('=',Buf);
             if X = 0 then begin
               ERR_MSG := 'Lipseste "=" din sintaxa WIDTH=UN_NUMAR !';
               ERR_TEXT := Buf;
               Result := ERR_EGAL_EXPECTED
             end else begin
               Result := EncodeNumber(Copy(Buf,X+1,Length(Buf)-X));
               COD[CS] := ISET_WIDTH;
               Inc(CS);
             end;
             exit;
           end;
           exit;
         end;
    else  begin
      ERR_MSG := 'Instructiune necunoscuta !';
      ERR_TEXT := Buf;
      Result := ERR_INVALID_OPCODE;
      exit;
    end;
    end;
  until false;
end;

function VM_COMPILER.EncodeNumber(AText: String): Integer;
var
  Token : Array[0..128] of String;
  I, J, K, TC : Integer;
  D : Double;
  Ch : Char;
  function GenerateTokenCode(AToken : Integer) : Integer;
  var
    Temp : String;
    X : Integer;
  begin
    Temp := Token[AToken];
    if Temp = '' then begin
      ERR_MSG := 'Numar vid !';
      ERR_TEXT := Temp;
      Result := ERR_INVALID_NUMBER;
      exit;
    end;
    Result := 0;
    if Copy(Temp,1,4) = 'LPOS' then begin
      I := Pos(',', Temp);
      if I = 0 then begin
        ERR_MSG := 'Lipseste "," din sintaxa LPOS(UN_TEXT,UN_TEXT) !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Result := EncodeText(Copy(Temp,6,I-6));
      if Result <> 0 then exit;
      Delete(Temp,1,I);
      Result := EncodeText(Copy(Temp,1,Length(Temp)-1));
      Cod[CS] := INPUSHPOS;
      Inc(CS);
      exit;
    end;
    if Copy(Temp,1,5) = 'LDATA' then begin
      I := Pos(',', Temp);
      if I = 0 then begin
        ERR_MSG := 'Lipseste "," din sintaxa LDATA(UN_TEXT,UN_TEXT) !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Result := EncodeText(Copy(Temp,7,I-7));
      if Result <> 0 then exit;
      Delete(Temp,1,I);
      Result := EncodeText(Copy(Temp,1,Length(Temp)-1));
      Cod[CS] := INPUSHDIFDATA;
      Inc(CS);
      exit;
    end;
    if Temp[1] = 'L' then begin
      Result := EncodeText(Copy(Temp,3,Length(Temp)-3));
      Cod[CS] := INPUSHLEN;
      Inc(CS);
      exit;
    end;
    if Copy(Temp,1,6) = 'ROUND(' then begin
      Result := EncodeNumber(Copy(Temp,7,Length(Temp)-7));
      Cod[CS] := INPUSHROUND;
      Inc(CS);
      exit;
    end;
    if Temp[1]='@' then begin
      if Temp[3] in ['1','2','3'] then begin
        COD[CS] := INFIELDXPUSH;
        COD[CS+1] := Byte(Temp[3])-48;
        COD[CS+2] := Byte(Temp[4])-Byte('A');
        CS := CS + 3;
      end else begin
        COD[CS] := INFIELDPUSH;
        COD[CS+1] := GET_FIELD(Copy(Temp,3,Length(Temp)-2));
        CS := CS + 2;
      end;
      exit;
    end;
    if Copy(Temp,1,2) = '%_' then begin
      Delete(Temp,1,2);
      I := Pos('[',Temp);
      J := GetANVAR(Copy(Temp,1,I-1),-1);
      if J = -1 then begin
        ERR_MSG := 'Variabila array nu e initializata !';
        ERR_TEXT := Copy(Temp,1,I-1);
        Result := ERR_INVALID_ANVAR;
        exit;
      end;
      Delete(Temp,1,I);
      SetLength(Temp, Length(Temp)-1);
      Temp := Trim(Temp);
      K := StrToIntDef(Temp,-1);
      if K = -1 then begin
        K := EncodeNumber(Temp);
        if K <> 0 then begin
          Result := K; exit;
        end;
        K := -1;
      end;
      if K = -1 then begin
        COD[CS] := IANPUSHVAR;
        COD[CS+1] := J;
      end else begin
        COD[CS] := IXANPUSHVAR;
        COD[CS+1] := J-K;
      end;
      CS := CS + 2;
      exit;
    end;
    if Temp[1] = '%' then begin
      COD[CS] := INPUSHVAR;
      I := GetNVAR(Copy(Temp,3,Length(Temp)-2));
      if I = -1 then begin
        ERR_MSG := 'Variabila nu e de tip numeric !';
        ERR_TEXT := Copy(Temp,3,Length(Temp)-2);
        Result := ERR_INVALID_NVAR;
        exit;
      end;
      COD[CS+1] := I;
      CS := CS + 2;
      exit;
    end;
    for X := 1 to Length(Temp)-1 do
    if Temp[X] in ['+','-'] then begin
      Inc(TC);
      Token[TC] := Copy(Temp,1,X-1);
      I := GenerateTokenCode(TC);
      if I <> 0 then begin
        Result := I;
        exit;
      end;
      Inc(TC);
      Token[TC] := Copy(Temp,X+1,Length(Temp)-X);
      I := GenerateTokenCode(TC);
      if I <> 0 then begin
        Result := I;
        exit;
      end;
      COD[CS] := INOP_POP;
      if Temp[X] = '+' then COD[CS+1] := 1
      else if Temp[X] = '-' then COD[CS+1] := 2;
      CS := CS + 2;
      exit;
    end;
    for X := 1 to Length(Temp)-1 do
    if Temp[X] in ['*','/','^'] then begin
      Inc(TC);
      Token[TC] := Copy(Temp,1,X-1);
      I := GenerateTokenCode(TC);
      if I <> 0 then begin
        Result := I;
        exit;
      end;
      Inc(TC);
      Token[TC] := Copy(Temp,X+1,Length(Temp)-X);
      I := GenerateTokenCode(TC);
      if I <> 0 then begin
        Result := I;
        exit;
      end;
      COD[CS] := INOP_POP;
      if Temp[X] = '*' then COD[CS+1] := 3
      else if Temp[X] = '/' then COD[CS+1] := 4
      else if Temp[X] = '^' then COD[CS+1] := 5;
      CS := CS + 2;
      exit;
    end;
    if Temp[1] = '!' then begin
      Result := GenerateTokenCode(255-Byte(Temp[2]));
      exit;
    end;
    if DecimalSeparator = ',' then
      for X := 1 to Length(Temp) do if Temp[I] = '.' then Temp[I] := ',';
    try D := StrToFloat(Temp);
    except
      ERR_MSG := 'Constanta numerica invalida !';
      ERR_TEXT := Temp;
      Result := ERR_INVALID_NUMBER;
      exit;
    end;
    COD[CS] := INPUSH;
    Move(D,COD[CS+1],SizeOf(Double));
    CS := CS + 1 + SizeOf(Double);
  end;
begin
  TC := 0;
  // Token L()
  repeat
    I := Pos('L(', AText);
    if I = 0 then break;
    for J := I+2 to Length(AText) do
      if AText[J] = ')' then break;
    if (J > Length(AText)) or (AText[J] <> ')') then begin
      ERR_MSG := 'Lipseste ")" din sintaxa L(UN_TEXT) !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    Inc(TC);
    Token[TC] := Copy(AText,I, J-I+1);
    AText[I] := '!';
    AText[I+1] := Char(255-TC);
    Delete(AText,I+2,J-I-1);
  until false;
  // Token LPOS()
  repeat
    I := Pos('LPOS(', AText);
    if I = 0 then break;
    for J := I+5 to Length(AText) do
      if AText[J] = ')' then break;
    if (J > Length(AText)) or (AText[J] <> ')') then begin
      ERR_MSG := 'Lipseste ")" din sintaxa LPOS(UN_TEXT,UN_TEXT) !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    Inc(TC);
    Token[TC] := Copy(AText,I, J-I+1);
    AText[I] := '!';
    AText[I+1] := Char(255-TC);
    Delete(AText,I+2,J-I-1);
  until false;
  // Token LDATA()
  repeat
    I := Pos('LDATA(', AText);
    if I = 0 then break;
    for J := I+5 to Length(AText) do
      if AText[J] = ')' then break;
    if (J > Length(AText)) or (AText[J] <> ')') then begin
      ERR_MSG := 'Lipseste ")" din sintaxa LDATA(UN_TEXT,UN_TEXT) !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    Inc(TC);
    Token[TC] := Copy(AText,I, J-I+1);
    AText[I] := '!';
    AText[I+1] := Char(255-TC);
    Delete(AText,I+2,J-I-1);
  until false;
  // Token ROUND()
  repeat
    I := Pos('ROUND(', AText);
    if I = 0 then break;
    for J := I+2 to Length(AText) do
      if AText[J] = ')' then break;
    if (J > Length(AText)) or (AText[J] <> ')') then begin
      ERR_MSG := 'Lipseste ")" din sintaxa ROUND(UN_NUMAR) !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    Inc(TC);
    Token[TC] := Copy(AText,I, J-I+1);
    AText[I] := '!';
    AText[I+1] := Char(255-TC);
    Delete(AText,I+2,J-I-1);
  until false;
  // Token %_NUME_VAR[]
  I := 1;
  while I <= Length(AText) do begin
    if (AText[I] = '%') and (AText[I+1] = '_') then begin
      for J := I + 2 to Length(AText) do
        if AText[J] = ']' then break;
      if J > Length(AText) then begin
        ERR_MSG := 'Lipseste "]" din sintaxa array !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Inc(TC);
      Token[TC] := Copy(AText,I, J-I+1);
      AText[I] := '!';
      AText[I+1] := Char(255-TC);
      Delete(AText,I+2,J-I-1);
      Inc(I,2);
    end else Inc(I);
  end;
  // Token %%NUME_VAR sau @%NUME_FIELD
  I := 1;
  while I <= Length(AText) do begin
    if AText[I] in ['%', '@'] then begin
      if AText[I+1] <> '%' then begin
        ERR_MSG := 'Lipseste al doilea "%" al variabilei numerice !';
        ERR_TEXT := Copy(AText,I,Length(AText)-I+1);
        Result := ERR_AMPERSAND_EXPECTED;
        exit;
      end;
      for J := I + 2 to Length(AText) do
        if AText[J] in ['+','-','*','/','^',')']
          then break;
      if (I+2 >Length(AText)) or (J > Length(AText)) then J := Length(AText)+1;
      Inc(TC);
      Token[TC] := Copy(AText,I, J-I);
      AText[I] := '!';
      AText[I+1] := Char(255-TC);
      Delete(AText,I+2,J-I-2);
      Inc(I,2);
    end else Inc(I);
  end;
  // Token (expr)
  I := 1; J := -1;
  while I <= Length(AText) do begin
    if AText[I] = '(' then J := I
    else if AText[I] = ')' then begin
      if J = -1 then begin
        ERR_MSG := 'Lipseste "(" !';
        ERR_TEXT := AText;
        Result := ERR_LEFT_PARANTHESE;
        exit;
      end;
      Inc(TC);
      Token[TC] := Copy(AText,J+1, I-J-1);
      AText[J] := '!';
      AText[J+1] := Char(255-TC);
      Delete(AText,J+2,I-J-1);
      I := 0;
      J := -1;
    end;
    Inc(I);
  end;
  Inc(TC);
  Token[TC] := AText;
  Result := GenerateTokenCode(TC);
end;

function VM_COMPILER.Compile(const AOutFileName : string) : Integer;
var
  J,V1,V2 : Integer;
  Name : AnsiString;
  Value : String;
  F : TFileStream;
  S : TStringList;
begin
  Result := ERR_EMPTY_FILE;
  Header.Sign := 'MCOD';
  Header.Versiune1 := 2;
  Header.Versiune2 := 1;
  ERR_MSG := 'Fiesier gol';
  ERR_TEXT := '';
  CS := 0; IP := 0; IWHILE := 0; IIF := 0;
  if Inst.Count = 0 then exit;
  COD[CS] := ICALL;
  Inc(CS);
  SRELOC.Add('START='+IntToStr(CS));
  CS := CS + 4;
  COD[CS] := ISTOP;
  J := 0;
  MOVE(J, COD[CS+1], SizeOf(Integer));
  CS := CS + 5;
  while (IP < Inst.Count) do begin
    J := Encode;
    if J <> 0 then begin
      Result := J;
      exit;
    end;
    Inc(IP)
  end;
  for J := 0 to SReloc.Count - 1 do begin
    Name := SReloc[J];
    V1 := Pos('=', Name);
    Value := Copy(Name,V1+1,Length(Name)-V1);
    SetLength(Name,V1-1);
    V1 := StrToIntDef(Value,0);
    if SAdr.IndexOfName(Name) = -1 then begin
      ERR_MSG := 'Adresa negasita !';
      ERR_TEXT := Name;
      Result := ERR_INVALID_ADR;  exit;
    end;
    Value := SAdr.Values[Name];
    V2 := StrToIntDef(Value,0);
    Move(V2,COD[V1],SizeOf(Integer));
  end;
  Result := ERR_WRITE_COD_FILE;
  ERR_MSG := 'Eroare scriere fisier cod !';
  ERR_TEXT := AOutFileName;
  try    F := TFileStream.Create(AOutFileName, fmCreate);
  except exit;
  end;
  S := TStringList.Create;
  S.Sorted := TRUE;
  for J := 0 to SVAR.Count-1 do
    S.Add(SVAR.Strings[J]+'='+IntToStr(FIRST_VAR-J));
  for J := 0 to NVAR.Count-1 do
    S.Add(NVAR.Strings[J]+'='+IntToStr(FIRST_VAR-J));
  for J := 0 to BVAR.Count-1 do
    S.Add(BVAR.Strings[J]+'='+IntToStr(FIRST_VAR-J));
  Name := '';
  for J := 0 to ISQL-1 do
    Name := Name+SQL_FIELDS.Values['__SQLDEF'+IntToStr(J)]+',';
  if Name <> '' then Name[Length(Name)] := ' ';
  S.Add('SQL_FIELDS='+Name);
  Name := S.Text;
  Header.CodSize := CS;
  Header.VarSize := Length(Name);
  try    if (F.Write(HEADER, SizeOf(Header)) <> SizeOf(Header))
         or (F.Write(COD[0], CS) <> CS)
         or (F.Write(Name[1], Header.VarSize) <> Header.VarSize)
         then begin
           F.Free; exit;
         end;
  except F.Free; exit;
  end;
  F.Free;
  Result := 0;
  ERR_MSG := 'Compilare cu succes !';
  ERR_TEXT := '';
end;

function VM_COMPILER.EncodeText(AText: String): Integer;
var
  I, J, K, L : Integer;
  X, Y : Integer;
  Ch : Char;
begin
  if AText='' then begin
    ERR_MSG := 'Lipsa text (VID) !';
    ERR_TEXT := AText;
    Result := ERR_INVALID_TEXT;
    exit;
  end;
  Result := 0;
  L := 0;
  repeat
    // ANumber = 'AText' [+]
    if AText[1]='''' then begin
      Delete(AText,1,1);
      I := Pos('''', AText);
      if I = 0 then begin
        ERR_MSG := 'Lipseste apostrof de inchidere sir "''" !';
        ERR_TEXT := AText;
        Result := ERR_APOSTROF_EXPECTED;
        exit;
      end;
      COD[CS] := ISPUSH;
      COD[CS+1] := I-1;
      Move(AText[1], COD[CS+2], I-1);
      CS := CS + COD[CS+1]+3;
      COD[CS-1] := 0;
      Delete(AText,1,I);
      if (AText <> '') and (AText[1] <> '+') then begin
        ERR_MSG := 'Lipseste "+" de adunare siruri !';
        ERR_TEXT := AText;
        Result := ERR_PLUS_EXPECTED;
        exit;
      end;
      Delete(AText,1,1);
    // ANumber = @AField [+]
    end else if AText[1] = '@' then begin
      I := Pos('+', AText);
      if I = 0 then I := Length(AText) + 1;
      if (AText[2] in ['1','2','3']) then begin
        COD[CS] := ISFIELDXPUSH;
        COD[CS+1] := Byte(AText[2])-48;
        COD[CS+2] := Byte(AText[3])-Byte('A');
        CS := CS + 3;
      end else begin
        COD[CS] := ISFIELDPUSH;
        COD[CS+1] := GET_FIELD(COPY(AText,2,I-2));
        CS := CS + 2;
      end;
      Delete(AText,1,I-1);
      if (AText <> '') then Delete(AText,1,1);
    // ANumber = %AVar [+]
    end else if AText[1] = '%' then begin
      I := Pos('+', AText);
      if I = 0 then I := Length(AText) + 1;
      COD[CS] := ISPUSHVAR;
      J := GetSVAR(Copy(AText,2,I-2));
      if J = -1 then begin
        ERR_MSG := 'Variabila nu e de tip string !';
        ERR_TEXT := Copy(AText,2,I-2);
        Result := ERR_INVALID_SVAR;
        exit;
      end;
      COD[CS+1] := J;
      CS := CS + 2;
      Delete(AText,1,I-1);
      if (AText <> '') then Delete(AText,1,1);
    // AText = VERIFYIBAN|CNP|CUI(xText)| [+]
    end else if (UpperCase(COPY(AText,1,6)) = 'VERIFY') then begin
      Delete(AText,1,8);
      Ch := AText[1];
      if not(CH in ['A','P','I','F']) then begin
        ERR_MSG := 'Lipseste "IBAN,CUI,CNP" din declararea functiei VERIFY !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      if CH = 'A' then Delete(AText,1,1);
      Delete(AText,1,1);
      if AText[1] <> '(' then begin
        ERR_MSG := 'Lipseste "(" din declararea functiei VERIFY !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Delete(AText,1,1);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei VERIFY !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Result := EncodeText(Trim(Copy(AText,1,I-1)));
      if CH = 'A' then Cod[CS] := ISPUSHVERIFYIBAN;
      if CH = 'P' then Cod[CS] := ISPUSHVERIFYCNP;
      if (CH = 'I') or (Ch = 'F') then Cod[CS] := ISPUSHVERIFYCUI;
      Inc(CS);
      Delete(AText,1,I);
      if AText <> '' then
        if AText[1] <> '+' then begin
          ERR_MSG := 'Lipseste "+" din declaratia string !';
          ERR_TEXT := AText;
          Result := ERR_PLUS_EXPECTED;
          exit;
        end else Delete(AText,1,1);
    // AText = FILEEXISTS(xText)| [+]
    end else if (UpperCase(COPY(AText,1,11)) = 'FILEEXISTS(') then begin
      Delete(AText,1,11);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei FILEEXISTS !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Result := EncodeText(Trim(Copy(AText,1,I-1)));
      Cod[CS] := ISPUSHFILEEXISTS;
      Inc(CS);
      Delete(AText,1,I);
      if AText <> '' then
        if AText[1] <> '+' then begin
          ERR_MSG := 'Lipseste "+" din declaratia string !';
          ERR_TEXT := AText;
          Result := ERR_PLUS_EXPECTED;
          exit;
        end else Delete(AText,1,1);
    // AText = SQLSTRING(xText)| [+]
    end else if (UpperCase(COPY(AText,1,10)) = 'SQLSTRING(') then begin
      Delete(AText,1,10);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei SQLSTRING !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      Result := EncodeText(Trim(Copy(AText,1,I-1)));
      Cod[CS] := ISPUSHSQLSTRING;
      Inc(CS);
      Delete(AText,1,I);
      if AText <> '' then
        if AText[1] <> '+' then begin
          ERR_MSG := 'Lipseste "+" din declaratia string !';
          ERR_TEXT := AText;
          Result := ERR_PLUS_EXPECTED;
          exit;
        end else Delete(AText,1,1);
    // AText = CENTER(xNr,xText)|RIGHT(xNr,xText) [+]
    end else if (UpperCase(COPY(AText,1,6)) = 'RIGHT(') or
      (UpperCase(COPY(AText,1,7)) = 'CENTER(') then begin
      Ch := AText[1];
      if Ch = 'C' then I := 7 else I := 6;
      Delete(AText,1,I);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei RIGHT/CENTER !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      J := Pos(',', AText);
      if (J = 0) or (J > I) then begin
        ERR_MSG := 'Lipseste "," din declararea functiei RIGHT/CENTER !';
        ERR_TEXT := AText;
        Result := ERR_COMMA_EXPECTED;
        exit;
      end;
      K := EncodeNumber(Trim(Copy(AText,1,J-1)));
      if K <> 0 then begin
        Result := K;
        exit;
      end;
      Result := EncodeText(Trim(Copy(AText,J+1,I-J-1)));
      if Ch = 'C' then Cod[CS] := ISPushCenter
      else Cod[CS] := ISPushRight;
      Inc(CS);
      Delete(AText,1,I);
      if AText <> '' then
        if AText[1] <> '+' then begin
          ERR_MSG := 'Lipseste "+" din declaratia string !';
          ERR_TEXT := AText;
          Result := ERR_PLUS_EXPECTED;
          exit;
        end else Delete(AText,1,1);
    // ANumber = STR(xNr,yNr,zNr)|STRP(xNr,yNr,zNr)
    //          |COPY(xNr,yNr,zNr) [+]
    end else if (UpperCase(COPY(AText,1,4)) = 'STR(') or
      (UpperCase(COPY(AText,1,5)) = 'STRP(') or
      (UpperCase(COPY(AText,1,5)) = 'COPY(') then begin
      Ch := AText[4];
      if Ch = '(' then I := 4 else I := 5;
      Delete(AText,1,I);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei STR[P]/COPY !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      J := Pos(',', AText);
      if (J = 0) or (J > I) then begin
        ERR_MSG := 'Lipseste "," din declararea functiei STR[P]/COPY !';
        ERR_TEXT := AText;
        Result := ERR_COMMA_EXPECTED;
        exit;
      end;
      if Ch = 'Y' then begin
        K := EncodeNumber(Trim(Copy(AText,1,J-1)));
        if K <> 0 then begin
          Result := K; exit;
        end;
      end else begin
        X := StrToIntDef(Trim(Copy(AText,1,J-1)),-1);
        if X = -1 then begin
          ERR_MSG := 'Constanta numerica invalida in declararea functiei STR[P]/COPY !';
          ERR_TEXT := AText;
          Result := ERR_INVALID_NUMBER; exit;
        end;
      end;
      Delete(AText,1,J);
      I := I - J;
      J := Pos(',', AText);
      if (J = 0) or (J > I) then begin
        ERR_MSG := 'Lipseste a doua "," din declararea functiei STR[P]/COPY !';
        ERR_TEXT := AText;
        Result := ERR_COMMA_EXPECTED;
        exit;
      end;
      if Ch = 'Y' then begin
        K := EncodeNumber(Trim(Copy(AText,1,J-1)));
        if K <> 0 then begin
          Result := K;
          exit;
        end;
      end else begin
        Y := StrToIntDef(Trim(Copy(AText,1,J-1)),-1);
        if Y = -1 then begin
          ERR_MSG := 'Constanta numerica invalida in declararea functiei STR[P]/COPY !';
          ERR_TEXT := AText;
          Result := ERR_INVALID_NUMBER; exit;
        end;
      end;
      if CH = 'Y' then Result := EncodeText(Trim(Copy(AText,J+1,I-J-1)))
      else Result := EncodeNumber(Trim(Copy(AText,J+1,I-J-1)));
      if CH ='P' then Cod[CS] := ISFORMAT2_XY
      else if CH='Y' then Cod[CS] := ISCOPY_XY
      else Cod[CS] := ISFORMAT1_XY;
      if CH <> 'Y' then begin
        Move(X,COD[CS+1], SizeOf(Integer));
        Move(Y,COD[CS+5], SizeOf(Integer));
        CS := CS + 8;
      end;
      Inc(CS);
      Delete(AText,1,I);
      AText := Trim(AText);
      if (AText <> '') and (AText[1] <> '+') then begin
        ERR_MSG := 'Lipseste "+" din declaratia STRING !';
        ERR_TEXT := AText;
        Result := ERR_PLUS_EXPECTED;
        exit;
      end;
      Delete(AText,1,1);
    // ANumber = CHR(xNr) [+]
    end else if (UpperCase(COPY(AText,1,4)) = 'CHR(') then
    begin
      Delete(AText,1,4);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei CHR !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      COD[CS] := ISPUSH;
      J := StrToIntDef(Copy(AText,1,I-1),-1);
      if J = -1 then begin
        ERR_MSG := 'Constanta numerica invalida in declararea functiei CHR !';
        ERR_TEXT := AText;
        Result := ERR_INVALID_NUMBER;
        exit;
      end;
      COD[CS+1] := 1;
      COD[CS+2] := J;
      COD[CS+3] := 0;
      CS := CS + 4;
      Delete(AText,1,I);
      if (AText <> '') and (AText[1] <> '+') then begin
        ERR_MSG := 'Lipseste "+" din declaratia STRING !';
        ERR_TEXT := AText;
        Result := ERR_PLUS_EXPECTED;
        exit;
      end;
      Delete(AText,1,1);
    // ANumber = IN_LITERE[+]
    end else if (UpperCase(COPY(AText,1,10)) = 'IN_LITERE(') then
    begin
      Delete(AText,1,10);
      I := GetClosedBracket(AText);
      if I = -1 then begin
        ERR_MSG := 'Lipseste ")" din declararea functiei IN_LITERE !';
        ERR_TEXT := AText;
        Result := ERR_RIGHT_PARANTHESE;
        exit;
      end;
      EncodeNumber(Copy(AText,1,I-1));
      COD[CS] := ISPUSHLITERE;
      Inc(CS);
      Delete(AText,1,I);
      AText := TrimLeft(AText);
      if (AText <> '') and (AText[1] <> '+') then begin
        ERR_MSG := 'Lipseste "+" din declaratia STRING !';
        ERR_TEXT := AText;
        Result := ERR_PLUS_EXPECTED;
        exit;
      end;
      Delete(AText,1,1);
    // ANumber = BUFFER|HEADER [+]
    end else if (UpperCase(COPY(AText,1,6)) = 'BUFFER') or
      (UpperCase(COPY(AText,1,6)) = 'HEADER') or
      (UpperCase(COPY(AText,1,4)) = 'TEXT')then
    begin
      if AText[1] = 'H' then Cod[CS] := ISPUSHHEADER
      else if AText[1] = 'B' then Cod[CS] := ISPUSHBUFFER
      else Cod[CS] := ISPUSHTEXT;
      if AText[1] = 'T' then Delete(AText,1,4)
      else Delete(AText,1,6);
      if (AText <> '') and (AText[1] <> '+') then begin
        ERR_MSG := 'Lipseste "+" din declaratia STRING !';
        ERR_TEXT := AText;
        Result := ERR_PLUS_EXPECTED;
        exit;
      end;
      Delete(AText,1,1);
      Inc(CS);
    end else begin
      ERR_MSG := 'Text invalid !';
      ERR_TEXT := AText;
      Result := ERR_INVALID_TEXT;
      exit;
    end;
    Inc(L);
  until AText = '';
  for I := 1 to L - 1 do begin
    COD[CS] := ISPLUS_POP;
    Inc(CS);
  end;
end;

function VM_COMPILER.GetBVar(const AVar: String): Integer;
var
  I : Integer;
begin
  if Copy(AVAR,1,3)='EOF' then begin
    if Length(AVar) = 3 then Result := 1
    else Result := Byte(AVar[4])-47;
    exit;
  end;
  I := BVAR.IndexOf(UpperCase(AVar));
  if I <> -1 then begin
    Result := FIRST_VAR-I;
    exit;
  end;
  if (SVAR.IndexOf(UpperCase(AVar)) <> -1)
  or (NVAR.IndexOf(UpperCase(AVar)) <> -1)
  then begin
    Result := -1;
    exit;
  end;
  BVar.Add(UpperCase(AVar));
  Result := FIRST_VAR - (BVar.Count - 1);
end;

function VM_COMPILER.GetNVar(const AVar: String): Integer;
var
  I : Integer;
begin
  I := NVAR.IndexOf(UpperCase(AVar));
  if I <> -1 then begin
    Result := FIRST_VAR-I;
    exit;
  end;
  if (SVAR.IndexOf(UpperCase(AVar)) <> -1)
  or (BVAR.IndexOf(UpperCase(AVar)) <> -1)
  then begin
    Result := -1;
    exit;
  end;
  NVar.Add(UpperCase(AVar));
  Result := FIRST_VAR - (NVar.Count - 1);
end;

function VM_COMPILER.GetSVar(const AVar: String): Integer;
var
  I : Integer;
begin
  I := SVAR.IndexOf(UpperCase(AVar));
  if I <> -1 then begin
    Result := FIRST_VAR-I;
    exit;
  end;
  if (NVAR.IndexOf(UpperCase(AVar)) <> -1)
  or (BVAR.IndexOf(UpperCase(AVar)) <> -1)
  then begin
    Result := -1;
    exit;
  end;
  SVar.Add(UpperCase(AVar));
  Result := FIRST_VAR - (SVar.Count - 1);
end;

function VM_COMPILER.EncodeConditie(AText: String): Integer;
var
  I, J, Op : Integer;
  Ch : Char;
begin
  if AText = '' then begin
    ERR_MSG := 'Conditie negasita (vida) !';
    ERR_TEXT := AText;
    Result := ERR_INVALID_CONDITIE;
    exit;
  end;
  if AText[1] = '(' then begin
    Delete(AText,1,1);
    I := GetClosedBracket(AText);
    if I = -1 then begin
      ERR_MSG := 'Lipseste ")" din declaratia conditiei !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    J := EncodeConditie(Copy(AText,1,I-1));
    if J <> 0 then begin
      Result := J; exit;
    end;
    Delete(AText,1,I);
  end else if Copy(AText,1,2) = '@@' then begin
    Delete(AText,1,2);
    J := Pos(' ', AText);
    if J = 0 then J := Length(AText)+1;
    Cod[CS] := IBOOLPUSHVAR;
    I := GetBVar(Copy(AText,1,J-1));
    if I = -1 then begin
      ERR_MSG := 'Variabila nu e de tip boolean !';
      ERR_TEXT := Copy(AText,1,J-1);
      Result := ERR_BOOL_VAR_EXPECTED;
      exit;
    end;
    Cod[CS+1] := I;
    CS := CS + 2;
    Delete(AText,1,J);
  end else if UpperCase(Copy(AText,1,4)) = 'NOT(' then begin
    Delete(AText,1,4);
    I := GetClosedBracket(AText);
    if I = -1 then begin
      ERR_MSG := 'Lipsa ")" in declaratia NOT(Conditie) !';
      ERR_TEXT := AText;
      Result := ERR_RIGHT_PARANTHESE;
      exit;
    end;
    J := EncodeConditie(Copy(AText,1,I-1));
    if J <> 0 then begin
      Result := J; exit;
    end;
    Delete(AText,1,I);
    Cod[CS] := IBOOL_NOT;
    Inc(CS);
  end else begin
    J := 0;
    for I := 1 to Length(AText) do
      if AText[I] in ['>','<','#','='] then begin
        J := I; break;
      end;
    if J = 0 then begin
      ERR_MSG := 'Operator >,<,#,=,>=,<= negasit !';
      ERR_TEXT := AText;
      Result := ERR_OPERATOR_EXPECTED;
      exit;
    end;
    if (AText[1] in ['0'..'9']) or (Copy(AText,1,2)='@%') or (Copy(AText,1,2)='%%')
      or (Copy(AText,1,2)='L(') or (Copy(AText,1,2)='%_') then Ch := '0'
    else Ch := '1';
    if Ch = '0' then I := EncodeNumber(Trim(Copy(AText,1,J-1)))
    else I := EncodeText(Trim(Copy(AText,1,J-1)));
    if I <> 0 then begin
      Result := I; exit;
    end;
    Op := 0;
    if (AText[J] = '=') then Op := 1;
    if (AText[J] = '#') then Op := 2;
    if (AText[J] = '<') then Op := 3;
    if (AText[J] = '>') then Op := 4;
    if (Op > 2) and (AText[J+1]='=') then Op := Op + 2;
    if Op > 4 then Inc(J);
    Delete(AText,1,J);
    if Ch = '0' then I := EncodeNumber(Trim(AText))
    else I := EncodeText(Trim(AText));
    if I <> 0 then begin
      Result := I; exit;
    end;
    if Ch = '0' then Cod[CS] := INTEST_OP
    else Cod[CS] := ISTEST_OP;
    Cod[CS+1] := Op;
    CS := CS + 2;
    AText := '';
  end;
  Result := 0;
  if AText = '' then exit;
  AText := Trim(AText);
  if (Uppercase(Copy(AText,1,2)) = 'OR') or ((Uppercase(Copy(AText,1,3)) = 'XOR')
    or (Uppercase(Copy(AText,1,3)) = 'AND')) then begin
    Ch := AText[1];
    if Ch = 'O' then Delete(AText,1,2)
    else Delete(AText,1,3);
    AText := Trim(AText);
    Result := EncodeConditie(AText);
    if Ch = 'O' then Op := 1
    else if Ch = 'A' then Op := 2
    else Op := 3;
    Cod[CS] := IBOOL_OP;
    Cod[CS+1] := Op;
    CS := CS + 2;
  end else begin
    ERR_MSG := 'Operator OR,AND,XOR negasit !';
    ERR_TEXT := AText;
    Result := ERR_BOOL_OP_EXPECTED;
  end;
end;

function VM_COMPILER.GetANVar(const AVar: String;
  const DIM_MAX: Integer): Integer;
var
  I : Integer;
begin
  I := ANVAR.IndexOf(UpperCase(AVar));
  if I <> -1 then begin
    Result := FIRST_VAR-I;
    exit;
  end;
  if DIM_MAX = -1 then Result := -1
  else begin
    Result := FIRST_VAR - ANVar.Count;
    for I := 0 to DIM_MAX do
      ANVar.Add(UpperCase(AVar));
  end;
end;

function VM_COMPILER.GET_FIELD(const AFieldName: String): Integer;
var
  I : Integer;
begin
  I := SQL_FIELDS.IndexOfName(AFieldName);
  if I = -1 then begin
    SQL_FIELDS.Add(AFieldName+'='+IntToSTr(ISQL));
    Result := ISQL;
    SQL_FIELDS.Add('__SQLDEF'+IntToStr(ISQL)+'='+AFieldName);
    Inc(ISQL);
    exit;
  end;
  Result := StrTOIntDef(SQL_FIELDS.VALUES[AFieldName],100)
end;

end.
