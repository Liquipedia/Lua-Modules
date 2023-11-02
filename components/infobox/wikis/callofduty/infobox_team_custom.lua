---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')
local String = require('Module:StringUtils')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	return team:createInfobox()
end

function CustomTeam:createBottomContent()
	return MatchTicker.participant{team = self.pagename}
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.competesin = (args.league or ''):upper()

	return lpdbData
end

function CustomTeam:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.league) then
		table.insert(categories, string.upper(args.league) .. ' Teams')
	end

	return categories
end

return CustomTeam
