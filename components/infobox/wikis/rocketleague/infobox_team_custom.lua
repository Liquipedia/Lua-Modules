---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)
local Language = mw.language.new('en')

local _team

function CustomTeam.run(frame)
    local team = Team(frame)
    team.calculateEarnings = CustomTeam.calculateEarnings
	_team = team
    return team:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
    Variables.varDefine('rating', _team.args.rating)
	table.insert(widgets, Cell({
		name = '[[Portal:Rating|LPRating]]',
		content = {_team.args.rating or 'Not enough data'}
	}))
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		local earnings = Earnings.calculateForTeam({team = _team.pagename or _team.name})
		Variables.varDefine('earnings', earnings)
		if earnings == 0 then
			earnings = nil
		else
			earnings = '$' .. Language:formatNum(earnings)
		end
		return {
			Cell{
				name = 'Earnings',
				content = {
					earnings
				}
			}
		}
	end
	return widgets
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
