---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')
local Opponent = require('Module:Opponent')
local Abbreviation = require('Module:Abbreviation')


local CustomOpponent = Table.deepCopy(Opponent)

function CustomOpponent.resolve(opponent, date)
	Opponent.resolve(opponent, date, {syncPlayer = true})
	if Opponent.typeIsParty(opponent.type) then
		local PlayerExt = require('Module:Player/Ext/Custom')
		for _, player in ipairs(opponent.players) do
			if Opponent.playerIsTbd(player) then
				player.displayName = Abbreviation.make('TBD', 'To be determined (or to be decided)')
			else
				if not player.team then
					player.team = PlayerExt.syncTeam(player.pageName, nil)
				end
			end
		end
	end
	return opponent
end

return CustomOpponent