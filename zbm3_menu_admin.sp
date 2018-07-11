/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin AdministatorMenu =
{
    name            = "[ZP] Menu: Administator",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Administator menu generator",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Admin menu cases.
 **/
enum AdminMenu
{
    AdminMenu_Human,            /** Human menu slot. */
    AdminMenu_Zombie,           /** Zombie menu slot. */
    AdminMenu_Respawn,          /** Respawn menu slot. */
    AdminMenu_Nemesis,          /** Nemesis menu slot. */
    AdminMenu_Survivor,         /** Survivor menu slot. */
    AdminMenu_Ammopack,         /** Ammopack menu slot. */
    AdminMenu_Level,            /** Level menu slot. */
    AdminMenu_Armageddon,       /** Armageddon menu slot. */
    AdminMenu_Multi,            /** Multi menu slot. */
    AdminMenu_Swarm,            /** Swarm menu slot. */
    AdminMenu_Plague            /** Plague menu slot. */
};

/**
 * HUD synchronization hadnle.
 **/
Handle hHudSync;

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
        
        // Create a commands
        RegConsoleCmd("zadminmenu", Command_AdminMenu, "Open the administator menu with unique commands.");
        
        /*
         * Creates a HUD synchronization object. This object is used to automatically assign and re-use channels for a set of messages.
         * The HUD has a hardcoded number of channels (usually 6) for displaying text. You can use any channel for any area of the screen. 
         * Text on different channels can overlap, but text on the same channel will erase the old text first. This overlapping and overwriting gets problematic.
         * A HUD synchronization object automatically selects channels for you based on the following heuristics: - If channel X was last used by the object, 
         * and hasn't been modified again, channel X gets re-used. - Otherwise, a new channel is chosen based on the least-recently-used channel.
         * This ensures that if you display text on a sync object, that the previous text displayed on it will always be cleared first. 
         * This is because your new text will either overwrite the old text on the same channel, or because another channel has already erased your text.
         * Note that messages can still overlap if they are on different synchronization objects, or they are displayed to manual channels.
         * These are particularly useful for displaying repeating or refreshing HUD text, in addition to displaying multiple message sets in one area of the screen 
         * (for example, center-say messages that may pop up randomly that you don't want to overlap each other).
         */
        hHudSync = CreateHudSynchronizer();
    }
}

/**
 * Handles the zadminmenu command. Open the administator menu with unique commands.
 * 
 * @param clientIndex        The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action Command_AdminMenu(int clientIndex, int iArguments)
{
    // Open an admin menu
    MenuAdmin(clientIndex);
}

/*
 * Admin menu
 */
 
/**
 * Create an admin menu.
 *
 * @param clientIndex        The client index.
 **/
void MenuAdmin(int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }
    
    // Verify admin
    if(!ZP_IsPlayerPrivileged(clientIndex, Admin_Generic))
    {
        // Emit error sound
        ClientCommand(clientIndex, "play buttons/button11.wav");
        return;
    }
    
    // Initialize char
    static char sBuffer[NORMAL_LINE_LENGTH];

    // Sets the global language target
    SetGlobalTransTarget(clientIndex);

    // Initialize menu
    Menu iMenu = CreateMenu(AdminMenuSlots);

    // Add formatted options to menu
    SetMenuTitle(iMenu, "%t", "Admin menu");

    // Make human
    Format(sBuffer, sizeof(sBuffer), "%t", "Make human");
    AddMenuItem(iMenu, "1", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Reservation)));
    
    // Make zombie
    Format(sBuffer, sizeof(sBuffer), "%t", "Make zombie");
    AddMenuItem(iMenu, "2", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Kick)));
    
    // Respawn player
    Format(sBuffer, sizeof(sBuffer), "%t", "Respawn");
    AddMenuItem(iMenu, "3", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Slay)));
    
    // Make nemesis
    Format(sBuffer, sizeof(sBuffer), "%t", "Make nemesis");
    AddMenuItem(iMenu, "4", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Changemap)));
    
    // Make survivor
    Format(sBuffer, sizeof(sBuffer), "%t", "Make survivor");
    AddMenuItem(iMenu, "5", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom2)));
    
    // Give ammopacks
    Format(sBuffer, sizeof(sBuffer), "%t", "Give ammopacks");
    AddMenuItem(iMenu, "6", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom3)));
    
    // Give level
    Format(sBuffer, sizeof(sBuffer), "%t", "Give level");
    AddMenuItem(iMenu, "7", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom3)));
    
    // Start armageddon
    Format(sBuffer, sizeof(sBuffer), "%t", "Start armageddon");
    AddMenuItem(iMenu, "8", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom4)));
    
    // Start multi mode
    Format(sBuffer, sizeof(sBuffer), "%t", "Start multi mode");
    AddMenuItem(iMenu, "9", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom5)));
    
    // Start swarm mode
    Format(sBuffer, sizeof(sBuffer), "%t", "Start swarm mode");
    AddMenuItem(iMenu, "10", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom6)));

    // Start plague mode
    Format(sBuffer, sizeof(sBuffer), "%t", "Start plague mode");
    AddMenuItem(iMenu, "11", sBuffer, MenuGetItemDraw(ZP_IsPlayerPrivileged(clientIndex, Admin_Custom6)));
    
    // Sets exit and back button
    SetMenuExitBackButton(iMenu, true);
    
    // Sets options and display it
    SetMenuOptionFlags(iMenu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
    DisplayMenu(iMenu, clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMenuSlots(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            CloseHandle(iMenu);
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Open main menu back
                if(IsPlayerExist(clientIndex, false)) FakeClientCommand(clientIndex, "zmainmenu");
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Create menu
            MenuSubAdmin(clientIndex, view_as<AdminMenu>(mSlot));
        }
    }
}

/**
 * Used for creating sub part of admin menu by choosing mode.
 *
 * @param clientIndex        The client index.
 * @param iMode                The mode of the command.
 **/
void MenuSubAdmin(int clientIndex, AdminMenu iMode)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Sets the global language target
    SetGlobalTransTarget(clientIndex);
    
    // Gets client name
    static char sAdminName[NORMAL_LINE_LENGTH];
    GetClientName(clientIndex, sAdminName, sizeof(sAdminName));
    
    // Initialize menu
    Menu iMenu;
    
    // Switch the menu mode
    switch(iMode)
    {
        //!                                                      Menu Handle      Title             Alive?        Dead?           Skip Zombies?       Skip Humans?        Skip Nemesises?         Skip Survivors?
        case AdminMenu_Human    : iMenu = CreatePlayerList(AdminMakeHumanList,    "Make human",     true,         false,          false,              true,               false,                  true);
        case AdminMenu_Zombie   : iMenu = CreatePlayerList(AdminMakeZombieList,   "Make zombie",    true,         false,          true,               false,              true,                   false);
        case AdminMenu_Respawn  : iMenu = CreatePlayerList(AdminMakeAliveList,    "Respawn",        false,        true,           false,              false,              false,                  false);    
        case AdminMenu_Nemesis  : iMenu = CreatePlayerList(AdminMakeNemesisList,  "Make nemesis",   true,         false,          false,              false,              true,                   false);         
        case AdminMenu_Survivor : iMenu = CreatePlayerList(AdminMakeSurvivorList, "Make survivor",  true,         false,          false,              false,              false,                  true);
        case AdminMenu_Ammopack : iMenu = CreatePlayerList(AdminMakeAmmopackList, "Give ammopacks", false,        false,          false,              false,              false,                  false);
        case AdminMenu_Level    : iMenu = CreatePlayerList(AdminMakeLevelList,    "Give level",     false,        false,          false,              false,              false,                  false);
        default : 
        {
            // If round started, then stop
            if(!ZP_IsNewRound())
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");
                return;
            }
            
            // Switch the menu mode
            switch(iMode)
            {
                case AdminMenu_Armageddon :
                {
                    // Start mode
                    ZP_SetServerGameMode("Armageddon");
                    
                    // Print event
                    HUDSendToAll("Admin started armageddon", sAdminName);
                }
                case AdminMenu_Multi :
                {
                    // Start mode
                    ZP_SetServerGameMode("Multi");

                    // Print event
                    HUDSendToAll("Admin started multi mode", sAdminName);
                }
                case AdminMenu_Swarm :
                {
                    // Start mode
                    ZP_SetServerGameMode("Swarm");
                    
                    // Print event
                    HUDSendToAll("Admin started swarm mode", sAdminName);
                }
                case AdminMenu_Plague :
                {
                    // Start mode
                    ZP_SetServerGameMode("Plague");

                    // Print event
                    HUDSendToAll("Admin started plague mode", sAdminName);
                }
            }
            return;
        }
    }

    // Sets exit and back button
    SetMenuExitBackButton(iMenu, true);
    
    // Sets options and display it
    SetMenuOptionFlags(iMenu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
    DisplayMenu(iMenu, clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Shows a list of all clients to a client, different handlers can be used for this, as well as title.
 * 
 * @param sHandler            The menu handler.
 * @param sTitle            Set menu title to the translated phrase.
 * @param bAlive            If true, only clients that are alive will be displayed.
 * @param bDead             If true, only clients that are dead will be displayed. 
 * @param bZombie           If true, only clients on a zombie will be skipped.
 * @param bHuman            If true, only clients on a human will be skipped.
 * @param bNemesis          If true, only clients on a nemesis will be skipped.
 * @param bSurvivor            If true, only clients on a survivor will be skipped.
 * @return                     The menu index.
 **/
Menu CreatePlayerList(MenuHandler sHandler, char[] sTitle, bool bAlive, bool bDead, bool bZombie, bool bHuman , bool bNemesis, bool bSurvivor)
{
    // Initialize menu
    Menu iMenu = CreateMenu(sHandler);
    
    // Initialize chars variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    
    // Add formatted options to menu
    SetMenuTitle(iMenu, "%t", sTitle);
    
    // Amount of cases
    int iCount;
    
    // i = Client index
    for(int i = 1; i <= MaxClients; i++)
    {
        //If client isn't connected, then stop
        if(!IsClientConnected(i))
        {
            continue;
        }

        // If client isn't in-game, then stop
        if(!IsClientInGame(i))
        {
            continue;
        }

        // If client is dead, then stop
        if(bAlive && !IsPlayerAlive(i))
        {
            continue;
        }

        // If client is alive, then stop
        if(bDead && IsPlayerAlive(i))
        {
            continue;
        }

        // If client is zombie, then stop
        if(bZombie && ZP_IsPlayerZombie(i))
        {
            continue;
        }
        
        // If client is human, then stop
        if(bHuman && ZP_IsPlayerHuman(i))
        {
            continue;
        }
        
        // If client is nemesis, then stop
        if(bNemesis && ZP_IsPlayerNemesis(i))
        {
            continue;
        }

        // If client is survivor, then stop
        if(bSurvivor && ZP_IsPlayerSurvivor(i))
        {
            continue;
        }

        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%N", i);
        
        //Strips a quote pair and whitespaces off a string 
        StripQuotes(sBuffer);
        TrimString(sBuffer);
        
        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        AddMenuItem(iMenu, sInfo, sBuffer);

        // Increment count
        iCount++;
    }
    
    // If there are no clients, add an "(Empty)" line
    if(!iCount)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "Empty");

        AddMenuItem(iMenu, "empty", sEmpty, ITEMDRAW_DISABLED);
    }

    // Return a new menu Handle
    return iMenu;
}            

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeHumanList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Human);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeZombieList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Zombie);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeAliveList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Respawn);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeNemesisList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Nemesis);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeSurvivorList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Survivor);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeAmmopackList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Ammopack);
}

/**
 * Called when client selects option in the sub admin menu, and handles it.
 *  
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 **/ 
public int AdminMakeLevelList(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    AdminCommand(iMenu, mAction, clientIndex, mSlot, AdminMenu_Level);
}

/**
 * Create sub admin menu.
 *
 * @param iMenu                The handle of the menu being used.
 * @param mAction            The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex        The client index.
 * @param mSlot                The slot index selected (starting from 0).
 * @param menuMode            The mode of the command.
 **/
void AdminCommand(Menu iMenu, MenuAction mAction, int clientIndex, int mSlot, AdminMenu menuMode)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            CloseHandle(iMenu);
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Open main menu back
                MenuAdmin(clientIndex);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }
            
            // If round ended, then stop
            if(ZP_IsEndRound())
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Gets client's name
            static char sAdminName[NORMAL_LINE_LENGTH];
            GetClientName(clientIndex, sAdminName, sizeof(sAdminName));
            
            /*
             *  ADMIN VALIDATION OF MENU
             */
            
            // Initialize char
            static char sInfo[SMALL_LINE_LENGTH];

            // Gets index of the player in the menu
            GetMenuItem(iMenu, mSlot, sInfo, sizeof(sInfo));
            int selectedIndex = StringToInt(sInfo);

            // Verify that the selected client is connected
            if(!IsPlayerExist(selectedIndex, false))
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }
            
            // Gets selected client's name
            static char sClientName[NORMAL_LINE_LENGTH];
            GetClientName(selectedIndex, sClientName, sizeof(sClientName));
            
            // Switch the menu mode
            switch(menuMode)
            {
                // Make a humans
                case AdminMenu_Human :
                {
                    // Verify that the chosen client is alive and a zombie
                    if(IsPlayerAlive(selectedIndex) && ZP_IsPlayerZombie(selectedIndex))
                    {
                        // If new round or last zombie
                        if(ZP_IsNewRound() || ZP_GetZombieAmount() <= 1)
                        {
                            // Emit error sound
                            ClientCommand(clientIndex, "play buttons/button11.wav");    
                            return;
                        }
                        
                        // Make a human
                        ZP_SwitchClientClass(selectedIndex, _, TYPE_HUMAN);

                        // Print event
                        HUDSendToAll("Admin give antidot", sAdminName, sClientName);
                    }
                    // Player is dead or human
                    else 
                    {
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav");    
                    }
                }
                
                // Make a zombies
                case AdminMenu_Zombie :    
                {
                    // Verify that the chosen client is alive and not zombie
                    if(IsPlayerAlive(selectedIndex) && ZP_IsPlayerHuman(selectedIndex))
                    {
                        // Start mode
                        if(ZP_IsNewRound())
                        {
                            ZP_SetServerGameMode("Normal", selectedIndex);
                        }
                        else
                        {
                            // If last human
                            if(ZP_GetHumanAmount() <= 1)
                            {
                                // Emit error sound
                                ClientCommand(clientIndex, "play buttons/button11.wav");    
                                return;
                            }
                            
                            // Make zombie
                            ZP_SwitchClientClass(selectedIndex, _, TYPE_ZOMBIE);
                        }

                        // Print event
                        HUDSendToAll("Admin infect player", sAdminName, sClientName);
                    }
                    // Player is dead or zombie
                    else 
                    {
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav");    
                    }
                }
                
                // Respawn players
                case AdminMenu_Respawn :
                {
                    // Verify that the chosen client is dead
                    if(!IsPlayerAlive(selectedIndex))
                    {
                        // Respawn
                        ZP_ForceClientRespawn(selectedIndex);

                        // Print event
                        HUDSendToAll("Admin respawned player", sAdminName, sClientName);
                    }
                    // Player is alive
                    else
                    {
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav");    
                    }
                }    
                
                // Make a nemesis
                case AdminMenu_Nemesis :    
                {
                    // Verify that the chosen client is alive
                    if(IsPlayerAlive(selectedIndex))
                    {
                        // Start mode
                        if(ZP_IsNewRound())
                        {
                            ZP_SetServerGameMode("Nemesis", selectedIndex);
                        }
                        else
                        {
                            // If last human
                            if(ZP_GetHumanAmount() <= 1 && ZP_IsPlayerHuman(selectedIndex))
                            {
                                // Emit error sound
                                ClientCommand(clientIndex, "play buttons/button11.wav");    
                                return;
                            }
                            
                            // Make nemesis
                            ZP_SwitchClientClass(selectedIndex, _, TYPE_NEMESIS);
                        }

                        // Print event
                        HUDSendToAll("Admin give a nemesis to player", sAdminName, sClientName);
                    }
                    // Player is dead
                    else 
                    {
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav");    
                    }
                }
                
                // Make a survivor
                case AdminMenu_Survivor :    
                {
                    // Verify that the chosen client is alive
                    if(IsPlayerAlive(selectedIndex))
                    {
                        // Start mode
                        if(ZP_IsNewRound())
                        {
                            ZP_SetServerGameMode("Survivor", selectedIndex);
                        }
                        else
                        {
                            // If last zombie
                            if(ZP_GetZombieAmount() <= 1 && ZP_IsPlayerZombie(selectedIndex))
                            {
                                // Emit error sound
                                ClientCommand(clientIndex, "play buttons/button11.wav");    
                                return;
                            }
                            
                            // Make survivor
                            ZP_SwitchClientClass(selectedIndex, _, TYPE_SURVIVOR);
                        }

                        // Print event
                        HUDSendToAll("Admin give a survivor to player", sAdminName, sClientName);
                    }
                    // Player is dead
                    else 
                    {
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav");    
                    }
                }
                
                // Give a ammopack
                case AdminMenu_Ammopack :    
                {
                    // Give ammopacks
                    ZP_SetClientAmmoPack(selectedIndex, ZP_GetClientAmmoPack(selectedIndex) + 100);

                    // Print event
                    HUDSendToAll("Admin give 100 ammopacks to player", sAdminName, sClientName);
                }
                
                // Give a level
                case AdminMenu_Level :    
                {
                    // Give level
                    ZP_SetClientLevel(selectedIndex, ZP_GetClientLevel(selectedIndex) + 1);

                    // Print event
                    HUDSendToAll("Admin give 1 level to player", sAdminName, sClientName);
                }
            }
            
            // Update menu
            MenuSubAdmin(clientIndex, menuMode);
        }
    }
}

/**
 * Print hud text on the screen among all clients.
 *
 * @param ...    Formatting parameters.
 **/
stock void HUDSendToAll(any ...)
{
    // Initialize char
    static char sHudText[BIG_LINE_LENGTH];
    
    // i = client index
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(!IsPlayerExist(i, false))
        {
            continue;
        }
        
        // Sets translation target
        SetGlobalTransTarget(i);
        
        // Create phrase
        VFormat(sHudText, sizeof(sHudText), "%t", 1);

        // Print translated phrase to server or client's screen
        SetHudTextParams(0.5, 0.3, 3.0, 255, 255, 255, 255, 0);
        ShowSyncHudText(i, hHudSync, sHudText);
    }
}

/**
 * Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
stock int MenuGetItemDraw(bool menuCondition)
{
    return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}