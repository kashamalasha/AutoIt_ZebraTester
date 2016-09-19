#include<GUIConstants.au3>
#include<GUIConstantsEx.au3>
#include<FONTConstants.au3>
#include<WindowsConstants.au3>
#include<GUIEdit.au3>
#include<WinAPI.au3>
#include<StringConstants.au3>

Opt("GUIOnEventMode", 1)

Local $sFont = "Arial"
HotKeySet("^a", "_SelAll")

Local $hMainGUI = GUICreate("Zebra Tester", 900, 400)
GUISetStyle(BitOR($WS_MAXIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU), 0)
GUISetFont(9, $FW_DONTCARE, $GUI_FONTNORMAL, "Consolas")
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

; ������� ����
$iFileMenu = GUICtrlCreateMenu("����")
$iFileOpen = GUICtrlCreateMenuItem("�������..", $iFileMenu)
GUICtrlSetOnEvent($iFileOpen, "File_Open") ; DONE
GUICtrlCreateMenuItem("", $iFileMenu)
$iFileSaveAs = GUICtrlCreateMenuItem("���������..", $iFileMenu)
GUICtrlSetOnEvent($iFileSaveAs, "File_Save") ; DONE
$iHelpenu = GUICtrlCreateMenu("������")
$iAbout = GUICtrlCreateMenuItem("� ���������..", $iHelpenu)
GUICtrlSetOnEvent($iAbout, "File_About") ; DONE

; ������ ��������
GUICtrlCreateLabel("ZPL �������:", 740, 20, 100)
$iListItem = GUICtrlCreateList("", 740, 40, 140, 80)
GUICtrlSetFont(-1, 9, $FW_NORMAL,"", $sFont)
$iListLabel = GUICtrlSetData($iListItem, "1. �������� ��������")
$iListLS = GUICtrlSetData($iListItem, "2. ��������� �����")
$iListDel = GUICtrlSetData($iListItem, "3. ������� �����")
$iListSelectButton = GUICtrlCreateButton("< - ���������", 740, 120, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iListSelectButton, "Select_Template") ; DONE

; ���� "IP �����"
GUICtrlCreateLabel("IP �����", 740, 150)
GUICtrlSetResizing(-1, 640)
$iIPaddress = GUICtrlCreateInput("127.0.0.1", 740, 170, 140, 20)
GUICtrlSetResizing(-1, 640)

; ���� "����"
GUICtrlCreateLabel("����", 740, 200)
GUICtrlSetResizing(-1, 640)
$iPort = GUICtrlCreateInput("6101", 740, 220, 140, 20)
GUICtrlSetResizing(-1, 640)

; ������ "��������� �������"
$iPingButton = GUICtrlCreateButton("��������� �������", 740, 265, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iPingButton, "Ping_Printer") ; DONE

; ������ "�������� �������"
$iSendButton = GUICtrlCreateButton("�������� �������", 740, 295, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iSendButton, "Send_Command") ; DONE

; �������� ������
$iEditField = GUICtrlCreateEdit("", 20, 20, 700, 300)
$iEditField_Handle = GUICtrlGetHandle(-1)

; ������ ���
GUICtrlCreateLabel("������:", 20, 330, 50)
GUICtrlSetFont(-1, 9, $FW_BOLD,"", $sFont)
$iStatusBar = GUICtrlCreateLabel("", 75, 330, 600, 100)
GUICtrlSetFont(-1, 9, $FW_NORMAL,"", $sFont)

GUISetState(@SW_SHOW, $hMainGUI)

While 1
   Sleep(100)
WEnd

Func CLOSEButton()
   TCPShutdown()
   Exit
EndFunc ;==>CLOSEButton

Func _SelAll()

    Switch _WinAPI_GetFocus()
        Case $iEditField_Handle
            _GUICtrlEdit_SetSel($iEditField_Handle, 0, -1)
    EndSwitch

EndFunc   ;==>_SelAll

Func File_Open()
   $FileOpen = FileOpenDialog("������� ����",@desktopdir,"All (*.*)")
   $sLine = FileRead($FileOpen)
   GUICtrlSetData($iEditField,$sLine)
   GUICtrlSetData($iStatusBar, "")
   WinSetTitle($hMainGUI, "", "Zebra Tester - " & $FileOpen)
EndFunc

Func File_Save()

   Local Const $sMessage = "������� ��� �����."

   Local $sFileSave = FileSaveDialog($sMessage, "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "All (*.*)", $FD_PATHMUSTEXIST)

   If @error Then
       GUICtrlSetData($iStatusBar, "���� �� ��������.")
   Else
       Local $sFileName = StringTrimLeft($sFileSave, StringInStr($sFileSave, "\", $STR_NOCASESENSE, -1))
       Local $iExtension = StringInStr($sFileName, ".", $STR_NOCASESENSE)
       If $iExtension Then
           If Not (StringTrimLeft($sFileName, $iExtension - 1) = ".zpl") Then $sFileSave &= ".zpl"
       Else
           $sFileSave &= ".zpl"
		EndIf
		FileOpen($sFileSave, 2)
		FileWrite($sFileSave, GUICtrlRead($iEditField))
		FileClose($sFileSave)
	   GUICtrlSetData($iStatusBar, "���� ��������:" & @CRLF & $sFileSave)
	   WinSetTitle($hMainGUI, "", "Zebra Tester - " & $sFileSave)
   EndIf
EndFunc

Func File_About()

   MsgBox( 64, "Zebra Tester v.0.1", _
               "������� ������������� ��� ������������ ��������� Zebra, ������������ � ��������� ����." & @CRLF & _
			   "����� ����������: AutoIt v3." & @CRLF & @CRLF & _
			   "�� ���� �������� ������������� ���������� � ��������� �.")

EndFunc

Func Select_Template()

   Select
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 1 ; ==> �������� ��������
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^FX Frame ^FS" & @CRLF & _
	  "^FO10,10^GB380,105,2^FS" & @CRLF & _
	  "^FX Text ^FS" & @CRLF & _
	  "^FO80,45^A0N,50,50^FDHello World!^FS" & @CRLF & _
	  "^XZ")
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 2 ; ==> ��������� �����
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^LL200" & @CRLF & _
	  "^WDE:X5_*.*" & @CRLF & _
	  "^XZ")
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 3 ; ==> ������� �����
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^IDE:X5_*.*^FS" & @CRLF & _
	  "^XZ")
   EndSelect

EndFunc

Func Ping_Printer()

   Local $sError

   If GUICtrlRead($iIPaddress) = "" Then
	  GUICtrlSetData($iStatusBar, "�� ����� ����� ����!")
   Else
	  GUICtrlSetData($iStatusBar, "+")
	  Sleep(1000)
	  GUICtrlSetData($iStatusBar, "+ +")
	  Sleep(1000)
	  GUICtrlSetData($iStatusBar, "+ + +")
	  Sleep(1000)
	  Local $iPing = Ping(GUICtrlRead($iIPaddress), 100)
	  If $iPing Then
		 GUICtrlSetData($iStatusBar, "���� ��������. ����� �������: " & $iPing & "��.")
	  Else
		 Select
		 Case @error = 1
			$sError = "Host is offline"
		 Case @error = 2
			$sError = "Host is unreachable"
		 Case @error = 3
			$sError = "Bad destination"
		 Case @error = 4
			$sError = "Other error"
		 EndSelect
		 GUICtrlSetData($iStatusBar, "���� ����������: " & $sError)
	  EndIf
   EndIf

EndFunc

Func Send_Command()

   If GUICtrlRead($iIPaddress) = "" Then
	  GUICtrlSetData($iStatusBar, "�� ����� ����� ����!")
   ElseIf GUICtrlRead($iPort) = "" Then
	  GUICtrlSetData($iStatusBar, "�� ����� ����� �����!")
   ElseIf GUICtrlRead($iEditField) = "" Then
	  GUICtrlSetData($iStatusBar, "��� ��������� ��� ��������!")
   Else
	  GUICtrlSetData($iStatusBar, "�������� ������� �� �������..")
	  TCPStartup()
	  $iSocket = TCPConnect(GUICtrlRead($iIPAddress), GUICtrlRead($iPort))
	  If @error Then
		 GUICtrlSetData($iStatusBar, "�� �������� ���������� ����������. ��� ������: " & @error)
	  Else
		 GUICtrlSetData($iStatusBar, "���������� �����������. ��������.. ")
		 Sleep(1000)
	  EndIf
	  $sMessage = GUICtrlRead($iEditField)
	  TCPSend($iSocket,$sMessage)
	  If @error Then
		 GUICtrlSetData($iStatusBar, "�� �������� ��������� ���������. ��� ������: " & @error)
	  Else
		 GUICtrlSetData($iStatusBar, "��������� ����������.")
	  EndIf
	  TCPCloseSocket($iSocket)
   EndIf

EndFunc