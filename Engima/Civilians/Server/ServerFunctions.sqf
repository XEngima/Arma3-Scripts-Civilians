ENGIMA_CIVILIANS_GetParamValue = {
  	private ["_params", "_key"];
  	private ["_value"];

   	_params = _this select 0;
   	_key = _this select 1;
	_value = if (count _this > 2) then { _this select 2 } else { objNull };

   	{
   		if (_x select 0 == _key) then {
   			_value = _x select 1;
   		};
   	} foreach (_params);
    	
   	_value
};

/*
 * Summary: Checks if a position is inside a marker.
 * Remarks: Marker can be of shape "RECTANGLE" or "ELLIPSE" and at any angle.
 * Arguments:
 *   _markerName: Name of current marker.
 *   _pos: Position to test.
 * Returns: true if position is inside marker. Else false.
 */
ENGIMA_CIVILIANS_GetAllPlayersPositions = {
	private ["_playerPositions"];

	_playerPositions = [];
	
	if (isMultiplayer) then {
		{
			if (isPlayer _x) then {
				_playerPositions pushBack (position vehicle _x);
			};
		} foreach (playableUnits);
	}
	else {
		if (player == player) then {
			_playerPositions = [position vehicle player];
		};
	};
	
	// testing
	//_playerPositions = [p1, p2];
	
	_playerPositions
};

ENGIMA_CIVILIANS_CountPositionsInBuilding = {
	private ["_building"];
	private ["_count"];
	
	_building = _this select 0;
	
	_count = 0;
	while { format ["%1", _building buildingPos _count] != "[0,0,0]" } do {
		_count = _count + 1;
	};
	
	_count
};

ENGIMA_CIVILIANS_FindSpawnPosition = {
	private ["_minSpawnDistance", "_playerBuildings", "_blackListMarkers"];
	private ["_playerPositions", "_tries", "_positionFound", "_foundPosition", "_buildingPosCount", "_building", "_tooClose", "_buildingPosNo", "_playerBuilding"];
	
	_minSpawnDistance = _this select 0;
	_playerBuildings = _this select 1;
	_blackListMarkers = _this select 2;
	
	_playerPositions = call ENGIMA_CIVILIANS_GetAllPlayersPositions;
	
	_tries = 0;
	_positionFound = false;
	_foundPosition = [];

	while { count _playerBuildings > 0 && !_positionFound && _tries < 10 } do {
		_tries = _tries + 1;
		_playerBuilding = _playerBuildings select floor random count _playerBuildings;
		_building = _playerBuilding select 0;
		_buildingPosCount = _playerBuilding select 1;
		
		//_buildingPosCount = [_building] call ENGIMA_CIVILIANS_CountPositionsInBuilding;
		
		if (_buildingPosCount > 0) then {
			_buildingPosNo = floor random _buildingPosCount;
			
			_tooClose = false;
			if (time > 5) then {
				{
					if (_x distance _building < _minSpawnDistance) then {
						_tooClose = true;
					};
				} foreach _playerPositions;
			};
			
			if (!_tooClose) then {
				if (!([getPos _building, _blackListMarkers] call ENGIMA_CIVILIANS_PositionInsideBlackMarker)) then {
					_foundPosition = _building buildingPos _buildingPosNo;
					_positionFound = true;
				};
			};
		};
	};

	_foundPosition
};

ENGIMA_CIVILIANS_PositionInsideBlackMarker = {
	private ["_pos", "_blackListMarkers"];
	private ["_isInsideMarker"];
	
	_pos = _this select 0;
	_blackListMarkers = _this select 1;
	
	_isInsideMarker = false;
	
	{
		if (_pos inArea _x) then { 
			_isInsideMarker = true;
		};
	} foreach _blackListMarkers;
	
	_isInsideMarker
};

ENGIMA_CIVILIANS_FindDestinationPosition = {
	private ["_civilian", "_blackListMarkers", "_maxSpawnDistance"];
	private ["_tries", "_positionFound", "_foundPosition", "_buildingPosCount", "_buildings", "_building", "_buildingPosNo", "_unitPos"];
	
	_civilian = _this select 0;
	_blackListMarkers = _this select 1;
	_maxSpawnDistance = _this select 2;

	_foundPosition = [];
	_tries = 0;
	_positionFound = false;
	_unitPos = getPosAtl _civilian;
	
	if (random 100 > 50) then {
		// Pick a building
		_buildings = nearestObjects [_unitPos, ["house"], _maxSpawnDistance];
		
		while { count _buildings > 0 && !_positionFound && _tries < 10 } do {
			_tries = _tries + 1;
			
			_building = _buildings select floor random count _buildings;
			_buildingPosCount = [_building] call ENGIMA_CIVILIANS_CountPositionsInBuilding;
			
			if (_buildingPosCount > 0) then {
				if (!([getPos _building, _blackListMarkers] call ENGIMA_CIVILIANS_PositionInsideBlackMarker)) then {
					_buildingPosNo = floor random _buildingPosCount;
					_foundPosition = _building buildingPos _buildingPosNo;
					_positionFound = true;
				};
			};
		};
	}
	else {
		private ["_distance", "_angle", "_x", "_y", "_pos"];
		
		while { !_positionFound && _tries < 10 } do {
			_tries = _tries + 1;
			
			_distance = random 200;
			_angle = random 360;
			_x = _distance * cos _angle;
			_y = _distance * sin _angle;
			
			_pos = [(_unitPos select 0) + _x, (_unitPos select 1) + _y];
			if (!isOnRoad _pos && !surfaceIsWater _pos && !([_pos, _blackListMarkers] call ENGIMA_CIVILIANS_PositionInsideBlackMarker)) then {
				_foundPosition = _pos;
				_positionFound = true;
			};
		};
	};	
	
	_foundPosition
};

ENGIMA_CIVILIANS_GetPlayerBuildings = {
	private ["_allPlayerPositions", "_maxSpawnDistance", "_blackListMarkers"];
	private ["_playerBuildings", "_buildings", "_playerBuildingsTemp", "_buildingPosCount"];

	_allPlayerPositions = _this select 0;
	_maxSpawnDistance = _this select 1;
	_blackListMarkers = _this select 2;

	_playerBuildings = [];
	_allPlayerPositions = call ENGIMA_CIVILIANS_GetAllPlayersPositions;
	
	{
		_buildings = nearestObjects [_x, ["house"], _maxSpawnDistance];
		sleep 0.01;
		_buildings = _buildings - _playerBuildings;
		sleep 0.01;
		_playerBuildings = _playerBuildings + _buildings;
		sleep 0.01;
	} foreach _allPlayerPositions;
	
	// Remove all buildings that have no positions or are inside blacklist markers
	_playerBuildingsTemp = [];
	{
		_buildingPosCount = [_x] call ENGIMA_CIVILIANS_CountPositionsInBuilding;
		
		if (_buildingPosCount > 0) then {
			if (!([getPos _x, _blackListMarkers] call ENGIMA_CIVILIANS_PositionInsideBlackMarker)) then {
				_playerBuildingsTemp pushBack [_x, _buildingPosCount];
			};
		}
	} foreach _playerBuildings;

//	hint str count _playerBuildingsTemp;
	
//	{
//		[str getPos (_x select 0), getPos (_x select 0), "mil_dot", "ColorYellow", ""] call ENGIMA_CIVILIANS_SetDebugMarkerAllClients;
//	} foreach _playerBuildingsTemp;
		
	_playerBuildingsTemp
};

// Starts the Engima Civilians script.
// _parameters (Array): An array of key value paired configuration options.
ENGIMA_CIVILIANS_StartCivilians = {
	private ["_unit", "_maxUnitsCount"];
	private ["_civilianItems"];
	private ["_spawnUnit", "_allPlayerPositions", "_playerBuildings"];
	
	private _side = [_this, "SIDE", civilian] call ENGIMA_CIVILIANS_GetParamValue;
	private _minSkill = [_this, "MIN_SKILL", 0.4] call ENGIMA_CIVILIANS_GetParamValue;
	private _maxSkill = [_this, "MAX_SKILL", 0.6] call ENGIMA_CIVILIANS_GetParamValue;
	private _unitClasses = [_this, "UNIT_CLASSES", ["C_man_1", "C_man_1_1_F", "C_man_1_2_F", "C_man_1_3_F", "C_man_polo_1_F", "C_man_polo_1_F_afro", "C_man_polo_1_F_euro", "C_man_polo_1_F_asia", "C_man_polo_2_F", "C_man_polo_2_F_afro", "C_man_polo_2_F_euro", "C_man_polo_2_F_asia", "C_man_polo_3_F", "C_man_polo_3_F_afro", "C_man_polo_3_F_euro", "C_man_polo_3_F_asia", "C_man_polo_4_F", "C_man_polo_4_F_afro", "C_man_polo_4_F_euro", "C_man_polo_4_F_asia", "C_man_polo_5_F", "C_man_polo_5_F_afro", "C_man_polo_5_F_euro", "C_man_polo_5_F_asia", "C_man_polo_6_F", "C_man_polo_6_F_afro", "C_man_polo_6_F_euro", "C_man_polo_6_F_asia", "C_man_p_fugitive_F", "C_man_p_fugitive_F_afro", "C_man_p_fugitive_F_euro", "C_man_p_fugitive_F_asia", "C_man_p_beggar_F", "C_man_p_beggar_F_afro", "C_man_p_beggar_F_euro", "C_man_p_beggar_F_asia", "C_man_w_worker_F", "C_scientist_F", "C_man_hunter_1_F", "C_man_p_shorts_1_F", "C_man_p_shorts_1_F_afro", "C_man_p_shorts_1_F_euro", "C_man_p_shorts_1_F_asia", "C_man_shorts_1_F", "C_man_shorts_1_F_afro", "C_man_shorts_1_F_euro", "C_man_shorts_1_F_asia", "C_man_shorts_2_F", "C_man_shorts_2_F_afro", "C_man_shorts_2_F_euro", "C_man_shorts_2_F_asia", "C_man_shorts_3_F", "C_man_shorts_3_F_afro", "C_man_shorts_3_F_euro", "C_man_shorts_3_F_asia", "C_man_shorts_4_F", "C_man_shorts_4_F_afro", "C_man_shorts_4_F_euro", "C_man_shorts_4_F_asia", "C_Orestes", "C_Nikos", "C_Nikos_aged"]] call ENGIMA_CIVILIANS_GetParamValue;
	private _unitsPerBuilding = [_this, "UNITS_PER_BUILDING", 0.1] call ENGIMA_CIVILIANS_GetParamValue;
	private _maxGroupsCount = [_this, "MAX_GROUPS_COUNT", 100] call ENGIMA_CIVILIANS_GetParamValue;
	private _minSpawnDistance = [_this, "MIN_SPAWN_DISTANCE", 100] call ENGIMA_CIVILIANS_GetParamValue;
	private _maxSpawnDistance = [_this, "MAX_SPAWN_DISTANCE", 500] call ENGIMA_CIVILIANS_GetParamValue;
	private _blackListMarkers = [_this, "BLACKLIST_MARKERS", []] call ENGIMA_CIVILIANS_GetParamValue;
	private _hideBlacklistMarkers = [_this, "HIDE_BLACKLIST_MARKERS", true] call ENGIMA_CIVILIANS_GetParamValue;
	private _fnc_OnSpawningCallback = [_this, "ON_UNIT_SPAWNING_CALLBACK", { true }] call ENGIMA_CIVILIANS_GetParamValue;
	private _fnc_OnSpawnedCallback = [_this, "ON_UNIT_SPAWNED_CALLBACK", {}] call ENGIMA_CIVILIANS_GetParamValue;
	private _fnc_OnRemoveCallback = [_this, "ON_UNIT_REMOVE_CALLBACK", { true }] call ENGIMA_CIVILIANS_GetParamValue;
	private _debug = [_this, "DEBUG", false] call ENGIMA_CIVILIANS_GetParamValue;

	if (_hideBlacklistMarkers) then {
		{
			_x setMarkerAlpha 0;
		} foreach _blackListMarkers;
	};
	
	// #region SpawnUnit

	_spawnUnit = {
		params ["_side", "_minSpawnDistance", "_unitClasses", "_playerBuildings", "_blackListMarkers", "_fnc_OnSpawningCallback" , "_fnc_OnSpawnedCallback", "_currentCivilianCount", "_calculatedCivilianCount"];
		private ["_pos", "_unit", "_group"];
		
		_pos = [_minSpawnDistance, _playerBuildings, _blackListMarkers] call ENGIMA_CIVILIANS_FindSpawnPosition;
		_unit = objNull;
		
		if (count _pos > 0) then {
            private _classToSpawn = selectRandom _unitClasses;
            private _spawnArgs = [_classToSpawn, _pos];
            private _spawnOk = [_spawnArgs, _currentCivilianCount, _calculatedCivilianCount] call _fnc_OnSpawningCallback;
            
            _classToSpawn = _spawnArgs select 0;
            _pos = _spawnArgs select 1;
            
            if (!isNil "_pos" && { typeName _pos == "ARRAY" } && { _pos isEqualTypeArray [0,0] || _pos isEqualTypeArray [0,0,0] }) then {
                if (!isNil "_spawnOk" && { typeName _spawnOk == "BOOL" } && { _spawnOk }) then {
        			_group = createGroup _side;
        			_unit = _group createUnit [_classToSpawn, [0, 0, 100], [], random 360, "FORM"];
        			
        			ENGIMA_CIVILIANS_GROUP_INSTANCE_NO = ENGIMA_CIVILIANS_GROUP_INSTANCE_NO + 1;
        			_unit setVehicleVarName "ENGIMA_CIVILIAN_UNIT_" + str ENGIMA_CIVILIANS_GROUP_INSTANCE_NO;
        			
                    doStop _unit;
                    _unit setPos _pos;
                    
        			[_unit, _currentCivilianCount] spawn _fnc_OnSpawnedCallback;
                };
            };
		};
		
		_unit
	};
	
	// #endregion

	sleep 0.5;
	
	_civilianItems = []; // Items of type [unit, behavior, destination pos, last pos, isMoving, nextActionTime, isRunning].
	
	while { true } do {
        private _civilianCount = count _civilianItems;
	    
		_allPlayerPositions = call ENGIMA_CIVILIANS_GetAllPlayersPositions;
		_playerBuildings = [_allPlayerPositions, _maxSpawnDistance, _blackListMarkers] call ENGIMA_CIVILIANS_GetPlayerBuildings;
		_maxUnitsCount = ceil (_unitsPerBuilding * count _playerBuildings);
		
		// Do not spawn in too many civs
		if (_maxUnitsCount > _maxGroupsCount) then {
			_maxUnitsCount = _maxGroupsCount;
		};
		
		if (_civilianCount < _maxUnitsCount) then {		
			_unit = [_side, _minSpawnDistance, _unitClasses, _playerBuildings, _blackListMarkers, _fnc_OnSpawningCallback, _fnc_OnSpawnedCallback, _civilianCount, _maxUnitsCount] call _spawnUnit;
			if (!isNull _unit) then {
				_unit setSkill _minSkill + random (_maxSkill - _minSkill);
				_civilianItems pushBack [_unit, "CITIZEN", [], getPos _unit, false, time, random 1 < ENGIMA_CIVILIANS_RUNNINGCHANCE];
			};
			
			sleep 0.1;
		};
		
		private _civilianItemsToKeep = [];
		{
			private ["_civilian"];
			private ["_tooCloseToRemove", "_removeUnit", "_group"];
			
			_civilian = _x select 0;
			_tooCloseToRemove = false;
			
			{
				if (_x distance _civilian < _maxSpawnDistance) then {
					_tooCloseToRemove = true;
				};
			} foreach _allPlayerPositions;
			
			if (_tooCloseToRemove) then {
				_civilianItemsToKeep pushBack _x;
			}
			else {
				_removeUnit = [_civilian, count _civilianItems] call _fnc_OnRemoveCallback;
				
				if (isNil "_removeUnit") then {
					_removeUnit = true;
				};
				
				if (typeName _removeUnit != "BOOL") then {
					_removeUnit = true;
				};
				
				if (!_removeUnit) then {
					_civilianItemsToKeep pushBack _x;
				}
				else {
					_group = group _civilian;
					[vehicleVarName _civilian] call ENGIMA_CIVILIANS_DeleteDebugMarkerAllClients;
					deleteVehicle _civilian;
					deleteGroup _group;
				};
			};
			
			sleep 0.01;
		} foreach _civilianItems;
		
		_civilianItems = _civilianItemsToKeep;
		
		{
			private ["_unit", "_behaviour", "_destinationPos", "_lastPos", "_isMoving", "_nextActionTime", "_isRunning"];
			private ["_destPos"];
			
			_unit = _x select 0;
			_behaviour = _x select 1;
			_destinationPos = _x select 2;
			_lastPos = _x select 3;
			_isMoving = _x select 4;
			_nextActionTime = _x select 5;
			_isRunning = _x select 6;
			
			// If civilian has reached its destination
			if (_isMoving && _lastPos distance getPos _unit < 1) then {
				_isMoving = false;
				_nextActionTime = time + random ENGIMA_CIVILIANS_MAXWAITINGTIME;
				
				_x set [4, _isMoving]; // Set isMoving = false
				_x set [5, _nextActionTime]; // Next action time
				
				(group _unit) setFormDir random 360;
			};
			
			// If it is time for civilian to move
			if (!_isMoving && time > _nextActionTime) then {
				
				_destPos = [_unit, _blackListMarkers, _maxSpawnDistance] call ENGIMA_CIVILIANS_FindDestinationPosition;
				if (count _destPos > 0) then {
					_unit doMove _destPos;
					_unit setBehaviour "SAFE";
					
					_destinationPos = _destPos;
					_isMoving = true;
					_isRunning = random 1 < ENGIMA_CIVILIANS_RUNNINGCHANCE;
					
					_x set [3, _destinationPos]; // Set destinationPos
					_x set [4, _isMoving]; // Set isMoving
					_x set [6, _isRunning]; // Set isRunning
				};
			};
			
			if (_isRunning) then {
				_unit setSpeedMode "NORMAL";
			}
			else {
				_unit setSpeedMode "LIMITED";
			};
			
			_x set [3, getPos _unit];
			
			if (_debug) then {
				[vehicleVarName _unit, getPos _unit, "mil_dot", "ColorWhite", "Civ"] call ENGIMA_CIVILIANS_SetDebugMarkerAllClients;
			};
			
		} foreach _civilianItems;

		sleep 3;
	};
};

