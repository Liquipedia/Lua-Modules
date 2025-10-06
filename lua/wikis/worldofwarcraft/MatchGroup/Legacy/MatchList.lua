---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/MatchList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local Opponent = Lua.import('Module:Opponent/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')

local globalVars = PageVariableNamespace()

local NUMBER_OF_OPPONENTS = 2

local LegacyMatchList = {}

function LegacyMatchList.generate(frame)
	return LegacyMatchList.run(frame, true)
end

-- invoked by Template:LegacyMatchList
function LegacyMatchList.run(frame, generate)
	local args = Arguments.getArgs(frame)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	local matches = Array.mapIndexes(function(matchIndex)
		return LegacyMatchList.processMatch(args['match' .. matchIndex])
	end)

	local matchListArgs = Table.deepCopy(matches)
	matchListArgs.id = args.id
	matchListArgs.isLegacy = true
	matchListArgs.title = args.title or args[1] or 'Match List'
	matchListArgs.width = args.width

	if Logic.nilOr(Logic.readBoolOrNil(args.hide), true) then
		matchListArgs.collapsed = true
		matchListArgs.attached = true
	else
		matchListArgs.collapsed = false
	end
	if store then
		matchListArgs.store = true
	else
		matchListArgs.noDuplicateCheck = true
		matchListArgs.store = false
	end

	if generate then
		return MatchGroupLegacy.generateWikiCodeForMatchList(args)
	end

	return MatchGroup.MatchList(matchListArgs)
end

function LegacyMatchList.processMatch(input)
	local args = Json.parseStringified(input)
	if Logic.isDeepEmpty(args) then return end

	local details = Table.extract(args, 'details') or {}
	-- remap matchX --> mapX
	details = Table.map(details, function(key, value)
		local mapIndex = key:match('^match(%d+)')
		if mapIndex then
			return 'map' .. mapIndex, value
		end
		return key, value
	end)

	LegacyMatchList._handleOpponents(args)

	return Match.makeEncodedJson(Table.merge(args, details))
end

---@param args table
function LegacyMatchList._handleOpponents(args)
	for opponentIndex = 1, NUMBER_OF_OPPONENTS do
		if args['team' .. opponentIndex] and args['team' .. opponentIndex]:lower() == 'bye' then
			args['opponent' .. opponentIndex] = {
				['type'] = Opponent.literal,
				name = 'BYE',
			}
		else
			args['opponent' .. opponentIndex] = {
				['type'] = Opponent.team,
				template = args['team' .. opponentIndex],
				score = args['games' .. opponentIndex],
			}
			if args['team' .. opponentIndex] == '' then
				args['opponent' .. opponentIndex]['type'] = 'literal'
			end
		end

		args['team' .. opponentIndex] = nil
		args['games' .. opponentIndex] = nil
	end
end

return LegacyMatchList
