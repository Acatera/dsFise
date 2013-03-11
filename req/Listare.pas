unit Listare;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ShellApi, Buttons, Grids, StForm, sButton,
{$IFDEF BROWSE}
  MyInet, Progress,
{$ENDIF}
  Common, MemoEx, sSkinManager, sComboBox, smslabel;

const
  ColChars = 10;
  Repl0Char = #255;
{$IFDEF BROWSE}
  CHEIE_DSOFT : string = #142#129#189#180#166#165#179#160#183#142#144#189#160#190#179#188+
    #182#142#150#179#166#179#176#179#161#183#242#151#188#181#187#188#183#242+
    #144#160;
{$ENDIF}

type
{$IFDEF BROWSE}
  TMyInternetProgress=class(TMyInternet)
    PForm : TFProgress;
    ATime : TMyTime;
    constructor Create;
    procedure ShowProgress(Sender : TObject);
  public
    destructor Destroy; override;
  end;
{$ENDIF}
  tPageId = class(TObject)
    StartOffs : Integer;
  end;
  TListForm = class(TForm)
    Title: mslabelFX;
    SLabel1: mslabelFX;
    SLabel2: mslabelFX;
    SCulori: mslabelFX;
    SLabel5: mslabelFX;
    LLine: mslabelFX;
    PrintersBox: TsComboBox;
    TipBox: TsComboBox;
    SLabel6: mslabelFX;
    PrintDialog1: TPrintDialog;
    STime: mslabelFX;
    MView: TStringGrid;
    PrinterBtn: TSpeedButton;
    FontBtn: TSpeedButton;
    SExemplu: mslabelFX;
    SLabel4: mslabelFX;
    FontSizeBox: TsComboBox;
    ColorBox: TsComboBox;
    CSpatiu: TsComboBox;
    ExpEditPadBtn: TSpeedButton;
    RefreshBtn: TSpeedButton;
    XView: TMemoEx;
    PrintBtn: TsButton;
    QUITBTN: TsButton;
    RelistBTn: TsButton;
    SearchBtn: TsButton;
    ExcelBtn: TsButton;
    SkinManager: TsSkinManager;
    procedure FormShow(Sender: TObject);
    procedure MViewDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure MViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MViewKeyPress(Sender: TObject; var Key: Char);
    procedure ColorBoxChange(Sender: TObject);
    procedure FontSizeBoxChange(Sender: TObject);
    procedure PrintBtnClick(Sender: TObject);
    procedure TipBoxChange(Sender: TObject);
    procedure PrintersBoxChange(Sender: TObject);
    procedure RelistBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MViewSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure QuitBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure SLabel6DblClick(Sender: TObject);
    procedure SLabel6ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure PrintBtnKeyPress(Sender: TObject; var Key: Char);
    procedure ExcelBtnClick(Sender: TObject);
    procedure PrinterBtnClick(Sender: TObject);
    procedure FontBtnClick(Sender: TObject);
    procedure CSpatiuEnter(Sender: TObject);
    procedure CSpatiuExit(Sender: TObject);
    procedure ExpEditPadBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RefreshBtnClick(Sender: TObject);
    procedure SFontDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FontSizeBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TemaDblClick(Sender: TObject);
  private
    { Private declarations }
    LocalDir : String;
    Lista, ListaFisier, BrowseOpt : TStringList;
    NrPag, HorizOfs, MaxListaWidth : Integer;
    FitHorizontal, LucidaConsole, MyF : Boolean;
    JetFont : TFont;
//    MTipImprimanta : Char;
{$IFDEF BROWSE}
    function ShareWare : Integer;
{$ENDIF}
    function TiparesteJet(IStart, ILength : Integer): Integer;
    function TiparesteMatricial(IStart, ILength : Integer): Integer;
    function GetMaxListaWidth: Integer;
    function JetTextOut(LeftO, PagPos : Integer; AText : PChar) : Integer;
    procedure CountPages;
    function LoadFile : Integer;
  public
    { Public declarations }
    NumeLista, NumeFisier : String;
    FixedCol0 : Integer;
    procedure CleanExit;
    procedure Reload;
    function Start(Optiuni : Integer) : Integer;
    procedure EditBtnClick(Sender: TObject);
  end;

var
  ListForm: TListForm;

const
  LIST_CAN_RELIST = 8;
  LIST_AUTO_PRINT = 16;
  LIST_NO_SHOW_MODAL = 32;
  LIST_PRINT_ONCE = 64;

  A3_MAX_WIDTH = 136;
  A4_MAX_WIDTH = 80;
  FORM_FEED = #12;
  EOL = #13#10;

function IsPrinterMatrix: Boolean;

implementation

uses
{$IFDEF BROWSE}
  ExpExcel, Registry,
{$ENDIF}
  Display, Printers, WinSpool, MyDlg, Constants, CForm;

const
  MColors : Array[0..3,0..6] of TColor = (
// Clasic
  ($300000, clBlack, $000000A8, $00F0FFF0, $00A8A800, $000000A8, clGreen ),
// Norton
  ($FCFC54, clYellow, clWhite, $A80000, $A8A800, $000000A8, clBlack),
// Negru
  (clwhite, clFuchsia, clAqua, clblack, clnavy, clred, clTeal),
// Ocean
  (clBlue, clBlack, clred, clAqua, clInfoBk, clred, clRed)
// text    numere   linii  Fondul  Bara    FormFeed Selectia
  );

{$R *.DFM}

function IsPrinterMatrix: Boolean;
var
  DeviceMode: THandle;
  Device, Driver, Port: array [0..79] of Char;
  pDevice, pDriver, pPort: PChar;
begin

  // Determinate that active printer is a Dot-Marix
  Result:= False;
  pDevice := @Device;
  pDriver := @Driver;
  pPort   := @Port;

  Device  := #0;
  Driver  := #0;
  Port    := #0;
  Result := False;
  try
    Printer.GetPrinter(pDevice, pDriver, pPort, DeviceMode);

    // Printer can be dot-matrix when number of colors is maximum 16
    // and when printer is capable to print only for TRUETYPE
    // fonts as graphics (dot-matrix and PCL printers are capable for that).

    if (GetDeviceCaps(Printer.Handle,NUMCOLORS)<=16) and
       (DeviceCapabilities(pDevice, pPort,DC_TRUETYPE,nil,nil) = DCTT_BITMAP)
    then
      Result := True
  except
    Result := False;
  end;
end;

function TListForm.Start(Optiuni : Integer) : Integer;
var
  I, iFileHandle, iFileLength, iBytesRead : Integer;
  Temp : String;
  J : TFontStyles;
begin
  Tag := Optiuni;
  Result := mrCancel;
  BrowseOpt := TStringList.Create;
  LocalDir := 'C:\WINDOWS\';
  if not MyFileExists(LocalDir+'BROWSE.INI') then begin
    Temp := ParamStr(0);
    LocalDir := ExtractFileDir(Temp);
    LocalDir := LocalDir + '\';
  end;
  if MyFileExists(LocalDir+'BROWSE.INI') then
  try BrowseOpt.LoadFromFile(LocalDir+'BROWSE.INI');
  except
  end;
{$IFDEF BROWSE}
  Randomize;
  if (Random(70)=7) then SFontDblClick(nil);
  if (Random(70)=7) then TemaDblClick(Self)
  else TemaDblClick(nil);
  if ParamCount = 0 then begin
    Tag := 1234;
    FMyDlg.Start('Utilizare :'#13'BROWSE numefisier_lista [numar_coloane_fixe]',M_INFO+M_OK);
    Close; exit;
  end;
  if BrowseOpt.Values['AUTO_PRINT'] = '1'
    then Tag := Tag OR LIST_AUTO_PRINT;
  Firma.Optiuni.Text := BrowseOpt.Text;
{$ENDIF}
  SortList(10, BrowseOpt);
{$IFDEF BROWSE}
  ListForm.NumeLista := ParamStr(1);
  if (ParamCount > 1) and (UpperCase(ParamStr(2)) = 'PRINT') then
    Tag := Tag OR LIST_AUTO_PRINT;
  ListForm.NumeFisier := ListForm.NumeLista;
  if ParamCount >= 2 then ListForm.FixedCol0 := StrToIntDef(ParamStr(2), 0)
  else ListForm.FixedCol0 := 0;
  SkinManager.SkinName := SkinManager.InternalSkins.Items[SCulori.Tag].Name;
{$ENDIF}
  JetFont := nil;
  //EditBtn.OnClick := EditBtnClick;
  Temp := BrowseOpt.Values['JETFONTNAME'];
  if Temp <> '' then begin
    JetFont := TFont.Create;
    JetFont.Name := Temp;
    I := 0;
    I := StrToIntDef(BrowseOpt.Values['JETFONTSTYLE'],0);
    Move(I, J, SizeOf(J));
    JetFont.Style := J;
    SExemplu.Visible := True;
    SExemplu.Font.Assign(JetFont);
  end;
  Lista := TStringList.Create;
  PrintersBox.Items.Clear;
  PrintersBox.Items.AddStrings(Printer.Printers);
  if PrintersBox.Items.Count <> 0 then PrintersBox.ItemIndex := Printer.PrinterIndex
  else PrintersBox.ItemIndex := -1;
  if Firma.Optiuni.Values['SAVE_PRINTER']='DA' then
    Firma.Optiuni.Values['OLDPRINTERBOX'] := IntToStr(Printer.PrinterIndex);
  try
  //  {$IFDEF BROWSE}
      CForm.SetForm(Self, BrowseOpt);
      Temp := Firma.Optiuni.Values['PPRINTERBOX'];
      if Temp <> '' then begin
        I := StrToIntDef(Temp,-2);
        if I = -2 then I := PrintersBox.Items.IndexOf(Temp);
        if I = -1 then I := -2;
        if I <> -2 then PrintersBOX.ItemIndex := I;
      end;
      try
        if Printer.PrinterIndex <> PrintersBox.ItemIndex
          then PrintersBoxChange(Self);
      except
      end;
  //  {$ENDIF}
  {  if BrowseOptINI.Values['TIP_IMPRIMANTA'] = '' then begin
      if PrintersBox.Items.Count <> 0 then begin
        if (Pos('LASER', UpperCase(PrintersBox.Text)) <> 0) or
           (Pos('JET', UpperCase(PrintersBox.Text)) <> 0) then
                MTipImprimanta := 'J'
           else MTipImprimanta := 'M';
      end else MTipImprimanta := 'M';
    end else MTipImprimanta := UpCase(BrowseOptINI.Values['TIP_IMPRIMANTA'][1]);}
    LucidaConsole := FALSE;
    MyF := False;
    for I := 1 to Screen.Fonts.Count do begin
      Temp := UpperCase(Screen.Fonts[I-1]);
      if Pos('LUCIDA CONSOLE', Temp) <> 0 then LucidaConsole := TRUE;
      if Pos('MYF', Temp) <> 0 then MyF := True;
    end;
    RelistBtn.Visible := (Optiuni AND LIST_CAN_RELIST) <> 0;
  {  if MTipImprimanta = 'J' then TipBox.ItemIndex := 0;
    if MTipImprimanta = 'M' then TipBox.ItemIndex := 1;}
    if IsPrinterMatrix then TipBox.ItemIndex := 1 else TipBox.ItemIndex := 0;
    Result := LoadFile;
    if Result <> 0 then begin
      {$IFDEF BROWSE} Close; {$ENDIF}
      exit;
    end;
    if NumeFisier = '' then NumeFisier := NumeLista;
    if NumeFisier <> NumeLista then begin
      ListaFisier := TStringList.Create;
      try
        ListaFisier.LoadFromFile(NumeFisier);
      except
        //FMyDlg.Start('Eroare la incarcarea fisierului : '+NumeFisier + ' !', M_ERROK);
        ShowMessage('Eroare la incarcarea fisierului : '+NumeFisier + ' !');
        {$IFDEF BROWSE}
        Close;
        {$ENDIF}
        exit;
      end;
    end else ListaFisier := Lista;
    CountPages;
    MaxListaWidth := GetMaxListaWidth;
    if NrPag = 2 then RelistBtn.Visible := FALSE;
    MView.Row := 0;
  //  XView.CaretY := 0;
    if ColorBox.ItemIndex = -1 then ColorBox.ItemIndex := 0;
    ColorBoxChange(Self);
    MView.RowCount := Lista.Count + 1;
  //  XView.Lines.Text := Lista.Text;
    if Tag AND DS_SHOW = 0 then ActiveControl := MView;
    if Caption = '' then Caption := 'Listare fisier';
    if Title.Caption = '' then Title.Caption := Caption;
    WindowState := wsMaximized;
    if (FontSizeBox.Tag = 0) or (FontSizeBox.Itemindex = -1) then begin
      I := 0;
      if MaxListaWidth <= A4_MAX_WIDTH then I := I + 2;
      if Screen.Width < 700 then I := I + 0
      else if Screen.Width < 800 then I :=  I + 1
      else if Screen.Width < 1024 then I := I + 2
      else if Screen.Width < 1600 then I := I + 3
      else if Screen.Width < 9100 then I := I + 4;
      FontSizeBox.ItemIndex := I;
      FontSizeBoxChange(Self);
    end;
    if Tag AND LIST_NO_SHOW_MODAL <> 0 then begin
      {$IFDEF BROWSE} Close; {$ENDIF}
      exit;
    end;
    if Tag AND LIST_AUTO_PRINT <> 0 then begin
      PrintBtn.Click;
      Result := mrOk;
    end else begin
  {$IFNDEF BROWSE}
    Result := ShowModal;
  {$ENDIF}
    end;
  finally
    try
      if Firma.Optiuni.Values['SAVE_PRINTER']='DA' then
        Printer.PrinterIndex := StrToInt(Firma.Optiuni.Values['OLDPRINTERBOX']);
    except
    end;
  end;
  {$IFNDEF BROWSE}
    CleanExit;
  {$ENDIF}
end;

procedure TListForm.FormShow(Sender: TObject);
begin
  if Tag = 1234 then exit;
  SendMessage(MView.Handle,WM_HSCROLL,SB_PAGELEFT,0);
  SendMessage(MView.Handle,WM_VSCROLL,SB_TOP,0);
end;

function GetColor(Ch : Char) : Integer;
begin
  case Ch of
  '0'..'9':     Result := 1;
  '-','+','|':  Result := 2;
  else          Result := 0;
  end;
end;

procedure TListForm.MViewKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then begin
   {$IFDEF BROWSE}
     Close;
   {$ENDIF}
    ModalResult := mrCancel
  end else if Key = #13 then SelectNext(MView, True, True)
  else if Key = '+' then begin
    if FontSizeBox.ItemIndex < FontSizeBox.Items.Count - 1 then begin
      FontSizeBox.ItemIndex := FontSizeBox.ItemIndex + 1;
      FontSizeBoxChange(Sender);
    end;
  end else if Key = '-' then begin
    if FontSizeBox.ItemIndex > 0 then begin
      FontSizeBox.ItemIndex := FontSizeBox.ItemIndex - 1;
      FontSizeBoxChange(Sender);
    end;
  end else if UpCase(Key) in ['A'..'Z'] then begin
    FMyDlg.EInput.Text := UpCase(Key);
    SearchBtnClick(MView);
  end else exit;
  Key := #0;
end;


procedure TListForm.MViewDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  S, T : String;
  SI, I, C, FontSize, TopOfs : Integer;
begin
  if (Tag = 1234) or (Lista = nil) then exit;
  with Sender as TStringGrid do
  begin
    FontSize := Canvas.TextWidth('M');
    TopOfs := (MView.DefaultRowHeight - Canvas.TextHeight('M')) DIV 2;
    if (ARow = Row) then begin
      if ((FixedCol0 = 0) or (ACol <> MView.Col)) then
        Canvas.Brush.Color := MColors[ColorBox.ItemIndex][4]
      else Canvas.Brush.Color := MColors[ColorBox.ItemIndex][6];
    end else begin
      if (ARow < Lista.Count) and (Pos(FORM_FEED, Lista[ARow]) <> 0) then
        Canvas.Brush.Color := MColors[ColorBox.ItemIndex][5]
      else begin
        if Odd(ARow) then Canvas.Brush.Color := MColors[ColorBox.ItemIndex][3]
        else Canvas.Brush.Color := Shadow(MColors[ColorBox.ItemIndex][3]);
      end;
    end;
    Canvas.FillRect(Rect);
    if ARow < Lista.Count then
    if Lista[ARow] <> '' then begin
      S := Lista[ARow];
      I := Pos(FORM_FEED, S);
      if I <> 0 then begin
        Delete(S, I, 1);
        Insert('< NEW PAGE >', S, I);
      end;
      if FixedCol0 <> 0 then begin
        if ACol = 0 then begin
          if Length(S) > FixedCol0 then SetLength(S, FixedCol0);
        end else begin
          Delete(S, 1, FixedCol0 + (ACol - 1) * ColChars);
          if Length(S) > ColChars then SetLength(S, ColChars);
        end;
      end;
      if S <> '' then begin
        I := 1; C := GetColor(S[I]);
        T := '';
        repeat
          SI := I - 1;
          while (GetColor(S[I]) = C) and (I <= Length(S)) do begin
            T := T + S[I];
            Inc(I);
          end;
          Canvas.Font.Assign(Font);
          Canvas.Font.Color := MColors[ColorBox.ItemIndex][C];
          if FixedCol0 = 0 then Canvas.TextOut(Rect.Left + SI * FontSize + 2,
            Rect.Top + TopOfs, T)
          else Canvas.TextOut(Rect.Left + SI * FontSize, Rect.Top + TopOfs, T);
          T := '';
          if I > Length(S) then break;
          C := GetColor(S[I]);
        until false;
      end;
    end;
  end;
end;

procedure TListForm.MViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (FixedCol0 = 0) and (not FitHorizontal) then begin
    if Key = VK_END then begin
      if not (SSCtrl in Shift) then begin
        SendMessage(MView.Handle,WM_HSCROLL,SB_PAGERIGHT,0);
        Key := 0;
      end else
        SendMessage(MView.Handle,WM_HSCROLL,SB_PAGELEFT,0);
    end;
    if Key = VK_HOME then begin
      SendMessage(MView.Handle,WM_HSCROLL,SB_PAGELEFT,0);
      if not (SSCtrl in Shift) then Key := 0;
    end;
    if Key = VK_RIGHT then begin
      Key := 0;
      SendMessage(MView.Handle,WM_HSCROLL,SB_LINERIGHT,0);
    end;
    if Key = VK_LEFT then begin
      Key := 0;
      SendMessage(MView.Handle,WM_HSCROLL,SB_LINELEFT,0);
    end;
  end;
  if Key = vk_F7 then SearchBtn.Click
  else if Key = vk_F3 then SearchBtnClick(nil)
  else if Key = vk_F9 then PrintBtn.Click
  else if Key = vk_F8 then RelistBtn.Click
  else exit;
  Key := 0;
end;

procedure TListForm.ColorBoxChange(Sender: TObject);
begin
  MView.Color := MColors[ColorBox.ItemIndex][3];
//  XView.Color := MColors[ColorBox.ItemIndex][3];
  if Tag AND DS_SHOW = 0 then
    ActiveControl := MView;
  if Visible then MView.Repaint;
end;

procedure TListForm.FontSizeBoxChange(Sender: TObject);
var
  I : Integer;
begin
  I := StrToIntDef(FontSizeBox.Items[FontSizeBox.ItemIndex], 7);
  if I = 8 then begin
    if MyF then MView.Font.Name := 'MyF'
    else begin
      if LucidaConsole then MView.Font.Name := 'Lucida Console'
      else MView.Font.Name := 'Courier new';
      MView.Font.Size := I;
    end;
  end else begin
    if LucidaConsole then MView.Font.Name := 'Lucida Console'
    else MView.Font.Name := 'Courier new';
    MView.Font.Size := I;
  end;
//  XView.Font.Name := MView.Font.Name;
//  XView.Font.Size := MView.Font.Size;
  if Assigned(BrowseOpt) and (BrowseOpt.Values['OEM_CHARSET'] = 'DA') then
    MView.Font.Charset := OEM_CHARSET;
  if I = 7 then MView.DefaultRowHeight := 11
  else if I = 8 then MView.DefaultRowHeight := 14
  else MView.DefaultRowHeight := 16;
  MView.Canvas.Font.Assign(MView.Font);
  FitHorizontal := (MView.Canvas.TextWidth(DuplicateChar('M',MaxListaWidth)) <=
    MView.ClientWidth);
  if FixedCol0 = 0 then begin
    if Visible then SendMessage(MView.Handle,WM_HSCROLL,SB_PAGELEFT,0);
    MView.ColCount := 1;
    MView.DefaultColWidth := MView.Canvas.TextWidth(Spaces(MaxListaWidth)) + 4;
    if FitHorizontal then
      MView.DefaultColWidth := MView.ClientWidth;
    MView.FixedCols := 0;
  end else begin
    MView.ColCount := 1 + (MaxListaWidth - FixedCol0+ColChars-1) DIV ColChars;
    MView.DefaultColWidth := MView.Canvas.TextWidth(DuplicateChar('M',ColChars));
    MView.FixedCols := 1;
    MView.ColWidths[0] := MView.Canvas.TextWidth(Spaces(FixedCol0));
  end;
  if Visible then begin
    MView.Repaint;
    MView.SetFocus;
  end;
end;

procedure TListForm.FontSizeBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F2) and (Sender = FontSizeBox) then FontSizeBox.Tag := FontSizeBox.Tag XOR 1
  else if (Key = VK_F2) and (Sender = ColorBox) then ColorBox.Tag := ColorBox.Tag XOR 1
  else begin
    inherited;
    exit;
  end;
  Key := 0;
end;

function TListForm.GetMaxListaWidth: Integer;
var
  AMax, I : Integer;
begin
  AMax := StrToIntDef(BrowseOpt.Values['JET_MIN_WIDTH'],0);
  if AMax = 0 then AMax := A4_MAX_WIDTH;
  for I := 1 to ListaFisier.Count do
    if Length(ListaFisier.Strings[I-1]) > AMax then
      AMax := Length(ListaFisier.Strings[I-1]);
  Result := AMax;
end;

procedure TListForm.PrintBtnClick(Sender: TObject);
var
  I : Integer;
  AStart: Integer;
  ALen: Integer;
  J: Integer;
begin
  if PrintersBox.ItemIndex < 0 then begin
    //FMyDlg.Start('Nu este nici o imprimanta selectata !', M_ERROK);
    ShowMessage('Nu este nici o imprimanta selectata !');
    PrintersBox.SetFocus;
    exit;
  end;
  if TipBox.ItemIndex = 0 then TiparesteJet(0,
                          tPageID(ListaFisier.Objects[NrPag-1]).StartOffs);
  if TipBox.ItemIndex = 1 then
  begin
    if Firma.Optiuni.Values['PAGINI_SEPARATE']='DA' then begin
      for I := 1 to NrPag - 1 do begin
        AStart := tPageID(Lista.Objects[I - 1]).StartOffs;
        ALen := tPageID(Lista.Objects[I]).StartOffs - AStart;
        J := TiparesteMatricial(AStart, ALen);
      end;
      if J = 0 then
        //MyOSD.Start('Tiparirea a fost realizata cu succes !', M_INFOOK);
        ShowMessage('Tiparirea a fost realizata cu succes !');
    end else
    TiparesteMatricial(0, tPageID(ListaFisier.Objects[NrPag-1]).StartOffs);
  end;
  if Tag AND LIST_PRINT_ONCE <> 0 then ModalResult := mrOk;
end;

function TListForm.JetTextOut(LeftO, PagPos : Integer; AText : PChar) : Integer;
var
  N : PChar;
  Ignore : boolean;
begin
  Ignore := FALSE;
  try
    repeat
      N := StrPos(AText, EOL);
      if N <> nil then begin
        N[0] := #0;
        if not Ignore AND (PagPos > Printer.PageHeight) then begin
          {if FMyDlg.Start('Atentie !!! Textul imprimat depaseste lungimea paginii '+
            'setate pe imprimanta dvs.'#13'Continuati ?',M_CONF+M_YES+M_NO)
            <> M_YES then begin}
          ShowMessage('Atentie !!! Textul imprimat depaseste lungimea paginii '+
            'setate pe imprimanta dvs.');
              Printer.Abort;
              Result := -1;
              exit;
            //end;
          Ignore := TRUE;
        end;
        Printer.Canvas.TextOut(LeftO, PagPos, AText);
        PagPos := PagPos + HorizOfs;
        AText := N+2;
      end else begin
        Printer.Canvas.TextOut(LeftO, PagPos, AText);
        break;
      end;
      if AText = '' then break;
    until false;
    Result := 0;
  except
    Result := -1;
  end;
end;

function TListForm.TiparesteJet(IStart, ILength : Integer) : Integer;
var
  LeftOfs, PagPos, I : Integer;
  Buf, PageBuf : PChar;
  Temp : String;
begin
  Result := -1;
  Printer.Canvas.Font.Name := 'Courier New';
  if Assigned(JetFont) then Printer.Canvas.Font.Assign(JetFont);
  if BrowseOpt.Values['OEM_CHARSET'] = 'DA' then
    Printer.Canvas.Font.Charset := OEM_CHARSET;
  I := 16;
  Temp := Spaces(A4_MAX_WIDTH);
  repeat
    Dec(I);
    Printer.Canvas.Font.Size := I;
  until Printer.Canvas.TextWidth(Temp) <= Printer.PageWidth;
  Temp := Spaces(MaxListaWidth);
  I := 64;
  HorizOfs := Printer.Canvas.TextHeight('Ag');
  repeat
    Dec(I);
    Printer.Canvas.Font.Height := -MulDiv(I, Printer.Canvas.Font.PixelsPerInch, 288)
  until Printer.Canvas.TextWidth(Temp) <= Printer.PageWidth;
  if CSpatiu.ItemIndex > 0 then HorizOfs := Printer.Canvas.TextHeight('Ag');
  I := StrToIntDef('HORIZ_OFS', 0);
  if I <> 0 then begin
    HorizOfs := HorizOfs * I DIV 100;
  end else begin
    if CSpatiu.ItemIndex = 2 then HorizOfs := HorizOfs * 5 DIV 4;
    if CSpatiu.ItemIndex = 3 then HorizOfs := HorizOfs * 3 DIV 2;
  end;
  LeftOfs := (Printer.PageWidth - Printer.Canvas.TextWidth(Temp)) DIV 2;
  PagPos := 0;
  Printer.BeginDoc;
  Buf := ListaFisier.GetText;
  Buf := Buf + IStart;
  Dec(ILength);
  Buf[ILength] := #0;
  repeat
    PageBuf := StrPos(Buf, FORM_FEED);
    if PageBuf <> nil then begin
      PageBuf[0] := #0;
      if JetTextOut(LeftOfs, PagPos, Buf) <> 0 then begin
        Printer.Abort;
        FMyDlg.Start('A fost o eroare la imprimare pe imprimanta '+PrintersBox.Text,M_ERROK);
        exit;
      end;
      Printer.NewPage;
      Buf := PageBuf+1;
    end else begin
      if JetTextOut(LeftOfs, PagPos, Buf) <> 0 then begin
        Printer.Abort;
        FMyDlg.Start('A fost o eroare la imprimare pe imprimanta '+PrintersBox.Text,M_ERROK);
        exit;
      end;
      break;
    end;
    if Buf = '' then break;
  until false;
  Printer.EndDoc;
  if (Tag AND LIST_AUTO_PRINT = 0)
    and (Firma.Optiuni.Values['PAGINI_SEPARATE']<>'DA') then
    //FMyDlg.Start('Tiparirea a fost realizata cu succes !', M_INFO+M_OK);
      ShowMessage('Tiparirea a fost realizata cu succes !');
  Result := 0;
end;

function TListForm.TiparesteMatricial(IStart, ILength : Integer) : Integer;
var
  ADevice, ADriver, APort : PCHar;
  ADeviceMode : THandle;
  xHandle : THandle;
  xDocInfo: TDocInfo1;
  PrinterName : String;
  xBytesWritten : DWord;
  Buf, S : PChar;
begin
  xDocInfo.pDocName := PChar(NumeFisier);
  xDocInfo.pOutputFile := nil;
  xDocInfo.pDatatype := 'RAW';
  GetMem(ADevice, 250);
  GetMem(ADriver, 250);
  GetMem(APort, 250);
  Printer.GetPrinter(ADevice, ADriver, APort, ADeviceMode);
  PrinterName := ADevice;
  FreeMem(ADevice);
  FreeMem(ADriver);
  FreeMem(APort);
  Result := -1;
  if NOT OpenPrinter(PChar(PrinterName), xHandle, nil) then
    FMyDlg.Start('Eroare la deschiderea imprimantei : '+PrinterName+' !',
       M_ERROK)
  else begin
    if (StartDocPrinter(xHandle, 1, @xDocInfo) = 0) then
      FMyDlg.Start('Eroare la accesarea imprimantei : '+PrinterName+' !',
        M_ERROK)
    else begin
      Buf := ListaFisier.GetText;
      S := Buf+IStart;
      repeat
        S := StrPos(S, Repl0Char);
        if S <> nil then begin
          S[0] := #0;
          S := S + 1;
        end;
      until S = nil;
      if (NOT WritePrinter(xHandle, @Buf[IStart], ILength, xBytesWritten))
        OR (DWord(ILength) <> xBytesWritten) then
          FMyDlg.Start('Eroare la scrierea la imprimanta '+PrinterName+' !',
            M_ERROK)
      else begin
        if Buf[IStart+ILength - 1] <> FORM_FEED then begin
          PrinterName := FORM_FEED;
          WritePrinter(xHandle, @PrinterName[1], 1, xBytesWritten);
        end;
        Result := 0;
      end;
    end;
    ClosePrinter(xHandle);
  end;
  if (Result = 0) and (Tag AND LIST_AUTO_PRINT = 0) and
     (Firma.Optiuni.Values['PAGINI_SEPARATE']<>'DA')
  then
    //FMyDlg.Start('Tiparirea a fost realizata cu succes !', M_INFO+M_OK);
    ShowMessage('Tiparirea a fost realizata cu succes !');
end;

procedure TListForm.TipBoxChange(Sender: TObject);
begin
{  if TipBox.ItemIndex = 0 then MTipImprimanta := 'J';
  if TipBox.ItemIndex = 1 then MTipImprimanta := 'M';
  BrowseOptINI.Values['TIP_IMPRIMANTA'] := MTipImprimanta;}
  if Visible then MView.SetFocus;
end;

procedure TListForm.PrintersBoxChange(Sender: TObject);
begin
  if PrintersBox.ItemIndex = -1 then exit;
  Printer.PrinterIndex := PrintersBox.ItemIndex;
  if Visible then MView.SetFocus;
  if IsPrinterMatrix then TipBox.ItemIndex := 1 else TipBox.ItemIndex := 0;
end;

procedure TListForm.RefreshBtnClick(Sender: TObject);
begin
  LoadFile;
  MView.Repaint;
end;

procedure TListForm.RelistBtnClick(Sender: TObject);
var
  AStart, ALen : Integer;
begin
  if PrintersBox.ItemIndex < 0 then begin
    FMyDlg.Start('Nu este nici o imprimanta selectata !', M_ERROK);
    PrintersBox.SetFocus;
    exit;
  end;
  PrintDialog1.MaxPage := NrPag - 1;
  PrintDialog1.ToPage := NrPag - 1;
  PrintDialog1.FromPage := 1;
  if PrintDialog1.Execute then begin
    if PrintDialog1.PrintRange = prAllPages then
    begin
      PrintBtn.Click;
      exit;
    end;
    if PrintersBox.ItemIndex < 0 then begin
      FMyDlg.Start('Nu este nici o imprimanta selectata !', M_ERROK);
      PrintersBox.SetFocus;
      exit;
    end;
    if PrintDialog1.PrintRange = prPageNums then
    begin
    AStart := tPageID(Lista.Objects[PrintDialog1.FromPage - 1]).StartOffs;
    ALen := tPageID(Lista.Objects[PrintDialog1.ToPage]).StartOffs - AStart;
    if TipBox.ItemIndex = 0 then TiparesteJet(AStart, ALen);
    if TipBox.ItemIndex = 1 then TiparesteMatricial(AStart, ALen);
    end;
  end;
  if Visible then MView.SetFocus;
end;

procedure TListForm.CountPages;
var
  I : Integer;
  T : tPageID;
  Buf : PChar;
begin
  NrPag := 1;
  Buf := ListaFisier.GetText;
  I := StrLen(Buf);
  if I < 2 then exit;
  if (I >= 3) and (Buf[I - 3] = FORM_FEED) then
    Buf[I-2] := #0;
  T := tPageID.Create;
  T.StartOffs := 0;
  ListaFisier.Objects[0] := T;
  for I := 0 to StrLen(Buf) - 1 do
    if Buf[I] = FORM_FEED then begin
      T := tPageID.Create;
      T.StartOffs := I + 1;
      ListaFisier.Objects[NrPag] := T;
      Inc(NrPag);
    end;
  if Buf[StrLen(Buf) - 1] <> FORM_FEED then begin
      T := tPageID.Create;
      T.StartOffs := StrLen(Buf)+1;
      ListaFisier.Objects[NrPag] := T;
      Inc(NrPag);
  end;
end;

procedure TListForm.FormResize(Sender: TObject);
var
  Step : Integer;
begin
  Step := (QuitBtn.Left-PrintBtn.Left-3 * PrintBtn.Width) DIV 3;
  RelistBtn.Left := PrintBtn.Width + PrintBtn.Left + Step;
  SearchBtn.Left := RelistBtn.Width + RelistBtn.Left + Step;
  FontSizeBoxChange(Self);
end;

procedure TListForm.MViewSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  I : Integer;
begin
  LLine.Caption := IntToStr(ARow+1);
  if FixedCol0 <> 0 then
  for I := 1 to MView.ColCount do begin
    MView.Cells[I-1, ARow] := '';
    MView.Cells[I-1, Mview.Row] := '';
  end;
end;

procedure TListForm.FormActivate(Sender: TObject);
begin
{$IFDEF BROWSE}
  PostMessage(Self.Handle, WM_KEYDOWN, vk_F11, 1);
{$ENDIF}
end;

procedure TListForm.FormCreate(Sender: TObject);
begin
{$IFNDEF BROWSE}
  SkinManager.Free;
{$ENDIF}
end;

procedure TListForm.QuitBtnClick(Sender: TObject);
begin
  BrowseOpt.Values['FONTSIZEBOX.ITEMINDEX']:=IntToStr(FONTSIZEBOX.ITEMINDEX);
  BrowseOpt.Values['FONTSIZEBOX.TAG']:=IntToStr(FONTSIZEBOX.TAG);
  BrowseOpt.Values['COLORBOX.ITEMINDEX']:=IntToStr(COLORBOX.ITEMINDEX);
  BrowseOpt.Values['CSPATIU.ITEMINDEX']:=IntToStr(CSPATIU.ITEMINDEX);
  try BrowseOpt.SaveToFile(LocalDir+'BROWSE.INI');
  except
  end;
{$IFDEF BROWSE}
  Close;
{$ENDIF}
end;

procedure TListForm.CleanExit;
var
  I : Integer;
begin
  if Assigned(Lista) then  
    for I := 0 to NrPag-1 do
      if Assigned(Lista.Objects[I]) then Lista.Objects[I].Free;
  if NumeFisier <> NumeLista then
    if Assigned(ListaFisier) then ListaFisier.Free;
  FontSizeBox.ItemIndex := -1;
  ColorBox.ItemIndex := -1;
  if Assigned(Lista) then Lista.Free;
  NumeFisier := '';
  Caption := '';
  Title.Caption := '';
end;

procedure TListForm.FormDestroy(Sender: TObject);
begin
{$IFDEF BROWSE}
  CleanExit;
{$ENDIF}
end;

procedure TListForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
{$IFDEF BROWSE}
  if Key=VK_F11 then begin
    if Tag <> 0 then exit;
    Tag := 1;
    Start(LIST_CAN_RELIST);
    if Tag AND LIST_AUTO_PRINT <> 0 then Close;
  end;
{$ENDIF}
end;

procedure TListForm.SearchBtnClick(Sender: TObject);
var
  Search : String;
  I : Integer;
begin
  if Sender <> nil then
    FMyDlg.Title.Caption := 'Cautare text';
  FMyDlg.EInput.AutoSelect := Sender <> MView;
  if (Sender = nil) or (FMyDlg.Start('Introduceti textul care doriti sa-l cautati',M_GETTEXT+M_CONF+M_OK+M_CANCEL) = m_OK)
  then begin
    FMyDlg.EInput.AutoSelect := TRUE;
    Search := UpperCase(FMyDlg.EInput.Text);
    if Search = '' then exit;
    for I := MView.Row+1 to Lista.Count - 1 do
      if Pos(Search, UpperCase(Lista[I])) <> 0 then begin
        MView.Row := I;
        if I > 10 then MView.TopRow := I - 10
        else MView.TopRow := 0;
        MView.Repaint;
        exit;
      end;
    FMyDlg.Start('Textul "'+Search+'" nu a fost gasit !', M_INFOOK);
  end else FMyDlg.EInput.AutoSelect := TRUE;
  if Visible then MView.SetFocus;
end;

procedure TListForm.SLabel6DblClick(Sender: TObject);
var
  S : String;
begin
  S := 'Nume fisier : "'+NumeFisier+'"';
  if NumeFisier <> NumeLista then S := S + #13+'Nume lista (ecran) : "'+NumeLista+'"';
  FMyDlg.Start(S,M_INFOOK);
end;

procedure TListForm.SFontDblClick(Sender: TObject);
{$IFDEF BROWSE}
var
  S : TStringList;
  INet : TMyInternetProgress;
  Temp : AnsiString;
  ATimeStamp, wwwRequired, NewName : String;
  F : TFileStream;
{$ENDIF}
begin
{$IFDEF BROWSE}
  S := TStringList.Create;
  INet := TMyInternetProgress.Create;
  try
    try
      S.LoadFromFile(Firma.ExeDIR+'UPDATES.TXT');
    except
    end;
    if not INet.Connect then begin
      FMyDlg.Start('Eroare la conectarea la internet !',M_ERROK); exit;
    end;
    wwwRequired := Firma.Optiuni.Values['LIVE_EXE'];
    if wwwRequired = '' then wwwRequired := 'www.dsoft.ro/download/browse.exe';
    ATimeStamp := INet.GetURLDATE(wwwRequired);
    if ATimeStamp = '' then begin
      FMyDlg.Start('Eroare la conectarea la '+wwwRequired+' !',M_ERROK); exit;
    end;
    if S.IndexOf('EXE_BROWSE='+ATimeStamp) = -1 then begin
      if (FMyDlg.Start('O noua versiune de program este disponibila pe internet'+
          #13'Actualizati ?',M_CONF+M_YES+M_NO) <> M_YES) then begin
        exit;
      end;
      Temp := INet.ReadURL(wwwRequired);
      NewName := Firma.ExeDIR+'BROWSE_'+GetSDataStr(Ziua,Luna,Anul)+GetTimp6+'.EXE';
      if not RenameFile(ParamStr(0),NewName) then begin
        FMyDlg.Start('Eroare la renumirea fisierului '+ParamStr(0)+
          '->'+NewName,M_ERROK);
        exit;
      end;
      try
        F := TFileStream.Create(ParamStr(0),fmCreate);
      except
        FMyDlg.Start('Eroare la crearea fisierului '+ParamStr(0),M_ERROK);
        exit;
      end;
      try
        F.Write(Temp[1], Length(Temp))
      finally
        F.Free;
      end;
      S.Add('EXE_BROWSE='+ATimeStamp);
      S.SaveToFile(Firma.ExeDIR+'UPDATES.TXT');
      FMyDlg.Start('Actualizare cu succes !',M_INFOOK);
      exit;
    end else begin
      FreeAndNil(Inet);
      if Sender <> nil then
        FMyDlg.Start('Aveti ultima versiune instalata !',M_INFOOK);
    end;
  finally
    if Assigned(INet) then INet.Free;
    S.Free;
  end;
{$ENDIF}
end;

procedure TListForm.TemaDblClick(Sender: TObject);
begin
  if Sender <> nil then begin
    SCulori.Tag := SCulori.Tag + 1;
    if SCulori.Tag >= SkinManager.InternalSkins.Count  then
      SCulori.Tag := 0;
  end;
  SkinManager.SkinName := SkinManager.InternalSkins.Items[SCulori.Tag].Name;
end;

procedure TListForm.SLabel6ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
   {$IFDEF BROWSE}
     Exit;
   {$ENDIF}
  NumeLista := NumeFisier;
  CleanExit;
  Start(LIST_NO_SHOW_MODAL);
end;

procedure TListForm.PrintBtnKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then begin
   {$IFDEF BROWSE}
     Close;
   {$ENDIF}
    ModalResult := mrCancel
  end;
end;

function TListForm.LoadFile : Integer;
var
  I, iFileHandle, iFileLength, iBytesRead : Integer;
  Temp : String;
begin
  try
    Lista.LoadFromFile(NumeLista);
  except
    FMyDlg.Start('Eroare la incarcarea fisierului : '+NumeLista+' !', M_ERROK);
    Result := mrCancel;
    exit;
  end;
  iFileHandle := FileOpen(NumeLista, fmOpenRead+fmShareCompat);
  if iFileHandle <> -1 then begin
    iFileLength := FileSeek(iFileHandle,0,2);
    if (iFileLength > Length(Lista.Text) + 10) then begin
      FileSeek(iFileHandle,0,0);
      SetLength(Temp, iFileLength + 1);
      iBytesRead := FileRead(iFileHandle, Temp[1], iFileLength);
      SetLength(Temp, iBytesRead);
      repeat
        iBytesRead := Pos(#0, Temp);
        if IBytesRead <> 0 then Temp[iBytesRead] := Repl0Char;
      until iBytesRead = 0;
      Lista.Text := Temp;
    end;
    FileClose(iFileHandle);
  end;
  if (Lista.Count > 0) then begin
    Temp := Lista.Strings[Lista.Count - 1];
    if (Temp <> '') AND (Temp[Length(Temp)] = #26) then
      SetLength(Temp,Length(Temp)-1);
    Lista.Strings[Lista.Count - 1] := Temp;
  end;
  if Lista.Count = 0 then begin
    FMyDlg.Start('Lista <'+NumeLista+'> este goal� !',M_ERROK);
    Result := -1
  end else Result := 0;
  if Lista.Count = 0 then Lista.Add(' ');
  if Lista.Count = 1 then Lista.Add(' ');
  {$IFDEF BROWSE}
  ExcelBtn.Visible := IdentifyExcelLista(Lista) > 0;
  {$ENDIF}
end;

procedure TListForm.Reload;
begin
  LoadFile;
  CountPages;
  MaxListaWidth := GetMaxListaWidth;
  MView.Row := 0;
  MView.RowCount := Lista.Count + 1;
end;

procedure TListForm.ExcelBtnClick(Sender: TObject);
{$IFDEF BROWSE}
var
  Temp : string;
  MyReg : TRegistry;
  Drivers : TStringList;
  I : Integer;
  Anul, Luna, Ziua : Word;
{$ENDIF}
begin
{$IFDEF BROWSE}
  MyReg := TRegistry.Create;
  MyReg.RootKey := HKEY_LOCAL_MACHINE;
  Temp := CHEIE_DSOFT;
  for I := 1 to Length(Temp) do
    Temp[I] := Char(Byte(Temp[I]) XOR 210);
  I := 0;
  if MyReg.OpenKey(Temp, False) then begin
    Drivers := TStringList.Create;
    MyReg.GetValueNames(Drivers);
    DecodeDate(Now,Anul, Luna, Ziua);
    if Drivers.IndexOf(IntToStr(Anul)+IntToStr(Luna)) <> -1 then I := 2;
  end;
  MyReg.CloseKey;
  MyReg.Free;
  if I = 0 then if ShareWare <> 0 then exit;
  ExportExcel(Lista);
{$ENDIF}
end;

{$IFDEF BROWSE}
function TListForm.ShareWare : Integer;
var
  I, J, K : Integer;
  Ch : Char;
  Temp, Temp2 : String;
  MyReg : TRegistry;
  NrLuni, Anul, Luna, Ziua : Word;
begin
  Result := -1;
  if FMyDlg.Start('Aceasta este o versiune demonstrativa de export excel'#13+
  'Pentru evitarea acestor mesaje, contactati telefonic firma D-Soft 0256-463942',
    M_INFO+M_OK) <> M_OK then exit;

  Randomize;
  Ch := Char(64+Random(26));
  I := Random(1000);
  if FMyDlg.Start('Aceasta este o versiune demonstrativa de export excel'#13+
  'Pentru continuare scrieti codul ['+Ch+'] de activare sau numarul '+'['+IntToStr(I)+']',
    M_INFO+M_OK+M_CANCEL+M_GETTEXT) <> M_OK then exit;
  Temp := FMyDlg.EInput.Text;
  if (Temp <> '') and (Temp[1] in ['A'..'Z']) then begin
     J := I * 26 + Byte(Ch);
     RandSeed := J;
     Temp2 := Ch + IntToStr(Random(9000));
     if Copy(Temp,1,Length(Temp2)) = Temp2 then begin
       Delete(Temp,1,Length(Temp2));
       if Odd(Length(Temp)) then begin
         FMyDlg.Start('Cod invalid [E]!',M_ERROK);
         exit;
       end;
       for K := Length(Temp) downto 1 do
       begin
         if Odd(K) then begin
           RandSeed := RandSeed + Byte(Temp[K])*100;
           if Temp[K+1] = Chr(48+Random(10)) then Delete(Temp,K+1,1)
           else begin
             FMyDlg.Start('Cod invalid [C]!',M_ERROK);
             exit;
           end;
         end;
       end;
       NrLuni := StrToIntDef(Temp,0);
       Temp := CHEIE_DSOFT;
       for I := 1 to Length(Temp) do
         Temp[I] := Char(Byte(Temp[I]) XOR 210);
       I := 0;
       MyReg := TRegistry.Create;
       MyReg.RootKey := HKEY_LOCAL_MACHINE;
       if MyReg.OpenKey(Temp, True) then begin
         DecodeDate(Now,Anul, Luna, Ziua);
         for K := 1 to NrLuni do begin
           MyReg.WriteString(IntToStr(Anul)+IntToStr(Luna),'');
           Inc(Luna);
           if Luna = 13 then begin
             Luna := 1; Inc(Anul);
           end;
         end;
         FMyDlg.Start('S-a activat produsul pentru '+IntToStr(NrLuni)+' luni de zile'#13+
           'Multumim',M_INFO+M_OK);
       end;
       MyReg.CloseKey;
       MyReg.Free;
       Result := 0;
       exit;
     end else FMyDlg.Start('Cod invalid [A]',M_ERROK);
  end;
  if FMyDlg.EInput.Text <> IntToStr(I) then exit;

  if FMyDlg.Start('Aceasta este o versiune demonstrativa de export excel'#13+
  'Nu functioneaza decat cu Microsoft Excel. Trebuie sa asteptati 75 sec.',
    M_INFO+M_OK+M_CANCEL) <> M_OK then exit;

  Sleep(75000);
  if FMyDlg.Start('Aceasta este o versiune demonstrativa de export excel'#13+
  'Va multumim pt. asteptare. Apasati OK si transferul in Excel va incepe',
    M_INFO+M_OK) <> M_OK then exit;
  Result := 0;
end;
{$ENDIF}

procedure TListForm.PrinterBtnClick(Sender: TObject);
var
  PrinterSetupDialog1: TPrinterSetupDialog;
begin
  if PrintersBox.ItemIndex < 0 then begin
    FMyDlg.Start('Nu este nici o imprimanta selectata !', M_ERROK);
    PrintersBox.SetFocus;
    exit;
  end;
  PrinterSetupDialog1:= TPrinterSetupDialog.Create(Self);
  PrinterSetupDialog1.Execute;
  PrinterSetupDialog1.Free;
end;

procedure TListForm.FontBtnClick(Sender: TObject);
var
  FontDialog1: TFontDialog;
  I : Integer;
  J : TFontStyles;
begin
  FontDialog1:= TFontDialog.Create(Self);
  if Assigned(JetFont) then FontDialog1.Font.Assign(JetFont);
  if FontDialog1.Execute then begin
    if not Assigned(JetFont) then JetFont := TFont.Create;
    JetFont.Assign(FontDialog1.Font);
    SExemplu.Visible := True;
    SExemplu.Font.Assign(JetFont);
    if (FMyDlg.Start('Doriti aceste setari permanente ?',M_GETTEXT+M_CONF+M_YES+M_NO) = M_YES)
      and (FMyDlg.EInput.Text = 'DA')
    then begin
      BrowseOpt.Values['JETFONTNAME']:=JetFont.Name;
      J := JetFont.Style;
      I := 0;
      Move(J, I, SizeOf(J));
      BrowseOpt.Values['JETFONTSTYLE']:=IntToStr(I);
      try BrowseOpt.SaveToFile(LocalDir+'BROWSE.INI');
      except
      end;
    end;
  end;
  FontDialog1.Free;
end;

procedure TListForm.EditBtnClick(Sender: TObject);
begin
  EditFile('C:\WINDOWS\BROWSE.INI');
  EditFile(LocalDir+'BROWSE.INI');
  inherited;
end;

procedure TListForm.CSpatiuEnter(Sender: TObject);
begin
  CSpatiu.Width := 147;
end;

procedure TListForm.CSpatiuExit(Sender: TObject);
begin
  CSpatiu.Width := 55;
end;

procedure TListForm.ExpEditPadBtnClick(Sender: TObject);
var
  ProgName, ProgParam : String;
begin
  ProgName := BrowseOpt.Values['NOTEPAD'];
  if ProgName = '' then ProgName := 'NOTEPAD.EXE';
  ProgParam := NumeFisier;
  ShellExecute(Application.Handle, 'open',
     PChar(ProgName),
     PChar(ProgParam),
     nil, SW_SHOW);
end;

{$IFDEF BROWSE}
{ TMyInternetProgress }

constructor TMyInternetProgress.Create;
begin
  inherited;
  ATime := TMyTime.Create;
  Application.CreateForm(TFProgress, PForm);
  PForm.gFile.Visible := FALSE;
  PForm.lbFile.Top := PForm.lbFile.Top - 5;
  PForm.Height := PForm.Height - 30;
  PForm.Show;
  Application.ProcessMessages;
  PForm.Repaint;
  Application.ProcessMessages;
  OnProgress := ShowProgress;
end;

destructor TMyInternetProgress.Destroy;
begin
  if Assigned(PForm) then PForm.Free;
  ATime.Free;
  inherited;
end;

procedure TMyInternetProgress.ShowProgress(Sender: TObject);
var
  TotalMB, DownloadMB : double;
  Speed : Integer;
begin
  Application.ProcessMessages;
  PForm.Title.Caption := 'Descarca ' + CurrentURL;
  PForm.gOverall.MaxValue := TotalLen;
  PForm.gOverall.Progress := Progress;
  Cancel := PForm.bCancel;
  TotalMB := (TotalLen DIV 100000) / 10;
  try
    Speed := Progress DIV ATime.GetTime;
  except
    Speed := 0;
  end;
  DownloadMB := (Progress DIV 100000) / 10;
  PForm.lbFile.Caption := FormatFloat('0.0',DownloadMB)+
    ' of ' + FormatFloat('0.0',TotalMB) + ' MB at '+IntToStr(Speed) + ' KB/sec;';
  PForm.Repaint;
  Application.ProcessMessages;
end;
{$ENDIF}

end.
