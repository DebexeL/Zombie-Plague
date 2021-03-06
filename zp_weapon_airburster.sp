/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: AirBurster",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_AIR_DAMAGE           10.0
#define WEAPON_AIR_DISTANCE         400.0
#define WEAPON_TIME_DELAY_ATTACK    0.075
#define WEAPON_TIME_DELAY_END       1.7
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT_MAIN,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT1,
    ANIM_SHOOT_END,
    ANIM_SHOOT2,
};

// Weapon states
enum
{
    STATE_BEGIN,
    STATE_ATTACK
}

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Decal index
int decalSmoke;

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("airburster");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"airburster\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("AIRBURSTER2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"AIRBURSTER2_SHOOT_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    decalSmoke = PrecacheModel("sprites/steam1.vmt", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Create an effect
    Weapon_OnEffectLogic(weaponIndex);
}

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Stop an effect
    Weapon_OnEffectLogic(weaponIndex, "Kill");
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iAmmo -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_ATTACK;
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    ///SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
    
    // Sets attack state
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_ATTACK);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT1, ANIM_SHOOT2 });
    
    // Create a air
    Weapon_OnCreateAirBurst(clientIndex, weaponIndex);

    // Initialize variables
    static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        ZP_CreateWeaponKickBack(clientIndex, 3.5, 4.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(clientIndex, 5.0, 4.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(clientIndex, 3.5, 1.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(clientIndex, 2.75, 2.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
    
    // Start an effect
    Weapon_OnEffectLogic(weaponIndex, "Start");
}

void Weapon_OnCreateAirBurst(int clientIndex, int weaponIndex)
{
    #pragma unused clientIndex, weaponIndex

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, WEAPON_AIR_DISTANCE, 0.0, 10.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TraceFilter, clientIndex);

    // Validate collisions
    if(TR_GetFraction() >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, clientIndex);
    }
    
    // Validate collisions
    if(TR_GetFraction() < 1.0)
    {
        // Gets victim index
        int victimIndex = TR_GetEntityIndex();

        // Validate victim
        if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
        {    
            // Create the damage for a victim
            ZP_TakeDamage(victimIndex, clientIndex, clientIndex, WEAPON_AIR_DAMAGE, DMG_NEVERGIB, weaponIndex);
        }
        else
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vEndPosition);
    
            // Create a sparks effect
            TE_SetupSmoke(vEndPosition, decalSmoke, 10.0, 10);
            TE_SendToAllInRange(vEndPosition, RangeType_Visibility);
        }
    }
}

void Weapon_OnEndAttack(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate attack
    if(GetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/))
    {
        // Sets end animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT_END);        

        // Sets begin state
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_END;
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
        ///SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        
        // Stop an effect
        Weapon_OnEffectLogic(weaponIndex, "Stop");
    }
}

void Weapon_OnEffectLogic(int weaponIndex, char[] sInput = "")
{
    #pragma unused weaponIndex, sInput

    // Gets the effect index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity");
    
    // Is effect should be created ?
    if(!hasLength(sInput))
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            return;
        }
        
        // Gets the world model index
        int worldModel = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
        
        // Validate model 
        if(worldModel != INVALID_ENT_REFERENCE)
        {
            // Create an attach fire effect
            entityIndex = UTIL_CreateParticle(worldModel, _, _, "muzzle_flash", "flamethrower_underwater");
            
            // Validate entity 
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets the effect index
                SetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity", entityIndex);
                
                // Stop an effect
                AcceptEntityInput(entityIndex, "Stop"); 
            }
        }
    }
    else
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Toggle state
            AcceptEntityInput(entityIndex, sInput); 
        }
    }
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2)         \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
                                \
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
                                \
        GetGameTime()           \
    )    

/**
 * @brief Called after a custom weapon is created.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Reset variables
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_BEGIN);
    }
}

/**
 * @brief Called on deploy of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Deploy(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on holster of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Holster(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        /// Block the scope
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9999.9);

        // Button secondary attack press
        if(!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
        // Button secondary attack release
        else if(iLastButtons & IN_ATTACK2)
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 *
 * @return                  True or false.
 **/
public bool TraceFilter(int entityIndex, int contentsMask, int filterIndex)
{
    return (entityIndex != filterIndex);
}