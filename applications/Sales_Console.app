<?xml version="1.0" encoding="UTF-8"?>
<CustomApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <defaultLandingTab>standard-home</defaultLandingTab>
    <detailPageRefreshMethod>none</detailPageRefreshMethod>
    <enableKeyboardShortcuts>true</enableKeyboardShortcuts>
    <enableMultiMonitorComponents>true</enableMultiMonitorComponents>
    <isServiceCloudConsole>true</isServiceCloudConsole>
    <keyboardShortcuts>
        <defaultShortcut>
            <action>FOCUS_CONSOLE</action>
            <active>true</active>
            <keyCommand>ESC</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_NAVIGATOR_TAB</action>
            <active>true</active>
            <keyCommand>V</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_DETAIL_VIEW</action>
            <active>true</active>
            <keyCommand>SHIFT+S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_PRIMARY_TAB_PANEL</action>
            <active>true</active>
            <keyCommand>P</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_SUBTAB_PANEL</action>
            <active>true</active>
            <keyCommand>S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_LIST_VIEW</action>
            <active>true</active>
            <keyCommand>N</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_FIRST_LIST_VIEW</action>
            <active>true</active>
            <keyCommand>SHIFT+F</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_SEARCH_INPUT</action>
            <active>true</active>
            <keyCommand>R</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>MOVE_LEFT</action>
            <active>true</active>
            <keyCommand>LEFT ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>MOVE_RIGHT</action>
            <active>true</active>
            <keyCommand>RIGHT ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>UP_ARROW</action>
            <active>true</active>
            <keyCommand>UP ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>DOWN_ARROW</action>
            <active>true</active>
            <keyCommand>DOWN ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>OPEN_TAB_SCROLLER_MENU</action>
            <active>true</active>
            <keyCommand>D</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>OPEN_TAB</action>
            <active>true</active>
            <keyCommand>T</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>CLOSE_TAB</action>
            <active>true</active>
            <keyCommand>C</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>REFRESH_TAB</action>
            <active>false</active>
            <keyCommand>SHIFT+R</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>ENTER</action>
            <active>true</active>
            <keyCommand>ENTER</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>EDIT</action>
            <active>true</active>
            <keyCommand>E</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>SAVE</action>
            <active>true</active>
            <keyCommand>CTRL+S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>CONSOLE_LINK_DIALOG</action>
            <active>false</active>
            <keyCommand>U</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>HOTKEYS_PANEL</action>
            <active>false</active>
            <keyCommand>SHIFT+K</keyCommand>
        </defaultShortcut>
    </keyboardShortcuts>
    <label>Sales Console</label>
    <listPlacement>
        <location>left</location>
        <units>percent</units>
        <width>25</width>
    </listPlacement>
    <listRefreshMethod>none</listRefreshMethod>
    <liveAgentConfig>
        <enableLiveChat>true</enableLiveChat>
        <openNewAccountSubtab>true</openNewAccountSubtab>
        <openNewCaseSubtab>false</openNewCaseSubtab>
        <openNewContactSubtab>true</openNewContactSubtab>
        <openNewLeadSubtab>true</openNewLeadSubtab>
        <openNewVFPageSubtab>false</openNewVFPageSubtab>
        <showKnowledgeArticles>false</showKnowledgeArticles>
    </liveAgentConfig>
    <logo>SBQQ__SteelBrick_Assets/Silver_Peak_Logo_Color.png</logo>
    <saveUserSessions>true</saveUserSessions>
    <tab>Sales_Development</tab>
    <tab>standard-Lead</tab>
    <tab>standard-Account</tab>
    <tab>standard-Contact</tab>
    <tab>Opportunities_Partner</tab>
    <workspaceMappings>
        <mapping>
            <tab>Opportunities_Partner</tab>
        </mapping>
        <mapping>
            <tab>Sales_Development</tab>
        </mapping>
        <mapping>
            <fieldName>ParentId</fieldName>
            <tab>standard-Account</tab>
        </mapping>
        <mapping>
            <fieldName>AccountId</fieldName>
            <tab>standard-Contact</tab>
        </mapping>
        <mapping>
            <fieldName>CampaignId</fieldName>
            <tab>standard-Lead</tab>
        </mapping>
    </workspaceMappings>
</CustomApplication>