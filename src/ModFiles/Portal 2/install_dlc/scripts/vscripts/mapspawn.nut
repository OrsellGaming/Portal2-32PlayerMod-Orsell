//------------------------------------------------------------------------------------------------------------------------------------------------//
//                                                                   COPYRIGHT                                                                    //
//                                                        © 2022 Portal 2: Multiplayer Mod                                                        //
//                                      https://github.com/kyleraykbs/Portal2-32PlayerMod/blob/main/LICENSE                                       //
// In the case that this file does not exist at all or in the GitHub repository, this project will fall under a GNU LESSER GENERAL PUBLIC LICENSE //
//------------------------------------------------------------------------------------------------------------------------------------------------//

//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//   __  __
//  |  \/  |  __ _  _ __   ___  _ __    __ _ __      __ _ __   _
//  | |\/| | / _` || '_ \ / __|| '_ \  / _` |\ \ /\ / /| '_ \ (_)
//  | |  | || (_| || |_) |\__ \| |_) || (_| | \ V  V / | | | | _
//  |_|  |_| \__,_|| .__/ |___/| .__/  \__,_|  \_/\_/  |_| |_|(_)
//                 |_|         |_|
//---------------------------------------------------
// Purpose: The heart of the mod's content. Runs on
// every map transition to bring about features and
//                 fixes for 3+ MP.
//---------------------------------------------------

// mapspawn.nut is called twice on map transitions for some reason...
// Prevent the second run
if (!("Entities" in this)) { return }

printl("\n-------------------------")
printl("==== calling mapspawn.nut")
printl("-------------------------\n")

IncludeScript("multiplayermod/pluginfunctionscheck.nut") // Make sure we know the exact status of our plugin first thing
IncludeScript("multiplayermod/config.nut")
IncludeScript("multiplayermod/configcheck.nut") // Make sure nothing was invalid and compensate

// Create a global point_servercommand entity for us to pass through commands
// We don't want to create multiple when it is called on, so reference it by targetname
Entities.CreateByClassname("point_servercommand").__KeyValueFromString("targetname", "p2mm_servercommand")

if (GetDeveloperLevel() == 918612) {
    // Take care of anything pertaining to progress check and how our plugin did when loading
    IncludeScript("multiplayermod/firstmapload.nut")
    return
}

IncludeScript("multiplayermod/variables.nut")
IncludeScript("multiplayermod/safeguard.nut")
IncludeScript("multiplayermod/functions.nut")
IncludeScript("multiplayermod/hooks.nut")
IncludeScript("multiplayermod/chatcommands.nut")

// Always have global root functions imported for any level
IncludeScript("multiplayermod/mapsupport/#propcreation.nut")
IncludeScript("multiplayermod/mapsupport/#rootfunctions.nut")

// Load the custom save system after everything else has been loaded
// IncludeScript("multiplayermod/savesystem.nut") Commented out for now, still need to finish

// Print P2:MM game art in console
foreach (line in ConsoleAscii) { printl(line) }
delete ConsoleAscii

//---------------------------------------------------

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard mapsupport

// This function is how we communicate with all mapsupport files.
// In case no mapsupport file exists, it will fall back to "nothing" instead of an error
//function MapSupport(MSInstantRun, MSLoop, MSPostPlayerSpawn, MSPostMapSpawn, MSOnPlayerJoin, MSOnDeath, MSOnRespawn, MSOnSave, MSOnSaveCheck, MSOnSaveLoad) {} This will be the layout for the system in the future
function MapSupport(MSInstantRun, MSLoop, MSPostPlayerSpawn, MSPostMapSpawn, MSOnPlayerJoin, MSOnDeath, MSOnRespawn) {}

// Import map support code
function LoadMapSupportCode(gametype) {
    printl("\n=============================================================")
    printl("(P2:MM): Attempting to load " + gametype + " mapsupport code!")
    printl("=============================================================\n")

    local MapName = FindAndReplace(GetMapName().tostring(), "maps/", "")
    MapName = FindAndReplace(MapName.tostring(), ".bsp", "")

    if (gametype != "standard") {
        try {
            // Import the core functions before the actual mapsupport
            IncludeScript("multiplayermod/mapsupport/" + gametype + "/#" + gametype + "functions.nut")
        } catch (exception) {
            printl("(P2:MM): Failed to load the " + gametype + " core functions file!")
        }
    }

    try {
        IncludeScript("multiplayermod/mapsupport/" + gametype + "/" + MapName.tostring() + ".nut")
    } catch (exception) {
        if (gametype == "standard") {
            printl("(P2:MM): Failed to load standard mapsupport for " + GetMapName() + "\n")
        } else {
            printl("(P2:MM): Failed to load " + gametype + " mapsupport code! Reverting to standard mapsupport...")
            return LoadMapSupportCode("standard")
        }
    }
}

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard mapsupport
switch (Config_GameMode) {
case 0:     LoadMapSupportCode("standard");     break
case 1:     LoadMapSupportCode("speedrun");     break
case 2:     LoadMapSupportCode("deathmatch");   break
case 3:     LoadMapSupportCode("futbol");       break
default:
    printl("(P2:MM): \"Config_GameMode\" value in config.nut is invalid! Be sure it is set to an integer from 0-3. Reverting to standard mapsupport.")
    LoadMapSupportCode("standard")
    break
}

//---------------------------------------------------

// Run InstantRun() shortly AFTER spawn (hooks.nut)

try {
    // Make sure that the user is in multiplayer mode before initiating everything
    if (!IsMultiplayer()) {
        printl("(P2:MM): This is not a multiplayer session! Disconnecting client...")
        EntFire("p2mm_servercommand", "command", "disconnect \"You cannot play the singleplayer mode when Portal 2 is launched from the Multiplayer Mod launcher. Please unmount and launch normally to play singleplayer.\"")
    }

    // InstantRun() must be delayed slightly
    EntFire("p2mm_servercommand", "command", "script InstantRun()", 0.02)
} catch (e) {
    printl("(P2:MM): Initializing our custom support!\n")
}
