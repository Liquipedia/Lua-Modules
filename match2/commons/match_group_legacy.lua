local p = {}

local getArgs = require("Module:Arguments").getArgs
local json = require("Module:Json")
local Match = require("Module:Match")
local MatchGroup = require("Module:MatchGroup")
local getOpponent = require("Module:Match/Subobjects").luaGetOpponent
local getMap = require("Module:Match/Subobjects").luaGetMap
local getDefaultMapping = require("Module:MatchGroup/Legacy/Default").get
local Lua = require("Module:Lua")
local Logic = require("Module:Logic")
local String = require("Module:StringUtils")
local Table = require("Module:Table")
local config = Lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}

local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

local _type
local _args
local _frame

function p.get(frame)
	_args = getArgs(frame)
	_frame = frame

	local bracketid = _args["id"]
	if Logic.isEmpty(bracketid) then
		error("argument 'id' is empty")
	end

	local templateid = _args["template"]
	if Logic.isEmpty(templateid) then
		error("argument 'template' is empty")
	end

	local oldTemplateid = _args["templateOld"]
	if Logic.isEmpty(oldTemplateid) then
		error("argument 'templateOld' is empty")
	end

	_type = _args.type
	if Logic.isEmpty(_type) then
		error("argument 'type' is empty")
	end
	
	local mapping = p._getMapping(templateid, oldTemplateid)

	local newArgs = p._convert(mapping)
	newArgs.id = bracketid
	newArgs["1"] = templateid
	
	return MatchGroup.luaBracket(frame, newArgs)
end

function p.getTemplate(frame)
	_args = getArgs(frame)
	_frame = frame

	local templateid = _args["template"]
	if Logic.isEmpty(templateid) then
		error("argument 'template' is empty")
	end

	local oldTemplateid = _args["templateOld"]
	if Logic.isEmpty(oldTemplateid) then
		error("argument 'templateOld' is empty")
	end

	_type = _args.type
	if Logic.isEmpty(_type) then
		error("argument 'type' is empty")
	end
	
	local mapping = p._getMapping(templateid)
	
	local out = json.stringify(mapping, true)
		:gsub("\"([^\n:\"]-)\":", "%1 = ")
		:gsub("type =", "[\"type\"] =")
		:gsub(" = %[(.-)%]", " = { %1 }")
	out = "-- Custom mapping for '" .. templateid .. "' from '" .. oldTemplateid .. "'\n"
		.. "local p = {}\n\n"
		.. "p[\"" .. oldTemplateid .. "\"] = function() "
		.. "return " .. out .. "\n"
		.. "end\n\n"
		.. "return p"

	return "[[Module:MatchGroup/Legacy/" .. templateid .. "|Link to mapping]]" .. "<pre class=\"selectall\">" .. out .. "</pre>"
end

function p._convert(mapping)
	local newArgs = {}
	for index, matchMapping in pairs(mapping) do
		-- flatten nested tables like RxGx
		local flatten = matchMapping["$flatten$"] or {}
		local flattened = {}
		for i, flattenIndex in ipairs(flatten) do
			local toFlatten = _args[flattenIndex] or {}
			if type(toFlatten) == "string" then
				toFlatten = json.parse(toFlatten)
			end
			for key, val in pairs(toFlatten) do
				flattened[key] = val
			end
		end
		matchMapping["$flatten$"] = nil
		
		-- do actual conversion
		local match = {}
		for key, val in pairs(flattened) do
			if not String.startsWith(key, "map") then
				match[key] = val
			end
		end
		for realKey, val in pairs(matchMapping) do
			if String.startsWith(realKey, "$$") then
				-- skip reference
			elseif type(val) == "table" then
				-- references
				if val["$ref$"] ~= nil then
					local subst = val["$1$"] or ""
					val = Table.deepCopy(mapping["$$" .. val["$ref$"]])
					Table.iter.forEachPair(val, function(k,v)
						if type(v) == "string" then
							val[k] = v:gsub("%$1%$",subst)
						end
					end)
				end	
				
				if val["$notEmpty$"] == nil or not Logic.isEmpty(_args[val["$notEmpty$"]] or flattened[val["$notEmpty$"]]) then
					local nestedArgs = {}
					for innerKey, innerVal in pairs(val) do
						nestedArgs[innerKey] = _args[innerVal] or flattened[innerVal]
					end
					if String.startsWith(realKey, "opponent") then
						match[realKey] = getOpponent(_frame, nestedArgs)
					elseif String.startsWith(realKey, "map") then
						match[realKey] = getMap(_frame, nestedArgs)
					else
						match[realKey] = nestedArgs
					end
				end
			else
				local options = String.split(val, "|")
				if Table.size(options) > 1 then
					for i, option in ipairs(options) do
						local set = _args[option] or flattened[option]
						if Logic.readBool(set) then
							match[realKey] = true
							break
						end
					end
				else
					match[realKey] = _args[val] or flattened[val]
				end
			end
		end
		
		if not Logic.isEmpty(match) then
			newArgs[index] = match
		end
	end
	return newArgs
end

function p._getMapping(templateid, oldTemplateid)
	if Lua.moduleExists("Module:MatchGroup/Legacy/" .. templateid) then
		mw.log("Module:MatchGroup/Legacy/" .. templateid .. "exists")
		return (require("Module:MatchGroup/Legacy/" .. templateid)[oldTemplateid] or function() return nil end)()
			or getDefaultMapping(templateid, _type)
	else
		return getDefaultMapping(templateid, _type)
	end
	return nil
end

return p
