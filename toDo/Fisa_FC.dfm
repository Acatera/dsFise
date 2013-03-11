object FisaFC: TFisaFC
  Left = 0
  Top = 0
  Caption = 'Fise parteneri'
  ClientHeight = 323
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnKeyPress = FormKeyPress
  DesignSize = (
    300
    323)
  PixelsPerInch = 96
  TextHeight = 16
  object LMoneda: TLabel
    Left = 153
    Top = 155
    Width = 50
    Height = 16
    Caption = 'Moneda:'
  end
  object LPerioada: TLabel
    Left = 10
    Top = 49
    Width = 55
    Height = 16
    Caption = 'Perioada:'
  end
  object Titlu: TLabel
    Left = 0
    Top = 8
    Width = 300
    Height = 25
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Fise parteneri'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitWidth = 282
  end
  object chComponenta: TCheckBox
    Left = 10
    Top = 232
    Width = 185
    Height = 17
    Caption = 'Cu componenta soldului'
    TabOrder = 12
  end
  object chDefalcat: TCheckBox
    Left = 10
    Top = 216
    Width = 219
    Height = 17
    Caption = 'Defalcare incasari/plati pe facturi'
    TabOrder = 11
  end
  object chSold: TCheckBox
    Left = 10
    Top = 248
    Width = 121
    Height = 17
    Caption = 'Doar cei cu sold'
    TabOrder = 13
  end
  object Btn_Corectare: TButton
    Left = 153
    Top = 248
    Width = 137
    Height = 25
    Caption = 'Corectare &achitare'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 14
  end
  object ECont: TLabeledEdit
    Left = 10
    Top = 175
    Width = 106
    Height = 24
    EditLabel.Width = 31
    EditLabel.Height = 16
    EditLabel.Caption = 'Cont:'
    EditLabel.Font.Charset = DEFAULT_CHARSET
    EditLabel.Font.Color = clWindowText
    EditLabel.Font.Height = -13
    EditLabel.Font.Name = 'Tahoma'
    EditLabel.Font.Style = []
    EditLabel.ParentFont = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    Text = 'TOATE'
  end
  object Btn_Conturi: TButton
    Left = 118
    Top = 174
    Width = 26
    Height = 26
    Hint = 'SELECTATI CONT(URILE) PENTRU CARE DORITI BALANTA'
    Caption = '...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
  end
  object EPartener: TLabeledEdit
    Left = 10
    Top = 119
    Width = 252
    Height = 24
    EditLabel.Width = 54
    EditLabel.Height = 16
    EditLabel.Caption = 'Partener:'
    EditLabel.Font.Charset = DEFAULT_CHARSET
    EditLabel.Font.Color = clWindowText
    EditLabel.Font.Height = -13
    EditLabel.Font.Name = 'Tahoma'
    EditLabel.Font.Style = []
    EditLabel.ParentFont = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    Text = 'TOTI'
  end
  object Btn_Partener: TButton
    Left = 264
    Top = 118
    Width = 26
    Height = 26
    Hint = 'SELECTATI CONT(URILE) PENTRU CARE DORITI BALANTA'
    Caption = '...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 7
  end
  object Btn_Executa: TButton
    Left = 10
    Top = 289
    Width = 137
    Height = 25
    Caption = '&Afiseaza'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 15
    OnClick = Btn_ExecutaClick
  end
  object Btn_Renunta: TButton
    Left = 153
    Top = 289
    Width = 137
    Height = 25
    Caption = '&Renunta'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 16
    OnClick = Btn_RenuntaClick
  end
  object Panel2: TPanel
    Left = 0
    Top = 151
    Width = 300
    Height = 2
    BevelEdges = [beTop, beBottom]
    BevelInner = bvRaised
    TabOrder = 17
  end
  object Panel1: TPanel
    Left = 0
    Top = 279
    Width = 300
    Height = 2
    BevelEdges = [beTop, beBottom]
    BevelInner = bvRaised
    TabOrder = 18
  end
  object Panel3: TPanel
    Left = 0
    Top = 206
    Width = 300
    Height = 2
    BevelEdges = [beTop, beBottom]
    BevelInner = bvRaised
    TabOrder = 19
  end
  object cbMoneda: TComboBox
    Left = 153
    Top = 175
    Width = 137
    Height = 24
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 16
    ItemIndex = 0
    ParentFont = False
    TabOrder = 10
    Text = 'LEI'
    Items.Strings = (
      'LEI'
      'VALUTA')
  end
  object EAn1: TEdit
    Left = 82
    Top = 71
    Width = 62
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 2
    Text = '2011'
  end
  object ELuna1: TEdit
    Left = 46
    Top = 71
    Width = 36
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 1
    Text = '1'
  end
  object EZi1: TEdit
    Left = 10
    Top = 71
    Width = 36
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 0
  end
  object EAn2: TEdit
    Left = 225
    Top = 71
    Width = 62
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 5
    Text = '2011'
  end
  object ELuna2: TEdit
    Left = 189
    Top = 71
    Width = 36
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 4
    Text = '3'
  end
  object EZi2: TEdit
    Left = 153
    Top = 71
    Width = 36
    Height = 24
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 3
  end
  object Query: TQuery
    DatabaseName = 'conta'
    Left = 8
    Top = 8
  end
end
