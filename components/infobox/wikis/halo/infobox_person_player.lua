---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Person/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Earnings = require('Module:Earnings')
local GameAppearances = require('Module:GetGameAppearances')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _pagename = mw.title.getCurrentTitle().prefixedText
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

		if not (String.isEmpty(manualHistory) and String.isEmpty(automatedHistory)) then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Game Appearances',
			content = GameAppearances.player({ player = _pagename })
		},
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:calculateEarnings()
	return Earnings.calc_player({ args = { player = _pagename }})
end

return CustomPlayer
