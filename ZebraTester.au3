#include <GUIConstantsEx.au3>
#include <FONTConstants.au3>
#include <WindowsConstants.au3>
#include <GUIEdit.au3>
#include <WinAPI.au3>
#include <StringConstants.au3>

Opt("GUIOnEventMode", 1)

Global $sFont = "Arial"
HotKeySet("^a", "_SelAll")

Global $hMainGUI = GUICreate("Zebra Tester", 900, 400)
GUISetStyle(BitOR($WS_MAXIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU), 0)
GUISetFont(9, $FW_DONTCARE, $GUI_FONTNORMAL, "Consolas")
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

; Главное меню
$iFileMenu = GUICtrlCreateMenu("Файл")
$iFileOpen = GUICtrlCreateMenuItem("Открыть..", $iFileMenu)
GUICtrlSetOnEvent($iFileOpen, "File_Open")
$iFileSaveAs = GUICtrlCreateMenuItem("Сохранить как..", $iFileMenu)
GUICtrlSetOnEvent($iFileSaveAs, "File_Save")
$iViewMenu = GUICtrlCreateMenu("Вид")
$iViewThemeBright = GUICtrlCreateMenuItem("Светлая тема", $iViewMenu, 0, 1)
$iViewThemeDark = GUICtrlCreateMenuItem("Темная тема", $iViewMenu, 1, 1)
GUICtrlSetState($iViewThemeDark, $GUI_CHECKED)
GUICtrlSetOnEvent($iViewThemeBright, "Theme_Change")
GUICtrlSetOnEvent($iViewThemeDark, "Theme_Change")
$iHelpenu = GUICtrlCreateMenu("Помощь")
$iAbout = GUICtrlCreateMenuItem("О программе..", $iHelpenu)
GUICtrlSetOnEvent($iAbout, "File_About")

; Список шаблонов
GUICtrlCreateLabel("ZPL Шаблоны:", 740, 20, 100, 15)
$iListItem = GUICtrlCreateList("", 740, 40, 140, 80)
GUICtrlSetFont(-1, 9, $FW_NORMAL, "", $sFont)
$iListLabel = GUICtrlSetData($iListItem, "1. Тестовая этикетка")
$iListLS = GUICtrlSetData($iListItem, "2. Проверить файлы")
$iListDel = GUICtrlSetData($iListItem, "3. Удалить файлы")
$iListSelectButton = GUICtrlCreateButton("< - Применить", 740, 120, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iListSelectButton, "Select_Template")

; Поле "IP адрес"
GUICtrlCreateLabel("IP адрес:", 740, 160, 100, 15)
GUICtrlSetResizing(-1, 640)
$iIPaddress = GUICtrlCreateInput("192.168.178.23", 740, 180, 140, 20)
GUICtrlSetResizing(-1, 640)

; Поле "Порт"
$iPortCheckbox = GUICtrlCreateCheckbox("Порт", 740, 210, 100, 15)
GUICtrlSetResizing(-1, 640)
$iPort = GUICtrlCreateInput("6101", 740, 230, 140, 20)
GUICtrlSetResizing(-1, 640)
GUICtrlSetState($iPort, $GUI_DISABLE)
GUICtrlSetOnEvent($iPortCheckbox, "Port_Edit")

; Кнопка "Проверить принтер"
$iPingButton = GUICtrlCreateButton("Проверить принтер", 740, 265, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iPingButton, "Ping_Node")

; Кнопка "Передать команду"
$iSendButton = GUICtrlCreateButton("Передать команду", 740, 295, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iSendButton, "Send_Command")

; Редактор текста
$iEditField = GUICtrlCreateEdit("", 20, 20, 700, 300)
$iEditField_Handle = GUICtrlGetHandle(-1)

; Статус бар
GUICtrlCreateLabel("Статус:", 20, 330, 50)
GUICtrlSetFont(-1, 9, $FW_BOLD, "", $sFont)
$iStatusBar = GUICtrlCreateLabel("", 75, 330, 600, 100)
GUICtrlSetFont(-1, 9, $FW_NORMAL, "", $sFont)

GUISetState(@SW_SHOW, $hMainGUI)
Theme_Change()

While 1
	Sleep(100)
WEnd

Func CLOSEButton()
	TCPShutdown()
	Exit
EndFunc   ;==>CLOSEButton

Func _SelAll()
	Switch _WinAPI_GetFocus()
		Case $iEditField_Handle
			_GUICtrlEdit_SetSel($iEditField_Handle, 0, -1)
	EndSwitch
EndFunc   ;==>_SelAll

Func File_Open()
	$FileOpen = FileOpenDialog("Открыть файл", @DesktopDir, "All (*.*)")
	$sLine = FileRead($FileOpen)
	GUICtrlSetData($iEditField, $sLine)
	GUICtrlSetData($iStatusBar, "")
	WinSetTitle($hMainGUI, "", "Zebra Tester - " & $FileOpen)
EndFunc   ;==>File_Open

Func File_Save()
	Local Const $sMessage = "Задайте имя файла."
	Local $sFileSave = FileSaveDialog($sMessage, "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "All (*.*)", BitOR($FD_PATHMUSTEXIST, $FD_PROMPTOVERWRITE))
	If @error Then
		GUICtrlSetData($iStatusBar, "Файл не сохранен.")
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
		GUICtrlSetData($iStatusBar, "Файл сохранен:" & @CRLF & $sFileSave)
		WinSetTitle($hMainGUI, "", "Zebra Tester - " & $sFileSave)
	EndIf
EndFunc   ;==>File_Save

Func Select_Template()
	Switch StringTrimRight(GUICtrlRead($iListItem), StringLen(GUICtrlRead($iListItem)) - 1)
		; Тестовая этикетка
		Case 1
			GUICtrlSetData($iEditField, _
					"^XA" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^FX | Тестовая этикетка Hello World! | ^FS" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^FX" & @CRLF & _
					"^LH50,40" & @CRLF & _
					"^FX Frame ^FS" & @CRLF & _
					"^FO10,10^GB270,95,2^FS" & @CRLF & _
					"^FX Text ^FS" & @CRLF & _
					"^FO20,30^A0I,50,50^FDHello World!^FS" & @CRLF & _
					"^XZ")
			; Проверить файлы
		Case 2
			GUICtrlSetData($iEditField, _
					"^XA" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^FX | Проверка директории FLASH (E:) | ^FS" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^LL200" & @CRLF & _
					"^WDE:X5_*.*" & @CRLF & _
					"^XZ")
			; Удалить файлы
		Case 3
			GUICtrlSetData($iEditField, _
					"^XA" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^FX | Удаление файлов из FLASH (E:)  | ^FS" & @CRLF & _
					"^FX  --------------------------------  ^FS" & @CRLF & _
					"^IDE:X5_*.*^FS" & @CRLF & _
					"^XZ")
	EndSwitch
	WinSetTitle($hMainGUI, "", "Zebra Tester - " & StringTrimLeft(GUICtrlRead($iListItem), 3))
EndFunc   ;==>Select_Template

Func Ping_Node()
	Local $sError
	If GUICtrlRead($iIPaddress) = "" Then
		GUICtrlSetData($iStatusBar, "Не задан адрес узла!")
	Else
		Local $sPing = "Ping "
		Do
			$sPing = $sPing & ">"
			GUICtrlSetData($iStatusBar, $sPing)
			Sleep(300)
		Until StringLen($sPing) = 9
		Local $iPing = Ping(GUICtrlRead($iIPaddress))
		If $iPing Then
			GUICtrlSetData($iStatusBar, "Узел доступен. Время отклика: " & $iPing & "мс.")
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
			GUICtrlSetData($iStatusBar, "Узел недоступен: " & $sError)
		EndIf
	EndIf
EndFunc   ;==>Ping_Node

Func Send_Command()
	Local $lCount
	Local $iSocket
	Local $sError
	Local $sMessage = GUICtrlRead($iEditField)
	If GUICtrlRead($iIPaddress) = "" Then
		GUICtrlSetData($iStatusBar, "Не задан адрес узла!")
	ElseIf GUICtrlRead($iPort) = "" Then
		GUICtrlSetData($iStatusBar, "Не задан адрес порта!")
	ElseIf GUICtrlRead($iEditField) = "" Then
		GUICtrlSetData($iStatusBar, "Нет сообщения для отправки!")
	Else
		TCPStartup()
		Local $sConnectString = "Установка соединения " ; 21 символ
		Local $sSendString = "Соединение установлено. Отправка " ; 33 символа
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
				$sConnectString = $sConnectString & ">"
			EndIf
		Until $sError = 0 Or TimerDiff($lCount) >= 5000
		If $sError Then
			GUICtrlSetData($iStatusBar, "Не возможно установить соединение. Код ошибки: " & $sError)
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
				GUICtrlSetData($iStatusBar, "Не возможно отправить сообщение. Код ошибки: " & @error)
			Else
				GUICtrlSetData($iStatusBar, "Сообщение отправлено.")
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
	MsgBox(64, "Zebra Tester v.0.4", _
			"Утилита предназначена для тестирования принтеров Zebra, подключенных к локальной сети." & @CRLF & _
			"Среда разработки: AutoIt v3." & @CRLF & @CRLF & _
			"По всем вопросам использования обращаться к Бурнышеву Д.")
EndFunc   ;==>File_About
