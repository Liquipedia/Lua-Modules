---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local TeamRanking = require('Module:TeamRanking')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_team.args.rating, _team.args.ratingRank = CustomTeam.fetchRating(_team.pagename)

	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = '[[Portal:Rating|LPRating]]',
		content = {
			_team.args.rating and _team.args.ratingRank and
				math.floor(_team.args.rating + 0.5) .. ' (Rank #'.. _team.args.ratingRank ..')'
			or 'Not enough data'}
	})
	table.insert(widgets, Cell{
		name = '[[RankingTableRLCS|RLCS Points]]',
		content = {TeamRanking.run{
			ranking = _team.args.ranking_name,
			team = _team.pagename
		}}
	})
	return widgets
end

function CustomInjector:parse(_, widgets)
	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.rating = _team.args.rating
	lpdbData.extradata.tier = string.lower(args.tier or '')

	return lpdbData
end

function CustomTeam.fetchRating(findTeam)
	local latestSnap = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata',
			limit = 1,
			order = 'date DESC',
			conditions = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]] AND [[name::rating]]'
		}
	)[1]
	if not latestSnap then
		return
	end

	if not latestSnap.extradata.table[findTeam] then
		return
	end

	for rank, team in ipairs(latestSnap.extradata.ranks) do
		if team == findTeam then
			return latestSnap.extradata.table[findTeam].rating, rank
		end
	end
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
