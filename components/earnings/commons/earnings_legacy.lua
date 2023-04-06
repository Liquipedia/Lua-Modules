---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Legacy version for smash, brawhalla and fighters as they are not on standardized prize pools yet
-- they do not have team events (and no teamCard usage) hence only overwrite the player function

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local CustomEarnings = Table.deepCopy(Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true}))

-- customizable in /Custom
CustomEarnings.defaultNumberOfStoredPlayersPerMatch = 10

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @prefix - (optional) the prefix under which the players are stored in the placements
-- @playerPositionLimit - (optional) the number for how many params the query should look in LPDB
-- @perYear - (optional) query all earnings per year and return the values in a lua table
function CustomEarnings.calculateForPlayer(args)
	args = args or {}
	local player = args.player

	if String.isEmpty(player) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	else
		player = player:gsub('_', ' ')
	end

	-- since TeamCards on some wikis store players with underscores and some with spaces
	-- we need to check for both options
	local playerAsPageName = player:gsub(' ', '_')

	local prefix = args.prefix or 'p'

	local playerPositionLimit = tonumber(args.playerPositionLimit) or CustomEarnings.defaultNumberOfStoredPlayersPerMatch
	if playerPositionLimit <= 0 then
		error('"playerPositionLimit" has to be >= 1')
	end

	-- they set 1 lpdb_placement object per player, so no additional conditions on player data needed
	local playerConditions = {
		'[[participant::' .. player .. ']]',
		'[[participant::' .. playerAsPageName .. ']]',
		'[[participantlink::' .. player .. ']]',
		'[[participantlink::' .. playerAsPageName .. ']]',
	}
	playerConditions = '(' .. table.concat(playerConditions, ' OR ') .. ')'

	return CustomEarnings.calculate(playerConditions, args.year, args.mode, args.perYear, nil, true)
end

function CustomEarnings._determineValue(placement)
	local indivPrize = tonumber(placement.individualprizemoney) or 0
	if indivPrize > 0 then
		return indivPrize
	end

	-- they currently set 1 lpdb_placement object per player with individualprizemoney in prizemoney field
	-- in many cases individualprizemoney field is unset
	return tonumber(placement.prizemoney) or 0
end

return Class.export(CustomEarnings)
