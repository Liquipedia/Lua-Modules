---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local RoleOf = require('Module:RoleOf')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplates = require('Module:Team')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local Widgets = require('Module:Infobox/Widget/All')
local Title = Widgets.Title
local Center = Widgets.Center
local Builder = Widgets.Builder

local _team

function CustomTeam.run(frame)
	local team = Team(frame)

	-- Override links to allow one param to set multiple links
	team.args.datdota = team.args.teamid
	team.args.dotabuff = team.args.teamid
	team.args.stratz = team.args.teamid

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.director = RoleOf.get{role = 'Director'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb

	_team = team

	return team:createInfobox()
end

function CustomTeam:createBottomContent()
--[[
	if not _team.args.disbanded then
		TODO:
		Leaving this out for now, will be a follow-up PR,
		as both the templates needs to be removed from team pages plus the templates also requires some div changes

		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing matches of',
			{team = _team.name or _team.pagename}
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = _team.name or _team.pagename}
		)
	end
--]]
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'achievements' then
		return {
			Builder{
				builder = function()
					if String.isNotEmpty(_team.args.achievements) then
						return {
							Title{name = 'Achievements'},
							Center{content = {_team.args.achievements}}
						}
					else
						local achievements = mw.ext.LiquipediaDB.lpdb('placement', {
							conditions = '[[placement::1]] AND [[liquipediatier::1]] AND ' ..
								'[[liquipediatiertype::]] AND [[mode::team]] AND ' ..
								'([[opponentname::' .. table.concat(
									TeamTemplates.queryHistoricalNames(_team.teamTemplate.historicaltemplate),
									']] OR [[opponentname::'
								) .. ']])',
							query = 'parent, tournament, date, icon, iconDark, series',
							order = 'date asc',
							limit = 500,
						})
						if Table.isNotEmpty(achievements) then
							return {
								Title{name = 'Achievements'},
								Center{content = Array.flatMap(achievements, function(placement, index)
										placement.link = placement.parent
										placement.name = placement.tournament
										placement.iconDark = placement.icondark
										return {LeagueIcon.display(placement), (index ~= #achievements) and '&nbsp;' or nil}
									end)}
							}
						end
					end
				end
			}
		}
	end
	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	lpdbData.extradata.teamid = args.teamid
	lpdbData.coach = Variables.varDefault('coachid') or args.coach or args.coaches
	lpdbData.manager = Variables.varDefault('managerid') or args.manager

	return lpdbData
end

return CustomTeam
