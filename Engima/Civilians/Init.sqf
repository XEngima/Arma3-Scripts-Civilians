call compile preprocessFileLineNumbers "Engima\Civilians\Common\Common.sqf";
call compile preprocessFileLineNumbers "Engima\Civilians\Common\Debug.sqf";
call compile preprocessFileLineNumbers "Engima\Civilians\HeadlessClient.sqf";

// Find out on which machine to run on

private _headlessClientPresent =  !(isNil Engima_Civilians_HeadlessClientName);
private _runOnThisMachine = false;

if (_headlessClientPresent && isMultiplayer) then {
    if (!isServer && !hasInterface) then {
        _runOnThisMachine = true;
    };
}
else {
    if (isServer) then {
        _runOnThisMachine = true;;   
    };
};

ENGIMA_CIVILIANS_MAXWAITINGTIME = 300; // Maximum standing still time in seconds
ENGIMA_CIVILIANS_RUNNINGCHANCE = 0.05; // Chance of running instead of walking

if (_runOnThisMachine) then {

    if (isNil "ENGIMA_CIVILIANS_GROUP_INSTANCE_NO") then {
        ENGIMA_CIVILIANS_GROUP_INSTANCE_NO = 0;
    };
 
	call compile preprocessFileLineNumbers "Engima\Civilians\Server\ServerFunctions.sqf";
	call compile preprocessFileLineNumbers "Engima\Civilians\ConfigAndStart.sqf";
};
