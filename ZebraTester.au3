;~ #include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <FONTConstants.au3>
#include <WindowsConstants.au3>
#include <GUIEdit.au3>
#include <WinAPI.au3>
#include <StringConstants.au3>
#include <GUIListBox.au3>
#include "RSZ.au3"
;~ #include "DBug.au3"
#include <SQLite.au3>
#include <SQLite.dll.au3>

Opt("GUIOnEventMode", 1)

; ������ ���������� �������
If WinExists('[CLASS:AutoIt v3;TITLE:' & @ScriptName & ']') Then
    MsgBox(16, @ScriptName, '�������� ��� �����������.')
    Exit
EndIf

Global $sFont = "Arial"
Global Const $RETURN = 0x0D
Global $hQuery, $aRow

_SQLite_Startup()
If @error Then
    MsgBox($MB_SYSTEMMODAL, "SQLite Error", "SQLite3.dll Can't be Loaded")
    Exit -1
EndIf

$hDB = _SQLite_Open('ZebraTester.sqlite')
If @error Then
    MsgBox($MB_SYSTEMMODAL, "SQLite Error", "Can't open database")
    Exit -1
EndIf

HotKeySet("^a", "_SelAll")

; TODO => ���������� ������������ ���� � ������ ��� ��������

Global $hMainGUI = GUICreate("Zebra Tester", 900, 400, 100, 100, $WS_OVERLAPPEDWINDOW)
GUISetFont(9, $FW_DONTCARE, $GUI_FONTNORMAL, "Consolas")
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

; ������� ����
; <= ���� =>
$iFileMenu = GUICtrlCreateMenu("����")
$iFileOpen = GUICtrlCreateMenuItem("�������..", $iFileMenu)
GUICtrlSetOnEvent($iFileOpen, "File_Open")
$iFileSaveAs = GUICtrlCreateMenuItem("��������� ���..", $iFileMenu)
GUICtrlSetOnEvent($iFileSaveAs, "File_Save")
GUICtrlCreateMenuItem("", $iFileMenu)
$iFileExit = GUICtrlCreateMenuItem("�����", $iFileMenu)
GUICtrlSetOnEvent($iFileExit, "CLOSEButton")
; <= ��� =>
$iViewMenu = GUICtrlCreateMenu("���")
$iViewThemeBright = GUICtrlCreateMenuItem("������� ����", $iViewMenu, 0, 1)
$iViewThemeDark = GUICtrlCreateMenuItem("������ ����", $iViewMenu, 1, 1)
GUICtrlSetState($iViewThemeDark, $GUI_CHECKED)
GUICtrlSetOnEvent($iViewThemeBright, "Theme_Change")
GUICtrlSetOnEvent($iViewThemeDark, "Theme_Change")
; <= ������ =>
$iHelpenu = GUICtrlCreateMenu("������")
$iAbout = GUICtrlCreateMenuItem("� ���������..", $iHelpenu)
GUICtrlSetOnEvent($iAbout, "File_About")

; ������ ��������
GUICtrlCreateLabel("ZPL �������:", 740, 20, 100, 15)
$iList = _GUICtrlListBox_Create($hMainGUI, "", 740, 40, 140, 120)
_SQLite_Query($hDB, _
    "SELECT ID || "". "" || Name " & _
    "FROM Templates " & _
    "ORDER BY ID;", $hQuery)
If @error Then
    MsgBox($MB_SYSTEMMODAL, "SQLite error", "Can't execute the query")
    Exit -1
EndIf
While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
    _GUICtrlListBox_AddString($iList, $aRow[0])
WEnd

; ���� "IP �����"
GUICtrlCreateLabel("IP �����:", 740, 160, 100, 15)
GUICtrlSetResizing(-1, 640)
$iIPaddress = GUICtrlCreateInput("192.168.178.23", 740, 180, 140, 20)
GUICtrlSetResizing(-1, 640)

; ���� "����"
$iPortCheckbox = GUICtrlCreateCheckbox("����", 740, 210, 100, 15)
GUICtrlSetResizing(-1, 640)
$iPort = GUICtrlCreateInput("6101", 740, 230, 140, 20)
GUICtrlSetResizing(-1, 640)
GUICtrlSetState($iPort, $GUI_DISABLE)
GUICtrlSetOnEvent($iPortCheckbox, "Port_Edit")

; ������ "��������� �������"
$iPingButton = GUICtrlCreateButton("��������� �������", 740, 265, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iPingButton, "Ping_Node")

; ������ "�������� �������"
$iSendButton = GUICtrlCreateButton("�������� �������", 740, 295, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iSendButton, "Send_Command")

; �������� ������
$iEditField = GUICtrlCreateEdit("", 20, 20, 700, 300)
$iEditField_Handle = GUICtrlGetHandle(-1)

; ������ ���
GUICtrlCreateLabel("������:", 20, 330, 50)
GUICtrlSetFont(-1, 9, $FW_BOLD, "", $sFont)
$iStatusBar = GUICtrlCreateLabel("", 75, 330, 600, 100)
GUICtrlSetFont(-1, 9, $FW_NORMAL, "", $sFont)

_SetGUI_MinSize($hMainGUI, 900, 400)
GUISetState(@SW_SHOW, $hMainGUI)
Theme_Change()
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
;~ GUIRegisterMsg($WM_SIZE, "_WM_SIZE")
$wProcHandle = DllCallbackRegister("_WindowProc", "int", "hwnd;uint;wparam;lparam")
$wProcOld = _WinAPI_SetWindowLong($iList, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))

While 1
	Sleep(100)
WEnd

Func CLOSEButton()
	TCPShutdown()
	_WinAPI_SetWindowLong($iList, $GWL_WNDPROC, $wProcOld)
	DllCallbackFree($wProcHandle)
    _SQLite_Close($hDB)
    _SQLite_Shutdown()
	Exit
EndFunc   ;==>CLOSEButton

Func _SelAll()
	Switch _WinAPI_GetFocus()
		Case $iEditField_Handle
			_GUICtrlEdit_SetSel($iEditField_Handle, 0, -1)
	EndSwitch
EndFunc   ;==>_SelAll

Func _WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
    Local $hWndFrom, $iIDFrom, $iCode, $hWndListBox
    If Not IsHWnd($iList) Then $hWndListBox = GUICtrlGetHandle($iList)
    $hWndFrom = $lParam
    $iIDFrom = BitAND($wParam, 0xFFFF) ; Low Word
    $iCode = BitShift($wParam, 16) ; Hi Word

    Switch $hWndFrom
        Case $iList, $hWndListBox
            Switch $iCode
				Case $LBN_DBLCLK
						Select_Template(_GUICtrlListBox_GetCurSel($iList) + 1)
						Return 0
            EndSwitch
    EndSwitch
EndFunc   ;==>WM_COMMAND

Func _WindowProc($hWnd, $Msg, $wParam, $lParam)
    Switch $hWnd
        Case $iList
            Switch $Msg
                Case $WM_GETDLGCODE
                    Switch $wParam
                        Case $RETURN
                            Select_Template(_GUICtrlListBox_GetCurSel($iList) + 1)
                            Return 0
                    EndSwitch
            EndSwitch
    EndSwitch
    Return _WinAPI_CallWindowProc($wProcOld, $hWnd, $Msg, $wParam, $lParam)
EndFunc

Func File_Open()
	$FileOpen = FileOpenDialog("������� ����", @DesktopDir, "All (*.*)")
	$sLine = FileRead($FileOpen)
	GUICtrlSetData($iEditField, $sLine)
	GUICtrlSetData($iStatusBar, "")
	WinSetTitle($hMainGUI, "", "Zebra Tester - " & $FileOpen)
EndFunc   ;==>File_Open

Func File_Save()
	Local Const $sMessage = "������� ��� �����."
	Local $sFileSave = FileSaveDialog($sMessage, Default, "ZPL Scripts (*.zpl)|Text files (*.txt)", BitOR($FD_PATHMUSTEXIST, $FD_PROMPTOVERWRITE))
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
EndFunc   ;==>File_Save

Func Select_Template($sListItem)
	_SQLite_QuerySingleRow($hDB, _
	    "SELECT Content " & _
		"FROM Templates " & _
		"WHERE ID = " & $sListItem & ";",$aRow)
;~ 		MsgBox(0, 0, $aRow[0])
		GUICtrlSetData($iEditField, $aRow[0])
	WinSetTitle($hMainGUI, "", "Zebra Tester - " & StringTrimLeft(GUICtrlRead($iList), 3))
EndFunc   ;==>Select_Template

Func Ping_Node()
	Local $sError
	If GUICtrlRead($iIPaddress) = "" Then
		GUICtrlSetData($iStatusBar, "�� ����� ����� ����!")
	Else
		Local $sPing = "Ping "
		Do
			GUICtrlSetData($iStatusBar, $sPing)
			Sleep(300)
			$sPing &= ">"
		Until StringLen($sPing) = 10
		Local $iPing = Ping(GUICtrlRead($iIPaddress))
		If $iPing Then
			GUICtrlSetData($iStatusBar, "���� ��������. ����� �������: " & $iPing & "��.")
		Else
			Switch @error
				Case 1
					$sError = "Host is offline"
				Case 2
					$sError = "Host is unreachable"
				Case 3
					$sError = "Bad destination"
				Case 4
					$sError = "Other error"
			EndSwitch
			GUICtrlSetData($iStatusBar, "���� ����������: " & $sError)
		EndIf
	EndIf
EndFunc   ;==>Ping_Node

Func Send_Command()
	Local $lCount
	Local $iSocket
	Local $sError
	Local $sMessage = GUICtrlRead($iEditField)
	If GUICtrlRead($iIPaddress) = "" Then
		GUICtrlSetData($iStatusBar, "�� ����� ����� ����!")
	ElseIf GUICtrlRead($iPort) = "" Then
		GUICtrlSetData($iStatusBar, "�� ����� ����� �����!")
	ElseIf GUICtrlRead($iEditField) = "" Then
		GUICtrlSetData($iStatusBar, "��� ��������� ��� ��������!")
	Else
		TCPStartup()
		Local $sConnectString = "��������� ���������� " ; 21 ������
		Local $sSendString = "���������� �����������. �������� " ; 33 �������
		$lCount = TimerInit()
		Local $iCounter = 0
		Do
			GUICtrlSetData($iStatusBar, $sConnectString)
			$iSocket = TCPConnect(GUICtrlRead($iIPaddress), GUICtrlRead($iPort))
			$sError = @error
			Sleep(200)
			If StringLen($sConnectString) > 23 Then
				$sConnectString = StringTrimRight($sConnectString, 3)
			Else
				$sConnectString &= ">"
			EndIf
		Until $sError = 0 Or TimerDiff($lCount) >= 5000
		If $sError Then
			GUICtrlSetData($iStatusBar, "�� �������� ���������� ����������. ��� ������: " & $sError)
		Else
			$lCount = TimerInit()
			Do
				GUICtrlSetData($iStatusBar, $sSendString)
				TCPSend($iSocket, $sMessage)
				$sError = @error
				Sleep(200)
				If StringLen($sSendString) > 35 Then
					$sSendString = StringTrimRight($sSendString, 3)
				Else
					$sSendString = $sSendString & ">"
				EndIf
			Until $sError = 0 Or TimerDiff($lCount) >= 5000
			If $sError Then
				GUICtrlSetData($iStatusBar, "�� �������� ��������� ���������. ��� ������: " & @error)
			Else
				GUICtrlSetData($iStatusBar, "��������� ����������.")
			EndIf
		EndIf
	EndIf
	TCPCloseSocket($iSocket)
EndFunc   ;==>Send_Command

Func Theme_Change()
	If BitAND(GUICtrlRead($iViewThemeBright), $GUI_CHECKED) Then
		GUICtrlSetBkColor($iEditField, 0xFFFACD)
		GUICtrlSetColor($iEditField, 0x000000)
	Else
		GUICtrlSetBkColor($iEditField, 0x404040)
		GUICtrlSetColor($iEditField, 0xFFD700)
	EndIf
EndFunc   ;==>Theme_Change

Func Port_Edit()
	If BitAND(GUICtrlRead($iPortCheckbox), $GUI_CHECKED) Then
		GUICtrlSetState($iPort, $GUI_ENABLE)
	Else
		GUICtrlSetState($iPort, $GUI_DISABLE)
	EndIf
EndFunc   ;==>Port_Edit

Func File_About()
	MsgBox(64, "Zebra Tester v.0.5", _
			"������� ������������� ��� ������������ ��������� Zebra, ������������ � ��������� ����." & @CRLF & _
			"����� ����������: AutoIt v3." & @CRLF & @CRLF & _
			"�� ���� �������� ������������� ���������� � ��������� �.")
EndFunc   ;==>File_About
