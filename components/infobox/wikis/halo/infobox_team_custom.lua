---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local String = require('Module:StringUtils')
local Region = require('Module:Region')

local CustomTeam = Class.new()

local _region

local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then
		return {
			Cell{name = 'Region', content = {CustomTeam:_createRegion(_team.args.region, _team.args.location)}}
		}
	end
	return widgets
end

function CustomTeam:_createRegion(region, location)
	region = Region.run({region = region, country = Team:getStandardLocationValue(location)})
	if type(region) == 'table' then
		_region = region.region
		return region.display
	end
end

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = args.image
	end

	lpdbData.region = _region

	return lpdbData
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
