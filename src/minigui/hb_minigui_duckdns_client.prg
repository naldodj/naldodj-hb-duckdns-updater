#include "minigui.ch"

#define PROGRAM "DuckDNS Updater"
#define VERSION "version 1.0"
#define COPYRIGHT "2025 Marinaldo de Jesus"

static aPublicVars as array:={"hb_minigui_duckdns_client.ini","example.duckdns.org","your-token-here","5","YES"}

#pragma -w3

#xtranslate cCfgFile     => aPublicVars\[1\]
#xtranslate cDomain      => aPublicVars\[2\]
#xtranslate cToken       => aPublicVars\[3\]
#xtranslate cRefresh     => aPublicVars\[4\]
#xtranslate cUpdateMsg   => aPublicVars\[5\]

procedure main()

    SET CENTURY ON
    SET DATE BRITISH
    SET MULTIPLE OFF

    if (!File(cCfgFile))
        BEGIN INI FILE cCfgFile
            SET SECTION "Options" ENTRY "Domain" TO cDomain
            SET SECTION "Options" ENTRY "Token" TO cToken
            SET SECTION "Options" ENTRY "Refresh" TO cRefresh
            SET SECTION "Options" ENTRY "UpdateMsg" TO cUpdateMsg
        END INI
    else
        BEGIN INI FILE cCfgFile
            GET cDomain SECTION "Options" ENTRY "Domain"
            GET cToken SECTION "Options" ENTRY "Token"
            GET cRefresh SECTION "Options" ENTRY "Refresh"
            GET cUpdateMsg SECTION "Options" ENTRY "UpdateMsg"
        END INI
    endif

    DEFINE WINDOW Form_Main;
        AT 0,0;
        WIDTH 0 HEIGHT 0;
        TITLE PROGRAM;
        MAIN NOSHOW;
        NOTIFYICON 'MAIN';
        NOTIFYTOOLTIP (PROGRAM+" - "+VERSION+hb_osNewLine()+"Next Update: "+__NextUpdate()+hb_osNewLine()+"Refresh: "+cRefresh+" minutes.");
        ON NOTIFYCLICK ShowOptions()

        DEFINE NOTIFY MENU
            ITEM '&Update Now' ACTION UpdateDuckDNS()
            SEPARATOR
            ITEM '&What is my IP Address' ACTION MsgInfo(getIP(),PROGRAM)
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
         ACTION ( UpdateDuckDNS() , Form_Main.NotifyTooltip:=(PROGRAM+" - "+VERSION+hb_osNewLine()+"Next Update: "+__NextUpdate()+hb_osNewLine()+"Refresh: "+cRefresh+" minutes.") )

    END WINDOW

    ACTIVATE WINDOW Form_Main

    return

*--------------------------------------------------------*
static procedure ShowOptions()
*--------------------------------------------------------*

    local aRefresh as array:={"5","10","15","30","60"}
    local aUpdateMsg as array:={"YES","NO"}

    local nRefresh as numeric:=Max(aScan(aRefresh,cRefresh),1)
    local nUpdateMsg as numeric:=Max(aScan(aUpdateMsg,cUpdateMsg),1)

    DEFINE WINDOW Form_Options;
        AT 0,0;
        WIDTH 400;
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
                    HEIGHT 24

        @ 50,120    TEXTBOX txtToken;
                    VALUE cToken;
                    WIDTH 250;
                    HEIGHT 24

        /*@ 80,120    COMBOBOX cmbTxtRefresh;
                    ITEMS aRefresh;
                    VALUE nRefresh;
                    WIDTH 50;
                    HEIGHT 24;
                 ON CHANGE cRefresh := aRefresh[Form_Options.cmbUpdateMsg.Value]*/

        @ 80,120   LISTBOX cmbTxtRefresh;
                        OF Form_Options;
                     WIDTH 50;
                    HEIGHT 24;
                     ITEMS aRefresh;
                     VALUE nRefresh;
                      FONT GetDefaultFontName();
                      SIZE 10;
                 ON CHANGE (cRefresh:=aRefresh[Form_Options.cmbTxtRefresh.Value])

        /*@ 110,120 COMBOBOX cmbUpdateMsg;
             ITEMS aUpdateMsg;
             VALUE nUpdateMsg;
             WIDTH 50;
            HEIGHT 24;
                ON CHANGE cUpdateMsg := aUpdateMsg[Form_Options.cmbUpdateMsg.Value]*/

        @ 110,120   LISTBOX cmbUpdateMsg;
                         OF Form_Options;
                      WIDTH 50;
                     HEIGHT 24;
                      ITEMS aUpdateMsg;
                      VALUE nUpdateMsg;
                       FONT GetDefaultFontName();
                       SIZE 10;
                  ON CHANGE (cUpdateMsg:=aUpdateMsg[Form_Options.cmbUpdateMsg.Value])

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

    return

*--------------------------------------------------------*
static procedure SaveOptions()
*--------------------------------------------------------*

    BEGIN INI FILE cCfgFile
        SET SECTION "Options" ENTRY "Domain" TO cDomain
        SET SECTION "Options" ENTRY "Token" TO cToken
        SET SECTION "Options" ENTRY "Refresh" TO cRefresh
        SET SECTION "Options" ENTRY "UpdateMsg" TO cUpdateMsg
    END INI

    if (IsControlDefined(Timer_UpdateDuckDNS,Form_Main))
        Form_Main.Timer_UpdateDuckDNS.Interval:=(val(cRefresh)*60000)
        Form_Main.Timer_UpdateDuckDNS.Enabled:= .T.
    endif

    Form_Main.NotifyTooltip:=(PROGRAM+" - "+VERSION+hb_osNewLine()+"Next Update: "+__NextUpdate()+hb_osNewLine()+"Refresh: "+cRefresh+" minutes.")
    Form_Options.Release

    return

*--------------------------------------------------------*
static procedure UpdateDuckDNS()
*--------------------------------------------------------*

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

*--------------------------------------------------------*
static function GetIP()
*--------------------------------------------------------*

    local cIP as character:=""
    local cResponse as character:=HttpGet("http://checkip.amazonaws.com")

    if (!Empty(cResponse))
        cIP:=AllTrim(cResponse)
    endif

    return(cIP) as character

*--------------------------------------------------------*
static function HttpGet(cUrl as character)
*--------------------------------------------------------*

    local cResponse as character := ""

    local oHttp as object:=TIpClientHttp():New(cUrl)

    if (oHttp:Open())
        cResponse:=oHttp:Read()
        oHttp:Close()
    endif

    return(cResponse) as character

*--------------------------------------------------------*
static function __NextUpdate()
*--------------------------------------------------------*

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

// Notify Icon Infotip flags
#define NIIF_NONE       0x00000000
// icon flags are mutualy exclusive
// and take only the lowest 2 bits
#define NIIF_INFO       0x00000001
#define NIIF_WARNING    0x00000002
#define NIIF_ERROR      0x00000003
*--------------------------------------------------------*
static procedure MsgBalloon(cMessage as character,cTitle as character,nIconIndex as numeric)
*--------------------------------------------------------*

    local i as numeric:=GetFormIndex("Form_Main")

    hb_default(@cMessage,"Prompt")
    hb_default(@cTitle,PROGRAM)
    hb_default(@nIconIndex,NIIF_INFO)

    ShowNotifyInfo(_HMG_aFormhandles[i],.F.,NIL,NIL,NIL,NIL,0)
    ShowNotifyInfo(_HMG_aFormhandles[i],.T.,LoadTrayIcon(GetInstance(),_HMG_aFormNotifyIconName[i]),_HMG_aFormNotifyIconToolTip[i],cMessage,cTitle,nIconIndex)


    hb_idleSleep(3)
    ActivateNotifyMenu(i)

    return

*--------------------------------------------------------*
static procedure ActivateNotifyMenu(i as numeric)
*--------------------------------------------------------*

    ShowNotifyInfo(_HMG_aFormhandles[i],.F.,NIL,NIL,NIL,NIL,0)
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

    HB_FUNC ( SHOWNOTIFYINFO )
    {
        ShowNotifyInfo( (HWND) hb_parnl(1), (BOOL) hb_parl(2), (HICON) hb_parnl(3), (LPSTR) hb_parc(4),
                (LPSTR) hb_parc(5), (LPSTR) hb_parc(6), (DWORD) hb_parnl(7) );
    }

    static void ShowNotifyInfo(HWND hWnd, BOOL bAdd, HICON hIcon, LPSTR szText, LPSTR szInfo, LPSTR szInfoTitle, DWORD nIconIndex)
    {
        NOTIFYICONDATA nid;

        ZeroMemory( &nid, sizeof(nid) );

        nid.cbSize      = sizeof(NOTIFYICONDATA);
        nid.hIcon       = hIcon;
        nid.hWnd        = hWnd;
        nid.uID         = 0;
        nid.uFlags      = NIF_INFO | NIF_TIP | NIF_ICON;
        nid.dwInfoFlags = nIconIndex;

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

#pragma ENDDUMP
