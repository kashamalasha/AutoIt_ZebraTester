;~ #include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <FONTConstants.au3>
#include <WindowsConstants.au3>
#include <GUIEdit.au3>
#include <WinAPI.au3>
#include <GUIListBox.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include "RSZ.au3"

Opt("GUIOnEventMode", 1)

; Запрет повторного запуска
If WinExists('[CLASS:AutoIt v3;TITLE:' & @ScriptName & ']') Then
    MsgBox(16, @ScriptName, 'Сценарий уже выполняется.')
    Exit
EndIf

Global $sFont = "Arial"
Global Const $RETURN = 0x0D
Global Const $WINTITLE = "Zebra Tester 0.5.2"
Global $hQuery, $aRow

HotKeySet("^a", "_SelAll")

Global $hMainGUI = GUICreate($WINTITLE, 900, 400, 100, 100, $WS_OVERLAPPEDWINDOW)
_SetGUI_MinSize($hMainGUI, 900, 440)
GUISetFont(9, $FW_DONTCARE, $GUI_FONTNORMAL, "Consolas")
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

; Главное меню
; <= Файл =>
$iFileMenu = GUICtrlCreateMenu("Файл")
$iFileOpen = GUICtrlCreateMenuItem("Открыть..", $iFileMenu)
GUICtrlSetOnEvent($iFileOpen, "File_Open")
$iFileSaveAs = GUICtrlCreateMenuItem("Сохранить как..", $iFileMenu)
GUICtrlSetOnEvent($iFileSaveAs, "File_Save")
GUICtrlCreateMenuItem("", $iFileMenu)
$iFileExit = GUICtrlCreateMenuItem("Выход", $iFileMenu)
GUICtrlSetOnEvent($iFileExit, "CLOSEButton")
; <= Вид =>
$iViewMenu = GUICtrlCreateMenu("Вид")
$iViewThemeBright = GUICtrlCreateMenuItem("Светлая тема", $iViewMenu, 0, 1)
$iViewThemeDark = GUICtrlCreateMenuItem("Темная тема", $iViewMenu, 1, 1)
GUICtrlSetState($iViewThemeDark, $GUI_CHECKED)
GUICtrlSetOnEvent($iViewThemeBright, "Theme_Change")
GUICtrlSetOnEvent($iViewThemeDark, "Theme_Change")
; <= Помощь =>
$iHelpenu = GUICtrlCreateMenu("Помощь")
$iAbout = GUICtrlCreateMenuItem("О программе..", $iHelpenu)
GUICtrlSetOnEvent($iAbout, "File_About")

; Список шаблонов
GUICtrlCreateLabel("ZPL Шаблоны:", 740, 20, 100, 15)
$iList = _GUICtrlListBox_Create($hMainGUI, "", 740, 40, 140, 100)
$iAddButton = GUICtrlCreateButton("Add", 740, 130, 45, 20)
$iUpdButton = GUICtrlCreateButton("Upd", 787, 130, 45, 20)
$iDelButton = GUICtrlCreateButton("Del", 834, 130, 45, 20)
GUICtrlSetResizing($iAddButton, $GUI_DOCKAUTO)
GUICtrlSetResizing($iUpdButton, $GUI_DOCKAUTO)
GUICtrlSetResizing($iDelButton, $GUI_DOCKAUTO)
GUICtrlSetOnEvent($iAddButton, "BUTTON_AddTemplate")
GUICtrlSetOnEvent($iUpdButton, "BUTTON_UpdTemplate")
GUICtrlSetOnEvent($iDelButton, "BUTTON_DelTemplate")

; Поле "IP адрес"
GUICtrlCreateLabel("IP адрес:", 740, 160, 100, 15)
GUICtrlSetResizing(-1, 640)
$iIPaddress = GUICtrlCreateInput("127.0.0.1", 740, 180, 140, 20)
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

$sLastIpAddress = _SQLite_QuerySingleRow($hDB, _
            "SELECT Value " & _
            "FROM Settings " & _
            "WHERE Name = ""Last_IPAddress"";", $aRow)
If $aRow[0] Then GUICtrlSetData($iIPaddress, $aRow[0])

$sLastPort = _SQLite_QuerySingleRow($hDB, _
            "SELECT Value " & _
            "FROM Settings " & _
            "WHERE Name = ""Last_Port"";", $aRow)
If $aRow[0] Then GUICtrlSetData($iPort, $aRow[0])

Fill_ListBox()
Theme_Change()
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
;~ GUIRegisterMsg($WM_SIZE, "_WM_SIZE")
$wProcHandle = DllCallbackRegister("_WindowProc", "int", "hwnd;uint;wparam;lparam")
$wProcOld = _WinAPI_SetWindowLong($iList, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))

GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
$wProcHandle = DllCallbackRegister("_WindowProc", "int", "hwnd;uint;wparam;lparam")
$wProcOld = _WinAPI_SetWindowLong($iList, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))

GUISetState(@SW_SHOW, $hMainGUI)

While 1
    Sleep(100)
WEnd

Func CLOSEButton()
    TCPShutdown()
    _WinAPI_SetWindowLong($iList, $GWL_WNDPROC, $wProcOld)
    DllCallbackFree($wProcHandle)
    $sLastIpAddress = GUICtrlRead($iIPaddress)
    $sLastPort = GUICtrlRead($iPort)
    _SQLite_Exec($hDB, "BEGIN;")
    _SQLite_Exec($hDB, _
            "INSERT OR REPLACE INTO Settings " & _
            "(ID, Name, Value) " & _
            "VALUES (1, ""Last_IPAddress"", " & _
            "CASE " & _
            " WHEN (SELECT Value FROM Settings WHERE ID = 1) IS NULL THEN """ & $sLastIpAddress & """ " & _
            " ELSE """ & $sLastIpAddress& """ " & _
            "END );")
    _SQLite_Exec($hDB, _
            "INSERT OR REPLACE INTO Settings " & _
            "(ID, Name, Value) " & _
            "VALUES (2, ""Last_Port"", " & _
            "CASE " & _
            " WHEN (SELECT Value FROM Settings WHERE ID = 2) IS NULL THEN """ & $sLastPort & """ " & _
            " ELSE """ & $sLastPort& """ " & _
            "END );")
    If @error Then
        MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                @CRLF & _SQLite_ErrMsg())
        _SQLite_Exec($hDB, "ROLLBACK;")
    Else
        _SQLite_Exec($hDB, "COMMIT;")
    EndIf
    _SQLite_Close($hDB)
    _SQLite_Shutdown()
    Exit
EndFunc   ;==>CLOSEButton

Func Fill_ListBox()
    Local $iCounter = 0
    _SQLite_Query($hDB, _
            "SELECT Name " & _
            "FROM Templates " & _
            "ORDER BY ID;", $hQuery)
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "SQLite error", "Can't execute the query")
        Exit -1
    EndIf
    _GUICtrlListBox_ResetContent($iList)
    While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
        $iCounter += 1
        _GUICtrlListBox_AddString($iList, $iCounter & ". " & $aRow[0])
    WEnd
EndFunc   ;==>Fill_ListBox

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
                    Local $sListItem = _GUICtrlListBox_GetText($iList, _GUICtrlListBox_GetCurSel($iList))
                    Select_Template(StringTrimLeft($sListItem, 3))
                    Return 0
            EndSwitch
    EndSwitch
EndFunc   ;==>_WM_COMMAND

Func _WindowProc($hWnd, $Msg, $wParam, $lParam)
    Switch $hWnd
        Case $iList
            Switch $Msg
                Case $WM_GETDLGCODE
                    Switch $wParam
                        Case $RETURN
                            Local $sListItem = _GUICtrlListBox_GetText($iList, _GUICtrlListBox_GetCurSel($iList))
                            Select_Template(StringTrimLeft($sListItem, 3))
                            Return 0
                    EndSwitch
            EndSwitch
    EndSwitch
    Return _WinAPI_CallWindowProc($wProcOld, $hWnd, $Msg, $wParam, $lParam)
EndFunc   ;==>_WindowProc

Func File_Open()
    $FileOpen = FileOpenDialog("Открыть файл", _
                    @DesktopDir, "ZPL Scripts (zpl.*)|Text files (*.txt)")
    $sLine = FileRead($FileOpen)
    GUICtrlSetData($iEditField, $sLine)
    GUICtrlSetData($iStatusBar, "")
    WinSetTitle($hMainGUI, "", $WINTITLE & " - " & $FileOpen)
EndFunc   ;==>File_Open

Func File_Save()
    Local $sFileSave = FileSaveDialog("Задайте имя файла", _
                            Default, "ZPL Scripts (*.zpl)|Text files (*.txt)", _
                            BitOR($FD_PATHMUSTEXIST, $FD_PROMPTOVERWRITE))
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
        WinSetTitle($hMainGUI, "", $WINTITLE & " - " & $sFileSave)
    EndIf
EndFunc   ;==>File_Save

Func Select_Template($sListItem)
    _SQLite_QuerySingleRow($hDB, _
            "SELECT Content " & _
            "FROM Templates " & _
            "WHERE Name = """ & $sListItem & """;", $aRow)
    $aRow[0] = StringStripWS( _
                    StringReplace( _
                        StringReplace($aRow[0], "^", @CRLF & "^"), _
                    @CRLF & "^FS", "^FS"), _
               $STR_STRIPLEADING)
    GUICtrlSetData($iEditField, $aRow[0])
    WinSetTitle($hMainGUI, "", "Zebra Tester - " & StringTrimLeft(GUICtrlRead($iList), 3))
EndFunc   ;==>Select_Template

Func Ping_Node()
    Local $sError
    If GUICtrlRead($iIPaddress) = "" Then
        GUICtrlSetData($iStatusBar, "Не задан адрес узла!")
    Else
        Local $sPing = "Ping "
        Do
            GUICtrlSetData($iStatusBar, $sPing)
            Sleep(300)
            $sPing &= ">"
        Until StringLen($sPing) = 10
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
        Local $sConnectString = "Установка соединения "
        Local $sSendString = "Соединение установлено. Отправка "
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

Func BUTTON_AddTemplate()
    Local $sContent = GUICtrlRead($iEditField)
    Local $aPos = WinGetPos($hMainGUI)
    Local $sNewName = InputBox("Add Template", "Enter the name of new Template", _
            "", "", -1, -1, $aPos[2] - 420, 200)
    If Not BitOR(@error, Not $sContent, Not $sNewName) Then
        $sContent = StringReplace($sContent, @CRLF, @CR)
        _SQLite_Exec($hDB, "BEGIN;")
        _SQLite_Exec($hDB, _
                "INSERT INTO Templates " & _
                "(Name, Content, Type) " & _
                "VALUES (""" & $sNewName & """, """ & $sContent & """, 2);")
        If @error Then
            MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                    @CRLF & _SQLite_ErrMsg())
            _SQLite_Exec($hDB, "ROLLBACK;")
        EndIf
        _SQLite_Exec($hDB, "COMMIT;")
        Fill_ListBox()
    ElseIf Not $sContent Then
        MsgBox(16, "Ошибка", "Не задан текст шаблона")
    ElseIf $sNewName = "" Then
        MsgBox(16, "Ошибка", "Не задано имя нового шаблона")
    Else
        Return
    EndIf
EndFunc   ;==>BUTTON_AddTemplate

Func BUTTON_UpdTemplate()
    Local $sCurName = StringTrimLeft(_GUICtrlListBox_GetText($iList, _
            _GUICtrlListBox_GetCurSel($iList)), 3)
    Local $sContent = GUICtrlRead($iEditField)
    $sContent = StringReplace($sContent, @CRLF, @CR)
    If SQL_CheckType($sCurName) <> 1 Then
        _SQLite_Exec($hDB, "BEGIN;")
        _SQLite_Exec($hDB, _
                "UPDATE Templates " & _
                "SET Content = """ & $sContent & """ " & _
                "WHERE Name = """ & $sCurName & """ " & _
                "AND Type <> 1;")
        If @error Then
            MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                    @CRLF & _SQLite_ErrMsg())
            _SQLite_Exec($hDB, "ROLLBACK;")
        Else
            _SQLite_Exec($hDB, "COMMIT;")
            MsgBox($MB_ICONINFORMATION, "Success", "Запись обновлена!")
        EndIf
    Else
        MsgBox($MB_ICONWARNING, "Ошибка", "Нельзя изменить системный шаблон!")
    EndIf
EndFunc   ;==>BUTTON_UpdTemplate

Func BUTTON_DelTemplate()
    Local $sCurName = StringTrimLeft(_GUICtrlListBox_GetText($iList, _
            _GUICtrlListBox_GetCurSel($iList)), 3)
    If SQL_CheckType($sCurName) <> 1 Then
        _SQLite_Exec($hDB, "BEGIN;")
        _SQLite_Exec($hDB, _
                "DELETE FROM Templates " & _
                "WHERE Name = """ & $sCurName & """ " & _
                "AND Type <> 1;")
        If @error Then
            MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                    @CRLF & _SQLite_ErrMsg())
            _SQLite_Exec($hDB, "ROLLBACK;")
        Else
            _SQLite_Exec($hDB, "COMMIT;")
            Fill_ListBox()
            MsgBox($MB_ICONINFORMATION, "Success", "Запись удалена!")
        EndIf
    Else
        MsgBox($MB_ICONWARNING, "Ошибка", "Нельзя удалить системный шаблон!")
    EndIf
EndFunc   ;==>BUTTON_DelTemplate

Func SQL_CheckType($sItem)
    _SQLite_QuerySingleRow($hDB, _
            "SELECT Type " & _
            "FROM Templates " & _
            "WHERE Name = """ & $sItem & """;", $aRow)
    Return $aRow[0]
EndFunc   ;==>SQL_CheckType

Func File_About()
    MsgBox($MB_ICONINFORMATION, $WINTITLE, _
            "Утилита предназначена для тестирования принтеров Zebra, подключенных к локальной сети." & @CRLF & _
            "Среда разработки: AutoIt v3." & @CRLF & @CRLF & _
            "По всем вопросам использования обращаться к Бурнышеву Д.")
EndFunc   ;==>File_About
