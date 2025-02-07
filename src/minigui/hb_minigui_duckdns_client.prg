#pragma -w3

#include "minigui.ch"

#define PROGRAM "DuckDNS Updater"
#define VERSION "version 1.0"
#define COPYRIGHT "2025 Marinaldo de Jesus"

#define REG_VAR "Software\Microsoft\Windows\CurrentVersion\Run"

static lWinRun as logical:=.F.
static aPublicVars as array:={"hb_minigui_duckdns_client.ini","example.duckdns.org","your-token-here","5","YES","NO"}
#xtranslate cCfgFile => aPublicVars\[1\]
#xtranslate cDomain=> aPublicVars\[2\]
#xtranslate cToken => aPublicVars\[3\]
#xtranslate cRefresh => aPublicVars\[4\]
#xtranslate cUpdateMsg => aPublicVars\[5\]
#xtranslate cWinRun=> aPublicVars\[6\]

procedure main(cStartUp as character)

    local cGetRegVar as character

    local lStartUP as logical

    SET CENTURY ON
    SET DATE BRITISH
    SET MULTIPLE OFF

    if (!File(cCfgFile))
        BEGIN INI FILE cCfgFile
            SET SECTION "Options" ENTRY "Domain" TO cDomain
            SET SECTION "Options" ENTRY "Token" TO cToken
            SET SECTION "Options" ENTRY "Refresh" TO cRefresh
            SET SECTION "Options" ENTRY "UpdateMsg" TO cUpdateMsg
            SET SECTION "Options" ENTRY "WinRun" TO cWinRun
        END INI
    else
        BEGIN INI FILE cCfgFile
            GET cDomain SECTION "Options" ENTRY "Domain"
            GET cToken SECTION "Options" ENTRY "Token"
            GET cRefresh SECTION "Options" ENTRY "Refresh"
            GET cUpdateMsg SECTION "Options" ENTRY "UpdateMsg"
            GET cWinRun SECTION "Options" ENTRY "WinRun"
        END INI
    endif

    lStartUP:=(!Empty(cStartUp).and.(Upper(Substr(cStartUp,2))=="STARTUP"))
    if (!lStartUP)
        cGetRegVar:=getRegVar(nil,REG_VAR,PROGRAM)
        lStartUP:=(!Empty(cGetRegVar))
    endif

    lWinRun:=((cWinRun=="YES").and.(lStartUP))

    DEFINE WINDOW Form_Main;
        AT 0,0;
        WIDTH 0 HEIGHT 0;
        TITLE PROGRAM;
        MAIN NOSHOW;
        NOTIFYICON 'MAIN';
        NOTIFYTOOLTIP __NotifyTooltip();
        ON NOTIFYCLICK ShowOptions()

        DEFINE NOTIFY MENU
            ITEM '&Update Now' ACTION UpdateDuckDNS()
            SEPARATOR
            ITEM '&What is my IP Address' ACTION MsgInfo(GetIP(),PROGRAM)
            ITEM '&Copy my IP Address to Clipboard' ACTION (CopyToClipboard(""),CopyToClipboard(GetIP()))
            SEPARATOR
            ITEM '&Options' ACTION ShowOptions()
            SEPARATOR
            ITEM '&About...' ACTION ShellAbout("",PROGRAM+VERSION+CRLF+"Copyright "+Chr(169)+COPYRIGHT,LoadIconByName("MAIN",32,32))
            SEPARATOR
            ITEM 'E&xit' ACTION Form_Main.Release
        END MENU

    DEFINE TIMER Timer_UpdateDuckDNS ;
        INTERVAL (val(cRefresh)*60000);
          ACTION (UpdateDuckDNS(),Form_Main.NotifyTooltip:=__NotifyTooltip())

    END WINDOW

    ACTIVATE WINDOW Form_Main

    return

static procedure ShowOptions()

    local aRefresh as array
    local aUpdateMsg as array

    local nRefresh as numeric
    local nUpdateMsg as numeric

    begin sequence

        if (!Empty(GetFormIndex("Form_Options")))
            break
        endif

        aRefresh:={"5","10","15","30","60"}
        aUpdateMsg:={"YES","NO"}

        nRefresh:=Max(aScan(aRefresh,cRefresh),1)
        nUpdateMsg:=Max(aScan(aUpdateMsg,cUpdateMsg),1)

        DEFINE WINDOW Form_Options;
               AT 0,0;
            WIDTH 500;
           HEIGHT 250;
            TITLE PROGRAM+' Options';
             ICON 'MAIN';
       NOMINIMIZE NOMAXIMIZE NOSIZE;
             FONT 'MS Sans Serif';
             SIZE 9

            @ 20,20 LABEL lblDomain;
                    VALUE 'Domain:';
                    WIDTH 80;
                   HEIGHT 20

            @ 50,20 LABEL lblToken;
                    VALUE 'Token:';
                    WIDTH 80;
                   HEIGHT 20

            @ 80,20 LABEL lblRefresh;
                    VALUE 'Refresh (min):';
                    WIDTH 80;
                   HEIGHT 20

            @ 110,20    LABEL lblUpdateMsg;
                        VALUE 'Show Notifications:';
                        WIDTH 100;
                       HEIGHT 20

            @ 20,120    TEXTBOX txtDomain;
                          VALUE cDomain;
                          WIDTH 250;
                         HEIGHT 24;
                   ON LOSTFOCUS (cDomain:=Form_Options.txtDomain.Value);
                       ON ENTER (cDomain:=Form_Options.txtDomain.Value)

            @ 50,120    TEXTBOX txtToken;
                          VALUE cToken;
                          WIDTH 250;
                         HEIGHT 24;
                   ON LOSTFOCUS (cToken:=Form_Options.txtToken.Value);
                       ON ENTER (cToken:=Form_Options.txtToken.Value)

            @ 80,120   LISTBOX cmbTxtRefresh;
                            OF Form_Options;
                         WIDTH 50;
                        HEIGHT 24;
                         ITEMS aRefresh;
                         VALUE nRefresh;
                          FONT GetDefaultFontName();
                          SIZE 10;
                     ON CHANGE (cRefresh:=aRefresh[Form_Options.cmbTxtRefresh.Value])

            @ 110,120   LISTBOX cmbUpdateMsg;
                             OF Form_Options;
                          WIDTH 50;
                         HEIGHT 24;
                          ITEMS aUpdateMsg;
                          VALUE nUpdateMsg;
                           FONT GetDefaultFontName();
                           SIZE 10;
                      ON CHANGE (cUpdateMsg:=aUpdateMsg[Form_Options.cmbUpdateMsg.Value])

            @ 135,120 CHECKBOX chkbWinRun;
                       CAPTION '&Start ' + PROGRAM + ' automatically at Windows Startup' ;
                         WIDTH 312;
                        HEIGHT 16;
                         VALUE lWinRun;
                     ON CHANGE (lWinRun:=!lWinRun,cWinRun:=if(lWinRun,"YES","NO"),WinRun(lWinRun))

            @ 150,120   BUTTON btnSave;
                       CAPTION '&Save';
                        ACTION SaveOptions();
                         WIDTH 80;
                        HEIGHT 24

            @ 150,210   BUTTON btnCancel;
                       CAPTION '&Cancel';
                        ACTION Form_Options.Release;
                         WIDTH 80;
                        HEIGHT 24
        END WINDOW

        CENTER WINDOW Form_Options
        ACTIVATE WINDOW Form_Options

    end sequence

    return

static procedure SaveOptions()

    cWinRun:=if(lWinRun,"YES","NO")

    BEGIN INI FILE cCfgFile
        SET SECTION "Options" ENTRY "Domain" TO cDomain
        SET SECTION "Options" ENTRY "Token" TO cToken
        SET SECTION "Options" ENTRY "Refresh" TO cRefresh
        SET SECTION "Options" ENTRY "UpdateMsg" TO cUpdateMsg
        SET SECTION "Options" ENTRY "WinRun" TO cWinRun
    END INI

    UpdateDuckDNS()

    if (IsControlDefined(Timer_UpdateDuckDNS,Form_Main))
        Form_Main.Timer_UpdateDuckDNS.Interval:=(val(cRefresh)*60000)
        Form_Main.Timer_UpdateDuckDNS.Enabled:=.T.
    endif

    Form_Main.NotifyTooltip:=__NotifyTooltip()
    Form_Options.Release

    return

static procedure UpdateDuckDNS()

    local cIP as character:=GetIP()
    local cResponse as character:=""

    if (!Empty(cIP))
        cResponse:=HttpGet("http://www.duckdns.org/update?domains="+cDomain+"&token="+cToken+"&ip="+cIP)
        if (cResponse=="OK")
            if (cUpdateMsg=="YES")
                MsgBalloon("DuckDNS updated successfully!",PROGRAM)
            endif
        else
            MsgInfo("Error updating DuckDNS: "+cResponse,PROGRAM)
        endif
    else
        MsgInfo("Could not retrieve IP address!",PROGRAM)
    endif

    return

static function GetIP()

    local cIP as character:=""
    local cResponse as character:=HttpGet("http://checkip.amazonaws.com")

    if (!Empty(cResponse))
        cIP:=strTran(strTran(AllTrim(cResponse),chr(10),""),chr(13),"")
    endif

    return(cIP) as character

static function HttpGet(cUrl as character)

    local cResponse as character :=""

    local oHttp as object:=TIpClientHttp():New(cUrl)

    if (oHttp:Open())
        cResponse:=oHttp:Read()
        oHttp:Close()
    endif

    return(cResponse) as character

static function __NextUpdate()

    local cTime as character
    local cNextUpdate as character

    local dDate as date:=Date()
    local nSeconds:=Seconds()

    nSeconds+=(val(cRefresh)*60)
    cTime:=SecToTime(nSeconds)
    if (cTime>"23:59:59")
        dDate++
        cTime:=ElapTime("24:00:00",cTime)
    endif

    cNextUpdate:=DToC(dDate)
    cNextUpdate+=" "
    cNextUpdate+=cTime

return(cNextUpdate) as character

static procedure WinRun(lMode as logical)

    local cRunName as character:=Upper(GetModuleFileName(GetInstance()))+" /STARTUP"
    local cRunKey as character:=REG_VAR
    local cRegKey as character:=getRegVar(nil,cRunKey,PROGRAM)

    if (IsWinNT())
        EnablePermissions()
    endif

    if (lMode)
        if (Empty(cRegKey).or.(cRegKey# cRunName))
            setRegVar(nil,cRunKey,PROGRAM,cRunName)
        endif
    else
        DelRegVar(nil,cRunKey,PROGRAM)
    endif

    return

static function getRegVar(nKey as numeric,cRegKey as character,cSubKey as character,uValue as usual/*as variant*/)

    local cValue as character
    local oTReg32 as object

    nKey:=if(nKey==nil,HKEY_CURRENT_USER,nKey)
    uValue:=if(uValue==nil,"",uValue)
    oTReg32:=TReg32():Create(nKey,cRegKey)
    cValue:=oTReg32:Get(cSubKey,uValue)
    oTReg32:Close()

    return(cValue) as character

static function setRegVar(nKey as numeric,cRegKey as character,cSubKey as character,uValue as usual/*as variant*/)

    local cValue as character
    local oTReg32 as object

    nKey:=if(nKey==nil,HKEY_CURRENT_USER,nKey)
    uValue:=if(uValue==nil,"",uValue)
    oTReg32:=TReg32():Create(nKey,cRegKey)
    cValue:=oTReg32:Set(cSubKey,uValue)
    oTReg32:Close()

    return(cValue) as character

static function DelRegVar(nKey as numeric,cRegKey as character,cSubKey as character)

    local cValue as character
    local nValue as numeric
    local oTReg32 as object

    nKey:=if(nKey==nil,HKEY_CURRENT_USER,nKey)
    oTReg32:=TReg32():New(nKey,cRegKey)
    nValue:=oTReg32:Delete(cSubKey)
    oTReg32:Close()

    return(nValue) as numeric

static function __NotifyTooltip()
return((PROGRAM+" - "+VERSION+hb_osNewLine()+"IP: "+GetIP()+hb_osNewLine()+"Next Update: "+__NextUpdate()+hb_osNewLine()+"Refresh: "+cRefresh+" minutes.")) as character

// Notify Icon Infotip flags
#define NIIF_NONE       0x00000000
// icon flags are mutualy exclusive
// and take only the lowest 2 bits
#define NIIF_INFO       0x00000001
#define NIIF_WARNING    0x00000002
#define NIIF_ERROR      0x00000003

static procedure MsgBalloon(cMessage as character,cTitle as character,nIconIndex as numeric)

    local i as numeric:=GetFormIndex("Form_Main")

    hb_default(@cMessage,"Prompt")
    hb_default(@cTitle,PROGRAM)
    hb_default(@nIconIndex,NIIF_INFO)

    ShowNotifyInfo(_HMG_aFormhandles[i],.F.,nil,nil,nil,nil,0)
    ShowNotifyInfo(_HMG_aFormhandles[i],.T.,LoadTrayIcon(GetInstance(),_HMG_aFormNotifyIconName[i]),_HMG_aFormNotifyIconToolTip[i],cMessage,cTitle,nIconIndex)


    hb_idleSleep(3)
    ActivateNotifyMenu(i)

    return

static procedure ActivateNotifyMenu(i as numeric)

    ShowNotifyInfo(_HMG_aFormhandles[i],.F.,nil,nil,nil,nil,0)
    ShowNotifyIcon(_HMG_aFormhandles[i],.T.,LoadTrayIcon(GetInstance(),_HMG_aFormNotifyIconName[i]),_HMG_aFormNotifyIconToolTip[i])

    return

/*
 * C-level
*/
#pragma BEGINDUMP

    #define _WIN32_IE      0x0500
    #define _WIN32_WINNT   0x0400

    #include <windows.h>
    #include "hbapi.h"

    static void ShowNotifyInfo(HWND hWnd, BOOL bAdd, HICON hIcon, LPSTR szText, LPSTR szInfo, LPSTR szInfoTitle, DWORD nIconIndex);

    HB_FUNC_STATIC( SHOWNOTIFYINFO )
    {
        ShowNotifyInfo( (HWND) hb_parnl(1), (BOOL) hb_parl(2), (HICON) hb_parnl(3), (LPSTR) hb_parc(4),
                (LPSTR) hb_parc(5), (LPSTR) hb_parc(6), (DWORD) hb_parnl(7) );
    }

    static void ShowNotifyInfo(HWND hWnd, BOOL bAdd, HICON hIcon, LPSTR szText, LPSTR szInfo, LPSTR szInfoTitle, DWORD nIconIndex)
    {
        NOTIFYICONDATA nid;

        ZeroMemory( &nid, sizeof(nid) );

        nid.cbSize=sizeof(NOTIFYICONDATA);
        nid.hIcon =hIcon;
        nid.hWnd=hWnd;
        nid.uID =0;
        nid.uFlags=NIF_INFO | NIF_TIP | NIF_ICON;
        nid.dwInfoFlags =nIconIndex;

        lstrcpy( nid.szTip, TEXT(szText) );
        lstrcpy( nid.szInfo, TEXT(szInfo) );
        lstrcpy( nid.szInfoTitle, TEXT(szInfoTitle) );

        if(bAdd)
            Shell_NotifyIcon( NIM_ADD, &nid );
        else
            Shell_NotifyIcon( NIM_DELETE, &nid );

        if(hIcon)
            DestroyIcon( hIcon );
    }

    HB_FUNC_STATIC( ENABLEPERMISSIONS )
    {
       LUID tmpLuid;
       TOKEN_PRIVILEGES tkp, tkpNewButIgnored;
       DWORD lBufferNeeded;
       HANDLE hdlTokenHandle;
       HANDLE hdlProcessHandle =GetCurrentProcess();

       OpenProcessToken(hdlProcessHandle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hdlTokenHandle);

       LookupPrivilegeValue(NULL, "SeShutdownPrivilege", &tmpLuid);

       tkp.PrivilegeCount=1;
       tkp.Privileges[0].Luid=tmpLuid;
       tkp.Privileges[0].Attributes=SE_PRIVILEGE_ENABLED;

       AdjustTokenPrivileges(hdlTokenHandle, FALSE, &tkp, sizeof(tkpNewButIgnored), &tkpNewButIgnored, &lBufferNeeded);
    }

#pragma ENDDUMP
