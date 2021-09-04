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
local String = require('Module:String')

local CustomTeam = Class.new()

local _EARNINGS
local _CURRENT_YEAR = os.date('%Y')

local CustomInjector = Class.new(Injector)
local Language = mw.language.new('en')

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	Variables.varDefine('rating', _team.args.rating)
	table.insert(widgets, Cell{
		name = '[[Portal:Rating|LPRating]]',
		content = {_team.args.rating or 'Not enough data'}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		Variables.varDefine('earnings', _EARNINGS)
		if _EARNINGS == 0 then
			_EARNINGS = nil
		else
			_EARNINGS = '$' .. Language:formatNum(_EARNINGS)
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

function CustomTeam:addToLpdb(lpdbData, args)
	_EARNINGS = Earnings.calculateForTeam({team = _team.pagename or _team.name})
	lpdbData.earnings = _EARNINGS
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = 'File:' .. args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = 'File:' .. args.image
	end

	lpdbData.extradata = { rating = Variables.varDefault('rating') }
	for year = 2015, _CURRENT_YEAR do
		local id = args.id or _team.pagename
		local earningsInYear = Template.safeExpand(mw.getCurrentFrame(), 'Total earnings of', {year = year, id})
		lpdbData.extradata['earningsin' .. year] = (earningsInYear or ''):gsub(',', ''):gsub('$', '')
	end

	return lpdbData
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
