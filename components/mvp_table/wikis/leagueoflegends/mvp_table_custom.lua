---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MvpTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MvpTable = Lua.import('Module:MvpTable', {requireDevIfEnabled = true})

function MvpTable.createPlayer(opponents, mvp)
	local player = {
		points = 0,
		mvp = 0,
		displayName = mvp,
		name = mvp,
	}

	for _, opponent in pairs(opponents) do
		local players = opponent.match2players or {}
		local mvpPageName = MvpTable.pageFromMvp(mvp)
		for _, matchPlayer in pairs(players) do
			if
				mvpPageName == matchPlayer.name or
				mvp == matchPlayer.displayname
			then
				player.displayName = matchPlayer.displayname
				player.flag = matchPlayer.flag
				player.name = matchPlayer.name
				player.team = opponent.template

				return player
			end
		end
	end

	return player
end

return Class.export(MvpTable)
