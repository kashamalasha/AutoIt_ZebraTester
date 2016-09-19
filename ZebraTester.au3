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

; Главное меню
$iFileMenu = GUICtrlCreateMenu("Файл")
$iFileOpen = GUICtrlCreateMenuItem("Открыть..", $iFileMenu)
GUICtrlSetOnEvent($iFileOpen, "File_Open")
GUICtrlCreateMenuItem("", $iFileMenu)
$iFileSaveAs = GUICtrlCreateMenuItem("Сохранить..", $iFileMenu)
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
GUICtrlCreateLabel("ZPL Шаблоны:", 740, 20, 100)
$iListItem = GUICtrlCreateList("", 740, 40, 140, 80)
GUICtrlSetFont(-1, 9, $FW_NORMAL,"", $sFont)
$iListLabel = GUICtrlSetData($iListItem, "1. Тестовая этикетка")
$iListLS = GUICtrlSetData($iListItem, "2. Проверить файлы")
$iListDel = GUICtrlSetData($iListItem, "3. Удалить файлы")
$iListSelectButton = GUICtrlCreateButton("< - Применить", 740, 120, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iListSelectButton, "Select_Template")

; Поле "IP адрес"
GUICtrlCreateLabel("IP адрес:", 740, 160)
GUICtrlSetResizing(-1, 640)
$iIPaddress = GUICtrlCreateInput("127.0.0.1", 740, 180, 140, 20)
GUICtrlSetResizing(-1, 640)

; Поле "Порт"
GUICtrlCreateLabel("Порт", 740, 210)
GUICtrlSetResizing(-1, 640)
$iPort = GUICtrlCreateInput("6101", 740, 230, 140, 20)
GUICtrlSetResizing(-1, 640)

; Кнопка "Проверить принтер"
$iPingButton = GUICtrlCreateButton("Проверить принтер", 740, 265, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iPingButton, "Ping_Printer")

; Кнопка "Передать команду"
$iSendButton = GUICtrlCreateButton("Передать команду", 740, 295, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($iSendButton, "Send_Command")

; Редактор текста
$iEditField = GUICtrlCreateEdit("", 20, 20, 700, 300)
$iEditField_Handle = GUICtrlGetHandle(-1)

; Статус бар
GUICtrlCreateLabel("Статус:", 20, 330, 50)
GUICtrlSetFont(-1, 9, $FW_BOLD,"", $sFont)
$iStatusBar = GUICtrlCreateLabel("", 75, 330, 600, 100)
GUICtrlSetFont(-1, 9, $FW_NORMAL,"", $sFont)

GUISetState(@SW_SHOW, $hMainGUI)
Theme_Change()

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
   $FileOpen = FileOpenDialog("Открыть файл",@desktopdir,"All (*.*)")
   $sLine = FileRead($FileOpen)
   GUICtrlSetData($iEditField,$sLine)
   GUICtrlSetData($iStatusBar, "")
   WinSetTitle($hMainGUI, "", "Zebra Tester - " & $FileOpen)
EndFunc

Func File_Save()
   Local Const $sMessage = "Задайте имя файла."
   Local $sFileSave = FileSaveDialog($sMessage, "::{450D8FBA-AD25-11D0-98A8-0800361B1103}", "All (*.*)", $FD_PATHMUSTEXIST)
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
		; TODO ==> Реализовать проверку FileExists($sFileSave)
		FileOpen($sFileSave, 2)
		FileWrite($sFileSave, GUICtrlRead($iEditField))
		FileClose($sFileSave)
	   GUICtrlSetData($iStatusBar, "Файл сохранен:" & @CRLF & $sFileSave)
	   WinSetTitle($hMainGUI, "", "Zebra Tester - " & $sFileSave)
   EndIf
EndFunc

Func Select_Template()
   Select
   ; Тестовая этикетка
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 1
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^FX Frame ^FS" & @CRLF & _
	  "^FO10,10^GB380,105,2^FS" & @CRLF & _
	  "^FX Text ^FS" & @CRLF & _
	  "^FO80,45^A0N,50,50^FDHello World!^FS" & @CRLF & _
	  "^XZ")
   ; Проверить файлы
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 2
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^LL200" & @CRLF & _
	  "^WDE:X5_*.*" & @CRLF & _
	  "^XZ")
   ; Удалить файлы
   Case StringTrimRight(GUICtrlRead($iListItem),StringLen(GUICtrlRead($iListItem))-1) = 3
	  GUICtrlSetData($iEditField, _
	  "^XA" & @CRLF & _
	  "^IDE:X5_*.*^FS" & @CRLF & _
	  "^XZ")
   EndSelect
   WinSetTitle($hMainGUI, "", "Zebra Tester - " & StringTrimLeft(GUICtrlRead($iListItem), 3))
EndFunc

Func Ping_Printer()
   Local $sError
   If GUICtrlRead($iIPaddress) = "" Then
	  GUICtrlSetData($iStatusBar, "Не задан адрес узла!")
   Else
	  GUICtrlSetData($iStatusBar, "+")
	  Sleep(1000)
	  GUICtrlSetData($iStatusBar, "+ +")
	  Sleep(1000)
	  GUICtrlSetData($iStatusBar, "+ + +")
	  Sleep(1000)
	  Local $iPing = Ping(GUICtrlRead($iIPaddress), 100)
	  If $iPing Then
		 GUICtrlSetData($iStatusBar, "Узел доступен. Время отклика: " & $iPing & "мс.")
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
		 GUICtrlSetData($iStatusBar, "Узел недоступен: " & $sError)
	  EndIf
   EndIf
EndFunc

Func Send_Command()
   If GUICtrlRead($iIPaddress) = "" Then
	  GUICtrlSetData($iStatusBar, "Не задан адрес узла!")
   ElseIf GUICtrlRead($iPort) = "" Then
	  GUICtrlSetData($iStatusBar, "Не задан адрес порта!")
   ElseIf GUICtrlRead($iEditField) = "" Then
	  GUICtrlSetData($iStatusBar, "Нет сообщения для отправки!")
   Else
	  GUICtrlSetData($iStatusBar, "Отправка команды на принтер..")
	  TCPStartup()
	  $iSocket = TCPConnect(GUICtrlRead($iIPAddress), GUICtrlRead($iPort))
	  If @error Then
		 GUICtrlSetData($iStatusBar, "Не возможно установить соединение. Код ошибки: " & @error)
	  Else
		 GUICtrlSetData($iStatusBar, "Соединение установлено. Отправка.. ")
		 Sleep(1000)
	  EndIf
	  $sMessage = GUICtrlRead($iEditField)
	  TCPSend($iSocket,$sMessage)
	  If @error Then
		 GUICtrlSetData($iStatusBar, "Не возможно отправить сообщение. Код ошибки: " & @error)
	  Else
		 GUICtrlSetData($iStatusBar, "Сообщение отправлено.")
	  EndIf
	  TCPCloseSocket($iSocket)
   EndIf
EndFunc

Func Theme_Change()
   Select
   Case BitAnd(GUICtrlRead($iViewThemeDark), $GUI_CHECKED)
	  GUICtrlSetBkColor($iEditField, 0x404040)
	  GUICtrlSetColor($iEditField, 0xFFD700)
   Case BitAnd(GUICtrlRead($iViewThemeBright), $GUI_CHECKED)
	  GUICtrlSetBkColor($iEditField, 0xFFFACD)
	  GUICtrlSetColor($iEditField, 0x000000)
   EndSelect
EndFunc

Func File_About()
   MsgBox( 64, "Zebra Tester v.0.3", _
               "Утилита предназначена для тестирования принтеров Zebra, подключенных к локальной сети." & @CRLF & _
			   "Среда разработки: AutoIt v3." & @CRLF & @CRLF & _
			   "По всем вопросам использования обращаться к Бурнышеву Д.")
EndFunc