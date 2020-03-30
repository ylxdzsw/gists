#NoEnv
#Warn
SendMode Input
SetWorkingDir C:\Users\%A_UserName%
setcapslockstate alwaysoff
capsCD := A_tickcount - 200
HCD := A_TickCount - 1000

capslock & esc::Reload

RShift::Return
LControl::LAlt
LAlt::LControl

~!capslock UP::
~^capslock UP::
~capslock UP::
	if (A_tickcount - capsCD > 200)
	{
		keywait, capslock , D T0.1
		if ErrorLevel
			return
		else
		{
			capsCD := A_tickcount
			if getkeystate("capslock","T")
				setcapslockstate alwaysoff
			else
				setcapslockstate alwayson
		}
	}
	return

capslock & c::
	state := getkeystate("ctrl") or getkeystate("alt")
	if state
	{
		WinGetPos,,, Width, Height, A
		WinMove, A,, (A_ScreenWidth/2)-(Width/2), (A_ScreenHeight/2)-(Height/2)-14
	}
	return

capslock & t::
	state := getkeystate("ctrl") or getkeystate("alt")
	if state
	{
		Winset, AlwaysOnTop,,A
	}
	return

capslock & w::send {up}
capslock & s::send {down}
capslock & a::send {left}
capslock & d::
	state := getkeystate("ctrl") or getkeystate("alt")
	if state
	{
		run ","
	}
	Else
	{
		send {right}
	}
	return
capslock & q::send {home}
capslock & e::send {end}
capslock & f::
	state := getkeystate("ctrl") or getkeystate("alt")
	if state
	{
		run C:\Users\%A_UserName%\fuck-project
	}
	Else
	{
		send {PgDn}
	}
	return
capslock & r::send {pgup}

capslock & j::send {BackSpace}
capslock & k::send {Del}
capslock & u::send ^z
capslock & i::send ^+z
capslock & h::
	KeyWait, h, T1
	if ErrorLevel
	{
		HCD := A_TickCount
		Send, ^+m
	}
	else if (A_tickcount - HCD > 1000)
		Send, ^m
	return
capslock & space::send ^{right}
capslock & enter::
	send {down}
	send {home}
	return
capslock & Numpad4::
	Send {Media_Prev}
	return
capslock & Numpad5::
	Send {Media_Play_Pause}
	return
capslock & Numpad6::
	Send {Media_Next}
	Return
capslock & Numpad8::
	Send {Volume_Up}
	Return
CapsLock & Numpad2::
	Send {Volume_Down}
	return

XButton2::
	Send ^{PgDn}
	return
XButton1::
	Send #{Tab}
	return
