local Legacy = {}

local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local getOpponent = require('Module:Match/Subobjects').luaGetOpponent
local getMap = require('Module:Match/Subobjects').luaGetMap
local getDefaultMapping = require('Module:MatchGroup/Legacy/Default/dev').get
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local _IS_USERSPACE = false
local _NAMESPACE_USER = 2
local _RESET_MATCH = 'RxMBR'
local _THIRD_PLACE_MATCH = 'RxMTP'

function Legacy.get(frame)
	_args = getArgs(frame)
	mw.addWarning('You are editing a page that uses a Legacy Bracket. '
		.. 'Please use the [[Liquipedia:Brackets|new Bracket System]] on new pages.')
	local nameSpaceNumber = mw.title.getCurrentTitle().namespace

	local storage = _args.store
	if storage == '' or storage == nil then
		storage = (Variables.varDefault('disable_SMW_storage') == 'true')
			and 'false' or nil
	end
	if (storage or '') ~= 'true' and nameSpaceNumber == _NAMESPACE_USER then
		storage = 'false'
		_IS_USERSPACE = true
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
	newArgs['1'] = templateid

	newArgs.store = storage
	newArgs.noDuplicateCheck = _args.noDuplicateCheck

	return MatchGroup.luaBracket(frame, newArgs)
end

function Legacy.getTemplate(frame)
	_args = getArgs(frame)
	_frame = frame

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

	local mapping = p._getMapping(templateid)

	local out = json.stringify(mapping, true)
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

function Legacy._convert(mapping)
	local newArgs = {}
	for index, matchMapping in pairs(mapping) do
		-- flatten nested tables like RxGx
		local flatten = matchMapping["$flatten$"] or {}
		local flattened = {}
		for _, flattenIndex in ipairs(flatten) do
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
			if not String.startsWith(tostring(key), "map") then
				match[key] = val
			end
		end
		for realKey, val in pairs(matchMapping) do
			local notSkipMe = not String.startsWith(realKey, "$$")
			if index == _RESET_MATCH and String.startsWith(realKey, "opponent") then
				local score2 = _args[val.score] or ''
				if score2 == '' then
					notSkipMe = false
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
				local score1 = json.parseIfString(nested.opponent1 or {}).score or ''
				local score2 = json.parseIfString(nested.opponent2 or {}).score or ''
				
				if source ~= 'RxMBR' and source ~= 'RxMTP' then
					if not nested.opponent1 then
						nested.opponent1 = '{\'type\':\'team\',\'template\':\'TBD\',\'icon\':\'Rllogo_std.png\',\'name\':\'TBD\'}'
						mw.log('Missing Opponent entry')
					end
					if not nested.opponent2 then
						nested.opponent2 = '{\'type\':\'team\',\'template\':\'TBD\',\'icon\':\'Rllogo_std.png\',\'name\':\'TBD\'}'
						mw.log('Missing Opponent entry')
					end
				elseif not nested.opponent1 then
					nested = nil
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

function Legacy._convertSingle(realKey, val, match, mapping, flattened, source)
	flattened = flattened or _args
	local noSkip = not String.startsWith(realKey, '$$')
	if source == 'RxMBR' and String.startsWith(realKey, 'opponent') then
		local score2 = _args[val.score] or ''
		if score2 == '' then
			notSkipMe = false
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

		if _IS_USERSPACE then
			--the following allows allow empty matches in the conversion
			if String.startsWith(realKey, 'opponent') and
				Logic.isEmpty(_args[val['$notEmpty$']] or flattened[val['$notEmpty$']]) then
					_args[val['$notEmpty$']] = '&nbsp;'
			end
		end

		if not Logic.isEmpty(match) then
			if index ~= _RESET_MATCH and index ~= _THIRD_PLACE_MATCH then
				if not match.opponent1 then
					match.opponent1 = "{\"type\":\"team\",\"template\":\"TBD\",\"icon\":\"Rllogo_std.png\",\"name\":\"TBD\"}"
					mw.log('Missing Opponent entry')
					--error('Missing Opponent entry')
				end
				if not match.opponent2 then
					match.opponent2 = "{\"type\":\"team\",\"template\":\"TBD\",\"icon\":\"Rllogo_std.png\",\"name\":\"TBD\"}"
					mw.log('Missing Opponent entry')
					--error('Missing Opponent entry')
				end
			end
		else
			match[realKey] = _args[val] or flattened[val]
		end
	end
	return match
end

function Legacy._getMapping(templateid, oldTemplateid)
	if Lua.moduleExists('Module:MatchGroup/Legacy/' .. templateid) then
		mw.log('Module:MatchGroup/Legacy/' .. templateid .. 'exists')
		return (require('Module:MatchGroup/Legacy/' .. templateid)[oldTemplateid] or function() return nil end)()
			or getDefaultMapping(templateid, _type)
	else
		return getDefaultMapping(templateid, _type)
	end
end

return Legacy
