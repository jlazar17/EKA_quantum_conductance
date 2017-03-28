#pragma rtGlobals=1		// Use modern global access method.
//#include ":NIDAQ Procedures:NIDAQ Wave Scan Procs"
//#include ":NIDAQ Procedures:NIDAQ WaveForm Gen Procs"
//#include ":IFDL v4 Procedures:IFDL Apply Filter"
//#include ":IFDL v4 Procedures:IFDL"
//#include <Differentiate XY> 


macro StartupDAQ()
	InitializeDAQ()
	MakePath()
	Current_Measurement()
	Actuator_Control()
//	Meter()
	InitializeGPIB(" ") 

Constant K_G0 = 77.5	// Quantum conductance in micro S
Constant K_ZPiezoScale = 62
Constant K_XPiezoScale = 522
Constant K_SenseScale = 314

end
macro Current_Panel()
	Current_Measurement()
//	Meter()
end

Function InitializeDAQ()
NewDataFolder/O root:Data
SetDataFolder root:Data //changed from 'Data' -- arun
DoWindow/T kwFrame, "Startup"

//************************************** Define Global Variables **************************************
//Variable/G root:Data:G_PiezoType=0 // 0 -> Julio's , 1 -> MadCityLabs


// PXI Variables
Variable/G root:Data:G_ExtensionGain=0	// in dB			
Variable/G root:Data:G_CurrentGain=0	// in dB
Variable/G root:Data:G_AcquisitionRate = 40000
Variable/G root:Data:G_CardTimeout=10;
Variable/G root:Data:G_MinNumPointsOutput=1000;
Variable/G root:Data:G_DeviceON=0;
Variable/G root:Data:G_OD1;
Variable/G root:Data:G_ID1;
Variable/G root:Data:G_ID2;
Variable/G root:Data:G_ID3;
Variable/G root:Data:G_OD2;
Variable/G root:Data:G_OD3;


// General Variables
Variable/G root:Data:G_ExcursionOffset=0		// in nm and MUST BE LARGER THAN EXCURSION SIZE when used with unipolar piezos, zero with bipolar piezo!!!!
Variable/G root:Data:G_PointsPerTrace=10000
Variable/G root:Data:G_SaveCheck=0 // if 0, then save all data
Variable/G root:Data:G_Z_Step_Size=5 //nm
Variable/G root:Data:G_Actual_Current =0
Variable/G root:Data:G_Actual_Bias = 0
Variable/G root:Data:G_MaxCurrent=0
Variable/G root:Data:G_SenseMeter=0
Variable/G root:Data:G_PiezoOutMeter=0
Variable/G root:Data:G_MaxPiezoOut = 0
Variable/G root:Data:G_MeasureOn
Variable/G root:Data:G_MaxSense=0
Variable/G root:Data:G_BeepOn=0
Variable/G root:Data:G_ExternalBiasCheck=1
Variable/G root:Data:G_X_Offset=0;
Variable/G root:Data:G_JunctionBias = 0;
Variable/G root:Data:G_JunctionRes = 0;

// FX Variables
Variable/G root:Data:G_ExcursionSize=20			// in nm
Variable/G root:Data:G_ExcursionRate=40			// in nm/s
Variable/G root:Data:G_MeasuredExcursionRate		// in nm/s
Variable/G root:Data:G_WriteFileNumber=0
Variable/G root:Data:G_Count_Recordings=0

// PullOut Variables
Variable/G root:Data:G_MaxExcursion = 5	// nm
Variable/G root:Data:G_EngageConductance = 5 // microS 
Variable/G root:Data:G_EngageCurrent = 2
//Variable/G root:Data:G_EngageStepSize = 1 //nm
Variable/G root:Data:G_EngageStepSize = .5 //nm; changed to .5 on 3/11/09 (MK)
Variable/G root:Data:G_EngageDelay = 0 // ms
Variable/G root:Data:G_PullOutNumber=0 // NW changed on 4/26/16 from 1 to 0. This variable correlates with #saved and when it is initially not zero the system will not save any data
Variable/G root:Data:G_PullOutAttempt=0
Variable/G root:Data:G_PullOutRate=20 // nm/s
Variable/G root:Data:G_EngageSetPoint=0.1
Variable/G root:Data:G_PullOutFail=0
Variable/G root:Data:G_StopNumber=10
Variable/G root:Data:G_ZeroCutOff=0.0001
Variable/G root:Data:G_XOffsetSwitch=0
Variable/G root:Data:G_BiasSaveCheck=0
Variable/G root:Data:G_SenseSaveCheck=0
Variable/G root:Data:G_SeriesResistance=10110
Variable/G root:Data:G_SmashNumber=20
Variable/G root:Data:G_XOffsetNumber=50
Variable/G root:Data:G_N2=0
Variable/G root:Data:G_N3=0
Variable/G root:Data:G_N1=0

Variable/G root:Data:G_Vac=0.1
Variable/G root:Data:G_Vdc=0
Variable/G root:Data:G_Sfreq=1432
Variable/G root:Data:G_nloopf
Variable/G root:Data:G_BlockCreated=0
Variable/G root:Data:G_CVBlockCreated=0
Variable/G root:Data:G_SBlockCreated=0



// IV Converter Variables
Variable/G root:Data:G_CurrentVoltGain = 6
Variable/G root:Data:G_CurrentVoltConversion=1		// microAmps per Volt
Variable/G root:Data:G_TipBias=25 // Bias in mV
Variable/G root:Data:G_DeviceUD = 0 // Device ID for IV converter
Variable/G root:Data:G_BoardUD = 0 // Board ID for GPIB IV converter
Variable/G root:Data:G_RiseTime = 0.01 // Filter Rise time for IV converter in milliseconds
Variable/G root:Data:G_CurrentSuppress = -0.0009 // search for 17.15 (3 times) and replace with new number if changing
Variable/G root:Data:G_VoltageOffset=0
Variable/G root:Data:G_CurrentSuppressConst = -.3

//Actuator Variables
Variable/G root:Data:AStepSize=1
Variable/G root:Data:AJogSpeed=0
String/G root:Data:APositionInSteps="115000"
String/G root:Data:AStatus
String/G root:Data:AError
Variable/G root:Data:AMotorStatus=0

End

Function MakePath()
Variable Okay,n
String today,month,day,year
Variable datenum

		today=Date()
		n=strsearch(today,",",0)
		today=today[n+2,inf]
		month=today[0,2]
		if (stringmatch(month,"jan")==1)
			month="01_"
		elseif (stringmatch(month,"feb")==1)
			month="02_"	
		elseif (stringmatch(month,"mar")==1)
			month="03_"
		elseif (stringmatch(month,"apr")==1)
			month="04_"	
		elseif (stringmatch(month,"may")==1)
			month="05_"
		elseif (stringmatch(month,"jun")==1)
			month="06_"
		elseif (stringmatch(month,"jul")==1)
		       month="07_"
		elseif (stringmatch(month,"aug")==1)
			month="08_"
		elseif (stringmatch(month,"sep")==1)
			month="09_"
		elseif (stringmatch(month,"oct")==1)
			month="10_"
		elseif (stringmatch(month,"nov")==1)
			month="11_"
		elseif (stringmatch(month,"dec")==1)
			month="12_"
		endif
		n=strsearch(today,",",0)
		day=today[4,n-1]+"_"
		year="14"
		today=month+day+year
		print today
		
		//NewPath/C Relocate "D:Experiments:"+today+"Waves:"
		NewPath/C Relocate2 "C:Experiments:"+today+"Merge:"
//		NewPath/C Backup "L:"+today+"Waves:"
		Print "New Path - Relocate - Created"
//		Print "New Path - Backup - Created"
end

Window Current_Measurement() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1324,57,1675,767)
	ModifyPanel frameStyle=1
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv save
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 95,487,"I (uA)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 172,487,"Min/Max"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 250,487,"Piezo (V)"
	SetDrawEnv fsize= 14,fstyle= 1
	// NW removed on 4/26/16 because these calculations don't work and aren't needed. Always show 0 which is confusing to an experimenter
	// DrawText 77,536,"Junc Volt (V)" 
	SetDrawEnv fsize= 14,fstyle= 1
	// NW removed on 4/26/16 because these calculations don't work and aren't needed. Always show 0 which is confusing to an experimenter
	//DrawText 184,536,"Junc Cond (G0)"
	Button button0,pos={250,50},size={60,40},disable=1,proc=Get_FX,title="get FX"
	Button button0,labelBack=(32768,54528,65280),fColor=(32768,54528,65280)
	SetVariable setvar20,pos={40,100},size={150,16},disable=1,title="amplitude (nm)         "
	SetVariable setvar20,limits={0,1000,1},value= root:Data:G_ExcursionSize
	SetVariable setvar18,pos={40,50},size={150,16},disable=1,title="pulling rate (nm/s)"
	SetVariable setvar18,limits={0.1,1000,100},value= root:Data:G_ExcursionRate
	SetVariable setvar10,pos={179,246},size={75,16},title="Z (nm)"
	SetVariable setvar10,limits={0,100,0.01},value= root:Data:G_Z_Step_Size
	SetVariable setvar23,pos={40,150},size={75,16},disable=1,title="# count"
	SetVariable setvar23,format="%d"
	SetVariable setvar23,limits={0,10000,0},value= root:Data:G_Count_Recordings
	SetVariable setvar6,pos={43,134},size={140,16},title="Points in Trace       "
	SetVariable setvar6,limits={-inf,inf,0},value= root:Data:G_PointsPerTrace
	SetVariable setvar19,pos={40,75},size={152,16},disable=1,title="measured rate (nm/s)"
	SetVariable setvar19,format="%3.1f"
	SetVariable setvar19,limits={-inf,inf,0},value= root:Data:G_MeasuredExcursionRate
	CheckBox check3,pos={262,247},size={57,14},proc=SaveAll,title="Save All"
	CheckBox check3,value= 0
	SetVariable setvar24,pos={119,150},size={75,16},disable=1,title="# saved"
	SetVariable setvar24,limits={-inf,inf,0},value= root:Data:G_WriteFileNumber
	SetVariable setvar7,pos={43,179},size={138,16},title="Extension Gain (dB) "
	SetVariable setvar7,limits={0,30,10},value= root:Data:G_ExtensionGain
	Button button5,pos={250,130},size={60,40},disable=1,proc=SaveFX,title="save FX"
	Button button5,labelBack=(32768,54528,65280),fColor=(32768,54528,65280)
	Slider Pos_Z,pos={26,270},size={300,53},disable=2,proc=Offset
	Slider Pos_Z,font="Times New Roman",fSize=12
	Slider Pos_Z,limits={-10,10,0.01},value= 0,live= 0,vert= 0,ticks= 20
	SetVariable setvar5,pos={43,156},size={138,16},title="Current Gain (dB)    "
	SetVariable setvar5,limits={0,30,10},value= root:Data:G_CurrentGain
	SetVariable setvar43,pos={34,417},size={118,16},proc=SetCurrentVoltConversion,title="Gain (exp V/A)"
	SetVariable setvar43,limits={3,10,1},value= root:Data:G_CurrentVoltGain
	SetVariable setvar44,pos={50,342},size={118,16},proc=SetTipBiasVoltage,title="Tip Bias (mV)"
	SetVariable setvar44,format="%3.1f"
	SetVariable setvar44,limits={-5000,5000,2.5},value= root:Data:G_TipBias
	Button button1,pos={27,244},size={60,20},proc=MoveZ,title="Move Z in"
	Button button2000,pos={103,244},size={60,20},proc=MoveZout,title="Move Z out"
	SetVariable setvar8,pos={39,75},size={110,16},disable=1,title="Excursion (nm)"
	SetVariable setvar8,limits={0.1,500,0},value= root:Data:G_MaxExcursion
	SetVariable setvar14,pos={38,100},size={140,16},disable=1,title="Conductance (G0)"
	SetVariable setvar14,limits={0,10000,0},value= root:Data:G_EngageConductance
	SetVariable setvar15,pos={40,124},size={140,16},disable=1,title="Engage Current"
	SetVariable setvar15,limits={0,10000,0},value= root:Data:G_EngageCurrent
	SetVariable setvar9,pos={160,75},size={80,16},disable=1,title="Step (nm)"
	SetVariable setvar9,limits={0,50,0},value= root:Data:G_EngageStepSize
	Button button7,pos={250,50},size={60,40},disable=1,proc=GetPullOut,title="PullOut"
	Button button7,labelBack=(65280,54528,32768),fColor=(65280,54528,32768)
	Button button9,pos={250,130},size={60,40},disable=1,proc=SavePullOut,title="Save"
	Button button9,labelBack=(65280,54528,32768),fColor=(65280,54528,32768)
	SetVariable setvar16,pos={148,150},size={80,16},disable=1,title="# saved"
	SetVariable setvar16,limits={0,inf,0},value= root:Data:G_PullOutNumber
	SetVariable setvar12,pos={160,50},size={80,16},disable=1,title="Delay (ms)"
	SetVariable setvar12,limits={0,1000,0},value= root:Data:G_EngageDelay
	SetVariable setvar11,pos={39,50},size={110,16},disable=1,title="Pull Rate (nm/s)"
	SetVariable setvar11,limits={0,1000,0},value= root:Data:G_PullOutRate
	SetVariable setvar54,pos={50,367},size={120,16},proc=SetRiseTime,title="Rise Time (ms)"
	SetVariable setvar54,limits={0.01,300,0},value= root:Data:G_RiseTime
	CheckBox check6,pos={221,369},size={74,14},proc=ZeroCheckProc,title="Zero Check"
	CheckBox check6,value= 1
	CheckBox check7,pos={30,343},size={16,14},disable=2,proc=BiasCheckProc,title=""
	CheckBox check7,value= 0
	CheckBox check8,pos={30,368},size={16,14},disable=2,proc=FilterCheckProc,title=""
	CheckBox check8,value= 0
	SetVariable setvar55,pos={50,392},size={120,16},proc=SetCurrentSuppress,title="Suppress I "
	SetVariable setvar55,limits={-1000,1000,0},value= root:Data:G_CurrentSuppressConst
	CheckBox check10,pos={30,393},size={16,14},proc=CurrentSuppressCheckProc,title=""
	CheckBox check10,value= 0
	Button button10,pos={273,341},size={35,20},proc=InitializeGPIB,title="Reset"
	Button button11,pos={218,341},size={35,20},proc=LocalGPIB,title="Local"
	Button button12,pos={221,390},size={75,20},proc=AutoCurrentSuppress,title="Auto Suppress"
	Button button14,pos={221,415},size={70,20},proc=ZeroCorrectProc,title="Zero Correct"
	Button button8,pos={250,100},size={60,20},disable=1,proc=Go_PullOut,title="Go PullOut"
	Button button8,labelBack=(65280,54528,32768),fColor=(65280,54528,32768)
	SetVariable setvar51,pos={34,440},size={100,16},title="Bias Offset"
	SetVariable setvar51,format="%3.2f"
	SetVariable setvar51,limits={-200,100,0},value= root:Data:G_VoltageOffset
	SetVariable setvar17,pos={40,150},size={80,16},disable=1,title="# Count"
	SetVariable setvar17,limits={0,inf,0},value= root:Data:G_PullOutAttempt
	CheckBox check5,pos={221,441},size={66,14},title="Save Bias"
	CheckBox check5,variable= root:Data:G_BiasSaveCheck
	CheckBox check06,pos={220,206},size={76,14},disable=1,title="Save Sense"
	CheckBox check06,variable= root:Data:G_SenseSaveCheck
	SetVariable setvar3,pos={43,90},size={140,16},title="Acquisition Rate     "
	SetVariable setvar3,limits={100,200000,0},value= root:Data:G_AcquisitionRate
	Button button3,pos={224,46},size={70,50},proc=SetUpPXI,title="Start\\W649"
	Button button3,fSize=12,fStyle=1,fColor=(16384,65280,16384)
	Button button4,pos={224,105},size={70,50},proc=StopPXI,title="Stop\\W616"
	Button button4,fSize=12,fStyle=1,fColor=(65280,16384,16384)
	SetVariable setvar4,pos={43,112},size={138,16},title="Buffer Size             "
	SetVariable setvar4,limits={25,2000,0},value= root:Data:G_MinNumPointsOutput
	TabControl Tab_0,pos={25,19},size={304,213},proc=TabProc
	TabControl Tab_0,tabLabel(0)="Basic Control",tabLabel(1)="      FX      "
	TabControl Tab_0,tabLabel(2)=" Pull Out ",value= 0
	Button button13,pos={224,165},size={70,30},proc=ResetPXI,title="Reset PXI"
	Button button13,labelBack=(65535,65535,65535),fSize=12,fStyle=1
	Button button13,fColor=(0,43520,65280)
	ValDisplay valdisp0,pos={81,492},size={77,20},font="Arial Black",fSize=14
	ValDisplay valdisp0,format="%3.5f",limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:Data:G_Actual_Current"
	ValDisplay valdisp2,pos={169,492},size={70,20},font="Arial Black",fSize=14
	ValDisplay valdisp2,format="%3.4f",limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp2,value= #"root:Data:G_MaxCurrent"
	CheckBox check11,pos={27,477},size={32,14},disable=2,proc=CurrentMeterONOFFProc,title="On"
	CheckBox check11,value= 0
	CheckBox check13,pos={27,496},size={43,14},disable=2,title="Beep"
	CheckBox check13,variable= root:Data:G_BeepOn
	CheckBox check4,pos={35,628},size={53,14},title="XOffset"
	CheckBox check4,variable= root:Data:G_XOffsetSwitch
	SetVariable setvar22,pos={41,175},size={100,16},disable=1,title="Stop  #"
	SetVariable setvar22,limits={0,inf,0},value= root:Data:G_StopNumber
	SetVariable setvar25,pos={40,199},size={120,16},disable=1,title="Zero Cutoff (G0)"
	SetVariable setvar25,limits={0,0.5,0},value= root:Data:G_ZeroCutOff
	GroupBox box10102,pos={24,610},size={304,79},title="Other controls"
	GroupBox box10102,font="Times New Roman",fSize=12
	CheckBox check1,pos={242,668},size={59,14},disable=2,proc=ExtBiasCheckProc,title="Ext. Bias"
	CheckBox check1,variable= root:Data:G_ExternalBiasCheck
	ValDisplay valdisp1,pos={250,492},size={70,20},font="Arial Black",fSize=14
	ValDisplay valdisp1,format="%3.4f",limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp1,value= #"root:Data:G_Actual_Bias"
	SetVariable setvar0,pos={34,666},size={120,16},proc=SetXOffset,title="X Offset (nm)"
	SetVariable setvar0,limits={0,5000,1},value= root:Data:G_X_offset
	ValDisplay valdisp4,pos={44,206},size={150,14},title="X piezo scale (nm/V)"
	ValDisplay valdisp4,limits={0,0,0},barmisc={0,1000},value= #"K_XPiezoScale"
	SetVariable setvar27,pos={178,628},size={125,16},title="Series R (Ohm)"
	SetVariable setvar27,limits={-inf,inf,0},value= root:Data:G_SeriesResistance
	SetVariable setvar28,pos={206,647},size={95,16},title="Smash Freq."
	SetVariable setvar28,limits={0,inf,0},value= root:Data:G_SmashNumber
	GroupBox box10105,pos={21,319},size={308,149},title="Keithley Controls"
	GroupBox box10105,font="Times New Roman",fSize=12
	ValDisplay valdisp3,pos={43,46},size={140,14},title="Z piezo scale (nm/V)"
	ValDisplay valdisp3,limits={0,0,0},barmisc={0,1000},value= #"K_ZPiezoScale"
	ValDisplay valdisp5,pos={43,68},size={140,14},title="Z Sense scale (nm/V)"
	ValDisplay valdisp5,limits={0,0,0},barmisc={0,1000},value= #"K_SenseScale"
	SetVariable setvar29,pos={34,646},size={90,16},title="Offset Freq"
	SetVariable setvar29,limits={0,1000,0},value= root:Data:G_XOffsetNumber
	// NW removed on 4/26/16 because these calculations don't work and aren't needed. Always show 0 which is confusing to an experimenter
	//ValDisplay valdisp6,pos={81,544},size={77,20},font="Arial Black",fSize=14
	//ValDisplay valdisp6,format="%3.5f",limits={0,0,0},barmisc={0,1000}
	//ValDisplay valdisp6,value= #"root:Data:G_JunctionBias"
	//ValDisplay valdisp7,pos={203,543},size={77,20},font="Arial Black",fSize=14
	//ValDisplay valdisp7,format="%3.5f",limits={0,0,0},barmisc={0,1000}
	//ValDisplay valdisp7,value= #"root:Data:G_JunctionRes"
	SetVariable setvar13,pos={80,581},size={60,16},title="Pull (nm)"
	SetVariable setvar13,limits={0,1000,0},value= root:Data:G_N1
	SetVariable setvar21,pos={158,581},size={65,16},title="hold(nm)"
	SetVariable setvar21,limits={0,1000,0},value= root:Data:G_N2
	SetVariable setvar26,pos={248,580},size={50,16},title="N3"
	SetVariable setvar26,limits={0,1000,0},value= root:Data:G_N3
	GroupBox box10103,pos={24,565},size={301,42},title="Ramp control"
	GroupBox box10103,font="Times New Roman",fSize=12
EndMacro

Window Actuator_Control() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(952,58,1302,427)
	ModifyPanel frameStyle=1
	SetDrawLayer UserBack
	DrawRect 44,210,44,210
	DrawRect 84,313,84,313
	SetDrawEnv fstyle= 1
	DrawText 128,345,"Motor Status:"
	Button AFullExtensionButton,pos={67,30},size={100,20},proc=AExtendFully,title="Extend Fully"
	Button AGetStatusButton,pos={177,30},size={100,20},proc=AGetStatus,title="Get Status"
	Button AStartJogButton,pos={91,94},size={75,20},proc=AStartJog,title="Start Jog"
	Button AStartJogButton,fColor=(49152,65280,32768)
	Button AStopJogButton,pos={176,94},size={75,20},proc=AStopJog,title="Stop Jog"
	Button AStopJogButton,fColor=(65280,16384,16384)
	Slider AJogSpeedSlider,pos={38,115},size={273,52}
	Slider AJogSpeedSlider,limits={-7,7,1},variable= root:Data:AJogSpeed,vert= 0
	Button APostiveStepButton,pos={52,199},size={50,20},proc=APositiveIncrement,title="+ Step"
	Button ANegativeStepButton,pos={114,199},size={50,20},proc=ANegativeIncrement,title="- Step"
	SetVariable AStepSizeSetVariable,pos={189,201},size={120,16},title="Step Size"
	SetVariable AStepSizeSetVariable,limits={0,1e+06,100},value= root:Data:AStepSize,live= 1
	Button AStartApproachButton,pos={125,240},size={100,20},proc=AStartApproach,title="Start Approach"
	Button AStartApproachButton,labelBack=(60416,59648,55296)
	Button AStartApproachButton,fColor=(49152,65280,32768)
	Button AMotorOffButton,pos={125,270},size={100,20},proc=AMotorOff,title="Motor OFF"
	Button AMotorOffButton,fColor=(65280,42400,0)
	GroupBox AJoggingGroupBox,pos={31,74},size={287,100},title="Jogging"
	GroupBox ASingleStepGroupBox,pos={31,180},size={287,46},title="Single Step"
	Button AGetPositionButton,pos={67,300},size={100,20},proc=AGetPosition,title="Store Position"
	Button AReturnPositionButton,pos={177,300},size={100,20},proc=AReturnPosition,title="Return to Position"
	Button button3,pos={287,300},size={50,20},disable=3
	Button button13,pos={4,325},size={50,20},disable=3
	Button button4,pos={64,325},size={50,20},disable=1
	Slider Pos_Z,pos={124,325},size={50,20},disable=1,limits={0,2,1},value= 0
	SetVariable setvar4,pos={184,325},size={50,20},disable=3
	SetVariable setvar3,pos={244,325},size={50,20},disable=3
	ValDisplay motorvaldisp,pos={208,328},size={16,20},font="Arial Black",fSize=14
	ValDisplay motorvaldisp,format="%1f",limits={0,0,0},barmisc={0,1000}
	ValDisplay motorvaldisp,value= #"root:Data:AMotorStatus"
EndMacro

Function TabProc(ctrlName,tabNum) : TabControl
	String ctrlName
	Variable tabNum

NVAR DeviceON = root:Data:G_DeviceON;

switch(tabNum)	// numeric switch
	case 0:
	// Basic Control Tab Enable
	DoWindow/F Current_Measurement
	if (DeviceON==1) // Device is on
	Button button3 disable=2
	Button button13 disable=2
	SetVariable setvar3 disable=2
	SetVariable setvar4 disable=2
	else
	Button button3 disable=0
	Button button13 disable=0
	SetVariable setvar3 disable=0
	SetVariable setvar4 disable=0	
	endif
	Button button4 disable=0
	SetVariable setvar6 disable=0
	SetVariable setvar5 disable=0
	SetVariable setvar7 disable=0
	ValDisplay valdisp3 disable=0
	ValDisplay valdisp4 disable=0
	ValDisplay valdisp5 disable=0
	// Pull Out Tab Disable
	Button button7 disable=1
	Button button8 disable=1
	Button button9 disable=1
	SetVariable setvar8 disable=1
	SetVariable setvar9 disable=1
	SetVariable setvar11 disable=1
	SetVariable setvar12 disable=1
	SetVariable setvar14 disable=1
	SetVariable setvar15 disable=1
	SetVariable setvar16 disable=1
	SetVariable setvar17 disable=1
	SetVariable setvar22 disable=1
	SetVariable setvar25 disable=1
	CheckBox check06 disable=1
	
	// FX Tab Disable
	SetVariable setvar18 disable=1
	SetVariable setvar19 disable=1
	SetVariable setvar20 disable=1
	SetVariable setvar23 disable=1
	SetVariable setvar24 disable=1
	Button button0 disable=1
	Button button5 disable=1

		break
	case 1:	
	// Basic Control Tab Disable
	DoWindow/F Current_Measurement
	Button button3 disable=1
	Button button13 disable=1
	Button button4 disable=1
	SetVariable setvar3 disable=1
	SetVariable setvar4 disable=1
	SetVariable setvar6 disable=1
	SetVariable setvar5 disable=1
	SetVariable setvar7 disable=1
	ValDisplay valdisp3 disable=1
	ValDisplay valdisp4 disable=1
	ValDisplay valdisp5 disable=1

	// FX Tab Enable
	If (DeviceON==1) // Device is on 
		Button button0 disable=0
	else
		Button button0 disable=2
	endif
	SetVariable setvar18 disable=0
	SetVariable setvar19 disable=0
	SetVariable setvar20 disable=0
	SetVariable setvar23 disable=0
	SetVariable setvar24 disable=0
	Button button5 disable=0
	// Pull Out Tab Disable
	Button button7 disable=1
	Button button8 disable=1
	Button button9 disable=1
	SetVariable setvar8 disable=1
	SetVariable setvar9 disable=1
	SetVariable setvar11 disable=1
	SetVariable setvar12 disable=1
	SetVariable setvar14 disable=1
	SetVariable setvar15 disable=1
	SetVariable setvar16 disable=1
	SetVariable setvar17 disable=1
	SetVariable setvar22 disable=1
	SetVariable setvar25 disable=1
	CheckBox check06 disable=1

		break
	case 2:
	// Basic Control Tab Disable
	DoWindow/F Current_Measurement
	Button button3 disable=1
	Button button13 disable=1
	Button button4 disable=1
	SetVariable setvar3 disable=1
	SetVariable setvar4 disable=1
	SetVariable setvar6 disable=1
	SetVariable setvar5 disable=1
	SetVariable setvar7 disable=1
	ValDisplay valdisp3 disable=1
	ValDisplay valdisp4 disable=1
	ValDisplay valdisp5 disable=1

	// Pull Out Tab Tab Enable
	if (DeviceON == 1)
		Button button7 disable=0
		Button button8 disable=0
	else
		Button button7 disable=2
		Button button8 disable=2
	endif
	Button button9 disable=0
	SetVariable setvar8 disable=0
	SetVariable setvar9 disable=0
	SetVariable setvar11 disable=0
	SetVariable setvar12 disable=0
	SetVariable setvar14 disable=0
	SetVariable setvar15 disable=0
	SetVariable setvar16 disable=0
	SetVariable setvar17 disable=0
	SetVariable setvar22 disable=0
	SetVariable setvar25 disable=0
	CheckBox check06 disable=0
	// FX Tab Disable
	SetVariable setvar18 disable=1
	SetVariable setvar19 disable=1
	SetVariable setvar20 disable=1
	SetVariable setvar23 disable=1
	SetVariable setvar24 disable=1
	Button button0 disable=1
	Button button5 disable=1

		break
endswitch
	return 0
End


Function SetUpPXI(ctrlName) : ButtonControl
String ctrlName

	NVAR G_OD1=root:Data:G_OD1
	NVAR rate=root:Data:G_AcquisitionRate
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR DeviceON = root:Data:G_DeviceON;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)
	NVAR G_OD3 = root:Data:G_OD3
	NVAR X_Offset = root:Data:G_X_Offset
	
	Variable AcquisitionRate=100000
	Make/N=20/D/O OffsetRamp


	Make/D/N=(MinNumPoints*2)/O DCOffset
	DCOffset[0,MinNumPoints-1]=ExcursionOffset/K_ZPiezoScale;
	DCOffset[MinNumPoints,2*MinNumPoints-1]=-(TipBias/1000)
	MXCreateTask("G_OD1");
	MXCreateAOVoltageChan(G_OD1,"dev1/ao0",-10,10);
	MXCreateAOVoltageChan(G_OD1,"dev1/ao1",-6,6);//can vary the range of applied voltage
	MXCfgSampClkTiming(G_OD1,rate,1,MinNumPoints);
	MXWriteAnalogF64(G_OD1,CardTimeout,2,DCOffset)
	if (GetRTError(1))
	endif
	MXStartTask(G_OD1);
	DeviceON=1;
	
	MXCreateTask("G_OD3");
	MXCreateAOVoltageChan(G_OD3,"dev2/ao0",0,10);
	MXCreateAOVoltageChan(G_OD3,"dev2/ao1",-1,1);
	MXCfgSampClkTiming(G_OD3,AcquisitionRate,1,10);
	X_Offset=0
	OffsetRamp[0,9]=X_Offset
	OffsetRamp[10,19]=TipBias/1000
	
	MXStartTask(G_OD3)
	MXWriteAnalogF64(G_OD3,10,2,OffsetRamp);
	if (GetRTError(1))
	endif


	DoWindow/F Current_Measurement
	Button button3 disable=2
	Button button13 disable=2
	Button button4 disable=0
	Slider Pos_Z disable=0
	SetVariable setvar4 disable=2
	SetVariable setvar3 disable=2
	CheckBox check11 disable=0
	CheckBox check13 disable=0

end

Function StopPXI(ctrlName) : ButtonControl
	String ctrlName

	NVAR G_OD1=root:Data:G_OD1
	NVAR G_ID1=root:Data:G_ID1
	NVAR DeviceON = root:Data:G_DeviceON;
	NVAR G_OD3 = root:Data:G_OD3
	NVAR X_Offset = root:Data:G_X_Offset

	DoWindow/F Current_Measurement
	CheckBox check11 value=0
	StopCurrent(" ")
	DoWindow/F Current_Measurement
	CheckBox check6 value=1
	execute "GPIBWrite \"C1X\""
	MoveZTo0(" ")

	
	MXStopTask(G_OD1)
	MXClearTask(G_OD1)
	MXStopTask(G_ID1)
	MXClearTask(G_ID1)
	DeviceON=0;
	Make/N=20/D/O OffsetRamp

	OffsetRamp=0
	
	MXWriteAnalogF64(G_OD3,10,2,OffsetRamp);
	if (GetRTError(1))
	endif
	MXStopTask(G_OD3)
	MXClearTask(G_OD3)

	DoWindow/F Current_Measurement
	Button button3 disable=0
	Button button13 disable=0
	Slider Pos_Z disable=2
	SetVariable setvar4 disable=0
	SetVariable setvar3 disable=0
	
	CheckBox check11 disable=2
	CheckBox check13 disable=2
	
	
	
end
Function ResetPXI(ctrlName) : ButtonControl
String ctrlName
	
	MXResetDevice("Dev1")
	MXResetDevice("Dev2")

end

Function GetExcursion()

	NVAR G_OD1=root:Data:G_OD1
	NVAR G_ID1=root:Data:G_ID1
	NVAR G_ID3=root:Data:G_ID3
	NVAR AcquisitionRate=root:Data:G_AcquisitionRate
	NVAR Size=root:Data:G_ExcursionSize// in nm
	NVAR ExcursionRate=root:Data:G_ExcursionRate// in nm/s
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset // nm
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR ExtensionGain = root:Data:G_ExtensionGain;
	NVAR CurrentGain = root:Data:G_CurrentGain;
	NVAR TipBias = root:Data:G_TipBias	
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion

	Variable Offset = DCOffset_nm/K_ZPiezoScale 	// offset in volts
	Variable NumPtsOut
	if (Size==0)
		NumPtsOut=round(0.5/ExcursionRate*AcquisitionRate)*2
	else
		NumPtsOut = round(Size/ExcursionRate*AcquisitionRate)*2
	endif
	Variable NumPtsIn = NumPtsOut+5000
	Variable NumSeg, i, j,error
	Variable timerRefNum,microSeconds,n
	
	Make/N=(NumPtsOut)/D/O RampOutput
	
	if (Size==0)
		RampOutput=0
	else
		RampOutput[0,NumPtsOut/2-1]=p*(ExcursionRate/K_ZPiezoScale/AcquisitionRate)
		RampOutput[NumPtsOut/2,NumPtsOut-1]=(Size/K_ZPiezoScale)-(p-NumPtsOut/2)*(ExcursionRate/K_ZPiezoScale/AcquisitionRate)
	endif
	RampOutput=RampOutput+Offset

	// Set Up the Input Task, Input Channel and Timing
	MXCreateTask("G_ID1");
	MXCreateAIVoltageChan(G_ID1,"Dev1/ai0",-10,10);
	MXCreateAIVoltageChan(G_ID1,"Dev1/ai1",-10,10);
	MXCfgSampClkTiming(G_ID1,AcquisitionRate,1,NumPtsIn);
	
	MXCreateTask("G_ID3")
	MXCreateAIVoltageChan(G_ID3,"Dev2/ai0",-2,2);
	MXCfgSampClkTiming(G_ID3,AcquisitionRate,1,NumPtsIn);

	Make/D/O/N=(NumPtsIn) CurrentIn, SenseIn, VoltageIn, ConductanceIn
	Make/D/O/N=(NumPtsIn*2) WaveIn

	NumSeg=NumPtsOut/MinNumPoints;
	
	make/O/D/N=(MinNumPoints*2) TempWave
	
	MXStartTask(G_ID1)
	MXStartTask(G_ID3)

	
	for (i=1;i<NumSeg+1;i+=1)	// Loops through each segment
		for (j=0;j<MinNumPoints;j+=1)	// Loops within one segment
			TempWave[j]=RampOutput[(i-1)*MinNumPoints+j]
		endfor
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
		error = MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif
	endfor
	TempWave[0,MinNumPoints-1]=Offset
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
	
	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTError(1))
	endif
	MXReadAnalogF64(G_ID1,10,2,WaveIn);
	MXReadAnalogF64(G_ID3,10,1,SenseIn);
	VoltageIn=WaveIn[p]
	CurrentIn=WaveIn[p+NumPtsIn]
	MXStopTask(G_ID1)
	MXClearTask(G_ID1)
	MXStopTask(G_ID3)
	MXClearTask(G_ID3)
//	SenseIn=SenseIn*K_SenseScale
	ConductanceIn=-CurrentIn*CurrentVoltConversion/VoltageIn/77.5
	Duplicate/O ConductanceIn,ConductanceIn_smth;
	Smooth/B 11, ConductanceIn_smth
	DoWindow/F SenseInDisplay
	if (V_Flag==0)
		Display/W=(5.25,42.5,399,232.25) SenseIn
		DoWindow/C SenseInDisplay
		DoUpdate
	else
		DoUpdate
	endif
	

end

Function NoiseTest([NumPtsOut])
Variable NumPtsOut

	NVAR G_OD1=root:Data:G_OD1
	NVAR G_ID1=root:Data:G_ID1
	NVAR G_ID3=root:Data:G_ID3
	NVAR AcquisitionRate=root:Data:G_AcquisitionRate
	NVAR ExcursionRate=root:Data:G_ExcursionRate// in nm/s
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion

	if (ParamIsDefault(NumPtsOut))
		NumPtsOut=AcquisitionRate/8
	endif
	Variable NumPtsIn = NumPtsOut+500
	Variable NumSeg, i, j,error
	
	// Set Up the Input Task, Input Channel and Timing
	MXCreateTask("G_ID1");
	MXCreateAIVoltageChan(G_ID1,"dev1/ai0",-10,10);
	MXCreateAIVoltageChan(G_ID1,"dev1/ai1",-10,10);
	MXCfgSampClkTiming(G_ID1,AcquisitionRate,1,NumPtsIn);

	Make/D/O/N=(NumPtsIn) CurrentIn, VoltageIn, ConductanceIn
	Make/D/O/N=(NumPtsIn*2) WaveIn

	NumSeg=NumPtsOut/MinNumPoints;
	
	make/O/D/N=(MinNumPoints*2) TempWave
	
	MXStartTask(G_ID1)

	
	for (i=1;i<NumSeg+1;i+=1)	// Loops through each segment
		TempWave[0,MinNumPoints-1]=0
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
		error = MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif
	endfor
	TempWave[0,MinNumPoints-1]=0
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
	
	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTError(1))
	endif
	MXReadAnalogF64(G_ID1,10,2,WaveIn);
	VoltageIn=WaveIn[p]
	CurrentIn=WaveIn[p+NumPtsIn]
	deletepoints 0,500,VoltageIn, ConductanceIn, CurrentIn
	MXStopTask(G_ID1)
	MXClearTask(G_ID1)
	ConductanceIn=-CurrentIn*CurrentVoltConversion/VoltageIn/77.5
	SetScale/I x 0,NumPtsOut/AcquisitionRate,"s", ConductanceIn
	

end
Function Get_FX(ctrlName) : ButtonControl
String ctrlName
	NVAR AcquisitionRate=root:Data:G_AcquisitionRate
	NVAR ExcursionRate=root:Data:G_ExcursionRate// in nm/s
	NVAR Size=root:Data:G_ExcursionSize// in nm
	NVAR MeasuredExcursionRate=root:Data:G_MeasuredExcursionRate
	NVAR CurrentGain=root:Data:G_CurrentGain
	NVAR ExtensionGain=root:Data:G_ExtensionGain	
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion
	NVAR TipBias = root:Data:G_TipBias
	NVAR VoltageOffset = root:Data:G_VoltageOffset
	NVAR PiezoVFactor = root:Data:G_PiezoVFactor
	NVAR PointsPerTrace = root:Data:G_PointsPerTrace
	NVAR MeasureOn = root:Data:G_MeasureOn
	NVAR ExternalBiasCheck = root:Data:G_ExternalBiasCheck
	
	PointsPerTrace = round(Size/ExcursionRate*AcquisitionRate)
	
	if (stringmatch(ctrlName, "FromGo" )==0)
		StopCurrent(" ")
	endif

	Variable Duration = Size/ExcursionRate*2, npA, npB, i
	Make/O/N=(2*PointsPerTrace) Extension
	Make/O/N=(2*PointsPerTrace) Current, Voltage, Force, TotalLaser
		
	SetScale/I x 0,Duration,Extension
	SetScale/I x 0,Duration,Current
		
	GetExcursion()
	Wave CurrentIn, SenseIn, VoltageIn
	
	for (i=0;i<PointsPerTrace*2;i+=1)
		Extension[i]=SenseIn[i+1100]
		Current[i]=CurrentIn[i+2200]
		Voltage[i]=-VoltageIn[i+2200]
	endfor
	// find center point
	
	duplicate/O extension extension_smooth
	smooth/B 49, extension_smooth
	wavestats/Q extension_smooth
	Variable center_pt = 0, Num=0

	center_pt = V_maxloc/duration*2*PointsPerTrace
		//fit the forward and backward traces of the measured extension
	CurveFit/Q/L=(center_pt) poly 3, Extension[0, center_pt-1] /D
	duplicate/O/R=[0,center_pt-1] Extension, Extension_Forward
	Duplicate/O fit_Extension Fit_Extension_Forward
	CurveFit/Q/L=(2*PointsPerTrace-center_pt+1) poly 3, Extension[center_pt,2*PointsPerTrace] /D
	duplicate/O/R=[center_pt,2*PointsPerTrace] Extension, Extension_Backward
	Duplicate/O fit_Extension Fit_Extension_Backward

			//Now that we know the actual extension in nm, we compute the actual pulling rate
	MeasuredExcursionRate=abs(Fit_Extension_Forward[1]-Fit_Extension_Forward[PointsPerTrace/2])/(duration/4)
		// the wave "fit_Extension" is added automatically to ExtensionVersusTime graph.  Here we remove it in case is there.
	DoWindow/F ExtensionVersusTime
	if(V_Flag==1)
		RemoveFRomGraph/W=ExtensionVersusTime/Z fit_Extension
	endif
 	Current=Current*CurrentVoltConversion		// Convert Volts from input to microamps
	Duplicate/O Current Conductance
	Conductance=Current/Voltage/77.5
	Duplicate/O/R=[0,center_pt-1] Conductance Conductance_Forward
	Duplicate/O/R=[center_pt,2*PointsPerTrace] Conductance Conductance_Backward
	
	variable shiftx

	shiftx=Fit_Extension_Forward[inf]
	Fit_Extension_Forward=shiftx-Fit_Extension_Forward
	Fit_Extension_Backward=shiftx-Fit_Extension_Backward

	// Display Conductance vs Extension
	DoWindow/F ConductanceExtensionCurves
	if (V_Flag==0)
		Display/W=(5.25,257,400.5,451.25) Conductance_Forward vs Fit_Extension_Forward as "Conductance (G0) vs Extension (nm)"
		DoWindow/C ConductanceExtensionCurves
		AppendToGraph Conductance_Backward vs Fit_Extension_Backward
		ModifyGraph rgb(Conductance_Backward)=(0,0,65280)
		ModifyGraph grid(left)=1
		ShowInfo
		DoUpdate
	else
		DoUpdate
	endif

	if (stringmatch(ctrlName, "FromGo" )==0)
		StartCurrent(" ")
	endif

End

Function SaveFX(ctrlName) : ButtonControl
	String ctrlName
	NVAR WriteFileNumber=root:Data:G_WriteFileNumber
	
	NVAR Size=root:Data:G_ExcursionSize// in nm
	NVAR Rate=root:Data:G_ExcursionRate// in nm/s
	NVAR MeasuredExcursionRate=root:Data:G_MeasuredExcursionRate
	NVAR CurrentGain=root:Data:G_CurrentGain
	NVAR ExtensionGain=root:Data:G_ExtensionGain	
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion
	NVAR TipBias = root:Data:G_TipBias
	NVAR RiseTime = root:Data:G_RiseTime
	NVAR VoltageOffset = root:Data:G_VoltageOffset
	NVAR ExternalBiasCheck = root:Data:G_ExternalBiasCheck
	
	make/O/N=17 Temp
	
	Temp[0] = Size
	Temp[1] = Rate
	Temp[2] = MeasuredExcursionRate
	Temp[3] = 0
	Temp[4] = 0
	Temp[5] = 0
	Temp[6] = 0
	Temp[7] = CurrentGain
	Temp[8] = ExtensionGain
	Temp[9] = CurrentVoltConversion
	Temp[10] = TipBias
	Temp[11] = 0
	Temp[12] = K_G0
	Temp[13] = 0
	Temp[14] = RiseTime
	Temp[15] = ExternalBiasCheck
	Temp[16] = VoltageOffset
	
	
 	String ParameterWave="FXParameter_"+Num2Str(WriteFileNumber)
	String Extension_F="Extension_F"+Num2Str(WriteFileNumber)
	String Extension_B="Extension_B"+Num2Str(WriteFileNumber)
	String Conductance_F="Conductance_F"+Num2Str(WriteFileNumber)
	String Conductance_B="Conductance_B"+Num2Str(WriteFileNumber)

	Duplicate/O Temp $ParameterWave
	KillWaves/Z Temp
	Duplicate/O Extension_Forward $Extension_F
	Duplicate/O Extension_Backward $Extension_B
	Duplicate/O Conductance_Forward $Conductance_F
	Duplicate/O Conductance_Backward $Conductance_B
	Save/C/P=Relocate $ParameterWave, $Extension_F, $Extension_B, $Conductance_F, $Conductance_B//, $Conductance2_F, $Conductance2_B
	Killwaves $ParameterWave, $Extension_F, $Extension_B, $Conductance_F, $Conductance_B//, $Conductance2_F, $Conductance2_B
	
	WriteFileNumber=WriteFileNumber+1
	Beep
End


Function Offset(name, value, event)			// slider sets Offset
	String name
	Variable value
	variable event
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)

	ExcursionOffset=value*K_ZPiezoScale
	
	Make/D/O/N=(MinNumPoints*2) TempWave

	TempWave[0,MinNumPoints-1]=value
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTError(1))
//		print "Error in function MyFunc"
//		print GetRTErrMessage()
	endif

End

Function SaveAll(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR SaveCheck=root:Data:G_SaveCheck
	if(checked==0)
		SaveCheck=0
	else
		SaveCheck=1
	endif
End

Function MoveZDelta(step)
	Variable step // nm
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)

	DCOffset_nm=DCOffset_nm+step
	DoWindow/F Current_Measurement
	Slider Pos_Z value=DCOffset_nm/K_ZPiezoScale
	
	Make/D/O/N=(MinNumPoints*2) TempWave
	TempWave[0,MinNumPoints-1]=DCOffset_nm/K_ZPiezoScale
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTerror(1))
	endif
		
End

Function MoveZ(ctrlName) : ButtonControl
	String ctrlName
	NVAR Zmove=root:Data:G_Z_Step_Size
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)

	DCOffset_nm=DCOffset_nm+Zmove
	DoWindow/F Current_Measurement
	Slider Pos_Z value=DCOffset_nm/K_ZPiezoScale
	variable DCOffset
	DCOffset = DCOffset_nm/K_ZPiezoScale
	
	Make/D/O/N=(MinNumPoints*2) TempWave

	TempWave=DCOffset;
	TempWave[0,MinNumPoints-1]=DCOffset
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTerror(1))
	endif

								
End
Function MoveZto0(ctrlName) : ButtonControl
	String ctrlName
	NVAR Zmove=root:Data:G_Z_Step_Size
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)

	DCOffset_nm=0
	DoWindow/F Current_Measurement
	Slider Pos_Z value=0
	variable DCOffset
	DCOffset = 0
	
	Make/D/O/N=(MinNumPoints*2) TempWave

	TempWave[0,MinNumPoints-1]=DCOffset
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTerror(1))
	endif

								
End

Function MoveZout(ctrlName) : ButtonControl
	String ctrlName
	NVAR Zmove=root:Data:G_Z_Step_Size
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	//-(TipBias/1000)

	DCOffset_nm=DCOffset_nm-Zmove
	DoWindow/F Current_Measurement
	Slider Pos_Z value=DCOffset_nm/K_ZPiezoScale
	variable DCOffset
	DCOffset = DCOffset_nm/K_ZPiezoScale
	
	Make/D/O/N=(MinNumPoints*2) TempWave


	TempWave[0,MinNumPoints-1]=DCOffset
	TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

	MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
	if (GetRTerror(1))
	endif

								
End



Function MeasureAll(s)
	STRUCT WMBackgroundStruct &s
	NVAR Actual_Current = root:Data:G_Actual_Current
	NVAR Actual_Bias = root:Data:G_Actual_Bias
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion
	NVAR MaxCurrent = root:Data:G_MaxCurrent
	NVAR G_ID2=root:Data:G_ID2
	NVAR MeasureOn = root:Data:G_MeasureOn
	NVAR BeepOn = root:Data:G_BeepOn
	NVAR JunctionBias = root:Data:G_junctionBias;
	NVAR JunctionRes = root:Data:G_junctionRes;
	Wave CurrentWave
//	NVAR K_G0 = Root:Data:G_K_G0
	Variable error,NNN=4
	Variable NumPtsIn=100*NNN
	Make/D/O/N=(NumPtsIn) WaveInMeter=0
	Make/D/O/N=(NumPtsIn/NNN) BiasIn, CurrentMeterIn, JuncBiasIn;

	error = MXReadAnalogF64(G_ID2,10,4,WaveInMeter); //reading low res card
	if (GetRTerror(1))
	endif
	BiasIn=WaveInMeter[p]
	CurrentMeterIn=WaveInMeter[p+NumPtsIn/NNN]
	JuncBiasIn = WaveInmeter[p+3*NumPtsIn/NNN]

//	Actual_Current = (sum(CurrentMeterIn,NumPtsIn/6,NumPtsIn/3-1)/(NumPtsIn/6))*CurrentVoltConversion  //in 10^-6 amps
	Actual_Current = (sum(CurrentMeterIn,NumPtsIn/(NNN*2),(NumPtsIn/NNN)-1)/(NumPtsIn/NNN/2))*CurrentVoltConversion
	Actual_Bias = (sum(BiasIn,NumPtsIn/(NNN*2),(NNN-1)*NumPtsIn/NNN-1)/(NumPtsIn/NNN/2))
	JunctionBias = (sum(JuncBiasIn, NumPtsIn/(NNN*2), (NNN-1)*NumPtsIn/NNN-1)/(NumPtsIn/NNN/2))
//	JunctionBias = sum(JuncBiasIn, 0, 4)/5;
	JunctionRes = abs(1e-6*(Actual_current/JunctionBias)/(K_G0*1e-6))
	
	if(waveexists(CurrentWave))

	Variable Pts = Numpnts(CurrentWave)
		Redimension/N=(Pts+1) CurrentWave
		CurrentWave[inf] = Actual_Current
		DoUpdate
	Endif	
	
	if ((abs(Actual_Current)>.16)&&(BeepOn==1))
		beep
	endif
	if (abs(Actual_Current)>MaxCurrent)
		MaxCurrent=abs(Actual_Current)
	endif	
	DoUpdate
	return 0	
End


Function StartCurrent(ctrlName) : ButtonControl
	String ctrlName
	NVAR MaxCurrent = root:Data:G_MaxCurrent
	NVAR MeasureOn = root:Data:G_MeasureOn
	NVAR BeepOn = root:Data:G_BeepOn
	NVAR G_ID2=root:Data:G_ID2
	NVAR CardTimeout = root:Data:G_CardTimeout;

	Variable AcquisitionRate=5000
	Variable NumPtsIn=100
	MaxCurrent=0


	if (MeasureOn == 1)	
		// Set Up the Input Task, Input Channel and Timing
		MXCreateTask("G_ID2");
		MXCreateAIVoltageChan(G_ID2,"dev2/ai0",-10,10);
		MXCreateAIVoltageChan(G_ID2,"dev2/ai1",-10,10);
//		MXCreateAIVoltageChan(G_ID2,"dev2/ai2",-10,10);	
		MXCreateAIVoltageChan(G_ID2,"dev2/ai3",-1,1); //voltage at the junction
		MXCfgSampClkTiming(G_ID2,AcquisitionRate,0,NumPtsIn);
	//	MXStartTask(G_ID1)
		CtrlNamedBackground measurecurrent, proc=MeasureAll, period = 20,burst=1,start
	else
		CtrlNamedBackground measurecurrent, stop
		MXStopTask(G_ID2)
		MXClearTask(G_ID2)
	endif
end
Function StopCurrent(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR G_ID2=root:Data:G_ID2	
	NVAR MeasureOn = root:Data:G_MeasureOn
	if (MeasureOn == 1)
		CtrlNamedBackground measurecurrent, stop		
		MXStopTask(G_ID2)
		MXClearTask(G_ID2)
	endif
end
Function CurrentMeterONOFFProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR MeasureOn = root:Data:G_MeasureOn
	if(checked==1)
		MeasureOn = 1;
		StartCurrent(" ")
	else
		StopCurrent(" ")
		MeasureOn = 0;
	endif

End
Function BeepOnCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR BeepOn = root:Data:G_BeepOn
	if (checked==1)
		BeepOn=1
	else
		BeepOn=0
	endif

End


Function GetPullOut(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR Size = root:Data:G_MaxExcursion
	NVAR EngageConductance = root:Data:G_EngageConductance
	NVAR EngageStepSize = root:Data:G_EngageStepSize
	NVAR EngageDelay = root:Data:G_EngageDelay
	NVAR CurrentGain = root:Data:G_CurrentGain
	NVAR TipBias = root:Data:G_TipBias
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR PointsPerTrace=root:Data:G_PointsPerTrace
	NVAR ExtensionGain=root:Data:G_ExtensionGain	
	NVAR ExcursionRate=root:Data:G_PullOutRate// in nm/s
	NVAR VoltageOffset = root:Data:G_VoltageOffset
	NVAR PullOutFail = root:Data:G_PullOutFail
	NVAR PullOutGain = root:Data:G_PullOutGain
	NVAR CurrentVoltConversion = root:Data:G_CurrentVoltConversion
	NVAR CurrentVoltGain = root:Data:G_CurrentVoltGain
	NVAR CurrentSuppress = root:Data:G_CurrentSuppress // in MicroAmps
	NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
	NVAR GainChange = root:Data:G_GainChange
	NVAR G_OD1=root:Data:G_OD1
	NVAR G_ID1=root:Data:G_ID1
	NVAR G_ID2=root:Data:G_ID2
	NVAR G_ID3=root:Data:G_ID3
	NVAR AcquisitionRate=root:Data:G_AcquisitionRate
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR ExternalBiasCheck = root:Data:G_ExternalBiasCheck
	NVAR SeriesResistance = root:Data:G_SeriesResistance
	NVAR BiasSave=root:Data:G_BiasSaveCheck
	NVAR SenseSave=root:Data:G_SenseSaveCheck
	NVAR N2in=root:Data:G_N2
	NVAR N3=root:Data:G_N3
	NVAR N1in=root:data:G_N1
	NVAR COND=root:Data:G_ConductanceIN
	NVAR EngageCurrent = root:Data:G_EngageCurrent
	NVAR x_offset = root:Data:G_x_offset
	Variable FromGo=0
	if (stringmatch(ctrlName, "FromGo" )==1)
		FromGo=1
	endif


	Variable MaxIVBias// = root:Data:G_MaxIVBias
	Variable Bias = TipBias+VoltageOffset

	Variable Offset = DCOffset_nm/K_ZPiezoScale 	// offset in volts
	Variable NumSeg, i, j,error
	Variable max_count
	Variable ContactOffset
	Variable Conductance, current
	Variable TipCurrent = 0
	Variable MinCond = 0.3
	Variable pNum=0
	Variable DelayOffset = MinNumPoints+5000
	Variable DeltaEx=ExcursionRate/K_ZPiezoScale/AcquisitionRate // in units of volts
	Variable DeltaBias=0.5
	Variable LastX, LastV,N1B,N2B, N1, N2
	N1in=3
	N1=round(N1in/ExcursionRate*AcquisitionRate)// Starting point for push/hold etc
	N3=2// Num Seg to push,hold, or pull
//	N2in=2// Size of push,pull hold segment in Nanometers //MASHA"S 
	N2in=N1in+3 // Jon's
	N2=round(N2in/ExcursionRate*AcquisitionRate)
	variable Nhold = round(5/ExcursionRate*acquisitionRate)
//	n3=
	// NOTE Size has to be modified in panel, add N3*N2 to full extension
	Variable CAPnm=0.5
	Variable CAP=round(CAPnm/ExcursionRate*AcquisitionRate)
	Variable NumPtsOut = round(Size/ExcursionRate*AcquisitionRate)
	Variable NumPtsIn = NumPtsOut+5000
//	Variable NumPtsIn2=NumPtsOut*Factor+5000
	
	PointsPerTrace = NumPtsOut
	
	max_count = round(20*Size/EngageStepSize) 
	
	//if (FromGO==0)
		StopCurrent(" ")
	//endif
	MXCreateTask("G_ID2");
	MXCreateAIVoltageChan(G_ID2,"dev2/ai1",-10,10);
	MXCreateAIVoltageChan(G_ID2, "dev2/ai3", -1,1);
	MXCfgSampClkTiming(G_ID2,5000,0,20);

	MXCreateTask("G_ID1");
	MXCreateAIVoltageChan(G_ID1,"dev1/ai0",-10,10);
	MXCreateAIVoltageChan(G_ID1,"dev1/ai1",-10,10)
	MXCfgSampClkTiming(G_ID1,AcquisitionRate,1,NumPtsIn);

	MXCreateTask("G_ID3")
	MXCreateAIVoltageChan(G_ID3,"Dev2/ai0",-10,10);
//	MXCreateAIVoltageChan(G_ID3,"Dev2/ai1",-10,10);
//	MXCreateAIVoltageChan(G_ID3,"Dev2/ai2",-10,10);
//	MXCreateAIVoltageChan(G_ID3,"Dev2/ai3",-5,5);
	MXCfgSampClkTiming(G_ID3,AcquisitionRate,1,NumPtsIn);

//	Make/D/O/N=(NumPtsIn2) SenseIn//, CurrentIn2
	Make/D/O/N=(NumPtsIn) CurrentIn, VoltageIn//, SenseIn
	Make/D/O/N=(NumPtsIn*2) WaveIn
	Make/D/O/N=(numPtsIn) SenseIn
//	Make/D/O/N=(NumPtsIn2) WaveIn2
	NumSeg=NumPtsOut/MinNumPoints;
	make/O/D/N=(MinNumPoints*2) TempWave
	Make/N=40/O/D ReadWave
	Make/N=20/O/D TempCurrentIn, tempVoltIn

	Make/N=(NumPtsOut)/D/O RampOutput, RampBias	
	
	RampOutput[0,NumPtsOut-1]=-p*DeltaEx //DEFAULT Pull Definition
	RampBias = -(TipBias/1000)                    // DEFAULT Bias WAVE
//	RampBias[N1+N2/2, 9/ExcursionRate*AcquisitionRate]=-(tipBias/1000);
//	RampBias = -(TipBias/1000)+0.001*sin(p/20*2*Pi)

	//RampBias[numptsout*.93, numptsout-1]=-tipbias/1000
//	Variable SpikeStart,SpikeEnd,SpikeVal
//	SpikeStart=round(NumPtsOut)*.97
//	SpikeEnd=round(NumPtsOut)*.99
//	//SpikeStart=round(NumPtsOut)*.99
//	//SpikeEnd=round(NumPtsOut)*.995
//	SpikeVal=-(TipBias/1000)-(min(.150,TipBias/1000))
//	RampBias[SpikeStart,SpikeEnd]=SpikeVal

// 	Line below is DEFAULT
//	RampBias[(NumSeg-0.3)*MinNumPoints,(NumSeg-0.2)*MinNumPoints]=-(TipBias/1000)-.150
//	Line below is changed 	

	//Variable TempOutput=RampOutput[16400]
	//RampOutput[SpikeStart,SpikeEnd]=TempOutput
//	RampBias[10000,11000]=SpikeVal
	
	// IV Bias WAVE
//	RampBias[N1B,N2B+N1B-1]= -(TipBias/1000)-sin((p-N1B)*4*pi/(N2B))*DeltaBias
//	BiasSave=1

// *** Jonathan's IV ***


	//N3=1


N3=0


	//00
	variable fsin=10000
	if (N3==5)
	
		RampBias[N1in,inf]=-(tipbias/1000)+sign(tipbias)*0.1*sin(2*pi*fsin/AcquisitionRate*p)
		RampOutput[0,N1-1]=-p*DeltaEx
		LastX=RampOutput[N1-1]
		RampOutput[N1,N2-1]=LastX 
		LastX=RampOutput[N2-1]
		RampOutput[N2,NumPtsOut-1]= -(p-N2)*DeltaEx+LastX
	endif
	
	
	RampBias[numptsout*.93, numptsout-1]=-tipbias/1000
	Variable SpikeStart,SpikeEnd,SpikeVal
	SpikeStart=round(NumPtsOut)*.97
	SpikeEnd=round(NumPtsOut)*.99
	//SpikeStart=round(NumPtsOut)*.99
	//SpikeEnd=round(NumPtsOut)*.995
	SpikeVal=-(TipBias/1000)-(min(.150,TipBias/1000))
	SpikeVal=-(1.5*TipBias/1000)//-(min(.150,TipBias/1000))
	RampBias[SpikeStart,SpikeEnd]=SpikeVal

	if (N3==88)
		BiasSave=1
		RampOutput[0,N1-1]=-p*DeltaEx
		LastX=RampOutput[N1-1]
		RampOutput[N1,N2-1]=LastX 
		LastX=RampOutput[N2-1]
		RampOutput[N2,NumPtsOut-1]= -(p-N2)*DeltaEx+LastX
		Variable lastBias = tipbias/1000 //original was /1000
		Variable MaxBias = -0.4//Ramp in Bias from Set Bias
		Variable DelBias = (MaxBias)/1000
		Variable Wait=1*CAP
	     RampBias[N1+CAP,N1+2*CAP-1]=-lastBias-(-(p-(N1+CAP))*DelBias)+(TipBias/1000)
            LastBias=RampBias[N1+2*CAP-1]
            RampBias[N1+2*CAP,N1+4*CAP-1]=LastBias+(-(p-(N1+2*CAP))*DelBias)
           LastBias=RampBias[N1+4*CAP-1]
           RampBias[N1+4*CAP,N1+5*CAP]=LastBias-(-(p-(N1+4*CAP))*DelBias)          
        endif 
		
	if (N3==89)
		BiasSave=1
		RampOutput[0,N1-1]=-p*DeltaEx
		LastX=RampOutput[N1-1]
		RampOutput[N1,N2-1]=LastX 
		LastX=RampOutput[N2-1]
		RampOutput[N2,NumPtsOut-1]= -(p-N2)*DeltaEx+LastX
		lastBias = tipbias/1000 //original was /1000
	 MaxBias = -2//Ramp in Bias from Set Bias
		 DelBias = (MaxBias)/1000

	     RampBias[N1+CAP,N1+3*CAP-1]=-lastBias-(-(p-(N1+CAP))*DelBias)+(TipBias/1000)
            LastBias=RampBias[N1+3*CAP-1]
            RampBias[N1+3*CAP,N1+5*CAP-1]=LastBias+(-(p-(N1+3*CAP))*DelBias)
   
        endif 	
        
	if (N3>0 && N3<=1)
//		BiasSave=1
//		RampOutput[0,N1-1]=-p*DeltaEx
//		LastX=RampOutput[N1-1]
//		RampOutput[N1,N2-1]=LastX //+ (p-N1)*DeltaEx
//		//RampOutput[N1,N2-1]=LastX + (p-N1)*DeltaEx
//		LastX=RampOutput[N2-1]
//		RampOutput[N2,NumPtsOut-1]= -(p-N2)*DeltaEx+LastX
//		//RampBias[N1+CAP,N2-CAP]=-(TipBias/1000)-(sin((p-(N1+CAP))/(N2-N1-2*CAP)*2*Pi)*0.9)
//		 lastBias = tipbias/1000 //original was /1000
//		 MaxBias = 1.15//Ramp in Bias from Set Bias
//		 DelBias = (MaxBias)/1000
//		 Wait=1*CAP
//	     RampBias[N1+CAP,N1+2*CAP-1]=-lastBias-(-(p-(N1+CAP))*DelBias)+(TipBias/1000)
//            LastBias=RampBias[N1+2*CAP-1]
//            RampBias[N1+2*CAP,N1+4*CAP-1]=LastBias+(-(p-(N1+2*CAP))*DelBias)
//           LastBias=RampBias[N1+4*CAP-1]
//           RampBias[N1+4*CAP,N1+5*CAP]=LastBias-(-(p-(N1+4*CAP))*DelBias)
	
	//	RampBias[0,numptsout*.96]=-(tipbias/1000)+0.9*sin(2*pi*fsin/AcquisitionRate*p)
	//	RampBias[N1+Cap,N1+5*CAP]=-(tipbias/1000)+0.1*sin(2*pi*fsin/AcquisitionRate*p)
	
//		RampBias[N1+CAP,N1+2*CAP-1]=-tipbias/10000
//		RampBias[N1+CAP+Wait,N1+2*CAP+Wait-1]=-(-lastBias-(p-(N1+CAP+Wait))*DelBias)//-(TipBias/1000)
//             LastBias=RampBias[N1+2*CAP+Wait-1]
//             RampBias[N1+2*CAP+Wait,N1+4*CAP+Wait-1]=LastBias-((p-(N1+2*CAP+Wait))*DelBias)
//            LastBias=RampBias[N1+4*CAP+Wait-1]
//             RampBias[N1+4*CAP+Wait,N1+5*CAP+Wait]=LastBias+(p-(N1+4*CAP+Wait))*DelBias
//             RampBias[N1+5*CAP+Wait,N1+6*CAP+Wait]=-tipbias/10000
	endif
	
// *** Jonathan's IV ***
// the first IF statement might be modified to allow for push-hold-pull analysis w/o IV stuff. orginal is N3>1
	Variable StartN,EndN
	if (N3 ==21)
		RampOutput[0,N1-1]=-p*DeltaEx
		LastX=RampOutput[N1-1]
		StartN=N1;EndN=N1+N2-1; // Regular
//		StartN=N1;EndN=N1+N2-1; // Pull Hold PUsh Pull

		StartN = N1; EndN = N1+N2-1;
		//RampOutput[StartN,Endn] = LastX;
		RampOutput[StartN, EndN] = LastX + (p-StartN)*DeltaEx
//		RampBias[N1+CAP,N2-CAP] = -(TipBias/1000)-(sin((p-(N1+CAP))/(N2-N1-2*CAP)*2*Pi)*0.95) //Jon's bias ramp
//		StartN=N1;EndN=N1+n2/6-1; //pull hold push pull; smaller hold
/////		StartN=EndN; EndN=StartN+N1-1;
//		RampOutput[StartN, EndN] = LastX + (p-StartN)*DeltaEx // push for a third of the way
//		LastX=RampOutput[EndN-1]
//		StartN=EndN; EndN = StartN+N2*2-1;
////		
////		RampOutput[StartN,Endn] = LastX;  //hold
////		StartN=EndN; EndN= StartN+2*N2/3-1;  //push for 2/3 of the way
//		startN=N1; endN=N1+N2;
//		LastX=RampOutput[endN-1];
//		RampOutput[StartN, EndN]=LastX;
//		startN=endN; endN = StartN+9*n2/10;
//		Rampoutput[startn, endn] = LastX - DeltaEx*800*2.5;
//		StartN=N1; EndN=N1+4*N2/10-1
//		RampOutput[StartN, EndN]=LastX
//		StartN = EndN+1;
//		EndN = EndN+N2/10-1;
//		LastX = RampOutput[StartN-1];
//		RampOutput[StartN,EndN]=LastX-DeltaEx*2.5*1500 
//		StartN = EndN+1;
//		EndN = EndN + N2/2-1;
//		LastX = RampOutput[StartN-1];
//		RampOutput[StartN, endN] = lastX+DeltaEx*2.5*1500
	//	StartN=EndN; EndN=StartN+N1;
//		RampOutput[StartN, EndN] = LastX + 4/3*(p-StartN)*DeltaEx //push for 1 segment
//		RampOutput[StartN, EndN] = LastX + (p-StartN)*DeltaEx //push for 1 segment
		LastX=RampOutput[EndN]
		
//		For(i=1;i<(N3/4);i+=1)
//		For(i=1;i<(N3/2-1);i+=1)
///			StartN=EndN+1; 
///			EndN=StartN+N2/2-1
///			RampOutput[StartN,EndN]=LastX+(p-StartN)*DeltaEx // Push 
///			LastX=RampOutput[EndN-1]
//			StartN=EndN+1; 
//			EndN=StartN+N2-1
//			RampOutput[StartN,EndN]=LastX // Hold
//			LastX=RampOutput[EndN]
///			StartN=EndN+1; 
///			EndN=StartN+N2/2-1
///			RampOutput[StartN,EndN]=LastX-(p-StartN)*DeltaEx //  Pull
///			LastX=RampOutput[EndN]
//			StartN=EndN+1; 
//			EndN=StartN+N2-1
//			RampOutput[StartN,EndN]=LastX // Hold
//			LastX=RampOutput[EndN]
//		EndFor	
//		StartN=EndN+1; 
//		EndN=StartN+N2-1
//		RampOutput[StartN,EndN]=LastX // Hold
//		LastX=RampOutput[EndN]
		RampOutput[EndN+1,NumPtsOut-1]=LastX-DeltaEx*(p-EndN+1)
	endif
	
	//RampOutput[0,NumPtsOut-1]=-p*DeltaEx
	
//	Make/O/N=2 ApproachG=0
	//Variable resistanceRation = (1/(K_G0*1e-6))/SeriesResistance

	j=0
	Variable Juncvolt;
	do	
		MXReadAnalogF64(G_ID2,10,2,ReadWave);
		tempCurrentIn = ReadWave //current in volts
		tempVoltIn= ReadWave[p+20];
		Current=abs((Sum(tempCurrentIn)*CurrentVoltConversion*1e-6)/20)
		JuncVolt = -Sum(tempVoltIn,9,19)/10;
//		MXReadAnalogF64(G_ID2,10,1,ReadWave);
//		Current=Sum(ReadWave,0,19)/20*CurrentVoltConversion*1e-6
//		if (abs(Current/(CurrentVoltConversion*1e-6))>EngageCurrent)
			//Conductance = abs((1/((Bias/1000)/Current-SeriesResistance))/(K_G0*1e-6))
			Conductance = abs(current/JuncVolt)/(K_G0*1e-6)
	//		print "Cond is ", Conductance, current, juncvolt
			if (((abs(Conductance)>abs(MinCond))&&(j==0))) // If in contact when starting
				MXClearTask(G_ID1)
				MXClearTask(G_ID3)			
				MXStopTask(G_ID2);
				MXClearTask(G_ID2)
				//sleep/s 1
				DCOffset_nm=DCOffset_nm-Size
				print DCOffset_nm
				ContactOffset = DCOffset_nm/K_ZPiezoScale
				TempWave[0,MinNumPoints-1]=ContactOffset
				TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
			//	print DCOffset_nm
				MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
				if (GetRTError(1))
					print "write error"
				endif
				
				DoWindow/F Current_Measurement
				Slider Pos_Z value=DCOffset_nm/K_ZPiezoScale
		//		sleep/s 0.2
				printf "In contact, Pull out\r"
				doupdate
				PullOutFail=2
				break
			endif
//		endif
		if (((Conductance> EngageConductance))||(Current/(CurrentVoltConversion*1e-6))>EngageCurrent)
//			if (PullOutGain==1)
//				CurrentVoltGain +=GainChange
//				CurrentVoltConversion = 10^(6-CurrentVoltGain)
//				CurrentSuppress = CurrentSuppressConst*10^(3-CurrentVoltGain)
//				execute "GPIBWrite \"H6R"+num2str(CurrentVoltGain)+"X\""
//				execute "GPIBWrite \"H8S"+num2str(CurrentSuppress/1000000)+",0X\""
//				sleep/s 0.2
//			endif
			TipCurrent=1
			MXStopTask(G_ID2);
			MXClearTask(G_ID2)
			break
		endif
				
		DCOffset_nm=DCOffset_nm+EngageStepSize
		ContactOffset = DCOffset_nm/K_ZPiezoScale
		TempWave[0,MinNumPoints-1]=ContactOffset
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

		error = MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		//if (GetRTError(1))
		//endif
		sleep/S EngageDelay/1000		// in EngageDelay is in milliseconds; was commented out (MK)
		j=j+1
		Variable keys = getKeyState(0)
		if(keys ==2)
			MXStopTask(G_ID2)
			MXClearTask(G_ID2)
			MXClearTask(G_ID1)	
			MXClearTask(G_ID3)	
			break
		endif

	while (j<max_count)
//			//now drag tip along bottom	
//				X_Offset+=1
//				if (X_Offset>1000)
//					X_Offset=5
//				Endif
//				SetXOffset(" ",X_Offset," ", " ")
//				
//				print "Offset X"

	printf "G = %3.3f; I = %3.3f\r",Conductance, Current/(CurrentVoltConversion*1e-6)
			
	if (TipCurrent == 1)		// If there is current, then go ahead and pull out tip
		PullOutFail=0
//		sleep/S EngageDelay/1000		// in EngageDelay is in milliseconds
//		TempWave[0,MinNumPoints-1]=(DCOffset_nm-3)/K_ZPiezoScale
//		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
//		MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
//		if (GetRTError(1))
//		endif
//		DCOffset_nm-=3

////****************************************add ramp modification for pull/push/pull*********************************************************Mike

	sleep/S EngageDelay/1000		// in EngageDelay is in milliseconds
		
		Variable PushSize=4		//How much to push back (in nm)
		Variable PushNum=1		//How many times to do a push/pull sequence before breaking
		Variable PushPosition=4	//Where during the pull should the first push start (in nm)
		Variable HoldLength=0
		
		//Variable PushPositionP=PushPosition/(NumPtsOut*DeltaEx)*NumPtsOut
		//Variable PushSizeP=PushSize/(NumPtsOut*DeltaEx)*NumPtsOut
		Variable PushPositionP=PushPosition/Size*NumPtsOut
		Variable PushSizeP=PushSize/Size*NumPtsOut
		Variable u=0
		Variable HoldLengthP=HoldLength/Size*NumPtsOut
		//Make/O/N=PushSizeP SawToothPart
		//SawToothPart=p*deltaEx
		RampOutput=RampOutput+DCOffset_nm/K_ZPiezoScale

		//CODE for push pull
//		RampOutput[PushPositionP+PushSizeP*(2*u),inf]+=(p-(PushPositionP+PushSizeP*(2*u)))*DeltaEx*2
//		RampOutput[PushPositionP+PushSizeP*(2*u+1),inf]+=-(p-(PushPositionP+PushSizeP*(2*u+1)))*DeltaEx*2
//		//END CODE for push pull
		
		//**************************************************************************************************************************************************
		
		//RampOutput=RampOutput+DCOffset_nm/K_ZPiezoScale;
		MXStartTask(G_ID1)
		MXStartTask(G_ID3)		
		for (i=1;i<NumSeg+1;i+=1)	// Loops through each segment
			
			TempWave[0,MinNumPoints-1]=RampOutput[(i-1)*MinNumPoints+p]
			TempWave[MinNumPoints,MinNumPoints*2-1]=RampBias[(i-2)*MinNumPoints+p]
			MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
			if (GetRTError(1))
			endif

		endfor
		DCOffset_nm = RampOutput[NumPtsOut-1]*K_ZPiezoScale
		TempWave[0,MinNumPoints-1]=DCOffset_nm/K_ZPiezoScale
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

		MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif

		MXReadAnalogF64(G_ID1,10,2,WaveIn);
		MXReadAnalogF64(G_ID3,10,1,SenseIn);
////////////*********************High Res Card Reading**********************////////		
		VoltageIn=wavein[p]
		CurrentIn=WaveIn[p+NumPtsIn]
		MXStopTask(G_ID1)
		MXClearTask(G_ID1)
/////////////********************Low Res Reading*****************************////////////
//		CurrentIN=sensein[p+NumPtsIn]
//		VoltageIn=sensein[p+NumPtsIn*2]
//		redimension/n=(numptsin) senseIn
		MXStopTask(G_ID3)
		MXClearTask(G_ID3)
////////////**********************************************************************////////////
//		SenseIn=WaveIn2[p]
//		CurrentIn2=WaveIn2[p+NumPtsIn2]
//		Xin=WaveIn2[p+2*NumPtsIn]
//		Yin=WaveIn2[p+3*NumPtsIn]
//		duplicate/o Xin Rin
//		Rin=sqrt(Xin^2+Yin^2)
//		Smooth/B 41, Rin

		wavestats/R=[NumPtsIn-1000,NumPtsIn-500]/Q currentin; print v_sdev
		SenseIn=SenseIn*K_SenseScale
		smooth/B 11, SenseIn
		VoltageIn=-VoltageIn


		Make/O/N=(NumPtsOut) PullOutVoltage,PullOutConductance,POExtension, PullOutCurrent
		SetScale/I x 0,Size, PullOutVoltage,PullOutConductance,POExtension,PullOutCurrent
		
//		Differentiate VoltageIn/D=VoltageIn_DIF
		wavestats/Q/R=[NumPtsIn-100,NumPtsIn-1]/Q VoltageIn
//		Variable temp =  v_avg+(-SpikeVal-v_avg)/2
		Findlevel/Q/P/R=[NumPtsIn-101,NumPtsIn-5000] VoltageIn, v_avg+(-SpikeVal-v_avg)/20
//		wavestats/R=[NumPtsIn-5000-SpikeEnd+SpikeStart,NumPtsIn-1]/Q VoltageIn_DIF
		if (V_flag ==0)
			DelayOffset=V_LevelX-SpikeEnd
		else
			DelayOffset=2200
			PullOutFail=3
			printf "Did Not Sync Input and Ouput\r"
		endif
//		print delayoffset
//		DelayOffset=2200
		duplicate/o currentin currentin_raw	
		CurrentIn=-CurrentIn*CurrentVoltConversion*1e-6
		PullOutVoltage=VoltageIn[p+DelayOffset]
		PullOutCurrent=-CurrentIn[p+DelayOffset]
		PullOutConductance=-CurrentIn[p+DelayOffset]
		PullOutConductance=PullOutConductance/PullOutVoltage/77.5e-6		// Convert Volts from input to microamps
//		POExtension=RampIn[p+DelayOffset-250]*K_ZPiezoScale-DCOffset_nm
		POExtension=RampOutput
		SetScale/P x DelayOffset,1,"", RampOutput

//		Make/O/N=2 PullOutExtension
//		PullOutExtension[0]=0
//		PullOutExtension[1]=Size

		DoWindow/F PullOutGvsE
		if (V_Flag==0)
			Display/W=(4.5,257.75,399,452) 
			DoWindow/C PullOutGvsE
			appendtograph/R PullOutVoltage
			appendtograph PullOutConductance
			ModifyGraph grid(left)=1
			ModifyGraph prescaleExp(right)=3,notation(right)=1
			ModifyGraph rgb(PullOutVoltage)=(32768,40704,65280)
			ModifyGraph mode=0
			Label right "Measured Bias (mV)"
			Label left "Conductance (G\\B0\\M)"
			Label bottom "Displacement (nm)"
			DoUpdate
		else
			DoUpdate
		endif
		DoWindow/F PullOutLow
		if (V_Flag==0)
			Display/W=(4.5,479,399,687.5) PullOutConductance as "PullOutLowG"
			DoWindow/C PullOutLow
			appendtograph/R PullOutVoltage
			ModifyGraph grid(left)=1
			ModifyGraph log(right)=1
			ModifyGraph prescaleExp(right)=3,notation(right)=1
			ModifyGraph rgb(PullOutVoltage)=(32768,40704,65280)
			ModifyGraph mode=0
			SetAxis left 1e-05,5.58676
			ModifyGraph log(left)=1
			
			Label left "Conductance (G\\B0\\M)"
			Label bottom "Displacement (nm)"
			DoUpdate
		else
			DoUpdate
		endif
		
		DoWindow/F SenseInDisplay
		if (V_Flag==0)
			Display/W=(5.25,42.5,399,232.25) SenseIn
			AppendtoGraph/R RampOutput
			ModifyGraph rgb(RampOutput)=(0,0,65280)
//			ModifyGraph offset(RampOutput)={DelayOffset,0}
			Label left "Sensor (nm)";
			Label bottom "Data Points";
			Label right "Ramp Output (V)"
			DoWindow/C SenseInDisplay
//		else
//			ModifyGraph offset(RampOutput)={DelayOffset,0}
		endif
	
	else
		if (PullOutFail !=2)
			PullOutFail=1 // No current so did not pull out
		endif
	endif 
	DoWindow/F Current_Measurement
	Slider Pos_Z value=DCOffset_nm/K_ZPiezoScale
	DoUpdate
	//if (FromGo==0)
		StartCurrent(" ")
	//endif
end

Function tipShape()
	
	NVAR G_ID1=root:Data:G_ID1
	NVAR G_ID2=root:Data:G_ID2
	NVAR AcquisitionRate = root:Data:G_acquisitionRate;
	
	Variable numptsin=40;

		
	
//	MXWriteAnalogF64(G_OD3,10,2,OffsetRamp);
//	if (GetRTError(1))
//	endif
	
//	MXCreateTask("G_ID2");
//	MXCreateAIVoltageChan(G_ID2,"dev2/ai0",-10,10); //move x piezo
////	MXCreateAIVoltageChan(G_ID2, "dev2/ai3", -1,1);
//	MXCfgSampClkTiming(G_ID2,AcquisitionRate,0,20);
//
//	MXCreateTask("G_ID1");
//	MXCreateAIVoltageChan(G_ID1,"dev1/ao0",-5,5);  //move z piezo
////	MXCreateAIVoltageChan(G_ID1,"dev1/ai1",-10,10)
//	MXCfgSampClkTiming(G_ID1,AcquisitionRate,1,NumPtsIn);
//


end

Function mpoh(start)
	Variable start
	NVAR PullOutNumber=root:Data:G_PullOutNumber
	NVAR SaveCheck=root:Data:G_SaveCheck
	wave PullOutConductance
	Variable i,error
	String PullOutWave
	
	make/O/N=1 POCondHist
	POCondHist=0
	if (PullOutNumber==0)
		return 0
	endif
	if (Start>PullOutNumber)
		return 0
	endif
	if (PullOutNumber>=start)
		PullOutWave="PullOutConductance_"+num2str(start)
		LoadWave/Q/H/P=Relocate/O PullOutWave+".ibw"
		duplicate/O $PullOutWave Conductance_D
		redimension/N=(numpnts($PullOutWave)-22) Conductance_D
		killwaves $PullOutWave
		Histogram/B={0,.01,1000} Conductance_D POCondHist
		DoWindow/F RawPullOutHist
		if (V_Flag==0)
			Display /W=(435,47,813,247.25) POCondHist
			DoWindow/C RawPullOutHist
			ModifyGraph mode=5
			ModifyGraph rgb(POCondHist)=(65280,0,0)
			ModifyGraph hbFill=2	
			Label left "Counts"
			Label bottom "Conductance (G\B0\M)"
			setaxis left 0,20000
		endif
		TextBox/C/N=text1/F=0/A=MC/X=30.00/Y=45.00 "Started at "+num2str(start)
	endif
	if ((PullOutNumber-start)>2)
		for (i=start+1;i<PullOutNumber;i+=1)
			PullOutWave="PullOutConductance_"+num2str(i)
			LoadWave/O/Q/H/P=Relocate/O PullOutWave+".ibw"
			duplicate/O $PullOutWave Conductance_D
			redimension/N=(numpnts($PullOutWave)-22) Conductance_D
			killwaves $PullOutWave
			Histogram/A  Conductance_D POCondHist
			TextBox/C/N=text0/F=0/A=MC num2str(i)
		endfor
	endif
	killwaves Conductance_D
	DoWindow/F RawPullOutHist
end

Function Go_PullOut(ctrlName) : ButtonControl
	String ctrlName
	NVAR PullOutNumber=root:Data:G_PullOutNumber
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset	// in nm
	NVAR Z_Step_Size = root:Data:G_Z_Step_Size
	NVAR PointsPerTrace=root:Data:G_PointsPerTrace
	NVAR PullOutAttempt = root:Data:G_PullOutAttempt
	NVAR PullOutFail=root:Data:G_PullOutFail
	NVAR SaveCheck=root:Data:G_SaveCheck
	NVAR G_OD1=root:Data:G_OD1
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR StopNumber = root:Data:G_StopNumber
	NVAR Zmove=root:Data:G_Z_Step_Size
	NVAR ZeroCutOff = root:Data:G_ZeroCutOff
	NVAR X_Offset = root:Data:G_X_Offset
	NVAR X_OffsetSwitch = root:Data:G_XOffsetSwitch
	NVAR TipBias = root:Data:G_TipBias
	NVAR CurrentVoltConversion = root:Data:G_CurrentVoltConversion
	NVAR SmashNum = root:data:G_SmashNumber
	NVAR XOffsetNum = root:data:G_XOffsetNumber
	NVAR EngageConductance = root:Data:G_EngageConductance
	String AStatusRequest
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus

	WAVE PullOutConductance, PullOutCurrent

	Variable i=0,kx=0,kn=0,numpts
	Variable Mean_Conductance,  Dev_Conductance, HistSum
	Variable MaxCurrent=10*CurrentVoltConversion/77.5/TipBias*1000
	Variable StopValue=0
	Make/O/N=1 CondHist

	PullOutFail=0
	if (PullOutNumber>=StopNumber)
		StopValue=2
		return StopValue
	endif	

	StopCurrent(" ")
	do
	
		if (PullOutAttempt>0)
			if ((PullOutAttempt-(round(PullOutAttempt/SmashNum))*SmashNum)==0)
				//MoveZDelta(30) // Default 100
			  //    MoveZDelta(-50) // Default 110
			     //  MoveZDelta(30) // Default 100
			     // MoveZDelta(-40)
				//MoveZDelta(30) // Default 100
			       //MoveZDelta(-50) // Default 110
//			
//			    MoveZDelta(550) // Default 100
//			    sleep/s 2
//			    MoveZDelta(-560) // Default 110
//			   
//			      MoveZDelta(350) // Default 100	
//			
//			    MoveZDelta(-360) // Default 110
	
			 //  MoveZDelta(-110) // Default 110
			  //   MoveZDelta(350) // Default 100
			  //    MoveZDelta(-360) // Default 110
			       sleep/s 1
				 MoveZDelta(50) // Default 100
			 	MoveZDelta(-60) // Default 110   MoveZDelta(250) // Default 100
			    
				print "Smashed Tip"
				//beep
			endif
			if (((PullOutAttempt-(round(PullOutAttempt/1000))*1000)==0))
				ZeroCorrectProc(" ")
				print "Ran Zero Correct"
				sleep/s 10
			endif
//			if (((PullOutAttempt-(round(PullOutAttempt/XOffsetNum))*XOffsetNum)==0)&&(X_OffsetSwitch==1))
//				X_Offset+=5
//				if (X_Offset>1000)
//					X_Offset=0
//				Endif
//				SetXOffset(" ",X_Offset," ", " ")
//				print "Offset X"
//			endif
		endif
		if (ExcursionOffset>560)
			print "positive Piezo limit reached"
			VDTOperationsPort2 Com1
			VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
			VDTWrite2 "0MO\r\n"
			VDTWrite2 "0PR-10\r\n"
			AMotorStatus=1
			sleep/T 30
			VDTWrite2 "0MF\r\n"
			//AMotorOff(ctrlName)
			VDTWrite2 "0TS?\r\n"
			VDTRead2/T="\n"/O=10 AStatusRequest
			sscanf AStatusRequest, "0TS? %s",AStatus
			strswitch(AStatus)
			case "81":
			AMotorStatus = 1
			break
			case "80":
			AMotorStatus = 1
			break
			case "65":
			AMotorStatus = 0
			break
			endswitch
			//DoUpdate /W=Actuator_Control()
	
			StopValue=5
		elseif (ExcursionOffset<-500)
			print "negative Piezo limit reached"
			VDTOperationsPort2 Com1
			VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
			VDTWrite2 "0MO\r\n"
			VDTWrite2 "0PR10\r\n"
			AMotorStatus=1
			sleep/T 30
			VDTWrite2 "0MF\r\n"
			//AMotorOff(ctrlName)
			VDTWrite2 "0TS?\r\n"
			VDTRead2/T="\n"/O=10 AStatusRequest
			sscanf AStatusRequest, "0TS? %s",AStatus
			strswitch(AStatus)
			case "81":
			AMotorStatus = 1
			break
			case "80":
			AMotorStatus = 1
			break
			case "65":
			AMotorStatus = 0
			break
			endswitch
			//DoUpdate /W=Actuator_Control()
			StopValue=5	
		endif
//		if (abs(ExcursionOffset)>580)
//			StopValue=5
//			break
//		endif
		GetPullOut("FromGo")
		
		PullOutAttempt+=1
//		if (PullOutFail != 2)
//		endif

		if (PullOutFail==0)	// Did not fail
			WaveStats/Q/R=[PointsPerTrace*0.92, PointsPerTrace*0.94] PullOutConductance
			Mean_Conductance = V_avg
			Dev_Conductance = V_adev
 
			if (abs(V_avg)>ZeroCutoff)  // end of PullOutConductance is not close to zero
//			if (V_avg>ZeroCutoff)  //WARNING: QUICK CHANGE 
//			wavestats/Q/R=[0,pointsPerTrace*.02] puloutconductance
//			if (v_avg< 2) //don't save if cond trace doesn't reach 2
				ExcursionOffset = ExcursionOffset-Z_Step_Size	//No current in the forward or backward direction so move sample closer to tip
				DoWindow/F Current_Measurement
				Slider Pos_Z value=ExcursionOffset/K_ZPiezoScale
				Make/D/O/N=(MinNumPoints*2) TempWave	
				TempWave[0,MinNumPoints-1]=ExcursionOffset/K_ZPiezoScale
				TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
				MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
				if (GetRTError(1))
				endif
				printf("End > ZeroCutoff, %3.3e\r"), V_avg
//			endif
			else	// else save data
				if (SaveCheck == 0)	
					WaveStats/Q/R=[0,round(PointsPerTrace/200)] PullOutConductance
//					if ((V_avg>EngageConductance)&&(V_avg<30))   // limit initial conductance to less than 30 G_0
					if ( V_avg > 1)//2
						HistSum=0
						CondHist=0
						Histogram/B={0.1,.1,40} PullOutConductance CondHist
						HistSum=sum(condhist,0.2,10.1)
						if (Dev_Conductance < .01) 
							if (HistSum>10)	// Save if there are enough low conductance points
								printf("Avg = %3.3e, Dev = %3.3e, PO # %d, Offset %3.0f, HistSum = %d\r"), Mean_Conductance, Dev_Conductance, PullOutNumber,ExcursionOffset,HistSum
								SavePullOut(" ")
							endif
						else
							printf("Avg = %3.3e, Dev = %3.3e\r"),  Mean_Conductance, Dev_Conductance
						endif
					//else
					//	printf " No Contact, Deviation = %2.6f\r",V_adev
					endif
				else // Save ALL curves
					
						SavePullOut(" ")
					
				endif
			
			endif
		endif
		
		Variable keys = getKeyState(0);
		if (keys==2)	
		//if(str2num(KeyboardState("")[1])==1)
			StopValue=1
			break
		endif		
		if (PullOutNumber>=StopNumber)
			StopValue=2
			break
		endif
		i=i+1

	while (i < 100000)
	
	//StartCurrent(" ")
	return StopValue
End

Function SavePullOut(ctrlName) : ButtonControl
	String ctrlName
	NVAR PullOutNumber=root:Data:G_PullOutNumber
	
	NVAR MaxExcursion= root:Data:G_MaxExcursion
	NVAR Rate=root:Data:G_PullOutRate// in nm/s
	NVAR EngageStepSize = root:Data:G_EngageStepSize
	NVAR CurrentGain=root:Data:G_CurrentGain
	NVAR ExtensionGain=root:Data:G_ExtensionGain	
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion
	NVAR TipBias = root:Data:G_TipBias
	NVAR EngageConductance = root:Data:G_EngageConductance
	NVAR EngageDelay = root:Data:G_EngageDelay
	NVAR RiseTime = root:Data:G_RiseTime
	NVAR VoltageOffset = root:Data:G_VoltageOffset
	NVAR ExternalBiasCheck = root:Data:G_ExternalBiasCheck
	NVAR Actual_Bias = root:Data:G_Actual_Bias
	NVAR BeepOn = root:Data:G_BeepOn
	NVAR CurrentSuppress = root:Data:G_CurrentSuppress // in MicroAmps
	NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset	// in nm
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset	// in nm
	NVAR BiasSave=root:Data:G_BiasSaveCheck
	NVAR SeriesResistance = root:Data:G_SeriesResistance
	NVAR SenseSave=root:Data:G_SenseSaveCheck
	NVAR CVBlockCreated=root:Data:G_CVBlockCreated
	NVAR BlockCreated=root:Data:G_BlockCreated
	NVAR SBlockCreated=root:Data:G_SBlockCreated

	 Wave SenseIn
	Variable StartX, StopX
	Wavestats/Q/R=[0,1000] SenseIn
	StartX=V_avg
	Wavestats/Q/R=[numpnts(SenseIn)-1000,numpnts(SenseIn)-1] SenseIn
	StopX=V_avg
	make/O/N=20 TempW
	
	TempW[0] = MaxExcursion
	TempW[1] = Rate
	TempW[2] = EngageStepSize
	TempW[3] = ExcursionOffset
	TempW[4] = BiasSave
	TempW[5] = StartX-StopX
	TempW[6] = Actual_Bias
	TempW[7] = CurrentGain
	TempW[8] = ExtensionGain
	TempW[9] = CurrentVoltConversion
	TempW[10] = TipBias
	TempW[11] = 0
	TempW[12] = SeriesResistance
	TempW[13] = EngageConductance
	TempW[14] = SenseSave
	TempW[15] = 0
	TempW[16] = RiseTime
	TempW[17] = ExternalBiasCheck
	TempW[18] = VoltageOffset
	TempW[19] = CurrentSuppress	

	String Conductance="PullOutConductance_"+Num2Str(PullOutNumber)
	
	Variable N=numpnts(PullOutConductance),i
	Wave PullOutConductanceSave, PullOutExtension,POCondHist
	Wave PullOutVoltage		
	Wave PullOutCurrent
	Wave POExtension
	
	Variable M,L
	
	Duplicate/O PullOutConductance PullOutconductanceSave
	redimension/N=(N+2+numpnts(TempW)) PullOutConductanceSave
	
//	PullOutConductanceSave[N]=0
//	PullOutConductanceSave[N+1]=MaxExcursion	
	
	PullOutConductanceSave[N+2, N+2+numpnts(Tempw)-1]=TempW[p-N-2]
	
///individual save///	
//	Duplicate/O PullOutConductanceSave $Conductance
//	Save/C/P=Relocate $Conductance
//	Killwaves $Conductance
///individual save///	
	
	M=numpnts(PullOutVoltage)
	L=numpnts(POExtension)
	
	Duplicate/O PullOutVoltage PullOutVoltageSave 
	redimension/N=(M+2) PullOutVoltageSave	
	PullOutVoltageSave[M]=0
	PullOutVoltageSave[M+1]=MaxExcursion
	
	
	Duplicate/O PullOutCurrent PullOutCurrentSave 	
	redimension/N=(M+2) PullOutCurrentSave	
	PullOutCurrentSave[M]=0
	PullOutCurrentSave[M+1]=MaxExcursion
	
	Duplicate/O POExtension POExtensionSave
	redimension/N=(L+2) POExtensionSave	
	POExtensionSave[L]=0
	POExtensionSave[L+1]=MaxExcursion
	
	
	//////BLOCKCREATE STARTS/////
	if(mod(PullOutNumber,100)==1)
		Make/O/N=(Numpnts(PullOutConductanceSave),100) ConductanceBlock=NAN
		BlockCreated=1
		Make/O/N=(Numpnts(PullOutVoltageSave),100) VoltageBlock=NAN
		Make/O/N=(Numpnts(PullOutCurrentSave),100) CurrentBlock=NAN
		CVBlockCreated=1
		Make/O/N=(Numpnts(POExtensionSave),100) ExtensionBlock=NAN
		SBlockCreated=1		
	endif
	//////BLOCKCREATE ENDS/////
	
	
	
	/////SAVE TO BLOCKS STARTS////	
	if(BlockCreated==1)
	ConductanceBlock[][mod(PullOutNumber-1,100)]=PullOutConductanceSave[p]
	VoltageBlock[][mod(PullOutNumber-1,100)]=PullOutVoltageSave[p]
	CurrentBlock[][mod(PullOutNumber-1,100)]=PullOutCurrentSave[p]
	ExtensionBlock[][mod(PullOutNumber-1,100)]=POExtensionSave[p]
	endif						
	
	/////SAVE TO BLOCKS ENDS////
	
///individual save///
	
//	
//	if ((BiasSave==1)||(round(PullOutNumber/100))==PullOutNumber/100)
//
//		String Voltage="PullOutVoltage_"+Num2Str(PullOutNumber)
//		String Current="PullOutCurrent_"+Num2Str(PullOutNumber)
//		
//		Duplicate/O PullOutVoltage $Voltage		
//		Save/C/P=Relocate $Voltage
//		Killwaves $Voltage
//		
//		Duplicate/O PullOutCurrent $Current
//		Save/C/P=Relocate $Current
//		Killwaves $Current
//	endif
//	if ((SenseSave==1)||(round(PullOutNumber/100))==PullOutNumber/100)
//		
//		String Extension="PullOutExtension_"+Num2Str(PullOutNumber)
//		Duplicate/O POExtension $Extension
//		Save/C/P=Relocate $Extension
//		Killwaves $Extension
//	endif	
///individual save///	

	
	//////SAVEBLOCK STARTS////	
	if(mod(PullOutNumber,100)==0 && BlockCreated==1 )
		String ConductanceBlockName="PullOutConductanceBlock_"+Num2Str(Round(PullOutNumber/100))
		Duplicate/O ConductanceBlock $ConductanceBlockName
		Save/C/P=Relocate2 $ConductanceBlockName
		killwaves $ConductanceBlockName, ConductanceBlock
		
	endif
	
	if(mod(PullOutNumber,100)==0)
		if(BlockCreated==1 && SenseSave==1 )
			String ExtensionBlockName="PullOutExtensionBlock_"+Num2Str(Round(PullOutNumber/100))
			Duplicate/O ExtensionBlock $ExtensionBlockName
			Save/C/P=Relocate2 $ExtensionBlockName
			killwaves $ExtensionBlockName, ExtensionBlock
			
		endif
		if(SenseSave==0)		
			String Extension2="PullOutExtension_"+Num2Str(PullOutNumber)
			Duplicate/O POExtension $Extension2
			Save/C/P=Relocate2 $Extension2
			Killwaves $Extension2		
		endif
	endif	
	
	if(mod(PullOutNumber,100)==0)	
		If(BiasSave==1 && BlockCreated==1)
			String VoltageBlockName="PullOutVoltageBlock_"+Num2Str(Round(PullOutNumber/100))
			Duplicate/O VoltageBlock $VoltageBlockName
			Save/C/P=Relocate2 $VoltageBlockName
			killwaves $VoltageBlockName, VoltageBlock	
			String CurrentBlockName="PullOutCurrentBlock_"+Num2Str(Round(PullOutNumber/100))
			Duplicate/O CurrentBlock $CurrentBlockName
			Save/C/P=Relocate2 $CurrentBlockName
			killwaves $CurrentBlockName, CurrentBlock	
			
		endif		
		If(BiasSave==0)	
			String Voltage2="PullOutVoltage_"+Num2Str(PullOutNumber)
			String Current2="PullOutCurrent_"+Num2Str(PullOutNumber)		
			Duplicate/O PullOutVoltage $Voltage2		
			Save/C/P=Relocate2 $Voltage2
			Killwaves $Voltage2		
			Duplicate/O PullOutCurrent $Current2
			Save/C/P=Relocate2 $Current2
			Killwaves $Current2	
		endif
	endif	
	
	if(mod(PullOutNumber,100)==0)
	BlockCreated=0
	endif
	//////SAVEBLOCK ENDS/////
	
	PullOutNumber=PullOutNumber+1
	
	if (BeepOn==1)
		Beep
	endif
	DoWindow/T kwFrame, "Exp: "+num2str(pulloutnumber)+" "+num2str(round(ExcursionOffset))
	
//	DoWindow/F RawPullOutHist
//	if(V_Flag==0)
//		mpoh(1)
//	else
//		Histogram/A  PullOutConductance POCondHist
//	endif
	TextBox/C/N=text0/F=0/A=MC num2str(PullOutNumber)
	DoUpdate
	
End


Function Set_SliderScale(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR PiezoVFactor = root:Data:G_PiezoVFactor
	
	PiezoVFactor = varNum
	
	Variable SlidermaxV = 3*(PiezoVFactor)
	if (SlidermaxV> 10)
	  	SlidermaxV = 10
	 endif
	 Slider Pos_Z, limits={-SlidermaxV, SlidermaxV,0}
End

Function InitializeGPIB(ctrlName) : ButtonControl
	String ctrlName

	SetUpGPIB()
End
Function LocalGPIB(ctrlName) : ButtonControl
	String ctrlName

	execute "GPIBWrite \"H2X\""
End

Function SetUpGPIB()
	NVAR BoardUD = root:Data:G_BoardUD
	NVAR DeviceUD = root:Data:G_DeviceUD
	NVAR IVConversion = root:Data:G_CurrentVoltConversion // MicroA to Volts
	NVAR TipBias = root:Data:G_TipBias // milli Volts
	Variable/G TempBoardUD, TempDeviceUD
	string cmd
	execute "NI488 ibfind \"gpib0\", TempBoardUD"
	execute "NI488 ibdev 0, 22, 0, 13, 1, 0, TempDeviceUD"
	execute "GPIB device TempDeviceUD"
	execute "GPIB board TempBoardUD"
	execute "GPIB KillIO"
	execute "GPIB InterfaceClear"
	BoardUD = TempBoardUD
	DeviceUD = TempDeviceUD
	cmd = "GPIBWrite \"C1P0B0N0V"+num2str(TipBias/1000)+"X\""
	execute cmd
	KillVariables TempBoardUD, TempDeviceUD
end

Function SetCurrentVoltConversion(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	String cmd
	NVAR CurrentVoltConversion = root:Data:G_CurrentVoltConversion
	NVAR CurrentVoltGain = root:Data:G_CurrentVoltGain
	NVAR CurrentSuppress = root:Data:G_CurrentSuppress // in MicroAmps
	NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
	NVAR EngageConductance = root:Data:G_EngageConductance

	Variable OldGain = CurrentVoltConversion
	CurrentVoltGain = varNum
	CurrentVoltConversion = 10^(6-CurrentVoltGain)
	CurrentSuppress =  CurrentSuppressConst*10^(3-CurrentVoltGain)
	cmd = "GPIBWrite \"H8S"+num2str(CurrentSuppress/1000000)+",0X\""
	execute cmd
	cmd = ""
	cmd = "GPIBWrite \"H6R"+num2str(CurrentVoltGain)+"X\""
	execute cmd
	cmd = ""
	print "Gain Set To ",CurrentVoltGain,cmd
end

Function SetTipBiasVoltage(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	String cmd

	NVAR ExtBias = root:Data:G_ExternalBiasCheck
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR TipBias = root:Data:G_TipBias	
	variable error


		TipBias = varNum
		if (ExtBias == 0)
			TipBias = round(TipBias/2.5)*2.5
			cmd = "GPIBWrite \"H9V"+num2str(TipBias/1000)+"X\""
			execute cmd	
		else
			Make/D/O/N=(MinNumPoints*2) TempWave
			TempWave[0,MinNumPoints-1]=ExcursionOffset/K_ZPiezoScale
			TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)
			MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
			if (GetRTError(1))
			endif
		endif

	print "Bias Voltage Set to ",TipBias
end
Function SetCurrentSuppress(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	String cmd

	NVAR CurrentSuppress = root:Data:G_CurrentSuppress // in MicroAmps
	NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
	NVAR CurrentVoltGain = root:Data:G_CurrentVoltGain

	Variable SuppressNum, SuppressExp, SuppressValue

	CurrentSuppressConst = varNum
	CurrentSuppress = CurrentSuppressConst*10^(3-CurrentVoltGain)

	cmd = "GPIBWrite \"H8S"+num2str(CurrentSuppress/1000000)+",0X\""
	execute cmd
end

Function SetRiseTime(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	String cmd
	NVAR RiseTime = root:Data:G_RiseTime
	Variable RiseTimeNum

	RiseTime = varNum
	if (RiseTime <0.02)
		RiseTime = 0.01
		RiseTimeNum = 0
	elseif (RiseTime < 0.065)
		RiseTime = 0.03
		RiseTimeNum = 1
	elseif (RiseTime < 0.2)
		RiseTime = 0.1
		RiseTimeNum = 2
	elseif (RiseTime < 0.65)
		RiseTime = 0.3
		RiseTimeNum = 3
	elseif (RiseTime < 2)
		RiseTime = 1
		RiseTimeNum = 4
	elseif (RiseTime < 6.5)
		RiseTime = 3
		RiseTimeNum = 5
	elseif (RiseTime < 20)
		RiseTime = 10
		RiseTimeNum = 6
	elseif (RiseTime < 65)
		RiseTime = 30
		RiseTimeNum = 7
	elseif (RiseTime < 200)
		RiseTime = 100
		RiseTimeNum = 8
	else
		RiseTime = 300
		RiseTimeNum = 9
	endif
	
	cmd = "GPIBWrite \"H7T"+num2str(RiseTimeNum)+"X\""
	execute cmd
	Print "Rise Time set to ",RiseTime
end

Function ZeroCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	if(checked==0)
		execute "GPIBWrite \"C0X\""
	else
		execute "GPIBWrite \"C1X\""
	endif
End

Function ZeroCorrectProc(ctrlName) : ButtonControl
	String ctrlName

	execute "GPIBWrite \"C2X\""
End

Function BiasCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR TipBias = root:data:G_TipBias

	print "Clicked Bias Voltage, trying to do stuff"
	if(checked==0)
		print "Trying to deactivate bias voltage"
		execute "GPIBWrite \"B0X\""
	else
		print "Trying to activate bias voltage"
		execute "GPIBWrite \"B1X\""
		TipBias = round(TipBias/2.5)*2.5
		execute "GPIBWrite \"H9V"+num2str(TipBias/1000)+"X\""
	endif
	print "Got to the end of the Bias Voltage Check function"
End

Function FilterCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if(checked==0)
		execute "GPIBWrite \"P0X\""
	else
		execute "GPIBWrite \"P1X\""
	endif
End
Function GainCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR CurrentVoltConversion = root:Data:G_CurrentVoltConversion

	if(checked==0)
		execute "GPIBWrite \"W0X\""
		CurrentVoltConversion=CurrentVoltConversion*10
	else
		execute "GPIBWrite \"W1X\""
		CurrentVoltConversion=CurrentVoltConversion/10
	endif
End

Function CurrentSuppressCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if(checked==0)
		execute "GPIBWrite \"N0X\""
	else
		execute "GPIBWrite \"N1X\""
	endif

End

Function AutoCurrentSuppress(ctrlName) : ButtonControl
	String ctrlName

	execute "GPIBWrite \"N2X\""

End

Function ExtBiasCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR ExcursionOffset=root:Data:G_ExcursionOffset
	NVAR G_OD1 = root:Data:G_OD1;		// Task Variable for output channel
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	
	Make/D/O/N=(MinNumPoints*2) TempWave

	NVAR TipBias = root:Data:G_TipBias
	if(checked==1)
		DoWindow/F Current_Measurement
		CheckBox check7,value= 0
		BiasCheckProc("",0)
		TempWave[0,MinNumPoints-1]=ExcursionOffset/K_ZPiezoScale
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

		MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif
	else
		TempWave[0,MinNumPoints-1]=ExcursionOffset/K_ZPiezoScale
		TempWave[MinNumPoints,MinNumPoints*2-1]=0

		MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif
		
	endif
	
End
Function SetBiasNew()

	NVAR G_OD3 = root:Data:G_OD3
	NVAR TipBias = root:Data:G_TipBias
	NVAR X_Offset = root:Data:G_X_Offset

	Make/N=20/D/O OffsetRamp
	OffsetRamp[0,9]=X_Offset/K_XPiezoscale
	OffsetRamp[10,19]=-TipBias/1000
	MXWriteAnalogF64(G_OD3,10,2,OffsetRamp);
	if (GetRTError(1))
	else
		Print " Bias Set to", TipBias
	endif

End


Function SetXOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR G_OD3 = root:Data:G_OD3
	NVAR X_Offset = root:Data:G_X_Offset
	NVAR TipBias = root:Data:G_TipBias

	Make/N=20/D/O OffsetRamp
	X_Offset=varNum
	OffsetRamp[0,9]=X_Offset/K_XPiezoscale
	OffsetRamp[10,19]=-TipBias/1000
	MXWriteAnalogF64(G_OD3,10,2,OffsetRamp);
	if (GetRTError(1))
	endif

End

Function RunGoLoop(HitG,Bias,StopN,Gain,Excursion,Rate,StopValue,[N1in, N2in,N3in])
Variable HitG,Bias,StopN,Gain,Excursion,Rate,StopValue,N1in,N2in,N3in

NVAR StopNumber = root:Data:G_StopNumber
NVAR EngageConductance = root:Data:G_EngageConductance
NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
NVAR MaxExcursion = root:Data:G_MaxExcursion
NVAR PulloutRate = root:Data:G_PulloutRate
NVAR N2=root:Data:G_N2
NVAR N3=root:Data:G_N3
NVAR N1=root:Data:G_N1
	If (StopValue==2)
		SetCurrentVoltConversion(" ",Gain," "," ")		// Pull Out Gain UnCheck, 10 mV
		EngageConductance=HitG
		SetTipBiasVoltage(" ",Bias," "," ")
		StopNumber=StopN
		MaxExcursion = Excursion
		PullOutRate = Rate
		N1=N1in
		N2=N2in
		N3=N3in
		StopValue=Go_PullOut(" ")
		if (StopValue==1)
			print "Auto Run Stopped"
		endif
		if (StopValue==5)
			print "Offset out of range"
		endif
	endif
	return StopValue
end

Function RunGo(Final)    // final=1 --> shut down at the end; final=0 --> not shut down
Variable Final
NVAR StopNumber = root:Data:G_StopNumber
NVAR EngageConductance = root:Data:G_EngageConductance
NVAR Pulloutnumber = root:Data:G_PullOutNumber
NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
NVAR PulloutRate = root:Data:G_PulloutRate
NVAR MaxExcursion = root:Data:G_MaxExcursion
NVAR N2=root:Data:G_N2
NVAR N3=root:Data:G_N3
NVAR N1=root:Data:G_N1
Variable StopValue=2
	
//RunGoLoop(HitG,Bias,StopN,Gain,Excursion,Rate,StopValue)

	SaveExperiment
	StopValue=RunGoLoop(5,-300,1101,6,12,20,StopValue)
	StopValue=RunGoLoop(5,300,1201,6,7,20,StopValue)
	StopValue=RunGoLoop(5,-300,1301,6,7,20,StopValue)
	StopValue=RunGoLoop(5,300,1401,6,9,20,StopValue)
	StopValue=RunGoLoop(5,-300,1501,6,9,20,StopValue)
	StopValue=RunGoLoop(2,300,1601,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,1701,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,1801,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,1901,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,2001,6,8,20,StopValue)
	StopValue=RunGoLoop(5,-300,2101,6,12,20,StopValue)
	StopValue=RunGoLoop(5,300,2201,6,7,20,StopValue)
	StopValue=RunGoLoop(5,-300,2301,6,7,20,StopValue)
	StopValue=RunGoLoop(5,300,2401,6,9,20,StopValue)
	StopValue=RunGoLoop(5,-300,2501,6,9,20,StopValue)
	StopValue=RunGoLoop(2,300,2601,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,2701,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,2801,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,2901,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,3001,6,8,20,StopValue)
	StopValue=RunGoLoop(5,-300,3101,6,8,20,StopValue)
	StopValue=RunGoLoop(5,300,3201,6,7,20,StopValue)
	StopValue=RunGoLoop(5,-300,3301,6,7,20,StopValue)
	StopValue=RunGoLoop(5,300,3401,6,9,20,StopValue)
	StopValue=RunGoLoop(5,-300,3501,6,9,20,StopValue)
	StopValue=RunGoLoop(2,300,3601,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,3701,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,3801,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,3901,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,4001,6,8,20,StopValue)
	StopValue=RunGoLoop(5,-300,4101,6,12,20,StopValue)
	StopValue=RunGoLoop(5,300,4201,6,6,20,StopValue)
	StopValue=RunGoLoop(5,-300,4301,6,7,20,StopValue)
	StopValue=RunGoLoop(5,300,4401,6,9,20,StopValue)
	StopValue=RunGoLoop(5,-300,4501,6,9,20,StopValue)
	StopValue=RunGoLoop(2,300,4601,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,4701,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,4801,6,8,20,StopValue)
	StopValue=RunGoLoop(2,-300,4901,6,8,20,StopValue)
	StopValue=RunGoLoop(2,300,5001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,-150,26001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,150,29001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,200,32001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,300,35001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,-300,48001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,-400,51001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,-100,54001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,300,57001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,700,60001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,400,63001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,800,66001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,1000,69001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,900,72001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,-700,75001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,1200,43001,6,7,20,StopValue)
	//StopValue=RunGoLoop(2,800,43001,6,7,20,StopValue)
	//StopValue=RunGoLoop(2,400,51001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,-700,54001,6,7,20,StopValue)
//	StopValue=RunGoLoop(2,-600,21001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,-700,24001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,-400,27001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,300,30001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,500,33001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,700,36001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,600,39001,6,8,20,StopValue)
//	StopValue=RunGoLoop(2,400,42001,6,8,20,StopValue)


//	  MoveZDelta(-500)


//	StopValue=RunGoLoop(1,500, 34001,6,7,20,StopValue)//, N1in=N1, N2in=N2, N3in=N3)
//	StopValue=RunGoLoop(5,7,39001,6,7,20,StopValue)
//	StopValue=RunGoLoop(5, 250, 25001,6,5,20,StopValue,N1in=N1, N2in=N2, N3in=N3)
//	StopValue=RunGoLoop(5,250, 35001, 6, 5, 20,StopValue, N1in=N1, N2in=N2, N3in=N3)
//	StopValue=RunGoLoop(5,100, 14701,6,5,20,StopValue, N1in=N1, N2in=N2 ,N3in=N3)
//	StopValue=RunGoLoop(5,250, 28001,6,5,20,StopValue, N1in=N1, N2in=N2 ,N3in=N3)
//	StopValue=RunGoLoop(5,25,17001,6,5,20,StopValue)
//	StopValue=RunGoLoop(5,250, 11001,6,7,20,StopValue)
//	StopValue=RunGoLoop(5,500, 16001,6,7,20,StopValue)
//	StopValue=RunGoLoop(5,1000, 21001,6,7,20,StopValue)
//	StopValue=RunGoLoop(1,750,27501,7,10,600,StopValue)
//	StopValue=RunGoLoop(5, 250, 25001, 6, 5, 20, StopValue)
//	StopValue=RunGoLoop(5, 1000, 25001, 6, 5, 20, StopValue)
//	StopValue=RunGoLoop(1, 500, 18501, 7, 9, 20, StopValue)
//	StopValue=RunGoLoop(1, 25, 30001, 6, 26, 20, StopValue)   // Valla's rungo, PLEASE DO NOT ALTER
//	StopValue=RunGoLoop(5, 750, 44001, 7, 5, 20, StopValue) 
//	StopValue=RunGoLoop(1, 1000, 37001, 7, 5, 20, StopValue)
//	StopValue=RunGoLoop(1.1, 500, 24001, 7, 10, 20, StopValue,N2in=2,N3in=3)
	
//	StopValue=RunGoLoop(.5, 1100,45001, 6, 5, 20, StopValue)//,N1in=2.5,N2in=2.5,N3in=1)
//	StopValue=RunGoLoop(1, 250,28101, 6, 12, 20, StopValue,n1in=N1,N2in=N2,N3in=N3)
//	StopValue=RunGoLoop(5,500,18001, 6, 5, 20, StopValue)
//	StopValue=RunGoLoop(1.5, 500,8001, 7, 7.8, 20, StopValue,N2in=0.3,N3in=13)
//	StopValue=RunGoLoop(1, 500, 29501, 7, 9, 20, StopValue,N2in=0.3,N3in=13)
//	StopValue=RunGoLoop(1, 500, 39501, 7, 10.2, 20, StopValue,N2in=0.4,N3in=13)
	

//RunGoLoop(HitG,Bias,StopN,Gain,Excursion,Rate,StopValue

	
	SaveExperiment

	If ((StopValue==2)||(StopValue==5))
		StopNumber=100000
		MoveZout(" ")
		MoveZout(" ")
		MoveZout(" ")
		if (Final == 1)
			execute "GPIBWrite \"C1X\""
			MoveZto0(" ")
			DoWindow/F Current_Measurement
			TabControl Tab_0 Value=0
			TabProc(" ",0)
			StopPXI(" ")
		endif
	endif
	SaveExperiment

end


Function AMotorOff(ctrlName): ButtonControl

	String ctrlName
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	String AStatusRequest
	
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MF\r\n"
	VDTWrite2 "0TS?\r\n"
	VDTRead2/T="\n"/O=10 AStatusRequest
	sscanf AStatusRequest, "0TS? %s",AStatus
	strswitch(AStatus)
	case "81":
		AMotorStatus = 1
		break
	case "80":
		AMotorStatus = 1
		break
	case "65":
		AMotorStatus = 0
		break
	endswitch
	
	
end

Function AStartJog(ctrlName): ButtonControl
	
	String ctrlName
	String AStatusRequest
	NVAR AJogSpeed=root:Data:AJogSpeed
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MO\r\n"
	VDTWrite2/O=10 "0JA"+Num2str(AJogSpeed)+"\r\n"
//	VDTWrite2 "0TS?\r\n"
//	VDTRead2/T="\n"/O=10 AStatusRequest
//	sscanf AStatusRequest, "0TS? %s",AStatus
//	strswitch(AStatus)
//	case "81":
//	AMotorStatus = 1
//	break
//	case "80":
//	AMotorStatus = 1
//	break
//	case "65":
//	AMotorStatus = 0
//	break
//	endswitch
	//DoUpdate /W=Actuator_Control()
	AMotorStatus = 1

end


Function AStopJog(ctrlName): ButtonControl
	
	String ctrlName
	String AStatusRequest
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2/O=10 "0ST\r\n"
	sleep/T 30
	VDTWrite2 "0MF\r\n"
	VDTWrite2 "0TS?\r\n"
	VDTRead2/T="\n"/O=10 AStatusRequest
	sscanf AStatusRequest, "0TS? %s",AStatus
	strswitch(AStatus)
	case "81":
	AMotorStatus = 1
	break
	case "80":
	AMotorStatus = 1
	break
	case "65":
	AMotorStatus = 0
	break
	endswitch
	
end


Function APositiveIncrement(ctrlName):ButtonControl	

	String ctrlName
	String AStatusRequest
	NVAR AStepSize=root:Data:AStepSize
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MO\r\n"
	VDTWrite2 "0PR"+Num2Str(AStepSize)+"\r\n"
//	VDTWrite2 "0TS?\r\n"
//	VDTRead2/T="\n"/O=10 AStatusRequest
//	sscanf AStatusRequest, "0TS? %s",AStatus
//	strswitch(AStatus)
//	case "81":
//	AMotorStatus = 1
//	break
//	case "80":
//	AMotorStatus = 1
//	break
//	case "65":
//	AMotorStatus = 0
//	break
//	endswitch
	AMotorStatus = 1
	
end


Function ANegativeIncrement(ctrlName):ButtonControl
	
	String ctrlName
	String AStatusRequest
	NVAR AStepSize=root:Data:AStepSize
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MO\r\n"
	VDTWrite2 "0PR"+Num2Str(-1*AStepSize)+"\r\n"
	//	VDTWrite2 "0TS?\r\n"
//	VDTRead2/T="\n"/O=10 AStatusRequest
//	sscanf AStatusRequest, "0TS? %s",AStatus
//	strswitch(AStatus)
//	case "81":
//	AMotorStatus = 1
//	break
//	case "80":
//	AMotorStatus = 1
//	break
//	case "65":
//	AMotorStatus = 0
//	break
//	endswitch
	AMotorStatus = 1
	
	
end
	


	
	
Function AExtendFully(ctrlName):ButtonControl

	String ctrlName
	String AStatusRequest
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MO\r\n"
	VDTWrite2 "0PA115000\r\n"
	//	VDTWrite2 "0TS?\r\n"
//	VDTRead2/T="\n"/O=10 AStatusRequest
//	sscanf AStatusRequest, "0TS? %s",AStatus
//	strswitch(AStatus)
//	case "81":
//	AMotorStatus = 1
//	break
//	case "80":
//	AMotorStatus = 1
//	break
//	case "65":
//	AMotorStatus = 0
//	break
//	endswitch
	AMotorStatus = 1
	
	
end

Function AGetStatus(ctrlName):ButtonControl
	
	String ctrlName
	String AStatusRequest
	String AErrorRequest
	SVAR AStatus=root:Data:AStatus
	SVAR AError=root:Data:AError
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0TS?\r\n"
	VDTRead2/T="\n"/O=10 AStatusRequest
	sscanf AStatusRequest, "0TS? %s",AStatus
	strswitch(AStatus)
	case "81":
	print "Motor on, motion not in progress"
	break
	case "80":
	print "Moton on, motion in progress"
	break
	case "65":
	print "Motor off, motion not in progress"
	break
	endswitch
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0TE?\r\n"
	VDTRead2/T="\n"/O=30 AErrorRequest
	sscanf AErrorRequest, "OTE? %s" ,AError
	strswitch(AError)
	case "0":
	print "No errors"
	break
	case "1":
	print "Driver fault (open load)"
	break
	case "2":
	print "Driver fault (thermal shut down)"
	break
	case "3":
	print "Driver fault (short)"
	break
	case "6":
	print "invalid command"
	break
	case "7":
	print "Parameter Out of Range"
	break
	case "8":
	print "No Motor connected"
	break
	case "10":
	print "Brown-out"
	break
	case "38":
	print "Command paramter missing"
	break
	case "24":
	print "Positive hardware limit detected"
	break
	case "25":
	print "Negative hardware limit detected"
	break
	case "26":
	print "Positive software limited detected"
	break
	case "27":
	print "Negative software limit detected"
	break
	case "210":
	print "Max velocity exceeded"
	break
	case "211":
	print "Max accelerated exceeded"
	break
	case "213":
	print "Motor not enabled"
	break
	case "214":
	print "Switch to invalid axis"
	break
	case "220":
	print "Homing aborted"
	break
	case "226":
	print "Paramter change not allowed during motion"
	break
	endswitch
	
end


Function AGetPosition(ctrlName):ButtonControl

	String ctrlName
	String APosition
	SVAR APositionInSteps=root:Data:APositionInSteps
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0TP?\r\n"
	VDTRead2/T="\n"/O=30 APosition
	sscanf APosition, "0TP? %s",APositionInSteps
	print "Current Position is " + APositionInSteps + " Microsteps"
	
end

Function AReturnPosition(ctrlName):ButtonControl

	String ctrlName
	String AStatusRequest
	SVAR APositionInSteps=root:Data:APositionInSteps
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	VDTOperationsPort2 Com1
	VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
	VDTWrite2 "0MO\r\n"
	VDTWrite2 "0PA" + APositionInSteps + "\r\n"
//	VDTWrite2 "0TS?\r\n"
//	VDTRead2/T="\n"/O=10 AStatusRequest
//	sscanf AStatusRequest, "0TS? %s",AStatus
//	strswitch(AStatus)
//	case "81":
//	AMotorStatus = 1
//	break
//	case "80":
//	AMotorStatus = 1
//	break
//	case "65":
//	AMotorStatus = 0
//	break
//	endswitch
	AMotorStatus = 1
	
end

Function AStartApproach(ctrlName): ButtonControl
	
	String CtrlName
	String AStatusRequest
	NVAR Actual_Current = root:Data:G_Actual_Current
	NVAR Actual_Bias = root:Data:G_Actual_Bias
	NVAR JunctionBias = root:Data:G_JunctionBias
	NVAR JunctionRes = root:Data:G_JunctionRes
	NVAR MeasureOn = root:Data:G_MeasureOn
	NVAR Actual_Bias =root:Data:G_Actual_Bias
	NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion
	NVAR MaxCurrent = root:Data:G_MaxCurrent
	NVAR G_ID2=root:Data:G_ID2
	NVAR BeepOn = root:Data:G_BeepOn
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR AMotorStatus=root:Data:AMotorStatus
	SVAR AStatus=root:Data:AStatus
	Variable error,NNN=4
	Variable NumPtsIn=100*NNN
	Variable AcquisitionRate=10000
	MaxCurrent=0

	//	SetUpPXI("")
	CurrentMeterONOFFProc(" ",0)
	//	SetUpPXI enables some buttons that need to be disabled again
	Button button3 disable=3
	Button button13 disable=3
	Button button4 disable=1
	Slider Pos_Z disable=1
	SetVariable setvar4 disable=3
	SetVariable setvar3 disable=3
	MXCreateTask("G_ID2");
	MXCreateAIVoltageChan(G_ID2,"dev2/ai0",-10,10);
	MXCreateAIVoltageChan(G_ID2,"dev2/ai1",-10,10);
	MXCreateAIVoltageChan(G_ID2,"dev2/ai2",-10,10);	
	MXCreateAIVoltageChan(G_ID2,"dev2/ai3",-1,1); //voltage at the junction
	MXCfgSampClkTiming(G_ID2,AcquisitionRate,0,NumPtsIn);
		
	Make/D/O/N=(NumPtsIn) WaveInMeter=0
	Make/D/O/N=(NumPtsIn/NNN) BiasIn, CurrentMeterIn, JuncBiasIn;
		
		
	//	Start the reading/approaching loop	
		
	DoWindow/K Counter 	
	Variable approachcount=0
	
	Actual_Current=0
		
	Do
		VDTOperationsPort2 Com1
		VDT2/P=Com1 baud=19200, databits=8, in=2,out=2, parity=0, stopbits=1
		VDTWrite2 "0MO\r\n"
		VDTWrite2 "0PR-1\r\n"
//		ANegativeIncrement("    ")
		approachcount+=1
		error = MXReadAnalogF64(G_ID2,10,4,WaveInMeter);
		if (GetRTerror(1))
		endif
		
		
		BiasIn=WaveInMeter[p]
		CurrentMeterIn=WaveInMeter[p+NumPtsIn/NNN]
		//JuncBiasIn = WaveInmeter[p+3*NumPtsIn/NNN]
		Actual_Current = (sum(CurrentMeterIn,NumPtsIn/(NNN*2),(NumPtsIn/NNN)-1)/(NumPtsIn/NNN/2))*CurrentVoltConversion
		//Actual_Bias = (sum(BiasIn,NumPtsIn/(NNN*2),(NNN-1)*NumPtsIn/NNN-1)/(NumPtsIn/NNN/2))
		//JunctionBias = (sum(JuncBiasIn, NumPtsIn/(NNN*2), (NNN-1)*NumPtsIn/NNN-1)/(NumPtsIn/NNN/2))
		//JunctionRes = abs(1e-6*(Actual_current/JunctionBias)/(K_G0*1e-6))
		DoUpdate
	
		Variable keys = getKeyState(0);
		if (keys==2)	
		//if(str2num(KeyboardState("")[1])==1)
		VDTWrite2 "0TS?\r\n"
		VDTRead2/T="\n"/O=10 AStatusRequest
		sscanf AStatusRequest, "0TS? %s",AStatus
		strswitch(AStatus)
		case "81":
		AMotorStatus = 1
		break
		case "80":
		AMotorStatus = 1
		break
		case "65":
		AMotorStatus = 0
		break
		endswitch
			break
		endif	
		
		AMotorStatus=1
		
		//DoUpdate /W=Actuator_Control()
		
//		DoWindow/F Counter
//		if (V_Flag==0)
//		Display /W=(5.25,582.5,91.5,608.75)
//		DoWindow/C Counter
//		endif
//		TextBox/N=text0/F=0/A=MC num2str(approachcount)
	While (abs(Actual_Current)<.15)
		Print ApproachCount
		MXStopTask(G_ID2)
		MXClearTask(G_ID2)
		CurrentMeterONOFFProc(" ",1)
		
end

function GetR(Series,Test)
String Series, Test

NVAR CurrentVoltConversion=root:Data:G_CurrentVoltConversion

Wave currentin, voltagein, conductancein, sensein
Wave/T SeriesR,TestR
Wave cur, vol,res,cond, rmsCur, rmsVol, Gain
variable NN
getexcursion()

NN=numpnts(cur)
redimension/N=(NN+1) cur, vol,res,cond,SeriesR,TestR,rmsCur, rmsVol,Gain
SeriesR[NN]=Series
TestR[NN]=Test
Gain[NN]=6-log(CurrentVoltConversion)
wavestats/q currentin;
cur[NN]=(v_avg*CurrentVoltConversion)*1e-6
currentin-=v_avg
wavestats/q currentin
rmsCur[NN]=V_sdev*CurrentVoltConversion*1e-6
wavestats/q voltagein
vol[NN]= v_avg-2.72e-04 //zero corrected ch0_hires
res[NN]=(v_avg-2.72e-04)/Cur[NN]
rmsVol[NN]=V_sdev
cond[NN]=cur[NN]/vol[NN]/77.5e-6

wavestats/q sensein
print "voltage = ", v_avg+0.00032697 //zero corrected ch0_lowres
print "vol rms = ", v_sdev

end

function GetIV(Maxbias,name)
Variable Maxbias
String Name
	NVAR Size = root:Data:G_MaxExcursion
	NVAR EngageConductance = root:Data:G_EngageConductance
	NVAR EngageStepSize = root:Data:G_EngageStepSize
	NVAR EngageDelay = root:Data:G_EngageDelay
	NVAR CurrentGain = root:Data:G_CurrentGain
	NVAR TipBias = root:Data:G_TipBias
	NVAR DCOffset_nm=root:Data:G_ExcursionOffset	// in nm
	NVAR PointsPerTrace=root:Data:G_PointsPerTrace
	NVAR ExtensionGain=root:Data:G_ExtensionGain	
	NVAR ExcursionRate=root:Data:G_PullOutRate// in nm/s
	NVAR VoltageOffset = root:Data:G_VoltageOffset
	NVAR PullOutFail = root:Data:G_PullOutFail
	NVAR PullOutGain = root:Data:G_PullOutGain
	NVAR CurrentVoltConversion = root:Data:G_CurrentVoltConversion
	NVAR CurrentVoltGain = root:Data:G_CurrentVoltGain
	NVAR CurrentSuppress = root:Data:G_CurrentSuppress // in MicroAmps
	NVAR CurrentSuppressConst = root:Data:G_CurrentSuppressConst
	NVAR GainChange = root:Data:G_GainChange
	NVAR G_OD1=root:Data:G_OD1
	NVAR G_ID1=root:Data:G_ID1
	NVAR G_ID2=root:Data:G_ID2
	NVAR G_ID3=root:Data:G_ID3
	NVAR AcquisitionRate=root:Data:G_AcquisitionRate
	NVAR CardTimeout = root:Data:G_CardTimeout;
	NVAR MinNumPoints = root:Data:G_MinNumPointsOutput;
	NVAR ExternalBiasCheck = root:Data:G_ExternalBiasCheck
	NVAR SeriesResistance = root:Data:G_SeriesResistance
	NVAR BiasSave=root:Data:G_BiasSaveCheck
	NVAR SenseSave=root:Data:G_SenseSaveCheck
	NVAR N2in=root:Data:G_N2
	NVAR N3=root:Data:G_N3
	NVAR N1in=root:data:G_N1
	NVAR COND=root:Data:G_ConductanceIN
	NVAR EngageCurrent = root:Data:G_EngageCurrent
	NVAR x_offset = root:Data:G_x_offset

             
	Variable MaxIVBias// = root:Data:G_MaxIVBias
	Variable Bias = TipBias+VoltageOffset

	Variable Offset = DCOffset_nm/K_ZPiezoScale 	// offset in volts
	Variable NumSeg, i, j,error
	Variable max_count
	Variable ContactOffset
	Variable Conductance, current
	Variable TipCurrent = 0
	Variable MinCond = 0.3
	Variable pNum=0
	Variable DelayOffset = MinNumPoints+5000
	Variable DeltaEx=ExcursionRate/K_ZPiezoScale/AcquisitionRate // in units of volts
	Variable DeltaBias=0.5
	Variable LastX, LastV,N1B,N2B, N1, N2
	Variable CAPnm=0.5
	Variable CAP=round(CAPnm/ExcursionRate*AcquisitionRate)
	
	Size=10
	Variable NumPtsOut = round(Size/ExcursionRate*AcquisitionRate)
	Variable NumPtsIn = NumPtsOut+5000
	
	PointsPerTrace = NumPtsOut
	
	max_count = round(20*Size/EngageStepSize) 
	
	MXCreateTask("G_ID1");
	MXCreateAIVoltageChan(G_ID1,"dev1/ai0",-5,5);
	MXCreateAIVoltageChan(G_ID1,"dev1/ai1",-10,10)
	MXCfgSampClkTiming(G_ID1,AcquisitionRate,1,NumPtsIn);

	Make/D/O/N=(NumPtsIn) CurrentIn, VoltageIn//, SenseIn
	Make/D/O/N=(NumPtsIn*2) WaveIn
	NumSeg=NumPtsOut/MinNumPoints;
	make/O/D/N=(MinNumPoints*2) TempWave

	Make/N=(NumPtsOut)/D/O RampOutput, RampBias	
	
	RampOutput[0,NumPtsOut-1]=-p*DeltaEx //DEFAULT Pull Definition
	RampBias = -(tipbias/1000)                    // DEFAULT Bias WAVE

//	RampBias[0, NumPtsOut/2] = 0 + p*(1)/(NumPtsOut/2) //Working - Up Sweep
//	//RampBias[NumPtsOut/2, NumPtsOut-1] =0 //Working - Down Sweep
//	RampBias[NumPtsOut/2, NumPtsOut-1] =1 - (p-(NumPtsOut/2))*(1)/(NumPtsOut/2) //Working - Down Sweep
//	RampBias-=.3

	Variable SpikeStart,SpikeEnd,SpikeVal
	SpikeStart=round(NumPtsOut)*.97
	SpikeEnd=round(NumPtsOut)*.99
	SpikeVal=-(TipBias/1000)-(min(.150,TipBias/1000))
	RampBias[SpikeStart,SpikeEnd]=SpikeVal
	N1=3/20*40000
	N2=N1+6/20*40000
	


		RampOutput[0,N1]=-p*DeltaEx
		LastX=RampOutput[N1-1]
		RampOutput[N1,N2-1]=LastX// + (p-N1)*DeltaEx
		LastX=RampOutput[N2-1]
		RampOutput[N2,NumPtsOut-1]= -(p-N2)*DeltaEx+LastX

		Variable lastBias = -tipbias/1000 //original was /1000
	//	Variable MaxBias = 1//Ramp in Bias from Set Bias
		Variable DelBias = (MaxBias)/1000
		Variable Wait=1*CAP
		
		RampBias[N1+CAP,N1+2*CAP-1]=-lastBias-(p-(N1+CAP))*DelBias-(TipBias/1000)
            LastBias=RampBias[N1+2*CAP-1]
            RampBias[N1+2*CAP,N1+4*CAP-1]=LastBias+(p-(N1+2*CAP))*DelBias
             LastBias=RampBias[N1+4*CAP-1]
            RampBias[N1+4*CAP,N1+5*CAP]=LastBias-(p-(N1+4*CAP))*DelBias
		
				
		error = MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)

		DCOffset_nm=0
			
		RampOutput=RampOutput+DCOffset_nm/K_ZPiezoScale;
		MXStartTask(G_ID1)
		for (i=1;i<NumSeg+1;i+=1)	// Loops through each segment
			
			TempWave[0,MinNumPoints-1]=RampOutput[(i-1)*MinNumPoints+p]
			TempWave[MinNumPoints,MinNumPoints*2-1]=RampBias[(i-2)*MinNumPoints+p]
			MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
			if (GetRTError(1))
			endif

		endfor
		DCOffset_nm = RampOutput[NumPtsOut-1]*K_ZPiezoScale
		TempWave[0,MinNumPoints-1]=DCOffset_nm/K_ZPiezoScale
		TempWave[MinNumPoints,MinNumPoints*2-1]=-(TipBias/1000)

		MXWriteAnalogF64(G_OD1,CardTimeout,2,TempWave)
		if (GetRTError(1))
		endif

		MXReadAnalogF64(G_ID1,10,2,WaveIn);
////////////*********************High Res Card Reading**********************////////		
		VoltageIn=wavein[p]
		CurrentIn=WaveIn[p+NumPtsIn]
		MXStopTask(G_ID1)
		MXClearTask(G_ID1)

		VoltageIn=-VoltageIn


		Make/O/N=(NumPtsOut) PullOutVoltage,PullOutConductance,POExtension, PullOutCurrent
		SetScale/I x 0,Size, PullOutVoltage,PullOutConductance,POExtension,PullOutCurrent
		
//		Differentiate VoltageIn/D=VoltageIn_DIF
		wavestats/Q/R=[NumPtsIn-100,NumPtsIn-1]/Q VoltageIn
//		Variable temp =  v_avg+(-SpikeVal-v_avg)/2
		Findlevel/Q/P/R=[NumPtsIn-101,NumPtsIn-5000] VoltageIn, v_avg+(-SpikeVal-v_avg)/20
//		wavestats/R=[NumPtsIn-5000-SpikeEnd+SpikeStart,NumPtsIn-1]/Q VoltageIn_DIF
		if (V_flag ==0)
			DelayOffset=V_LevelX-SpikeEnd
		else
			DelayOffset=2200
			PullOutFail=3
			printf "Did Not Sync Input and Ouput\r"
		endif
		//print delayoffset
//		DelayOffset=2200
		duplicate/o currentin currentin_raw	
		CurrentIn=-CurrentIn*CurrentVoltConversion*1e-6
		PullOutVoltage=VoltageIn[p+DelayOffset]
		PullOutCurrent=-CurrentIn[p+DelayOffset]
		PullOutConductance=-CurrentIn[p+DelayOffset]
		PullOutConductance=PullOutConductance/PullOutVoltage/77.5e-6		// Convert Volts from input to microamps
//		POExtension=RampIn[p+DelayOffset-250]*K_ZPiezoScale-DCOffset_nm
		POExtension=RampOutput
		
		deletepoints 0,(N1+Cap+DelayOffset+5),CurrentIn, VoltageIn
		redimension/N=(N2-N1-2*Cap-10) CurrentIn, VoltageIn
		duplicate/o CurrentIn $("CI_"+Name)
		duplicate/o VoltageIn $("VI_"+Name)
	
		
             end