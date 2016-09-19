#include<GUIConstants.au3>
#include<GUIConstantsEx.au3>
#include<GuiIPAddress.au3>

Opt("GUIOnEventMode", 1)

$hGUI = GUICreate("Test", 300, 200)
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEButton")

$g_hIPAddress = _GUICtrlIpAddress_Create($hGui, 10, 10, 150, 20)
_GUICtrlIpAddress_Set($g_hIPAddress, "24.168.2.128")
$hTestButton = GUICtrlCreateButton("Test", 10, 40, 40, 20)
GUICtrlSetOnEvent($hTestButton, "Test_Button")

GUISetState(@SW_SHOW)

While 1
   Sleep(100)
WEnd

Func CLOSEButton()
   TCPShutdown()
   Exit
EndFunc ;==>CLOSEButton

Func Test_Button()
   MsgBox(64, "Test", _GUICtrlIpAddress_Get($g_hIPAddress))
EndFunc