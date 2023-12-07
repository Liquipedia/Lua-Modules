---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Legacy = {}

local Arguments = require('Module:Arguments')
local json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroup = require('Module:MatchGroup')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupLegacyDefault = Lua.import('Module:MatchGroup/Legacy/Default', {requireDevIfEnabled = true})
local MatchSubobjects = Lua.import('Module:Match/Subobjects', {requireDevIfEnabled = true})
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific', {requireDevIfEnabled = true})

local IS_USERSPACE = false
local NAMESPACE_USER = 2
local RESET_MATCH = 'RxMBR'
local THIRD_PLACE_MATCH = 'RxMTP'
local _args
local _type

---@param frame Frame
---@return string
function Legacy.get(frame)
	_args = Arguments.getArgs(frame)
	mw.addWarning('You are editing a page that uses a Legacy Bracket. '
		.. 'Please use the new Bracket System on new pages.')
	local nameSpaceNumber = mw.title.getCurrentTitle().namespace

	local storage = _args.store
	if storage == '' or storage == nil then
		storage = (Variables.varDefault('disable_LPDB_storage') == 'true')
			and 'false' or nil
	end
	if (storage or '') ~= 'true' and nameSpaceNumber == NAMESPACE_USER then
		storage = 'false'
		IS_USERSPACE = true
	end

	local bracketid = _args['id']
	if Logic.isEmpty(bracketid) then
		error('argument \'id\' is empty')
	end

	local templateid = _args['template']
	if Logic.isEmpty(templateid) then
		error('argument \'template\' is empty')
	end

	local oldTemplateid = _args['templateOld']
	if Logic.isEmpty(oldTemplateid) then
		error('argument \'templateOld\' is empty')
	end

	_type = _args.type
	if Logic.isEmpty(_type) then
		error('argument \'type\' is empty')
	end

	local mapping = Legacy._getMapping(templateid, oldTemplateid)

	local newArgs = Legacy._convert(mapping)
	newArgs.id = bracketid
	newArgs[1] = templateid

	newArgs.store = storage
	newArgs.noDuplicateCheck = _args.noDuplicateCheck
	newArgs.isLegacy = true

	return MatchGroup.TemplateBracket(newArgs)
end

---@param frame Frame
---@return string
function Legacy.getTemplate(frame)
	_args = Arguments.getArgs(frame)

	local templateid = _args['template']
	if Logic.isEmpty(templateid) then
		error('argument \template\' is empty')
	end

	local oldTemplateid = _args['templateOld']
	if Logic.isEmpty(oldTemplateid) then
		error('argument \'templateOld\' is empty')
	end

	_type = _args.type
	if Logic.isEmpty(_type) then
		error('argument \'type\' is empty')
	end

	local mapping = Legacy._getMapping(templateid)

	local out = json.stringify(mapping, {pretty = true})
		:gsub('"([^\n:"]-)":', '%1 = ')
		:gsub('type =', '["type"] =')
		:gsub(' = %[(.-)%]', ' = { %1 }')
	out = '-- Custom mapping for \'' .. templateid .. '\' from \'' .. oldTemplateid .. '\'\n'
		.. 'local p = {}\n\n'
		.. 'p["' .. oldTemplateid .. '"] = function() '
		.. 'return ' .. out .. '\n'
		.. 'end\n\n'
		.. 'return p'
	out = '[[Module:MatchGroup/Legacy/' .. templateid .. '|Link to mapping]]' .. '<pre class=\"selectall\">' .. out
	return out .. '</pre>'
end

---@param mapping table
---@return table
function Legacy._convert(mapping)
	local newArgs = {}
	for source, target in pairs(mapping) do
		-- nested tables
		if type(target) == 'table' then
			-- flatten nested tables like RxGx
			local flatten = target['$flatten$'] or {}
			local flattened = {}
			for _, flattensource in ipairs(flatten) do
				local toFlatten = _args[flattensource] or {}
				if type(toFlatten) == 'string' then
					toFlatten = json.parse(toFlatten)
				end
				for key, val in pairs(toFlatten) do
					flattened[key] = val
				end
			end

			target['$flatten$'] = nil

			-- do actual conversion
			local nested = {}
			for key, val in pairs(flattened) do
				if not String.startsWith(tostring(key), 'map') then
					nested[key] = val
				end
			end
			for realKey, val in pairs(target) do
				nested = Legacy._convertSingle(realKey, val, nested, mapping, flattened, source)
			end

			if not Logic.isEmpty(nested) then
				if source ~= RESET_MATCH and source ~= THIRD_PLACE_MATCH then
					if not nested.opponent1 then
						nested.opponent1 = {type = 'team', template = 'TBD', icon = WikiSpecific.defaultIcon, name = 'TBD'}
						mw.log('Missing Opponent entry')
					end
					if not nested.opponent2 then
						nested.opponent2 = {type = 'team', template = 'TBD', icon = WikiSpecific.defaultIcon, name = 'TBD'}
						mw.log('Missing Opponent entry')
					end
				elseif not nested.opponent1 then
					nested = nil
				end
				if nested then
					for _, opponent, opponentIndex in Table.iter.pairsByPrefix(nested, 'opponent') do
						nested.winner = nested.winner or opponent.win and opponentIndex or nil
					end
				end

				newArgs[source] = nested
			end
		-- regular args
		else
			newArgs = Legacy._convertSingle(source, target, newArgs, mapping, nil, source)
		end
	end
	return newArgs
end

---@param realKey string
---@param val string|table
---@param match table
---@param mapping table
---@param flattened table?
---@param source string
---@return table
function Legacy._convertSingle(realKey, val, match, mapping, flattened, source)
	flattened = flattened or _args
	local noSkip = not String.startsWith(realKey, '$$')
	if source == RESET_MATCH and String.startsWith(realKey, 'opponent') then
		local score2 = _args[val.score] or ''
		if score2 == '' then
			noSkip = false
		end
	end

	if noSkip and type(val) == 'table' then
		if val['$ref$'] ~= nil then
			local subst = val['$1$'] or ''
			val = Table.deepCopy(mapping['$$' .. val['$ref$']])
			Table.iter.forEachPair(val, function(k,v)
					if type(v) == 'string' then
						val[k] = v:gsub('%$1%$',subst)
					end
				end)
		end

		if IS_USERSPACE then
			--the following allows allow empty matches in the conversion
			if String.startsWith(realKey, 'opponent') and
				Logic.isEmpty(_args[val['$notEmpty$']] or flattened[val['$notEmpty$']]) then
					_args[val['$notEmpty$']] = '&nbsp;'
			end
		end

		if val['$notEmpty$'] == nil or not Logic.isEmpty(_args[val['$notEmpty$']] or flattened[val['$notEmpty$']]) then
			local nestedArgs = {}
			for innerKey, innerVal in pairs(val) do
				nestedArgs[innerKey] = _args[innerVal] or flattened[innerVal]
			end
			if String.startsWith(realKey, 'opponent') then
				match[realKey] = nestedArgs
			elseif String.startsWith(realKey, 'map') then
				match[realKey] = MatchSubobjects.luaGetMap(nestedArgs)
			else
				match[realKey] = nestedArgs
			end
		end
	elseif noSkip then
		---@cast val string
		local options = String.split(val, '|')
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

---@param templateid string
---@param oldTemplateid string?
---@return table
function Legacy._getMapping(templateid, oldTemplateid)
	if Lua.moduleExists('Module:MatchGroup/Legacy/' .. templateid) then
		mw.log('Module:MatchGroup/Legacy/' .. templateid .. 'exists')
		return (require('Module:MatchGroup/Legacy/' .. templateid)[oldTemplateid] or function() return nil end)()
			or MatchGroupLegacyDefault.get(templateid, _type)
	else
		return MatchGroupLegacyDefault.get(templateid, _type)
	end
end

return Legacy
