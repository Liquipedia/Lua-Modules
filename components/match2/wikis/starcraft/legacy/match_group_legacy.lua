---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:MatchGroup/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Legacy = {}

local getArgs = require("Module:Arguments").getArgs
local json = require("Module:Json")
local MatchGroup = require("Module:MatchGroup")
local getDefaultMapping = require("Module:MatchGroup/Legacy/Default").get
local Logic = require("Module:Logic")
local Lua = require("Module:Lua")
local Table = require("Module:Table")
local String = require("Module:StringUtils")

local _type
local _args

function Legacy.get(frame)
	_args = getArgs(frame)

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

	local mapping = Legacy._getMapping(templateid, oldTemplateid)

	local newArgs = Legacy._convert(mapping)
	newArgs.id = bracketid
	newArgs[1] = templateid

	return MatchGroup.TemplateBracket(newArgs)
end

function Legacy.getTemplate(frame)
	_args = getArgs(frame)

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

	local mapping = Legacy._getMapping(templateid)

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

	return "[[Module:MatchGroup/Legacy/" .. templateid ..
		"|Link to mapping]]" .. "<pre class=\"selectall\">" .. out .. "</pre>"
end

function Legacy._convert(mapping)
	local newArgs = {}
	for source, target in pairs(mapping) do
		-- nested tables
		if type(target) == "table" then
			-- flatten nested tables like RxGx
			local flatten = target["$flatten$"] or {}
			local flattened = {}
			for _, flattensource in ipairs(flatten) do
				local toFlatten = _args[flattensource] or {}
				if type(toFlatten) == "string" then
					toFlatten = json.parse(toFlatten)
				end
				for key, val in pairs(toFlatten) do
					flattened[key] = val
				end
			end

			target["$flatten$"] = nil

			-- do actual conversion
			local nested = {}
			for key, val in pairs(flattened) do
				if not String.startsWith(key, "map") then
					nested[key] = val
				end
			end
			for realKey, val in pairs(target) do
				nested = Legacy._convertSingle(realKey, val, nested, mapping, flattened)
			end

			if not Logic.isEmpty(nested) then
				newArgs[source] = nested
			end
		-- regular args
		else
			newArgs = Legacy._convertSingle(source, target, newArgs, mapping)
		end
	end
	return newArgs
end

function Legacy._convertSingle(realKey, val, match, mapping, flattened)
	flattened = flattened or _args
	local noSkip = not String.startsWith(realKey, "$$")
	if noSkip and type(val) == "table" then
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
			match[realKey] = nestedArgs
		end
	elseif noSkip then
		local options = String.split(val, "|")
		if Table.size(options) > 1 then
			for _, option in ipairs(options) do
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
	return match
end

function Legacy._getMapping(templateid, oldTemplateid)
	if Lua.moduleExists("Module:MatchGroup/Legacy/" .. templateid) then
		mw.log("Module:MatchGroup/Legacy/" .. templateid .. "exists")
		return (require("Module:MatchGroup/Legacy/" .. templateid)[oldTemplateid] or function() return nil end)()
			or getDefaultMapping(templateid, _type)
	else
		return getDefaultMapping(templateid, _type)
	end
end

return Legacy
