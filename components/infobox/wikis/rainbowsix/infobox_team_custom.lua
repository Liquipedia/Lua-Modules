---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings of')
local Variables = require('Module:Variables')
local Flags = require('Module:Flags')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local String = require('Module:String')
local Template = require('Module:Template')

local CustomTeam = Class.new()

local _CURRENT_YEAR = os.date('%Y')
local _START_YEAR = 2015

local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		local earnings = Earnings.team({_team.args.id or _team.pagename])
		Variables.varDefine('earnings', earnings:gsub(',', ''))
		if earnings == 0 then
			earnings = nil
		else
			earnings = '$' .. earnings
		end
		return {
			Cell{
				name = 'Earnings',
				content = {
					earnings
				}
			}
		}
	elseif id == 'region' then
		return {
			Cell{name = 'Region', content = {_team:_createRegion(_team.args.region, _team.args.location)}}
		}
	end
	return widgets
end

function CustomTeam:createBottomContent()
	return Template.safeExpand(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.pagename or _team.name},
		''
	)
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.earnings = Variables.varDefault('earnings', 0)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = 'File:' .. args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = 'File:' .. args.image
	end

	lpdbData.extradata = {}
	for year = _START_YEAR, _CURRENT_YEAR do
		local id = args.id or _team.pagename
		lpdbData.extradata['earningsin' .. year] = Earnings.team({id, year = year}):gsub(',', '')
	end

	lpdbData.location = CustomTeam:_getStandardLocationValue(_team.args.location)
	lpdbData.location2 = CustomTeam:_getStandardLocationValue(_team.args.location2)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

function CustomTeam:_getStandardLocationValue(location)
	return Flags.CountryName(location) or location
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', _team.args.captain)
end

return CustomTeam
