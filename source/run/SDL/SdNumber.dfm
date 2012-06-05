object SdNumberForm: TSdNumberForm
  Left = 481
  Height = 105
  Top = 29
  Width = 257
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Choix d''un nombre'
  ClientHeight = 105
  ClientWidth = 257
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  KeyPreview = True
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  Position = poScreenCenter
  LCLVersion = '1.1'
  object LabelPrompt: TLabel
    Left = 16
    Height = 14
    Top = 24
    Width = 33
    Caption = 'Invite :'
    ParentColor = False
  end
  object ButtonOK: TButton
    Left = 84
    Height = 25
    Top = 64
    Width = 89
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
end
