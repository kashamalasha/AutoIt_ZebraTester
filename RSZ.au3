#Region Includes
#Include-Once
#Include <WindowsConstants.au3>
#Include <GuiConstantsEx.au3>
#Include <WinAPIEx.au3>
#Include <Constants.au3>
#Include <Array.au3>
#EndRegion Includes

#Region Global Variables
Global $a_Ctrl[1][15]
Global $a_CtrlDef
;$a_Ctrl[0][0]    -  ���������� ���������
;$a_Ctrl[$i][0]   -  $hWind ����
;$a_Ctrl[$i][1]   -  $aClient[0] ����
;$a_Ctrl[$i][2]   -  $aClient[1] ����
;$a_Ctrl[$i][3]   -  $hCtrl
;$a_Ctrl[$i][4]   -  $iResizing
;$a_Ctrl[$i][5]   -  $XCtrl
;$a_Ctrl[$i][6]   -  $YCtrl
;$a_Ctrl[$i][7]   -  $WCtrl
;$a_Ctrl[$i][8]   -  $HCtrl
;$a_Ctrl[$i][9]   -  $iReaddress_Flag
;$a_Ctrl[$i][10]  -  ������ (Class ��������)
;$a_Ctrl[$i][11]  -  $XCtrl_Current
;$a_Ctrl[$i][12]  -  $YCtrl_Current
;$a_Ctrl[$i][13]  -  $WCtrl_Current
;$a_Ctrl[$i][14]  -  $HCtrl_Current

Global $a_GUI[1][7]
;$a_GUI[0][0]     - ���������� ���������
;$a_GUI[0][1]     - ����������(����������) ����������� ������ ���� ($i_WidthMin)(AUTO)
;$a_GUI[0][2]     - ����������(����������) ����������� ������ ���� ($i_HeightMin)(AUTO)
;$a_GUI[0][3]     - $iBorder_Width (����� �� X) ����
;$a_GUI[0][4]     - $iCaption_Height (����� �� Y) ����
;$a_GUI[0][5]     - ������������� (�����������) ����������� ������ ���� ($i_WidthMin)
;$a_GUI[0][6]     - ������������� (�����������) ����������� ������ ���� ($i_HeightMin)

Global $s_External_WM_SIZE_Func ; ��� ������� �-�� WM_SIZE (������ �������� ������� )
Global $i_Opt_Autodetect_MinSize=1; ����� �������������� ���������� �������� ����
Global $i_Opt_MinMaxWinSize=1; ����� �������� ���������� �������� ����
Global $i_Registered_WM_SIZE = 0
Global $Init=False; ������������� GUI �� �����������
#EndRegion Global Variables

GUIRegisterMsg($WM_NCHITTEST, "__WM_NCHITTEST")
;��������� ����������� ��� ���������� ������� ���� � ����(��� ��������� �������� � ���������� ����  � ������������� �� ���������.).

#Region External Functions
;~ - _ControlResizing       ����������� ��������� � ��������� �� ��������  ��� ����������� �����
;~ - _ControlSetResizing    ������� ��������� ��������� ��������� ��� ��������� �������� GUI-����
;~ - _InitGUI               ������������� ��������� GUI-����
;~ - _Register_WM_SIZE      ����������� ������� �-�� WM_SIZE ������ �������� �������
;~ - _SetGUI_MinSize        ��������� ���������� ���������� �������� ��������� �������� GUI ����

; #FUNCTION# ====================================================================================================
; ���................:  _ControlResizing
; ��������...........:  ����������� ��������� � ��������� �� ��������  ��� ����������� �����.
; ���������..........:  _ControlResizing($ResLab, [$CheckMinMax, [$hWnd ]])
; ���������..........:  $ResLab      - ������������� �����.
;                       $CheckMinMax - ����� ������������ ������� ���� (�������������� ��������. �� ��������� : ��������)
;                       $hWnd        - ���������� ����,�������� ����������� ����� (�������������� ��������)
;
; �����. �������� ...:  �����    -  1
;                       �����    -  0
;                     	Error    =  1  - ������������ ��������� Resize-����������
; �����..............:  gregaz.
; ===============================================================================================================
Func _ControlResizing($ResLab, $CheckMinMax = True, $hWnd="")
	Local $iX_Ctrl, $iY_Ctrl, $iW_Ctrl, $iH_Ctrl, $iInterStice
	Local $iPosMin = -10, $iPosMax = 10000; *** 18.06.2013

	Local $iMouseCursor = MouseGetCursor()

	Local $iArrayCtrlInd = _ArraySearch($a_Ctrl, GUICtrlGetHandle($ResLab), 1, 0, 0, 0, 1, 3)
	If @Error Then Return
	If $hWnd="" Then
		$hWnd=$a_Ctrl[$iArrayCtrlInd][0]
	EndIf
	Local $hDC = _WinAPI_GetDC(GUICtrlGetHandle($ResLab))
	Local $Color = _WinAPI_GetPixel($hDC, 0, 0)
	_WinAPI_ReleaseDC($hWnd, $hDC)
	GUICtrlSetBkColor($ResLab, 0xFFFF00)

	Local $aCur_Info = GUIGetCursorInfo($hWnd)
	Local $aLab_Pos = ControlGetPos($hWnd, '', $ResLab)
	If @Error Then Return

	Local $dX = $aLab_Pos[0] - $aCur_Info[0]
	Local $dY = $aLab_Pos[1] - $aCur_Info[1]

	While $aCur_Info[2] = 1
		$aCur_Info = GUIGetCursorInfo($hWnd)
		If $iMouseCursor = 13 Then
			$iPos = $aCur_Info[0] + $dX
			If $iPos <= $iPosMin Or $iPos >= $iPosMax Then ContinueLoop
			For $i = 1 To UBound($a_Ctrl) - 1
				If $a_Ctrl[$i][0] <> $hWnd Then ContinueLoop
				If $a_CtrlDef[$i][6] < $a_CtrlDef[$iArrayCtrlInd][6] + $a_CtrlDef[$iArrayCtrlInd][8] And ($a_CtrlDef[$i][6] + $a_CtrlDef[$i][8]) >= $a_CtrlDef[$iArrayCtrlInd][6] Then
					If $a_Ctrl[$i][3] = GUICtrlGetHandle($ResLab) Then
						$iX_Ctrl = $iPos
						GUICtrlSetPos($ResLab, $iX_Ctrl, Default)
						$a_Ctrl[$i][11] = $iX_Ctrl
					ElseIf $a_CtrlDef[$iArrayCtrlInd][5] > ($a_CtrlDef[$i][5] + $a_CtrlDef[$i][7]) And $a_CtrlDef[$iArrayCtrlInd][5] - ($a_CtrlDef[$i][5] + $a_CtrlDef[$i][7]) <= 5 Then	; *****20.04.2013
						$iInterStice=$a_CtrlDef[$iArrayCtrlInd][5] - ($a_CtrlDef[$i][5] + $a_CtrlDef[$i][7])
						$iW_Ctrl = $iPos - $a_Ctrl[$i][5]-$iInterStice
						If $CheckMinMax = True And $iPosMin < $a_Ctrl[$i][5] Then
							$iPosMin = $a_Ctrl[$i][5] - $iInterStice
						EndIf
						__MoveControl($hWnd, $a_Ctrl[$i][3], Default, Default, $iW_Ctrl)
						$a_Ctrl[$i][13] = $iW_Ctrl
					ElseIf($a_CtrlDef[$iArrayCtrlInd][5] + $a_CtrlDef[$iArrayCtrlInd][7]) < $a_CtrlDef[$i][5] And ($a_CtrlDef[$iArrayCtrlInd][5] + $a_CtrlDef[$iArrayCtrlInd][7]) - $a_CtrlDef[$i][5] >= -5 Then	; *****20.04.2013
						$iInterStice=$a_CtrlDef[$i][5]-($a_CtrlDef[$iArrayCtrlInd][5] + $a_CtrlDef[$iArrayCtrlInd][7])
						$iX_Ctrl = $iPos + ($a_Ctrl[$iArrayCtrlInd][7]) + $iInterStice
						$iW_Ctrl = $a_Ctrl[$i][5] + $a_Ctrl[$i][7] - $iX_Ctrl
						If $CheckMinMax = True And $iPosMax > $a_Ctrl[$i][5] + $a_Ctrl[$i][7] - $a_Ctrl[$iArrayCtrlInd][7] Then
							$iPosMax = ($a_Ctrl[$i][5] + $a_Ctrl[$i][7]) - ($a_Ctrl[$iArrayCtrlInd][7] - $iInterStice)
						EndIf
						__MoveControl($hWnd, $a_Ctrl[$i][3], $iX_Ctrl, Default, $iW_Ctrl)
						$a_Ctrl[$i][11] = $iX_Ctrl
						$a_Ctrl[$i][13] = $iW_Ctrl
					EndIf
				EndIf
			Next
		ElseIf $iMouseCursor = 11 Then
			$iPos = $aCur_Info[1] + $dY
			If $iPos <= $iPosMin Or $iPos >= $iPosMax Then ContinueLoop
			For $i = 1 To UBound($a_Ctrl) - 1
				If $a_Ctrl[$i][0] <> $hWnd Then ContinueLoop
				If $a_CtrlDef[$i][5] < $a_CtrlDef[$iArrayCtrlInd][5] + $a_CtrlDef[$iArrayCtrlInd][7] And ($a_CtrlDef[$i][5] + $a_CtrlDef[$i][7]) >= $a_CtrlDef[$iArrayCtrlInd][5] Then
					If $a_Ctrl[$i][3] = GUICtrlGetHandle($ResLab) Then
						$iY_Ctrl = $iPos
						GUICtrlSetPos($ResLab, Default, $iY_Ctrl)
						$a_Ctrl[$i][12] = $iY_Ctrl
					ElseIf $a_CtrlDef[$iArrayCtrlInd][6] > ($a_CtrlDef[$i][6] + $a_CtrlDef[$i][8]) And $a_CtrlDef[$iArrayCtrlInd][6] - ($a_CtrlDef[$i][6] + $a_CtrlDef[$i][8]) <= 5 Then	; *****20.04.2013
						$iInterStice=$a_CtrlDef[$iArrayCtrlInd][6] - ($a_CtrlDef[$i][6] + $a_CtrlDef[$i][8])
						$iH_Ctrl = $iPos - $a_Ctrl[$i][6] - $iInterStice
						If $CheckMinMax = True And $iPosMin < $a_Ctrl[$i][6] Then
							$iPosMin = $a_Ctrl[$i][6] - $iInterStice
						EndIf
						__MoveControl($hWnd, $a_Ctrl[$i][3], Default, Default, $a_Ctrl[$i][7], $iH_Ctrl)
						$a_Ctrl[$i][14] = $iH_Ctrl
					ElseIf($a_CtrlDef[$iArrayCtrlInd][6] + $a_CtrlDef[$iArrayCtrlInd][8]) < $a_CtrlDef[$i][6] And ($a_CtrlDef[$iArrayCtrlInd][6] + $a_CtrlDef[$iArrayCtrlInd][8]) - $a_CtrlDef[$i][6] >= -5 Then	; *****20.04.2013
						$iInterStice=$a_CtrlDef[$i][6]-($a_CtrlDef[$iArrayCtrlInd][6] + $a_CtrlDef[$iArrayCtrlInd][8])
						$iY_Ctrl = $iPos + ($a_Ctrl[$iArrayCtrlInd][8]) + $iInterStice
						$iH_Ctrl = $a_Ctrl[$i][6] + $a_Ctrl[$i][8] - $iY_Ctrl
						If $CheckMinMax = True And $iPosMax > $a_Ctrl[$i][6] + $a_Ctrl[$i][8] - $a_Ctrl[$iArrayCtrlInd][8] Then
							$iPosMax = ($a_Ctrl[$i][6] + $a_Ctrl[$i][8]) - ($a_Ctrl[$iArrayCtrlInd][8] - $iInterStice)
						EndIf
						__MoveControl($hWnd, $a_Ctrl[$i][3], Default, $iY_Ctrl, $a_Ctrl[$i][7], $iH_Ctrl)
						$a_Ctrl[$i][12] = $iY_Ctrl
						$a_Ctrl[$i][14] = $iH_Ctrl
					EndIf
				EndIf
			Next
		EndIf
		$CheckMinMax = False
	WEnd

	GUICtrlSetBkColor($ResLab, $Color)

	For $i = 1 To UBound($a_Ctrl) - 1
		For $j = 5 To 8
			$a_Ctrl[$i][$j] = $a_Ctrl[$i][$j + 6]
		Next
	Next

	If $i_Opt_MinMaxWinSize=1 Then
		__GetMinMaxParameters($hWnd, $iMouseCursor)
	EndIf

	Return 1
EndFunc

; #FUNCTION# ====================================================================================================
; ���...............:  _ControlSetResizing
; ��������..........:  ������� ��������� ��������� ��������� ��� ��������� �������� GUI-����
; ���������.........:  _ControlSetResizing([$hCtrl, [$iResizing ]])
; ���������.........:  $hCtrl     - ����������/������������� �������� .(�������������� ��������. �� ��������� : -1)
;                      $iResizing - Resize-�������� (��������������. �� ��������� : $GUI_DOCKAUTO)
; �����. �������� ..:  �����      -  1
;                      �����      -  0
; �����.............:  gregaz.
; ===============================================================================================================
Func _ControlSetResizing($hCtrl = -1, $iResizing = $GUI_DOCKAUTO)
	If BitAND($iResizing, 262) = 262 Or BitAND($iResizing, 608) = 608 Then
		MsgBox(16, "$iResizing= " & $iResizing, "������������ ��������", 2)
		Return SetError(1, 0, 0)
	EndIf

	Local $hWind = __GetLastWindow()
	If @Error Then Return

	If $hCtrl = -1 Then
		$hCtrl = __GetLastControl($hWind)
	EndIf
	If @Error Then Return

	If IsHwnd($hCtrl) Then
		Local $iID = _WinAPI_GetDlgCtrlID($hCtrl)
		If GUICtrlGetHandle($iID) Then
			GUICtrlSetResizing($iID, $iResizing)
		EndIf
	Else
		GUICtrlSetResizing($hCtrl, $iResizing)
	EndIf

	Local $aWinPos = WinGetPos($hWind)
	Local $aClient = WinGetClientSize($hWind)
	Local $aCtrlPos = ControlGetPos($hWind, "", $hCtrl)
	If @Error Then Return SetError(2, 0, 0)

	$a_Ctrl[0][0] += 1
	ReDim $a_Ctrl[$a_Ctrl[0][0] + 1][UBound($a_Ctrl, 2)]

	$a_Ctrl[$a_Ctrl[0][0]][0] = $hWind ; ���������� ����
	$a_Ctrl[$a_Ctrl[0][0]][1] = $aClient[0] ; ClientWidth ����
	$a_Ctrl[$a_Ctrl[0][0]][2] = $aClient[1] ; ClientHeight ����
	$a_Ctrl[$a_Ctrl[0][0]][3] = $hCtrl ; ���������� ��������
	$a_Ctrl[$a_Ctrl[0][0]][4] = $iResizing ; �������� �-��  GUICtrlSetResizing
	$a_Ctrl[$a_Ctrl[0][0]][5] = $aCtrlPos[0] ; $XCtrl ��������
	$a_Ctrl[$a_Ctrl[0][0]][6] = $aCtrlPos[1] ; $YCtrl ��������
	$a_Ctrl[$a_Ctrl[0][0]][7] = $aCtrlPos[2] ; $WCtrl ��������
	$a_Ctrl[$a_Ctrl[0][0]][8] = $aCtrlPos[3] ; $HCtrl ��������
	$a_Ctrl[$a_Ctrl[0][0]][9] = ""; ������;  *** 13.03.2013           $iReaddress_Flag ; ���� ������������� �� �-��  GUICtrlSetResizing
	$a_Ctrl [$a_Ctrl [0][0]][10]=_WinAPI_GetClassName($hCtrl);$Class  (����� ��������)
	$a_Ctrl[$a_Ctrl[0][0]][11] = $aCtrlPos[0] ; $XCtrl_Current �������� (�������)
	$a_Ctrl[$a_Ctrl[0][0]][12] = $aCtrlPos[1] ; $YCtrl_Current  �������� (�������)
	$a_Ctrl[$a_Ctrl[0][0]][13] = $aCtrlPos[2] ; $WCtrl_Current  �������� (�������)
	$a_Ctrl[$a_Ctrl[0][0]][14] = $aCtrlPos[3] ; $HCtrl_Current  �������� (�������)
	;_ArrayDisplay($a_Ctrl , "$a_Ctrl")
	$a_CtrlDef = $a_Ctrl
	Return 1
EndFunc

; #FUNCTION# ====================================================================================================
; ���...............:  _InitGUI
; ��������..........:  ������������� ��������� GUI-����
; ���������.........: _InitGUI([$hWnd ])
; ���������.........:  $hWnd     - ���������� ���� .(�������������� ��������. �� ��������� : -1)
;
; �����. �������� ..:  �����      -  1
;                      �����      -  0
; �����.............:  gregaz.
; ===============================================================================================================
Func _InitGUI($hWnd = -1)
	Local $iInd_GUI, $ClassName, $iInd_GUI, $aWindow

	__CheckArray($a_GUI)

	If $hWnd = -1 Then
		$aWindow = _WinAPI_EnumProcessWindows(@AutoItPID, 0)
		If @Error Then Return
		;_ArrayDisplay($aWindow , "$aWindow")
		For $i = 1 To UBound($aWindow) - 1
			$ClassName = $aWindow[$i][1]
			If $ClassName = "AutoIt v3 GUI" Then
				$hWnd = $aWindow[$i][0]
				$iInd_GUI = __ArrayAddData($a_GUI, $hWnd)
				__InitControls($iInd_GUI)
				If $i_Opt_Autodetect_MinSize = 1 Then
					__GetMinMaxParameters($hWnd)
				EndIf
				If Not $i_Registered_WM_SIZE Then
					__RegisterMsg($hWnd)
				EndIf
			EndIf
		Next
	Else
		$iInd_GUI = __ArrayAddData($a_GUI, $hWnd)
		__InitControls($iInd_GUI)
		If $i_Opt_Autodetect_MinSize = 1 Then
			__GetMinMaxParameters($hWnd)
		EndIf
		If Not $i_Registered_WM_SIZE Then
			__RegisterMsg($hWnd)
		EndIf
	EndIf
	;_ArrayDisplay($a_GUI , "$a_GUI")
	;_ArrayDisplay($a_Ctrl , "$a_Ctrl")
	ConsoleWrite('������������� ' & UBound($a_GUI)-1 & '-� ���� ���������--- >' & @CRLF) ; & '<<>>' &
	Return 1
EndFunc

; #FUNCTION# ====================================================================================================
; ���...............:  _Register_WM_SIZE
; ��������..........:  ����������� ������� �-�� WM_SIZE ������ �������� �������
; ���������.........: _Register_WM_SIZE($sFunc)
; ���������.........:  $sFunc     - ��� �������� ������� WM_SIZE
;
; �����. �������� ..:  �����������
; �����.............:  gregaz.
; ===============================================================================================================
Func _Register_WM_SIZE($sFunc)
	$s_External_WM_SIZE_Func = $sFunc
EndFunc

; #FUNCTION# ====================================================================================================
; ���...............:  _SetGUI_MinSize
; ��������..........:  ��������� ���������� ���������� �������� ��������� �������� GUI ����
; ���������.........: _SetGUI_MinSize($hWnd, $iWidth='', $iHeight='')
; ���������.........:  $hWnd     - ���������� ����.
;                      $iWidth   - ���������� ���������� ������ ���� (�������������� ��������. �� ��������� : 0)
;                      $iHeight  - ���������� ���������� ������ ���� (�������������� ��������. �� ��������� : 0)
; �����. �������� ..:  �����������
; �����.............:  gregaz.
; ===============================================================================================================
Func _SetGUI_MinSize($hWnd, $iWidth='', $iHeight='')
	Local $iIndexGui = __ArrayAddData($a_GUI, $hWnd)
	$a_GUI[$iIndexGui][5]=$iWidth
	$a_GUI[$iIndexGui][6]=$iHeight
EndFunc
#EndRegion External Functions

#Region Internal Functions
;~ -  __ArrayAddData           ��������� �������� � ������
;~ -  __ArrayUpdateHeight      ���������� ���������� ������ ���������  �������
;~ -  __ArrayUpdateWidth       ���������� ���������� ������ ���������  �������
;~ -  __CheckArray             �������� ������� ���� �� �� �������������
;~ -  __CheckCtrlArray         ������������� ������� ���������
;~ -  __GetLastControl         ��������� ���������� ���������� ��������
;~ -  __GetLastWindow          ��������� ���������� ���������� ����
;~ -  __GetMinMaxParameters    ��������������� ����������� �������� GUI ����
;~ -  __InitControls           ������������� ���������
;~ -  __MoveControl            ����������� ���������

;~ -  __RegisterMsg            ����������� ���������� WM-�������
;~ -  __WM_GETMINMAXINFO       ���������� �-��  WM_GETMINMAXINFO
;~ -  __WM_NCHITTEST           ���������� �-��  WM_NCHITTEST(��������� �������� � ���������� ����  � ������������� �� ���������.)
;~ -  __WM_SIZe                ���������� �-��  WM_SIZE

;==================================================
; ��������� �������� � ������
;==================================================
Func __ArrayAddData(ByRef $aArray, $sData)
	Local $iIndGUI = _ArraySearch($aArray, $sData, 1)
	If @Error Then
		$aArray[0][0] += 1
		ReDim $aArray[$aArray[0][0] + 1][UBound($aArray, 2)]
		$aArray[$aArray[0][0]][0] = $sData ; ���������� ����
		$iIndGUI = $aArray[0][0]
	EndIf
	Return $iIndGUI
EndFunc

;==================================================
; ���������� ���������� ������ ���������  �������
;==================================================
Func __ArrayUpdateHeight($hWnd, $iHeight)
	For $i = 1 To UBound($a_Ctrl) - 1
		If $a_Ctrl[$i][0]= $hWnd Then
			$a_Ctrl[$i][2] = $iHeight
			$a_Ctrl[$i][6] = $a_Ctrl[$i][12]
			$a_Ctrl[$i][8] = $a_Ctrl[$i][14]
		EndIf
	Next
EndFunc

;==================================================
; ���������� ���������� ������ ���������  �������
;==================================================
Func __ArrayUpdateWidth($hWnd, $iWidth)
	For $i = 1 To UBound($a_Ctrl) - 1
		If $a_Ctrl[$i][0]= $hWnd Then
			$a_Ctrl[$i][1] = $iWidth
			$a_Ctrl[$i][5] = $a_Ctrl[$i][11]
			$a_Ctrl[$i][7] = $a_Ctrl[$i][13]
		EndIf
	Next
EndFunc

;==================================================
; �������� ������� ���� �� �� �������������
; ��� ��������� ��������������� ���� ��� ���������
; �� ������� � ����������� ������������� ������� ���������
;==================================================
Func __CheckArray(ByRef $aArray)
	For $i = UBound($aArray) - 1 To 1 Step -1
		If Not WinExists($aArray[$i][0]) Then
			__CheckCtrlArray($a_Ctrl, $aArray[$i][0])
			_ArrayDelete($aArray, $i)
			$aArray[0][0] -= 1
		EndIf
	Next
EndFunc

;==================================================
;������������� ������� ��������� � ��������� ���������
;�������������� ����
;==================================================
Func __CheckCtrlArray(ByRef $aArray, $hGUI)
	For $i = UBound($aArray) - 1 To 1 Step -1
		If $aArray[$i][0] = $hGUI Then
			_ArrayDelete($aArray, $i)
			$aArray[0][0] -= 1
		EndIf
	Next
EndFunc

;==================================================
; ��������� ���������� ���������� ��������
;==================================================
Func __GetLastControl($hWnd)
	Local $aChild = _WinAPI_EnumChildWindows($hWnd, 0)
	If @Error Then Return SetError(1, 0, 0)
	$hParent = _WinAPI_GetParent($aChild[$aChild[0][0]][0])
	If $hParent = $hWnd Then
		Return $aChild[$aChild[0][0]][0]
	Else
		Return $hParent
	EndIf
EndFunc

;==================================================
; ��������� ���������� ���������� ����
;==================================================
Func __GetLastWindow()
	Local $aWins = _WinAPI_EnumProcessWindows(@AutoItPID, 0)
	If @Error Then Return SetError(1, 0, 0)
	For $i = 1 To $aWins[0][0]
		If $aWins[$i][1] <> "AutoIt v3 GUI" Then ContinueLoop
		ExitLoop
	Next
	Return $aWins[$i][0]
EndFunc

;==================================================
; ��������������� ����������� �������� GUI ����
;==================================================
Func __GetMinMaxParameters($hWnd, $iMouseCursor = '')
	Local $iIndGui = _ArraySearch($a_Gui, $hWnd, 1)
	If $iIndGui = -1 Then Return

	Local $iIndex = _ArraySearch($a_Ctrl, $hWnd, 1)
	If @Error Then Return

	Local $iClientWidth = $a_Ctrl[$iIndex][1]
	Local $iBorder_Width = $a_Gui[$iIndGui][3]
	Local $iClientHeight = $a_Ctrl[$iIndex][2]
	Local $iCaption_Height = $a_GUI[$iIndGui][4]

	Local $iWidthMin_Ctrl = $iClientWidth + $iBorder_Width
	Local $iHeightMin_Ctrl = $iClientHeight + $iCaption_Height

	For $i = 1 To UBound($a_Ctrl) - 1
		If $a_Ctrl[$i][0] <> $hWnd Then ContinueLoop
		Local $hCtrl = $a_Ctrl[$i][3]
		Local $iResizing = $a_Ctrl[$i][4]
		If $iMouseCursor <> 11 Then
			If BitAND($iResizing, 256) Then ; $GUI_DOCKWIDTH
				If BitAND($iResizing, 4) Or BitAND($iResizing, 128) Then
					If $a_Ctrl[$i][5] < $iWidthMin_Ctrl Then ; �������� X
						$iWidthMin_Ctrl = $a_Ctrl[$i][5]
					EndIf
				EndIf
				If BitAND($iResizing, 2) Then ; $GUI_DOCKLEFT
					If $a_Ctrl[$i][1] - ($a_Ctrl[$i][5] + $a_Ctrl[$i][7]) < $iWidthMin_Ctrl Then
						$iWidthMin_Ctrl = $a_Ctrl[$i][1] - ($a_Ctrl[$i][5] + $a_Ctrl[$i][7]) ; �������� X+W
					EndIf
				EndIf
			Else
				If BitAND($iResizing, 2) And BitAND($iResizing, 4) Then ; $GUI_DOCKLEFT �  $GUI_DOCKRIGHT
					If $a_Ctrl[$i][7] < $iWidthMin_Ctrl Then
						$iWidthMin_Ctrl = $a_Ctrl[$i][7] ; �������� W
					EndIf
				EndIf
			EndIf
		EndIf

		If $iMouseCursor <> 13 Then
			If BitAND($iResizing, 512) Then
				If BitAND($iResizing, 64) Or BitAND($iResizing, 8) Then
					If $a_Ctrl[$i][6] < $iHeightMin_Ctrl Then
						$iHeightMin_Ctrl = $a_Ctrl[$i][6] ; �������� Y
					EndIf
				EndIf
				If BitAND($iResizing, 32) Then
					If $a_Ctrl[$i][2] - ($a_Ctrl[$i][6] + $a_Ctrl[$i][8]) < $iHeightMin_Ctrl Then
						$iHeightMin_Ctrl = $a_Ctrl[$i][2] - ($a_Ctrl[$i][6] + $a_Ctrl[$i][8]) ; �������� Y+H
					EndIf
				EndIf
			Else
				If BitAND($iResizing, 32) And BitAND($iResizing, 64) Then
					If $a_Ctrl[$i][8] < $iHeightMin_Ctrl Then
						$iHeightMin_Ctrl = $a_Ctrl[$i][8] ; �������� H
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	If $iMouseCursor <> 11 Then
		$a_GUI[$iIndGui][1] =($iClientWidth + $iBorder_Width) - $iWidthMin_Ctrl
	EndIf
	If $iMouseCursor <> 13 Then
		$a_GUI[$iIndGui][2] =($iClientHeight + $iCaption_Height) - $iHeightMin_Ctrl
	EndIf
	Return 1
EndFunc

;=======================================
; ������������� ���������
;=======================================
Func __InitControls($iInd_GUI)
	Local $hWnd, $hCtrl, $hParent, $iIndexCtrl, $aCtrlPos
	$hWnd = $a_GUI[$iInd_GUI][0]
	Local $aWinPos = WinGetPos($hWnd)
	If @Error Then Return SetError(1, 0, 0)
	Local $aClient = WinGetClientSize($hWnd)
	$a_GUI[$iInd_GUI][3] = $aWinPos[2] - $aClient[0] ;$iBorder_Width (����� �� X) ����
	$a_GUI[$iInd_GUI][4] = $aWinPos[3] - $aClient[1] ;$iCaption_Height (����� ��  Y) ����

	Local $aChild = _WinAPI_EnumChildWindows($hWnd, 0)
	If @Error Then Return SetError(1, 0, 0)
	;_ArrayDisplay($aChild, '$aChild')
	For $j = 1 To $aChild[0][0]
		$hCtrl = $aChild[$j][0]
		$hParent = _WinAPI_GetParent($hCtrl)
		If $hParent <> $hWnd Then
			ContinueLoop ; ���������� SysHeader32 ��� ListView � �.�.
		EndIf
		$iIndexCtrl = _ArraySearch($a_Ctrl, $hCtrl, 1, 0, 0, 3)
		If @Error Then
			$aCtrlPos = ControlGetPos($hWnd, "", $hCtrl)
			$a_Ctrl[0][0] += 1
			ReDim $a_Ctrl[$a_Ctrl[0][0] + 1][UBound($a_Ctrl, 2)]
			$iIndexCtrl = $a_Ctrl[0][0]
			$a_Ctrl[$iIndexCtrl][0] = $hWnd ; ���������� ����
			$a_Ctrl[$iIndexCtrl][1] = $aClient[0] ; ������ ���������� ������� ����
			$a_Ctrl[$iIndexCtrl][2] = $aClient[1] ; ������ ���������� ������� ����
			$a_Ctrl[$iIndexCtrl][3] = $hCtrl ; ���������� ��������
			If $a_Ctrl[$iIndexCtrl][4] = '' Then
				$a_Ctrl[$iIndexCtrl][4] = Opt("GUIResizeMode") ; Resizing-��������
			EndIf
			$a_Ctrl[$iIndexCtrl][5] = $aCtrlPos[0] ;$XCtrl
			$a_Ctrl[$iIndexCtrl][6] = $aCtrlPos[1] ;$YCtrl
			$a_Ctrl[$iIndexCtrl][7] = $aCtrlPos[2] ;$WCtrl
			$a_Ctrl[$iIndexCtrl][8] = $aCtrlPos[3] ;$HCtrl

			$a_Ctrl[$iIndexCtrl][10] = _WinAPI_GetClassName($hCtrl) ;������ (��� ������ ��������)
			$a_Ctrl[$iIndexCtrl][11] = $aCtrlPos[0] ;$XCtrl_Current
			$a_Ctrl[$iIndexCtrl][12] = $aCtrlPos[1] ;$YCtrl_Current
			$a_Ctrl[$iIndexCtrl][13] = $aCtrlPos[2] ;$WCtrl_Current
			$a_Ctrl[$iIndexCtrl][14] = $aCtrlPos[3] ;$HCtrl_Current
		EndIf
	Next
	$a_CtrlDef = $a_Ctrl
	Return 1
EndFunc

;==================================================
; ����������� �������� GUI
;==================================================
Func __MoveControl($hWnd, $hCtrl, $X=Default, $Y=Default, $W='', $H=Default)
	Local $iID=_WinAPI_GetDlgCtrlID($hCtrl)

	If GUICtrlGetHandle ($iID)  Then
		GUICtrlSetPos($iID, $X, $Y, $W, $H)
	Else
		If $H=Default Then
			ControlMove($hWnd, "", $hCtrl, $X, $Y, $W)
		Else
			ControlMove($hWnd, "", $hCtrl, $X, $Y, $W, $H)
		EndIf
	EndIf
EndFunc

;==================================================
; ����������� ���������� WM-�������
;==================================================
Func __RegisterMsg($hWind)
	Local $Style = _WinAPI_GetWindowLong($hWind, $GWL_STYLE)
	If BitAND($Style, $WS_SIZEBOX) = $WS_SIZEBOX Then
		GUIRegisterMsg($WM_GETMINMAXINFO, "__WM_GETMINMAXINFO")
		GUIRegisterMsg($WM_SIZE, "__WM_SIZe")
		$i_Registered_WM_SIZE = 1
	EndIf
EndFunc

;==================================================
;  ���������� �-��  WM_GETMINMAXINFO
;==================================================
Func __WM_GETMINMAXINFO($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam
	Local $iInd_GUI = _ArraySearch($a_GUI, $hWnd, 1)
	If @Error Then Return $GUI_RUNDEFMSG

	If  $i_Opt_Autodetect_MinSize=0  Then ;16.04.2013
		$a_GUI[$iInd_GUI][1]=0
		$a_GUI[$iInd_GUI][2]=0
	Else
		__GetMinMaxParameters($hWnd)
	EndIf
	Local $iWIdthMin, $iHeightMin
	If $a_GUI[$iInd_GUI][1]>= $a_GUI[$iInd_GUI][5] Then
		$iWIdthMin=$a_GUI[$iInd_GUI][1]
	Else
		$iWIdthMin=$a_GUI[$iInd_GUI][5]
	EndIf
	If $a_GUI[$iInd_GUI][2]>= $a_GUI[$iInd_GUI][6] Then
		$iHeightMin=$a_GUI[$iInd_GUI][2]
	Else
		$iHeightMin=$a_GUI[$iInd_GUI][6]
	EndIf

	Local $tMINMAXINFO = DllStructCreate("int;int;" & _
			"int MaxSizeX; int MaxSizeY;" & _
			"int MaxPositionX;int MaxPositionY;" & _
			"int MinTrackSizeX; int MinTrackSizeY;" & _
			"int MaxTrackSizeX; int MaxTrackSizeY", _
			$lParam)

	DllStructSetData($tMINMAXINFO, "MinTrackSizeX", $iWIdthMin)
	DllStructSetData($tMINMAXINFO, "MinTrackSizeY", $iHeightMin)
	Return $GUI_RUNDEFMSG
EndFunc

;==================================================
;  ���������� �-�� WM_NCHITTEST
;==================================================
Func __WM_NCHITTEST($hWnd, $Msg, $wParam, $lParam)
	If $Init=False Then
		$Init=True
		_InitGUI()
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

;==================================================
;  ���������� �-��  WM_SIZE
;==================================================
Func __WM_SIZe($hWnd, $nMsg, $wParam, $lParam)
	Local $Return = Call($s_External_WM_SIZE_Func, $hWnd, $nMsg, $wParam, $lParam)
	If $Return <> 'GUI_RUNDEFMSG' Then Return $Return

	Local $iMouseCursor, $iGUI_Width, $iGUI_Height, $iGUI_Width_Default,$iGUI_Height
	Local $hCtrl, $iResizing, $iRightMargin, $iWidthCtrl,$iBottomMargin,$iHeightCtrl

	$iMouseCursor = MouseGetCursor()

	If $iMouseCursor<>11 Then ;Gorizontal SIZE
		$iGUI_Width = _WinAPI_LoWord($lParam)
		If $iGUI_Width=0 Then Return
		For $i = 1 To UBound($a_Ctrl)-1
			If $a_Ctrl[$i][0]= $hWnd Then
				$hCtrl = $a_Ctrl[$i][3]
				$iResizing = $a_Ctrl[$i][4]
				$iGUI_Width_Default = $a_Ctrl[$i][1]
				If BitAND($iResizing, 2) Then ;$GUI_DOCKLEFT
					If BitAND($iResizing, 4) Then ;$GUI_DOCKRIGHT
						$a_Ctrl[$i][13]=$a_Ctrl[$i][7] + ($iGUI_Width - $iGUI_Width_Default)
					ElseIf Not BitAND($iResizing, 256) Then ;<>$GUI_DOCKWIDTH
						$a_Ctrl[$i][13]=$a_Ctrl[$i][7]* ($iGUI_Width / $iGUI_Width_Default)
					EndIf
				ElseIf BitAND($iResizing, 4) Then ;$GUI_DOCKRIGHT
					If BitAND($iResizing, 256) Then ;$GUI_DOCKWIDTH
						$a_Ctrl[$i][11]=$a_Ctrl[$i][5]+($iGUI_Width-$iGUI_Width_Default)
					Else
						$iRightMargin=$iGUI_Width_Default-($a_Ctrl[$i][5]+$a_Ctrl[$i][7])
						$a_Ctrl[$i][13]=$a_Ctrl[$i][7] * ($iGUI_Width / $iGUI_Width_Default)
						$a_Ctrl[$i][11]=$iGUI_Width-$iRightMargin-$a_Ctrl[$i][13]
					EndIf
				ElseIf BitAND($iResizing, 256) Then ;$GUI_DOCKWIDTH
					If BitAND($iResizing, 8) Then ;$GUI_DOCKHCENTER
						$a_Ctrl[$i][11]=($iGUI_Width - $iGUI_Width_Default) / 2 + $a_Ctrl[$i][5]
					ElseIf $a_CtrlDef[$i][5]>$a_CtrlDef[$i][1] / 2 Then
						$iXOffSet = ($a_CtrlDef[$i][1] - ($a_CtrlDef[$i][5] + $a_CtrlDef[$i][7])) * ($iGUI_Width / $a_CtrlDef[$i][1])
						$a_Ctrl[$i][11]=Ceiling($iGUI_Width - ($iXOffSet + $a_Ctrl[$i][7]))
					Else
						$a_Ctrl[$i][11]=$a_Ctrl[$i][5]* ($iGUI_Width / $iGUI_Width_Default)
					EndIf
				Else
					$a_Ctrl[$i][11]=$a_Ctrl[$i][5]* ($iGUI_Width / $iGUI_Width_Default)
					$a_Ctrl[$i][13]=$a_Ctrl[$i][7]* ($iGUI_Width / $iGUI_Width_Default)
				EndIf

				If Not GUICtrlGetHandle(_WinAPI_GetDlgCtrlID($hCtrl)) Then
					ControlMove($hWnd, "", $hCtrl, $a_Ctrl[$i][11], $a_Ctrl[$i][12], $a_Ctrl[$i][13], $a_Ctrl[$i][14])
				EndIf
			EndIf
		Next
		__ArrayUpdateWidth($hWnd, $iGUI_Width)
	EndIf

	If $iMouseCursor<>13 Then ;Vertical SIZE
		$iGUI_Height = _WinAPI_HiWord($lParam)
		If $iGUI_Height=0 Then Return
		For $i = 1 To UBound($a_Ctrl)-1
			If $a_Ctrl[$i][0]= $hWnd Then
				$hCtrl = $a_Ctrl[$i][3]
				$iResizing = $a_Ctrl[$i][4]
				$iGUI_Height_Default = $a_Ctrl[$i][2]
				If BitAND($iResizing, 32) Then ;$GUI_DOCKTOP
					If BitAND($iResizing, 64) Then ;$GUI_DOCKBOTTOM
						$a_Ctrl[$i][14]=$a_Ctrl[$i][8]+($iGUI_Height - $iGUI_Height_Default)
					ElseIf Not BitAND($iResizing, 512) Then ;<>$GUI_DOCKHEIGHT
						$a_Ctrl[$i][14]=$a_Ctrl[$i][8] * ($iGUI_Height / $iGUI_Height_Default)
					EndIf
				ElseIf BitAND($iResizing, 64) Then ;$GUI_DOCKBOTTOM
					If BitAND($iResizing, 512) Then ;$GUI_DOCKHEIGHT
						$a_Ctrl[$i][12]=$a_Ctrl[$i][6]+($iGUI_Height -$iGUI_Height_Default)
					Else
						$iBottomMargin=$iGUI_Height_Default-($a_Ctrl[$i][6]+$a_Ctrl[$i][8])
						$a_Ctrl[$i][14]=$a_Ctrl[$i][8] * ($iGUI_Height / $iGUI_Height_Default)
						$a_Ctrl[$i][12]=$iGUI_Height - $iBottomMargin-$a_Ctrl[$i][14]
					EndIf
				ElseIf BitAND($iResizing, 512) Then ;$GUI_DOCKHEIGHT
					If BitAND($iResizing, 128) Then ;$GUI_DOCKVCENTER
						$a_Ctrl[$i][12]=($iGUI_Height - $iGUI_Height_Default) / 2 + $a_Ctrl[$i][6]
					Else
						If $a_CtrlDef[$i][6]>$a_CtrlDef[$i][2] / 2 Then
							$iYOffSet= ($a_CtrlDef[$i][2] - ($a_CtrlDef[$i][6] + $a_CtrlDef[$i][8])) * ($iGUI_Height / $a_CtrlDef[$i][2])
							$a_Ctrl[$i][12]=Ceiling($iGUI_Height - ($iYOffSet + $a_Ctrl[$i][8]))
						Else
							$a_Ctrl[$i][12]=$a_Ctrl[$i][6]* ($iGUI_Height / $iGUI_Height_Default)
						EndIf
					EndIf
				Else
					$a_Ctrl[$i][12]=$a_Ctrl[$i][6]* ($iGUI_Height / $iGUI_Height_Default)
					$a_Ctrl[$i][14]=$a_Ctrl[$i][8]* ($iGUI_Height / $iGUI_Height_Default)
				EndIf

				If Not GUICtrlGetHandle(_WinAPI_GetDlgCtrlID($hCtrl)) Then
					ControlMove($hWnd, "", $hCtrl, $a_Ctrl[$i][11], $a_Ctrl[$i][12], $a_Ctrl[$i][13], $a_Ctrl[$i][14])
				EndIf
			EndIf
		Next
		__ArrayUpdateHeight($hWnd, $iGUI_Height )
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc
#EndRegion Internal Functions