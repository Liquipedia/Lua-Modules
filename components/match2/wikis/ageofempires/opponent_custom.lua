---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Abbreviation = require('Module:Abbreviation')
local PlayerExt = require('Module:Player/Ext/Custom')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local CustomOpponent = Table.deepCopy(Opponent)

function CustomOpponent.resolve(opponent, date, options)
	Opponent.resolve(opponent, date, options)
	if Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if Opponent.playerIsTbd(player) then
				player.displayName = Abbreviation.make('TBD', 'To be determined (or to be decided)')
			elseif not player.team and options.syncPlayer then
				player.team = PlayerExt.syncTeam(player.pageName, nil)
			end
		end
	end
	return opponent
end

return CustomOpponent
