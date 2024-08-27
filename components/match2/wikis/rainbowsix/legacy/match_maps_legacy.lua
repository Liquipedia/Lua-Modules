---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
	This module is used in the process to convert Legacy match1 MatchLists into match2.
	It converts a few fields to new format, calls match2 for all maps and saves the output in a variable.
	It is invoked by Template:MatchMaps.
]]

local Arguments = require('Module:Arguments')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Template = require('Module:Template')
local CustomInput = require('Module:MatchGroup/Input/Custom')

local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_GAME_NUM = 9

local MatchMaps = {}

function MatchMaps.main(frame)
	local args = Arguments.getArgs(frame)
	return MatchMaps._main(args, frame)
end

function MatchMaps._main(args, frame)
	-- Data storage (LPDB)
	if Logic.readBool(matchlistVars:get('store')) then

		--preparing storage as match2 in lpdb id bracketid is set
		if matchlistVars:get('bracketid') then
			--convert params for match2 storage
			local storage_args = {}
			local details = Json.parseIfString(args.details) or {}

			storage_args['title'] = args.date

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
						score = args['games' .. i] or args['score' .. i],
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
					storage_args[prefix] = CustomInput.processMap{
						map = details[prefix] or 'Unknown',
						finished = details[prefix..'finished'],
						score1 = details[prefix..'score1'],
						score2 = details[prefix..'score2'],
						t1ban1 = details[prefix..'t1ban1'],
						t1ban2 = details[prefix..'t1ban2'],
						t2ban1 = details[prefix..'t2ban1'],
						t2ban2 = details[prefix..'t2ban2'],
						t1firstside = details[prefix..'t1firstside'],
						t1firstsideot = details[prefix..'o1t1firstside'],
						t1atk = details[prefix..'t1atk'],
						t1def = details[prefix..'t1def'],
						t2atk = details[prefix..'t2atk'],
						t2def = details[prefix..'t2def'],
						t1otatk = details[prefix..'o1t1atk'],
						t1otdef = details[prefix..'o1t1def'],
						t2otatk = details[prefix..'o1t2atk'],
						t2otdef = details[prefix..'o1t2def'],
						vod = details['vod'..i],
						winner = details[prefix .. 'win']
					}
					details[prefix] = nil
					details[prefix ..'win'] = nil
					details[prefix ..'score'] = nil
					details[prefix ..'t1ban1'] = nil
					details[prefix ..'t1ban2'] = nil
					details[prefix ..'t2ban1'] = nil
					details[prefix ..'t2ban2'] = nil
					details[prefix ..'t1firstside'] = nil
					details[prefix ..'o1t1firstside'] = nil
					details[prefix ..'t1atk'] = nil
					details[prefix ..'t1def'] = nil
					details[prefix ..'t2atk'] = nil
					details[prefix ..'t2def'] = nil
					details[prefix ..'o1t1atk'] = nil
					details[prefix ..'o1t1def'] = nil
					details[prefix ..'o1t2atk'] = nil
					details[prefix ..'o1t2def'] = nil
					details['vod'..i] = nil
				else
					break
				end
			end

			storage_args['mapveto'] = Json.parseIfString(details.mapveto)
			details.mapbans = nil

			-- Add date
			storage_args.date = details.date
			-- If details is missing, let's assume it's finished
			if #details == 0 then
				storage_args.finished = true
			else
				storage_args.finished = details.finished
			end

			details.date = nil
			details.finished = nil

			for key, value in pairs(details) do
				storage_args[key] = value
			end

			-- Store the processed args for later usage
			Template.stashReturnValue(storage_args, 'LegacyMatchlist')
		end
	end
end


return MatchMaps
