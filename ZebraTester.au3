#AutoIt3Wrapper_Icon=ZebraTester.ico
#pragma compile(inputboxres, true)

#include <GUIConstantsEx.au3>
#include <FONTConstants.au3>
#include <WindowsConstants.au3>
#include <GUIEdit.au3>
#include <WinAPI.au3>
#include <GUIListBox.au3>
#include <GUIRichEdit.au3>
#include <Color.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>

#include "RSZ.au3"
#include "ExtMsgBox.au3"

Opt("GUIOnEventMode", 1)
;~ Opt("MustDeclareVars", 1)

#Region Constants
; #CONSTANTS# ================================================================
Global Const $WINTITLE = "Zebra Tester 0.9"
Global Const $FONT = "Arial"
Global Const $RETURN = 0x0D
Global Const $DARKBKG[3] = [0x40, 0x40, 0x40]
Global Const $DARKFNT[3] = [0xFF, 0xD7, 0x00]
Global Const $BRIGHTBKG[3] = [0xFF, 0xFA, 0xCD]
Global Const $BRIGNTFNT[3] = [0x00, 0x00, 0x00]
#EndRegion Constants

#Region Variables
; #VARIABLES# ================================================================
Global $hDB, $hMainGUI, $hFileMenu, $hFileOpen, $hFileSaveAs, $hFileExit, _
        $hViewMenu, $hViewThemeBright, $hViewThemeDark, $hHelpMenu, _
        $hAbout, $hListBox, $hAddButton, $hDelButton, $hUpdButton, _
        $hIPAddress, $hPortAddressCheckbox, $hPortAddress, $hPingButton, _
        $hSendButton, $hRichEdit, $hStatusBar

Local $hQuery, $aRow, $sLastIpAddress, $sLastPort, $sLastTheme, $wProcHandle, _
        $wProcOld
#EndRegion Variables

; Запрет повторного запуска  =================================================
If WinExists('[CLASS:AutoIt v3;TITLE:' & @ScriptName & ']') Then
    MsgBox(16, @ScriptName, 'Сценарий уже выполняется.')
    Exit
EndIf

; Подключение к СУБД =========================================================
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

#Region GUI
; GUI ========================================================================
$hMainGUI = GUICreate($WINTITLE, 900, 400, 100, 100, $WS_OVERLAPPEDWINDOW)
_SetGUI_MinSize($hMainGUI, 900, 440)
GUISetFont(9, $FW_DONTCARE, $GUI_FONTNORMAL, "Consolas")
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

; Главное меню
; < Файл >
$hFileMenu = GUICtrlCreateMenu("Файл")
$hFileOpen = GUICtrlCreateMenuItem("Открыть..", $hFileMenu)
GUICtrlSetOnEvent($hFileOpen, "File_Open")
$hFileSaveAs = GUICtrlCreateMenuItem("Сохранить как..", $hFileMenu)
GUICtrlSetOnEvent($hFileSaveAs, "File_Save")
GUICtrlCreateMenuItem("", $hFileMenu)
$hFileExit = GUICtrlCreateMenuItem("Выход", $hFileMenu)
GUICtrlSetOnEvent($hFileExit, "CLOSEButton")
; < Вид >
$hViewMenu = GUICtrlCreateMenu("Вид")
$hViewThemeBright = GUICtrlCreateMenuItem("Светлая тема", $hViewMenu, 0, 1)
$hViewThemeDark = GUICtrlCreateMenuItem("Темная тема", $hViewMenu, 1, 1)
;~ GUICtrlSetState($hViewThemeDark, $GUI_CHECKED)
GUICtrlSetOnEvent($hViewThemeBright, "Theme_Change")
GUICtrlSetOnEvent($hViewThemeDark, "Theme_Change")
; < Помощь >
$hHelpMenu = GUICtrlCreateMenu("Помощь")
$hAbout = GUICtrlCreateMenuItem("О программе..", $hHelpMenu)
GUICtrlSetOnEvent($hAbout, "File_About")

; Список шаблонов
GUICtrlCreateLabel("ZPL Шаблоны:", 740, 20, 100, 15)
$hListBox = _GUICtrlListBox_Create($hMainGUI, "", 740, 40, 140, 100)

; Кнопки работы с шаблонами
$hAddButton = GUICtrlCreateButton("Add", 740, 130, 45, 20)
$hUpdButton = GUICtrlCreateButton("Upd", 787, 130, 45, 20)
$hDelButton = GUICtrlCreateButton("Del", 834, 130, 45, 20)
GUICtrlSetResizing($hAddButton, $GUI_DOCKAUTO)
GUICtrlSetResizing($hUpdButton, $GUI_DOCKAUTO)
GUICtrlSetResizing($hDelButton, $GUI_DOCKAUTO)
GUICtrlSetOnEvent($hAddButton, "BUTTON_AddTemplate")
GUICtrlSetOnEvent($hUpdButton, "BUTTON_UpdTemplate")
GUICtrlSetOnEvent($hDelButton, "BUTTON_DelTemplate")

; Поле "IP адрес"
GUICtrlCreateLabel("IP адрес:", 740, 160, 100, 15)
GUICtrlSetResizing(-1, 640)
$hIPAddress = GUICtrlCreateInput("127.0.0.1", 740, 180, 140, 20)
GUICtrlSetResizing(-1, 640)

; Поле "Порт"
$hPortAddressCheckbox = GUICtrlCreateCheckbox("Порт", 740, 210, 100, 15)
GUICtrlSetResizing(-1, 640)
$hPortAddress = GUICtrlCreateInput("6101", 740, 230, 140, 20)
GUICtrlSetResizing(-1, 640)
GUICtrlSetState($hPortAddress, $GUI_DISABLE)
GUICtrlSetOnEvent($hPortAddressCheckbox, "Port_Edit")

; Кнопка "Проверить принтер"
$hPingButton = GUICtrlCreateButton("Проверить принтер", 740, 265, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($hPingButton, "Ping_Node")

; Кнопка "Передать команду"
$hSendButton = GUICtrlCreateButton("Передать команду", 740, 295, 140, 25)
GUICtrlSetResizing(-1, 128)
GUICtrlSetOnEvent($hSendButton, "Send_Command")

; Редактор текста
$hRichEdit = _GUICtrlRichEdit_Create($hMainGUI, "", 20, 20, 700, 300, _
        BitOR($ES_MULTILINE, $WS_HSCROLL, $WS_VSCROLL))
_GUICtrlRichEdit_SetFont($hRichEdit, 9, "Consolas")

; Статус бар
GUICtrlCreateLabel("Статус:", 20, 330, 50)
GUICtrlSetFont(-1, 9, $FW_BOLD, "", $FONT)
$hStatusBar = GUICtrlCreateLabel("", 75, 330, 600, 100)
GUICtrlSetFont(-1, 9, $FW_NORMAL, "", $FONT)
#EndRegion GUI

; Применение сохраненных настроек к GUI: IP Адрес, Порт, Тема редактора ======
$sLastIpAddress = _SQLite_QuerySingleRow($hDB, _
        "SELECT Value " & _
        "FROM Settings " & _
        "WHERE Name = 'Last_IPAddress';", $aRow)
If $aRow[0] Then GUICtrlSetData($hIPAddress, $aRow[0])

$sLastPort = _SQLite_QuerySingleRow($hDB, _
        "SELECT Value " & _
        "FROM Settings " & _
        "WHERE Name = 'Last_Port';", $aRow)
If $aRow[0] Then GUICtrlSetData($hPortAddress, $aRow[0])

$sLastTheme = _SQLite_QuerySingleRow($hDB, _
        "SELECT Value " & _
        "FROM Settings " & _
        "WHERE Name = 'Last_Theme';", $aRow)
If $aRow[0] = 'Bright' Then
    GUICtrlSetState($hViewThemeBright, $GUI_CHECKED)
Else
    GUICtrlSetState($hViewThemeDark, $GUI_CHECKED)
EndIf

Theme_Change()
Fill_ListBox()

GUISetState(@SW_SHOW, $hMainGUI)

; Обеспечение функционала работы со списком шаблонов =========================
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
$wProcHandle = DllCallbackRegister("_WindowProc", "int", "hwnd;uint;wparam;lparam")
$wProcOld = _WinAPI_SetWindowLong($hListBox, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))

; Разгружаем процессор =======================================================
While 1
    Sleep(100)
WEnd

; #FUNCTION# =================================================================
; Описание .....: Выполнеяется в момент закрытия приложения
; ============================================================================
Func CLOSEButton()
    TCPShutdown()
    _WinAPI_SetWindowLong($hListBox, $GWL_WNDPROC, $wProcOld)
    DllCallbackFree($wProcHandle)

    ; Сохраняем настройки, заданные пользователем
    $sLastIpAddress = GUICtrlRead($hIPAddress)
    $sLastPort = GUICtrlRead($hPortAddress)
    If BitAND(GUICtrlRead($hViewThemeBright), $GUI_CHECKED) Then
        $sLastTheme = 'Bright'
    Else
        $sLastTheme = 'Dark'
    EndIf
    _SQLite_Exec($hDB, "BEGIN;")
    _SQLite_Exec($hDB, _
            "INSERT OR REPLACE INTO Settings " & _
            "(ID, Name, Value) " & _
            "VALUES (1, 'Last_IPAddress', " & _
            "CASE " & _
            " WHEN (SELECT Value FROM Settings WHERE ID = 1) IS NULL " & _
            "  THEN '" & $sLastIpAddress & "' " & _
            " ELSE '" & $sLastIpAddress & "' " & _
            "END );")
    _SQLite_Exec($hDB, _
            "INSERT OR REPLACE INTO Settings " & _
            "(ID, Name, Value) " & _
            "VALUES (2, 'Last_Port', " & _
            "CASE " & _
            " WHEN (SELECT Value FROM Settings WHERE ID = 2) IS NULL " & _
            "  THEN '" & $sLastPort & "' " & _
            " ELSE '" & $sLastPort & "' " & _
            "END );")
    _SQLite_Exec($hDB, _
            "INSERT OR REPLACE INTO Settings " & _
            "(ID, Name, Value) " & _
            "VALUES (3, 'Last_Theme', " & _
            "CASE " & _
            " WHEN (SELECT Value FROM Settings WHERE ID = 3) IS NULL " & _
            "  THEN '" & $sLastTheme & "' " & _
            " ELSE '" & $sLastTheme & "' " & _
            "END );")
    If @error Then
        MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                @CRLF & _SQLite_ErrMsg())
        _SQLite_Exec($hDB, "ROLLBACK;")
    Else
        _SQLite_Exec($hDB, "COMMIT;")
    EndIf

    ; Отключаем СУБД
    _SQLite_Close($hDB)
    _SQLite_Shutdown()
    Exit
EndFunc   ;==>CLOSEButton

; #FUNCTION# =================================================================
; Описание .....: Обрабатывает WinAPI события в списке шаблонов: двойной клик
; ============================================================================
Func _WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
    Local $hWndFrom, $iIDFrom, $iCode, $hWndListBox
    If Not IsHWnd($hListBox) Then $hWndListBox = GUICtrlGetHandle($hListBox)
    $hWndFrom = $lParam
    $iIDFrom = BitAND($wParam, 0xFFFF) ; Low Word
    $iCode = BitShift($wParam, 16) ; Hi Word

    Switch $hWndFrom
        Case $hListBox, $hWndListBox
            Switch $iCode
                Case $LBN_DBLCLK
                    Local $sListItem = _GUICtrlListBox_GetText($hListBox, _GUICtrlListBox_GetCurSel($hListBox))
                    Select_Template(StringTrimLeft($sListItem, 3))
                    Return 0
            EndSwitch
    EndSwitch
EndFunc   ;==>_WM_COMMAND

; #FUNCTION# =================================================================
; Описание .....: Обрабатывает WinAPI события в списке шаблонов: клавиша ENTER
; ============================================================================
Func _WindowProc($hWnd, $Msg, $wParam, $lParam)
    Switch $hWnd
        Case $hListBox
            Switch $Msg
                Case $WM_GETDLGCODE
                    Switch $wParam
                        Case $RETURN
                            Local $sListItem = _GUICtrlListBox_GetText($hListBox, _GUICtrlListBox_GetCurSel($hListBox))
                            Select_Template(StringTrimLeft($sListItem, 3))
                            Return 0
                    EndSwitch
            EndSwitch
    EndSwitch
    Return _WinAPI_CallWindowProc($wProcOld, $hWnd, $Msg, $wParam, $lParam)
EndFunc   ;==>_WindowProc

; #FUNCTION# =================================================================
; Описание .....: Заполняет перечень шаблонов
; ============================================================================
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
    _GUICtrlListBox_ResetContent($hListBox)
    While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
        $iCounter += 1
        _GUICtrlListBox_AddString($hListBox, $iCounter & ". " & $aRow[0])
    WEnd
EndFunc   ;==>Fill_ListBox

; #FUNCTION# =================================================================
; Описание .....: Диалог открытия файла
; ============================================================================
Func File_Open()
    Local $hFileOpen = FileOpenDialog("Открыть файл", _
            @WorkingDir, "ZPL Scripts (*.zpl)|Text files (*.txt)")
    If Not @error Then
        Local $sLine = FileRead($hFileOpen)
        If StringLen(_GUICtrlRichEdit_GetText($hRichEdit)) > 0 Then
            _GUICtrlRichEdit_SetSel($hRichEdit, 0, -1, True)
            _GUICtrlRichEdit_ReplaceText($hRichEdit, $sLine)
            _GUICtrlRichEdit_HideSelection($hRichEdit, False)
        Else
            _GUICtrlRichEdit_InsertText($hRichEdit, $sLine)
        EndIf
        _GUICtrlRichEdit_SetScrollPos($hRichEdit, 0, 0)
        GUICtrlSetData($hStatusBar, "")
        WinSetTitle($hMainGUI, "", $WINTITLE & " - " & $hFileOpen)
    EndIf
EndFunc   ;==>File_Open

; #FUNCTION# =================================================================
; Описание .....: Диалог сохранения файла
; ============================================================================
Func File_Save()
    Local $sFileSave = FileSaveDialog("Задайте имя файла", _
            Default, "ZPL Scripts (*.zpl)|Text files (*.txt)", _
            BitOR($FD_PATHMUSTEXIST, $FD_PROMPTOVERWRITE))
    If @error Then
        GUICtrlSetData($hStatusBar, "Файл не сохранен.")
    Else
        Local $sFileName = StringTrimLeft($sFileSave, StringInStr($sFileSave, "\", $STR_NOCASESENSE, -1))
        Local $iExtension = StringInStr($sFileName, ".", $STR_NOCASESENSE)
        If $iExtension Then
            If Not (StringTrimLeft($sFileName, $iExtension - 1) = ".zpl") Then $sFileSave &= ".zpl"
        Else
            $sFileSave &= ".zpl"
        EndIf
        FileOpen($sFileSave, 2)
        FileWrite($sFileSave, _GUICtrlRichEdit_GetText($hRichEdit))
        FileClose($sFileSave)
        GUICtrlSetData($hStatusBar, "Файл сохранен:" & @CRLF & $sFileSave)
        WinSetTitle($hMainGUI, "", $WINTITLE & " - " & $sFileSave)
    EndIf
EndFunc   ;==>File_Save

; #FUNCTION# =================================================================
; Описание .....: Выбор шаблона для замещения текста в текстовом редакторе
; ============================================================================
Func Select_Template($sListItem)
    _SQLite_QuerySingleRow($hDB, _
            "SELECT Content " & _
            "FROM Templates " & _
            "WHERE Name = """ & $sListItem & """;", $aRow)
    If StringLen(_GUICtrlRichEdit_GetText($hRichEdit)) > 0 Then
        _GUICtrlRichEdit_SetSel($hRichEdit, 0, -1, True)
        _GUICtrlRichEdit_ReplaceText($hRichEdit, $aRow[0])
        _GUICtrlRichEdit_HideSelection($hRichEdit, False)
    Else
        _GUICtrlRichEdit_InsertText($hRichEdit, $aRow[0])
    EndIf
    _GUICtrlRichEdit_SetScrollPos($hRichEdit, 0, 0)
    WinSetTitle($hMainGUI, "", $WINTITLE & " - " & $sListItem)
EndFunc   ;==>Select_Template

; #FUNCTION# =================================================================
; Описание .....: Проверка доступности узла
; ============================================================================
Func Ping_Node()
    Local $sError
    If GUICtrlRead($hIPAddress) = "" Then
        GUICtrlSetData($hStatusBar, "Не задан адрес узла!")
    Else
        Local $sPing = "Ping "
        Do
            GUICtrlSetData($hStatusBar, $sPing)
            Sleep(300)
            $sPing &= ">"
        Until StringLen($sPing) = 10
        Local $iPing = Ping(GUICtrlRead($hIPAddress))
        If $iPing Then
            GUICtrlSetData($hStatusBar, "Узел доступен. Время отклика: " & $iPing & "мс.")
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
            GUICtrlSetData($hStatusBar, "Узел недоступен: " & $sError)
        EndIf
    EndIf
EndFunc   ;==>Ping_Node

; #FUNCTION# =================================================================
; Описание .....: Отправка посылки посредством TCP протокола
; ============================================================================
Func Send_Command()
    Local $lCount
    Local $iSocket
    Local $sError
    Local $sMessage = _GUICtrlRichEdit_GetText($hRichEdit)
    If GUICtrlRead($hIPAddress) = "" Then
        GUICtrlSetData($hStatusBar, "Не задан адрес узла!")
    ElseIf GUICtrlRead($hPortAddress) = "" Then
        GUICtrlSetData($hStatusBar, "Не задан адрес порта!")
    ElseIf Not _GUICtrlRichEdit_GetText($hRichEdit) Then
        GUICtrlSetData($hStatusBar, "Нет сообщения для отправки!")
    Else
        TCPStartup()
        Local $sConnectString = "Установка соединения "
        Local $sSendString = "Соединение установлено. Отправка "
        $lCount = TimerInit()
        Local $iCounter = 0
        Do
            GUICtrlSetData($hStatusBar, $sConnectString)
            $iSocket = TCPConnect(GUICtrlRead($hIPAddress), GUICtrlRead($hPortAddress))
            $sError = @error
            Sleep(200)
            If StringLen($sConnectString) > 23 Then
                $sConnectString = StringTrimRight($sConnectString, 3)
            Else
                $sConnectString &= ">"
            EndIf
        Until $sError = 0 Or TimerDiff($lCount) >= 5000
        If $sError Then
            GUICtrlSetData($hStatusBar, "Не возможно установить соединение. Код ошибки: " & $sError)
        Else
            $lCount = TimerInit()
            Do
                GUICtrlSetData($hStatusBar, $sSendString)
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
                GUICtrlSetData($hStatusBar, "Не возможно отправить сообщение. Код ошибки: " & @error)
            Else
                GUICtrlSetData($hStatusBar, "Сообщение отправлено.")
            EndIf
        EndIf
    EndIf
    TCPCloseSocket($iSocket)
EndFunc   ;==>Send_Command

; #FUNCTION# =================================================================
; Описание .....: Слушатель для меню выбора темы оформления редактора текста
; ============================================================================
Func Theme_Change()
    Local $aPos = _GUICtrlRichEdit_GetScrollPos($hRichEdit)
    _GUICtrlRichEdit_SetSel($hRichEdit, 0, -1, True)
    If BitAND(GUICtrlRead($hViewThemeBright), $GUI_CHECKED) Then
        _GUICtrlRichEdit_SetBkColor($hRichEdit, _ColorSetCOLORREF($BRIGHTBKG))
        _GUICtrlRichEdit_SetCharColor($hRichEdit, _ColorSetCOLORREF($BRIGNTFNT))
    Else
        _GUICtrlRichEdit_SetBkColor($hRichEdit, _ColorSetCOLORREF($DARKBKG))
        _GUICtrlRichEdit_SetCharColor($hRichEdit, _ColorSetCOLORREF($DARKFNT))
    EndIf
    _GUICtrlRichEdit_Deselect($hRichEdit)
    _GUICtrlRichEdit_HideSelection($hRichEdit, False)
    _GUICtrlRichEdit_SetFont($hRichEdit, 9, "Consolas")
    _GUICtrlRichEdit_SetScrollPos($hRichEdit, $aPos[0], $aPos[1])
EndFunc   ;==>Theme_Change

; #FUNCTION# =================================================================
; Описание .....: Слушатель для чекбокса поля Порт
; ============================================================================
Func Port_Edit()
    If BitAND(GUICtrlRead($hPortAddressCheckbox), $GUI_CHECKED) Then
        GUICtrlSetState($hPortAddress, $GUI_ENABLE)
    Else
        GUICtrlSetState($hPortAddress, $GUI_DISABLE)
    EndIf
EndFunc   ;==>Port_Edit

; #FUNCTION# =================================================================
; Описание .....: Слушатель для кнопки Add списка шаблонов
; ============================================================================
Func BUTTON_AddTemplate()
    Local $sContent = _GUICtrlRichEdit_GetText($hRichEdit)
    Local $aPos = WinGetPos($hMainGUI)
    Local $sNewName = InputBox("Add Template", "Enter the name of new Template", _
            "", "", -1, -1, $aPos[2] - 420, 200)
    Local $sError = @error
    If Not BitOR($sError, Not $sContent, Not $sNewName) Then
        _SQLite_Exec($hDB, "BEGIN;")
        _SQLite_Exec($hDB, _
                "INSERT INTO Templates " & _
                "(Name, Content, Type) " & _
                "VALUES ('" & $sNewName & "', " & _SQLite_Escape($sContent) & ", 2);")
        If @error Then
            MsgBox($MB_ICONERROR, "SQLite Error!", "Ошибка записи в базу данных:" & _
                    @CRLF & _SQLite_ErrMsg())
            _SQLite_Exec($hDB, "ROLLBACK;")
        Else
            _SQLite_Exec($hDB, "COMMIT;")
            Fill_ListBox()
        EndIf
    ElseIf $sError Then
        Return
    ElseIf Not $sContent Then
        MsgBox(16, "Ошибка", "Не задан текст шаблона")
    ElseIf Not $sNewName Then
        MsgBox(16, "Ошибка", "Не задано имя нового шаблона")
    EndIf
EndFunc   ;==>BUTTON_AddTemplate

; #FUNCTION# =================================================================
; Описание .....: Слушатель для кнопки Upd списка шаблонов
; ============================================================================
Func BUTTON_UpdTemplate()
    Local $sCurName = StringTrimLeft(_GUICtrlListBox_GetText($hListBox, _
            _GUICtrlListBox_GetCurSel($hListBox)), 3)
    Local $sContent = _GUICtrlRichEdit_GetText($hRichEdit)
    If Not BitOR(@error, Not $sContent, Not $sCurName) Then
        If SQL_CheckType($sCurName) <> 1 Then
            _SQLite_Exec($hDB, "BEGIN;")
            _SQLite_Exec($hDB, _
                    "UPDATE Templates " & _
                    "SET Content = " & _SQLite_Escape($sContent) & " " & _
                    "WHERE Name = '" & $sCurName & "' " & _
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
    ElseIf Not $sContent Then
        MsgBox(16, "Ошибка", "Не задан текст шаблона")
    ElseIf Not $sCurName Then
        MsgBox(16, "Ошибка", "Не выбрано имя шаблона")
    Else
        Return
    EndIf
EndFunc   ;==>BUTTON_UpdTemplate

; #FUNCTION# =================================================================
; Описание .....: Слушатель для кнопки Del списка шаблонов
; ============================================================================
Func BUTTON_DelTemplate()
    Local $sCurName = StringTrimLeft(_GUICtrlListBox_GetText($hListBox, _
            _GUICtrlListBox_GetCurSel($hListBox)), 3)
    If SQL_CheckType($sCurName) <> 1 Then
        _SQLite_Exec($hDB, "BEGIN;")
        _SQLite_Exec($hDB, _
                "DELETE FROM Templates " & _
                "WHERE Name = '" & $sCurName & "' " & _
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

; #FUNCTION# =================================================================
; Описание .....: Проверка типа шаблона на запрет редактирования
; ============================================================================
Func SQL_CheckType($sItem)
    _SQLite_QuerySingleRow($hDB, _
            "SELECT Type " & _
            "FROM Templates " & _
            "WHERE Name = '" & $sItem & "';", $aRow)
    Return $aRow[0]
EndFunc   ;==>SQL_CheckType

; #FUNCTION# =================================================================
; Описание .....: Вывод информации о приложении в меню Помощь
; ============================================================================
Func File_About()
    Local $sMsg = "Утилита предназначена для тестирования принтеров Zebra, подключенных к локальной сети." & @CRLF & _
            "Среда разработки: AutoIt v3." & @CRLF & @CRLF & _
            "По всем вопросам использования обращаться к Бурнышеву Д."
    _ExtMsgBox(@AutoItExe, "OK", $WINTITLE, $sMsg)
EndFunc   ;==>File_About
