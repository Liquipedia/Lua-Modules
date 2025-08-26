local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local ManualGroupWrapper = {}

local START_ARGS_TO_KEEP = {
	'width',
	'date',
	'show_p',
	'win_p',
	'tie_p',
	-- we will drop the below params with standardized, but can still map it here...
	'location',
	'preview',
	'lrthread',
	'vod',
	'vod1',
	'vod2',
	'vod3',
	'vod4',
	'vod5',
	'vod6',
	'vod7',
	'vod8',
	'vod9',
	'interview',
	'interview1',
	'interview2',
	'interview3',
	'interview4',
	'recap',
	'review',
}
local TYPE_FROM_NUMBER = Table.map(Opponent.partySizes, function(key, code) return code, key end)

---@param frame Frame
---@return string
function ManualGroupWrapper.run(frame)
	local args = Arguments.getArgs(frame)

	local title
	local indexOffset = 0
	local firstArgParsed = Json.parseIfTable(args[1])
	if not firstArgParsed then
		indexOffset = 1
		title = args[1]
	end

	local slotInputs = Array.mapIndexes(function(index)
		local opponentIndex = index + indexOffset
		return args[opponentIndex]
	end)

	local oppIssues = {}
	local slots = Array.map(slotInputs, function(input, index)
		local slotArgs = Json.parseIfTable(input)
		local slot, hasIssue = ManualGroupWrapper._readSlot(slotArgs, index)
		if hasIssue then
			oppIssues[index] = slotArgs[1]
		end
		return slot
	end)

	local output = Array.extend(
		'{{GroupTableLeague|finished=true|import=false<!--converted from manual group table-->',
		title and ('|title=' .. title) or nil,
		args.store and ('|storeStanding=' .. args.store) or nil,
		Array.map(START_ARGS_TO_KEEP, function(key)
			local value = args[key]
			if not value then return end
			return '|' .. key .. '=' .. value
		end),
		slots,
		'}}',
		Logic.isNotEmpty(oppIssues) and {
			'[[Category:Pages with issues in converted manual group tables]]<!--',
			Json.stringify(oppIssues),
			'-->'
		} or nil
	)

	return table.concat(output, '\n')
end

---@param args table?
---@param index integer
---@return string?
---@return boolean?
function ManualGroupWrapper._readSlot(args, index)
	if Logic.isEmpty(args) then return end
	---@cast args -nil

	local opponent = ManualGroupWrapper._processOpponent(args[1] or '')

	local output = Array.append({},
		args.bg and ('|bg' .. index .. '=' .. args.bg) or nil,
		args.pbg and ('|pbg' .. index .. '=' .. args.pbg) or nil,
		'|temp_tie' .. index .. '=' .. (50 - (tonumber(args.place) or 0)),
		args.win_g and ('|temp_win_g' .. index .. '=' .. args.win_g) or nil,
		args.lose_g and ('|temp_lose_g' .. index .. '=' .. args.lose_g) or nil,
		args.lose_m and ('|temp_lose_m' .. index .. '=' .. args.lose_m) or nil,
		args.tie_m and ('|temp_tie_m' .. index .. '=' .. args.tie_m) or nil,
		args.win_m and ('|temp_win_m' .. index .. '=' .. args.win_m) or nil,
		args.temp_p and ('|temp_p' .. index .. '=' .. args.temp_p) or nil,
		'|' .. (opponent or 'missing opponent')
	)

	return table.concat(output), Logic.isEmpty(opponent)
end

---@param opponentInput string
---@return string?
function ManualGroupWrapper._processOpponent(opponentInput)
	opponentInput = mw.getCurrentFrame():preprocess(opponentInput)

	-- team opponent
	local team = opponentInput:match('%{%{[tT]eam%w*%s*%|(%w*)[%|%}]')
	if team then
		return '{{TeamOpponent|template=' ..  team:lower() .. '}}'
	end

	-- assume it is player inputs if it isn't a team
	local opponentArgs = {}
	local playerIndex = 0
	for playerInputStr in opponentInput:gmatch('%{%{[pP]layer([^%}]*)%}%}') do
		playerIndex = playerIndex + 1
		local prefix = 'p' .. playerIndex

		opponentArgs[prefix] = playerInputStr:match('%|%s*([^=%|%}]*)[%|%}]')
		opponentArgs[prefix .. 'link'] = playerInputStr:match('%|%s*link%s*=%s*([^%|%}]*)[%|%}]')
		opponentArgs[prefix .. 'flag'] = playerInputStr:match('%|%s*flag%s*=%s*([^%|%}]*)[%|%}]')
		opponentArgs[prefix .. 'faction'] = playerInputStr:match('%|%s*race%s*=%s*([^%|%}]*)[%|%}]')
	end

	local opponentType = TYPE_FROM_NUMBER[playerIndex]

	if not opponentType or Logic.isEmpty(opponentArgs) then
		return
	end

	local opponentArgsArray = {}
	for key, value in pairs(opponentArgs) do
		table.insert(opponentArgsArray, '|' .. key .. '=' .. value)
	end

	return '{{' .. opponentType .. 'Opponent' .. table.concat(opponentArgsArray) .. '}}'
end

return ManualGroupWrapper
