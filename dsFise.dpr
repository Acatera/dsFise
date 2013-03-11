program dsFise;

uses
  Forms,
  ShellAPI,
  Main in 'Main.pas' {MainForm},
  fMyDate in 'fMyDate.pas',
  fMyDBFLoader in 'fMyDBFLoader.pas',
  fFise in 'fFise.pas',
  fMyPeriod in 'fMyPeriod.pas',
  LASM in 'req\LASM.pas',
  LCOMP in 'req\LCOMP.pas',
  Listare in 'req\Listare.pas' {ListForm},
  fGridForm in 'fGridForm.pas' {GridForm},
  fGUI_FisaCont in 'fGUI_FisaCont.pas' {GUI_FisaCont},
  fGUI_Optiuni in 'fGUI_Optiuni.pas' {GUI_Optiuni},
  fNetwork in 'fNetwork.pas',
  ftxtInput in 'ftxtInput.pas' {txtInput},
  BMAUpdate in '..\_myLib\BMAUpdate.pas' {FBMAUpdate};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFBMAUpdate, FBMAUpdate);
  if MainForm.Options.Values['TERMINATING'] = '' then
    Application.Run
  else if MainForm.Options.Values['TERMINATING'] = 'R' then
    ShellExecute(Application.Handle, 'open', PChar(Application.ExeName), PChar(MainForm.Options.Values['PARAMS']), nil, 1)
end.
