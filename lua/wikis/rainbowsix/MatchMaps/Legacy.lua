---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
	This module is used in the process to convert Legacy match1 MatchLists into match2.
	It converts a few fields to new format, calls match2 for all maps and saves the output in a variable.
	It is invoked by Template:MatchMaps.
]]

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_GAME_NUM = 9

local MatchMaps = {}

function MatchMaps.main(frame)
	return MatchMaps._main(Arguments.getArgs(frame))
end

function MatchMaps._main(args)
	local generate = Logic.readBool(Table.extract(args, 'generate'))

	if not generate and (not Logic.readBool(matchlistVars:get('store')) or not matchlistVars:get('bracketid')) then
		return
	end

	local storage_args = {}
	local details = Json.parseIfString(args.details) or {}

	storage_args.title = args.date

	--opponents
	for i = 1, 2 do
		if args['team' .. i] and args['team' .. i]:lower() == 'bye' then
			storage_args['opponent' .. i] = {
				['type'] = 'literal',
				name = 'BYE',
			}
		elseif args['team' .. i] == '' then
			storage_args['opponent' .. i] = {
				['type'] = 'literal',
				name = '',
			}
		else
			storage_args['opponent' .. i] = {
				['type'] = 'team',
				template = args['team' .. i],
				score = args['games' .. i],
			}
		end
	end

	if tonumber(args.walkover) then
		storage_args['opponent1'].score = tonumber(args.walkover) == 1 and 'W' or 'FF'
		storage_args['opponent2'].score = tonumber(args.walkover) == 2 and 'W' or 'FF'
	end

	--maps
	for i = 1, MAX_GAME_NUM do
		local prefix = 'map' .. i
		if Logic.isNotEmpty(details[prefix]) or Logic.isNotEmpty(details[prefix ..'finished']) then
			storage_args[prefix] = {
				map = Table.extract(details, prefix) or 'Unknown',
				finished = Table.extract(details, prefix..'finished'),
				score1 = Table.extract(details, prefix..'score1'),
				score2 = Table.extract(details, prefix..'score2'),
				t1ban1 = Table.extract(details, prefix..'t1ban1'),
				t1ban2 = Table.extract(details, prefix..'t1ban2'),
				t2ban1 = Table.extract(details, prefix..'t2ban1'),
				t2ban2 = Table.extract(details, prefix..'t2ban2'),
				t1firstside = Table.extract(details, prefix..'t1firstside'),
				t1firstsideot = Table.extract(details, prefix..'o1t1firstside'),
				t1atk = Table.extract(details, prefix..'t1atk'),
				t1def = Table.extract(details, prefix..'t1def'),
				t2atk = Table.extract(details, prefix..'t2atk'),
				t2def = Table.extract(details, prefix..'t2def'),
				t1otatk = Table.extract(details, prefix..'o1t1atk'),
				t1otdef = Table.extract(details, prefix..'o1t1def'),
				t2otatk = Table.extract(details, prefix..'o1t2atk'),
				t2otdef = Table.extract(details, prefix..'o1t2def'),
				vod = Table.extract(details, 'vod'..i),
				winner = Table.extract(details, prefix .. 'win'),
			}
		else
			break
		end
	end

	storage_args.mapveto = Json.parseIfString(Table.extract(details, 'mapveto'))

	storage_args.date = Table.extract(details, 'date')
	-- It's legacy, let's assume it's finished
	storage_args.finished = true
	details.finished = nil

	for key, value in pairs(details) do
		storage_args[key] = value
	end

	local opp1score, opp2score = storage_args.opponent1.score, storage_args.opponent2.score
	-- Legacy maps are Bo10 or Bo12, while >Bo5 in legacy matches are non existent
	-- Let's assume that if the sum of the scores is less than 6, it's a match, otherwise it's a map
	if (tonumber(opp1score) or 0) + (tonumber(opp2score) or 0) < 6 then
		if generate then
			return Json.stringify(storage_args)
		end
		Template.stashReturnValue(storage_args, 'LegacyMatchlist')
		return
	end

	storage_args.opponent1.score = nil
	storage_args.opponent2.score = nil
	storage_args.map1 = storage_args.map1 or {
		map = 'Unknown',
		finished = true,
		score1 = opp1score,
		score2 = opp2score,
	}

	if generate then
		return Json.stringify(storage_args)
	end

	Template.stashReturnValue(storage_args, 'LegacyMatchlist')
end

return MatchMaps
