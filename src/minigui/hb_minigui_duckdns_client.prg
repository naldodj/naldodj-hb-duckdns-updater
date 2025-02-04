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
            ITEM '&What is my IP Address' ACTION MsgInfo(getIP(),PROGRAM)
            ITEM '&Options' ACTION ShowOptions()
            ITEM '&About...' ACTION ShellAbout("",PROGRAM+VERSION+CRLF+"Copyright "+Chr(169)+COPYRIGHT,LoadIconByName("MAIN",32,32))
            SEPARATOR
            ITEM 'E&xit' ACTION Form_Main.Release
        END MENU

      DEFINE TIMER Timer_UpdateDuckDNS ;
         INTERVAL (val(cRefresh)*60000);
         ACTION ( UpdateDuckDNS() )

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
                MsgInfo("DuckDNS updated successfully!",PROGRAM)
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
    cNextUpdate+=" "
    cNextUpdate+=cTime

return(cNextUpdate) as character
