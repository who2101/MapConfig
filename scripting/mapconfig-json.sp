#pragma semicolon 1
#pragma newdecls required

#include <wlib/map>
#include <json>

#pragma dynamic 262144

#define DEBUG 0

#define CONFIG_DEFAULT "configs/mapconfig/default.json"
#define CONFIG_GAMETYPES "configs/mapconfig/gametypes.json"
#define CONFIG_MAPS "configs/mapconfig/maps.json"

char sMap[128], sGamemodePrefix[64];
char sDefaultFile[256], sGametypeFile[256], sMapsFile[256];

public void OnPluginStart()
{
	BuildPath(Path_SM, sDefaultFile, sizeof sDefaultFile, CONFIG_DEFAULT);
	BuildPath(Path_SM, sGametypeFile, sizeof sGametypeFile, CONFIG_GAMETYPES);
	BuildPath(Path_SM, sMapsFile, sizeof sMapsFile, CONFIG_MAPS);
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof sMap);
	GetCurrentMapPrefix(sGamemodePrefix, sizeof sGamemodePrefix);
}

public void OnConfigsExecuted()
{
	ParseJSON_Default(sDefaultFile);
	ParseJSON_GameTypes(sGametypeFile, sGamemodePrefix);
	ParseJSON_Maps(sMapsFile, sMap);
}

void ParseJSON_Default(const char[] filePath)
{
	if (!FileExists(filePath)) SetFailState("File %s is not exists", filePath);
	
	JSON_Object json_obj = json_read_from_file(filePath);
	
	if (json_obj != null)
	{
		ParseJSON_Obj(json_obj);
		json_cleanup_and_delete(json_obj);
	}
}

void ParseJSON_GameTypes(const char[] filePath, const char[] gamemodePrefix)
{
	if (!FileExists(filePath)) SetFailState("File %s is not exists", filePath);
	
	JSON_Array jsonArray = view_as<JSON_Array>(json_read_from_file(filePath));
	
	if (jsonArray == null) return;
	
	JSON_Object json_obj = jsonArray.GetObject(0);
	
	if (json_obj == null) return;

	if ((json_obj = json_obj.GetObject(gamemodePrefix)) != null)
	{
		ParseJSON_Obj(json_obj);
		json_cleanup_and_delete(jsonArray);
	}
}

void ParseJSON_Maps(const char[] filePath, const char[] map)
{
	if (!FileExists(filePath)) SetFailState("File %s is not exists", filePath);
	
	JSON_Array jsonArray = view_as<JSON_Array>(json_read_from_file(filePath));
	
	if (jsonArray == null) return;
	
	JSON_Object json_obj = jsonArray.GetObject(0);
	
	if (json_obj == null) return;

	if ((json_obj = json_obj.GetObject(map)) != null)
	{
		ParseJSON_Obj(json_obj);
		json_cleanup_and_delete(jsonArray);
	}
}

void ParseJSON_Obj(JSON_Object json_obj)
{
	JSON_Array unloadArray = view_as<JSON_Array>(json_obj.GetObject("unload"));
	JSON_Array loadArray = view_as<JSON_Array>(json_obj.GetObject("load"));
	JSON_Array reloadArray = view_as<JSON_Array>(json_obj.GetObject("reload"));
	JSON_Object variables_obj = json_obj.GetObject("variables");
	
	char buffer[512];
	
	if (unloadArray != null)
	{
		for (int i = 0; i < unloadArray.Length; i++) {
			buffer[0] = 0;
			unloadArray.GetString(i, buffer, sizeof buffer);
			
			if (buffer[0])
			{
				if (StrContains(buffer, ".smx") != -1)ServerCommand("sm plugins unload %s", buffer);
				else ServerCommand("sm plugins unload %s.smx", buffer);
				
				#if DEBUG
				PrintToServer("[MC-JSON] Unload - %s", buffer);
				#endif
			}
		}
	}
	
	if (loadArray != null)
	{
		for (int i = 0; i < loadArray.Length; i++) {
			buffer[0] = 0;
			loadArray.GetString(i, buffer, sizeof buffer);
			
			if (buffer[0])
			{
				if (StrContains(buffer, ".smx") != -1)ServerCommand("sm plugins load %s", buffer);
				else ServerCommand("sm plugins load %s.smx", buffer);
				
				#if DEBUG
				PrintToServer("[MC-JSON] Load - %s", buffer);
				#endif
			}
		}
	}
	
	if (reloadArray != null)
	{
		for (int i = 0; i < reloadArray.Length; i++) {
			buffer[0] = 0;
			reloadArray.GetString(i, buffer, sizeof buffer);
			
			if (buffer[0])
			{
				if (StrContains(buffer, ".smx") != -1)ServerCommand("sm plugins reload %s", buffer);
				else ServerCommand("sm plugins reload %s.smx", buffer);
				
				#if DEBUG
				PrintToServer("[MC-JSON] - Reload - %s", buffer);
				#endif
			}
		}
	}
	
	if (variables_obj != null)
	{
		int key_length = 0;
		
		// It does not work without it
		char out[1024];
		variables_obj.Encode(out, sizeof out);
		
		for (int i = 0; i < variables_obj.Length; i += 1) {
			buffer[0] = 0;
			key_length = variables_obj.GetKeySize(i);
			char[] key = new char[key_length];
			variables_obj.GetKey(i, key, key_length);

			if (!strcmp(key, "#") || !strcmp(key, "_comment") || !strcmp(key, "//") || !strcmp(key, "__comment__"))
				continue;
			
			variables_obj.GetString(key, buffer, sizeof buffer);
			
			if (buffer[0])
			{
				ServerCommand("%s \"%s\"", key, buffer);
				
				#if DEBUG
				PrintToServer("%s %s", key, buffer);
				#endif
			}
		}
	}
} 