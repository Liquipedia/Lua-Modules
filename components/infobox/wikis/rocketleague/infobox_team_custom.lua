---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local TeamRanking = require('Module:TeamRanking')
local Variables = require('Module:Variables')

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
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	Variables.varDefine('rating', _team.args.rating)
	table.insert(widgets, Cell{
		name = '[[Portal:Rating|LPRating]]',
		content = {_team.args.rating or 'Not enough data'}
	})
	local rankingSuccess, rlcsRanking = pcall(TeamRanking.run, {
		ranking = Variables.varDefault('ranking_name', ''),
		team = _team.pagename
	})
	if not rankingSuccess then
		rlcsRanking = CustomInjector:wrapErrorMessage(rlcsRanking)
	end
	table.insert(widgets, Cell{
		name = '[[RankingTableRLCS|RLCS Points]]',
		content = {rlcsRanking}
	})
	return widgets
end

function CustomInjector:wrapErrorMessage(text)
	local strongStart = '<strong class="error">Error: '
	local strongEnd = '</strong>'
	local errorText = text:gsub('Module:TeamRanking:%d+: ', '')
	local outText = strongStart .. mw.text.nowiki(errorText) .. strongEnd
	return outText
end

function CustomInjector:parse(_, widgets)
	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.rating = Variables.varDefault('rating')
	lpdbData.extradata.tier = string.lower(args.tier or '')

	return lpdbData
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
