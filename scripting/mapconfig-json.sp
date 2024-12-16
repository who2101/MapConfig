#pragma semicolon 1
#pragma newdecls required

#include <wlib/map>
#include <json>

#define DEBUG 				0

#define CONFIG_DEFAULT 		"configs/mapconfig/default.json"
#define CONFIG_GAMETYPES 	"configs/mapconfig/gametypes.json"
#define CONFIG_MAPGROUPS 	"configs/mapconfig/groups.json"
#define CONFIG_MAPS 		"configs/mapconfig/maps.json"

char 
	sMap[128],				// Текущая карта
	sGamemodePrefix[64],	// Текущий режим, например: de
	sDefaultFile[256],		// Пути к json файлам
	sGametypeFile[256],
	sMapsFile[256],
	sGroupsFile[256];

public void OnPluginStart()
{
	BuildPath(Path_SM, sDefaultFile, sizeof sDefaultFile, CONFIG_DEFAULT);
	BuildPath(Path_SM, sGametypeFile, sizeof sGametypeFile, CONFIG_GAMETYPES);
	BuildPath(Path_SM, sMapsFile, sizeof sMapsFile, CONFIG_MAPS);
	BuildPath(Path_SM, sGroupsFile, sizeof sGroupsFile, CONFIG_MAPGROUPS);
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof sMap);
	GetCurrentMapPrefix(sGamemodePrefix, sizeof sGamemodePrefix);
}

public void OnConfigsExecuted()
{
	LoadDefault(sDefaultFile);
	LoadGametype(sGametypeFile, sGamemodePrefix);
	LoadMapGroup(sGroupsFile, sMap);
	LoadMap(sMapsFile, sMap);
}

void LoadDefault(const char[] filePath)
{
	if (!FileExists(filePath)) SetFailState("Config %s not found", filePath);
	
	JSONObject json_array = JSONObject.FromFile(filePath);

	if(json_array.HasKey("load"))
	{
		JSONArray loadArray = view_as<JSONArray>(json_array.Get("load"));
		LoadPlugins(loadArray);
	}
	
	if(json_array.HasKey("unload"))
	{
		JSONArray unloadArray = view_as<JSONArray>(json_array.Get("unload"));
		UnloadPlugins(unloadArray);
	}

	if(json_array.HasKey("reload"))
	{
		JSONArray reloadArray = view_as<JSONArray>(json_array.Get("reload"));
		ReloadPlugins(reloadArray);
	}

	if(json_array.HasKey("variables"))
	{
		JSONObject variablesObject = view_as<JSONObject>(json_array.Get("variables"));
		LoadVariables(variablesObject);
	}	

	json_array.Close();
}

void LoadGametype(const char[] filePath, const char[] gamemodePrefix)
{
	if (!FileExists(filePath)) SetFailState("Config %s not found", filePath);
	
	JSONArray json_array = JSONArray.FromFile(filePath);
	JSONObject json_object = view_as<JSONObject>(json_array.Get(0));
	
	if(json_object.HasKey(gamemodePrefix))
	{
		JSONObject gamemodeObject = view_as<JSONObject>(json_object.Get(gamemodePrefix));
	
		if(gamemodeObject.HasKey("load"))
		{
			JSONArray loadArray = view_as<JSONArray>(gamemodeObject.Get("load"));
			LoadPlugins(loadArray);
		}
		
		if(gamemodeObject.HasKey("unload"))
		{
			JSONArray unloadArray = view_as<JSONArray>(gamemodeObject.Get("unload"));
			UnloadPlugins(unloadArray);		
		}
		
		if(gamemodeObject.HasKey("reload"))
		{
			JSONArray reloadArray = view_as<JSONArray>(gamemodeObject.Get("reload"));
			ReloadPlugins(reloadArray);
		}
			
		if(gamemodeObject.HasKey("variables"))
		{		
			JSONObject variablesObject = view_as<JSONObject>(gamemodeObject.Get("variables"));
			LoadVariables(variablesObject);
		}

		gamemodeObject.Close();
	}

	json_object.Close();
	json_array.Close();
}

void LoadMap(const char[] filePath, const char[] map)
{
	if (!FileExists(filePath)) SetFailState("Config %s not found", filePath);
	
	JSONArray json_array = JSONArray.FromFile(filePath);
	JSONObject json_object = view_as<JSONObject>(json_array.Get(0));
	
	if(json_object.HasKey(map))
	{
		JSONObject gamemodeObject = view_as<JSONObject>(json_object.Get(map));

		if(gamemodeObject.HasKey("load"))
		{
			JSONArray loadArray = view_as<JSONArray>(gamemodeObject.Get("load"));
			LoadPlugins(loadArray);
		}		

		if(gamemodeObject.HasKey("unload"))
		{
			JSONArray unloadArray = view_as<JSONArray>(gamemodeObject.Get("unload"));
			UnloadPlugins(unloadArray);		
		}
	

		
		if(gamemodeObject.HasKey("reload"))
		{
			JSONArray reloadArray = view_as<JSONArray>(gamemodeObject.Get("reload"));
			ReloadPlugins(reloadArray);
		}
			
		if(gamemodeObject.HasKey("variables"))
		{		
			JSONObject variablesObject = view_as<JSONObject>(gamemodeObject.Get("variables"));
			LoadVariables(variablesObject);
		}
		
		gamemodeObject.Close();
	}

	json_object.Close();
	json_array.Close();
}

void LoadMapGroup(const char[] filePath, const char[] map)
{
	if (!FileExists(filePath)) SetFailState("Config %s not found", filePath);
	
	JSONArray json_array = JSONArray.FromFile(filePath);
	JSONObject json_object = view_as<JSONObject>(json_array.Get(0));
	
	JSONObjectKeys keys = json_object.Keys();

	char
		groupSection[256],		// Названия групп карт
		mapName[256]; 			// Используется при обходе массива mapsArray

	while(keys.ReadKey(groupSection, sizeof groupSection))
	{
		JSONObject groupObject = view_as<JSONObject>(json_object.Get(groupSection));
		JSONArray mapsArray = view_as<JSONArray>(groupObject.Get("maps"));

		for(int i = 0; i < mapsArray.Length; i++)
		{
			if(mapsArray.GetString(i, mapName, sizeof mapName) && !strcmp(map, mapName))
			{
				if(groupObject.HasKey("load"))
				{
					JSONArray loadArray = view_as<JSONArray>(groupObject.Get("load"));
					LoadPlugins(loadArray);
				}
				
				if(groupObject.HasKey("unload"))
				{
					JSONArray unloadArray = view_as<JSONArray>(groupObject.Get("unload"));
					UnloadPlugins(unloadArray);
				}
				
				if(groupObject.HasKey("reload"))
				{
					JSONArray reloadArray = view_as<JSONArray>(groupObject.Get("reload"));
					ReloadPlugins(reloadArray);					
				}

				if(groupObject.HasKey("variables"))
				{
					JSONObject variablesObject = view_as<JSONObject>(groupObject.Get("variables"));
					LoadVariables(variablesObject);
				}
			}
		}
		
		mapsArray.Close();
		groupObject.Close();
	}
	
	keys.Close();
	json_object.Close();
	json_array.Close();
}

void LoadPlugins(JSONArray loadArray)
{
	char buffer[256];

	for(int load_index = 0; load_index < loadArray.Length; load_index++)
	{
		loadArray.GetString(load_index, buffer, sizeof buffer);

		ServerCommand(IsPluginHasSMX(buffer) ? "sm plugins load %s" : "sm plugins load %s.smx", buffer);

		#if DEBUG
		PrintToChatAll("Load: %s", buffer);
		#endif
	}
	
	loadArray.Close();
}

void ReloadPlugins(JSONArray reloadArray)
{
	char buffer[256];

	for(int reload_index = 0; reload_index < reloadArray.Length; reload_index++)
	{
		reloadArray.GetString(reload_index, buffer, sizeof buffer);

		ServerCommand(IsPluginHasSMX(buffer) ? "sm plugins reload %s" : "sm plugins reload %s.smx", buffer);
		
		#if DEBUG
		PrintToChatAll("Reload: %s", buffer);
		#endif
	}
	
	reloadArray.Close();
}

void UnloadPlugins(JSONArray unloadArray)
{
	char buffer[256];

	for(int unload_index = 0; unload_index < unloadArray.Length; unload_index++)
	{
		unloadArray.GetString(unload_index, buffer, sizeof buffer);

		ServerCommand(IsPluginHasSMX(buffer) ? "sm plugins unload %s" : "sm plugins unload %s.smx", buffer);
		
		#if DEBUG
		PrintToChatAll("Unload: %s", buffer);
		#endif
	}
	
	unloadArray.Close();
}

void LoadVariables(JSONObject variablesObject)
{
	JSONObjectKeys variablesKeys = variablesObject.Keys();
	
	char
		variable[128],
		value[128];
	
	while (variablesKeys.ReadKey(variable, sizeof variable))
	{
		variablesObject.GetString(variable, value, sizeof value);

		ServerCommand("%s \"%s\"", variable, value);

		#if DEBUG
		PrintToChatAll("Variable: %s | Value: %s", variable, value);
		#endif
	}
	
	variablesKeys.Close();
	variablesObject.Close();
}

// Проверяет, есть у плагина расширение .smx
bool IsPluginHasSMX(const char[] plugin_name)
{
	int length = strlen(plugin_name);

	return !strcmp(plugin_name[length-4], ".smx", false);
}