---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:MatchGroup/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Legacy = {}

local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local getDefaultMapping = require('Module:MatchGroup/Legacy/Default').get
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')

local _IS_USERSPACE = false
local _NAMESPACE_USER = 2
local _type
local _args

function Legacy.get(frame)
	_args = getArgs(frame)
	mw.addWarning('You are editing a page that uses a Legacy Bracket. '
		.. 'Please use the [[Liquipedia:Brackets|new Bracket System]] on new pages.')
	local nameSpaceNumber = mw.title.getCurrentTitle().namespace

	local storage = _args.store
	if storage == '' or storage == nil then
		storage = Variables.varDefault('disable_LPDB_storage') == 'true' and 'false' or nil
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
	newArgs[1] = templateid

	newArgs.store = storage
	newArgs.noDuplicateCheck = _args.noDuplicateCheck
	newArgs.isLegacy = true

	return MatchGroup.TemplateBracket(newArgs)
end

function Legacy.getTemplate(frame)
	_args = getArgs(frame)

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

	local mapping = Legacy._getMapping(templateid)

	local out = json.stringify(mapping, {pretty = true})
		:gsub('"([^\n:"]-)":', '%1 = ')
		:gsub('type =', '["type"] =')
		:gsub(' = %[(.-)%]', ' = { %1 }')
	out = '-- Custom mapping for \'' .. templateid .. '\' from \'' .. oldTemplateid .. '\'\n'
		.. 'local p = {}\n\n'
		.. 'p[\'' .. oldTemplateid .. '\'] = function() '
		.. 'return ' .. out .. '\n'
		.. 'end\n\n'
		.. 'return p'

	return '[[Module:MatchGroup/Legacy/' .. templateid ..
		'|Link to mapping]]' .. '<pre class=\'selectall\'>' .. out .. '</pre>'
end

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
				nested = Legacy._convertSingle(realKey, val, nested, mapping, flattened)
			end

			if not Logic.isEmpty(nested) then
				nested.opponent1 = nested.opponent1 or {}
				nested.opponent2 = nested.opponent2 or {}
				local score1 = json.parseIfString(nested.opponent1).score or ''
				local score2 = json.parseIfString(nested.opponent2).score or ''

				--handle advantages that were bassed the old way
				nested.opponent1 = Legacy.checkAdvantage(score1, nested.opponent1)
				nested.opponent2 = Legacy.checkAdvantage(score2, nested.opponent2)

				if source == 'RxMBR' then
					--for 3rd place match only add the data if the according scores are set
					if score1 ~= '' or score2 ~= '' then
						newArgs[source] = nested
					end
				else
					newArgs[source] = nested
				end
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
	local noSkip = not String.startsWith(realKey, '$$')
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
			--the following could be used to allow empty matches in the conversion
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
			match[realKey] = nestedArgs
		end
	elseif noSkip then
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

function Legacy._getMapping(templateid, oldTemplateid)
	if Lua.moduleExists('Module:MatchGroup/Legacy/' .. templateid) then
		mw.log('Module:MatchGroup/Legacy/' .. templateid .. 'exists')
		return (require('Module:MatchGroup/Legacy/' .. templateid)[oldTemplateid] or function() return nil end)()
			or getDefaultMapping(templateid, _type)
	else
		return getDefaultMapping(templateid, _type)
	end
end

function Legacy.checkAdvantage(score, opponent)
	local scoreAdvantage, scoreSum = string.match(score,
					'<abbr title="Winner\'s bracket advantage of (%d) game">(%d)</abbr>')
	if scoreAdvantage then
		opponent = opponent or {}
		opponent.score = scoreSum
		opponent.advantage = scoreAdvantage
	end
	return opponent
end

return Legacy
