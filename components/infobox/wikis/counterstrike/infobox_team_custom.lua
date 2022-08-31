---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Cell = require('Module:Infobox/Widget/Cell')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Infobox/Team')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local GAMES = {
	cs = {name = 'Counter-Strike', link = 'Counter-Strike', category = 'CS Teams'},
	cscz = {name = 'Condition Zero', link = 'Counter-Strike: Condition Zero', category = 'CSCZ Teams'},
	css = {name = 'Source', link = 'Counter-Strike: Source', category = 'CSS Teams'},
	cso = {name = 'Online', link = 'Counter-Strike Online', category = 'CSO Teams'},
	csgo = {name = 'Global Offensive', link = 'Counter-Strike: Global Offensive', category = 'CSGO Teams'},
}

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories

	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'staff' then
		return {
			Cell{name = 'Founders',	content = {_team.args.founders}},
			Cell{name = 'CEO', content = {_team.args.ceo}},
			Cell{name = 'Gaming Director', content = {_team.args['gaming director']}},
			widgets[4], -- Manager
			widgets[5], -- Captain
			Cell{name = 'In-Game Leader', content = {_team.args.igl}},
			widgets[1], -- Coaches
			Cell{name = 'Analysts', content = {_team.args.analysts}},
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {Cell{
		name = 'Games',
		content = Array.map(CustomTeam.getGames(), function (gameData)
			return Page.makeInternalLink({}, gameData.name, gameData.link)
		end)
	}}
end

function CustomTeam.getGames()
	return Array.extractValues(Table.map(GAMES, function (key, data)
		if _team.args[key] then
			return key, data
		end
		return key, nil
	end))
end

function CustomTeam:createBottomContent()
	if not _team.args.disbanded and mw.ext.TeamTemplate.teamexists(_team.pagename) then
		local teamPage = mw.ext.TeamTemplate.teampage(_team.pagename)

		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing matches of',
			{team = _team.lpdbname or teamPage}
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = _team.lpdbname or teamPage}
		)
	end
end

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = args.image
	end

	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

function CustomTeam:getWikiCategories(args)
	local categories = {}

	Array.extendWith(categories, Array.map(CustomTeam.getGames(), function (gameData)
		return gameData.category
	end))

	if args.teamcardimage then
		table.insert(categories, 'Teams using TeamCardImage')
	end

	if not args.region then
		table.insert(categories, 'Teams without a region')
	end

	if args.nationalteam then
		table.insert(categories, 'National Teams')
	end

	return categories
end

return CustomTeam
