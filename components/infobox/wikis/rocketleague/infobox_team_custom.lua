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
local Template = require('Module:Template')
local TeamRanking = require('Module:TeamRanking')

local CustomTeam = Class.new()

local _CURRENT_YEAR = os.date('%Y')
local _START_YEAR = 2015

local CustomInjector = Class.new(Injector)
local Language = mw.language.new('en')

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
		team = _team.args.name
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

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.earnings = Variables.varDefault('earnings', 0)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = 'File:' .. args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = 'File:' .. args.image
	end

	lpdbData.extradata = { rating = Variables.varDefault('rating') }
	for year = _START_YEAR, _CURRENT_YEAR do
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
