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
local TeamTemplate = require('Module:TeamTemplate')


local CustomOpponent = Table.deepCopy(Opponent)

function CustomOpponent.resolve(opponent, date)
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or 'tbd'
	elseif Opponent.typeIsParty(opponent.type) then
		local PlayerExt = require('Module:Player/Ext')
		for _, player in ipairs(opponent.players) do
			if Opponent.playerIsTbd(player) then
				player.displayName = Abbreviation.make('TBD', 'To be determined (or to be decided)')
			else
				if player.flag then
					PlayerExt.populatePageName(player)
				else
					PlayerExt.syncPlayer(player)
				end
				if player.team then
					player.team = TeamTemplate.resolve(player.team, date)
				else
					player.team = PlayerExt.syncTeam(player.pageName, nil)
				end
			end
		end
	end
	return opponent
end

return CustomOpponent
