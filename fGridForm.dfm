object GridForm: TGridForm
  Left = 0
  Top = 0
  ClientHeight = 346
  ClientWidth = 542
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Arial'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    542
    346)
  PixelsPerInch = 96
  TextHeight = 16
  object LTitlu: mslabelFX
    Left = 0
    Top = 0
    Width = 542
    Height = 48
    Align = alTop
    Alignment = taCenter
    Caption = 'Title'
    ParentFont = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 2171169
    Font.Height = -37
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ExplicitWidth = 79
  end
  object sPanel1: TsPanel
    Left = 0
    Top = 58
    Width = 542
    Height = 36
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    SkinData.SkinSection = 'PANEL'
  end
  object sPanel2: TsPanel
    Left = 0
    Top = 96
    Width = 542
    Height = 250
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    SkinData.SkinSection = 'PANEL'
    object g: TDBGrid
      Left = 1
      Top = 1
      Width = 540
      Height = 248
      Align = alClient
      DataSource = ds
      Options = [dgTitles, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = ANSI_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -13
      TitleFont.Name = 'Arial'
      TitleFont.Style = []
      OnKeyPress = gKeyPress
    end
    object pCauta: TsPanel
      Left = 0
      Top = 208
      Width = 541
      Height = 41
      TabOrder = 1
      Visible = False
      SkinData.SkinSection = 'PANEL'
      object eCauta: TsEdit
        Left = 8
        Top = 8
        Width = 432
        Height = 26
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        SkinData.SkinSection = 'EDIT'
        BoundLabel.Indent = 0
        BoundLabel.Font.Charset = DEFAULT_CHARSET
        BoundLabel.Font.Color = clWindowText
        BoundLabel.Font.Height = -11
        BoundLabel.Font.Name = 'Tahoma'
        BoundLabel.Font.Style = []
        BoundLabel.Layout = sclLeft
        BoundLabel.MaxWidth = 0
        BoundLabel.UseSkinColor = True
      end
      object btCauta: TsButton
        Left = 445
        Top = 8
        Width = 90
        Height = 26
        Caption = 'Cauta'
        TabOrder = 1
        SkinData.SkinSection = 'BUTTON'
      end
    end
  end
  object q: TQuery
    DatabaseName = 'dsListare'
    ParamCheck = False
    SQL.Strings = (
      'SELECT * FROM FUR')
    Left = 8
    Top = 8
  end
  object ds: TDataSource
    DataSet = q
    Left = 40
    Top = 8
  end
end
