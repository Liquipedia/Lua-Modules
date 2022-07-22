---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Cell = require('Module:Infobox/Widget/Cell')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Page = require('Module:Page')
local Series = require('Module:Infobox/Series')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier')

local CustomSeries = {}

local CustomInjector = Class.new(Injector)

local GAMES = {
	cs = {name = 'Counter-Strike', link = 'Counter-Strike', category = 'CS Teams'},
	cscz = {name = 'Condition Zero', link = 'Counter-Strike: Condition Zero', category = 'CSCZ Teams'},
	css = {name = 'Source', link = 'Counter-Strike: Source', category = 'CSS Teams'},
	cso = {name = 'Online', link = 'Counter-Strike Online', category = 'CSO Teams'},
	csgo = {name = 'Global Offensive', link = 'Counter-Strike: Global Offensive', category = 'CSGO Teams'},
}

local _args

function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args

	series.createWidgetInjector = CustomSeries.createWidgetInjector

	_args.liquipediatier = Tier.number[_args.liquipediatier]

	return series:createInfobox(frame)
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'location' then
		table.insert(widgets, 1, Cell{
			name = 'Type',
			content = {String.isNotEmpty(_args.type) and mw.getContentLanguage():ucfirst(_args.type) or nil}
		})
		table.insert(widgets, Cell{
			name = 'Venue',
			content = {_args.venue}
		})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Fate',
			content = {_args.fate}
		},
		Cell{
			name = 'Games',
			content = Array.map(CustomSeries.getGames(), function (gameData)
				return Page.makeInternalLink({}, gameData.name, gameData.link)
			end)
		}
	}
end

function CustomSeries.getGames()
	return Array.extractValues(Table.map(GAMES, function (key, data)
		if _args[key] then
			return key, data
		end
		return key, nil
	end))
end

return CustomSeries
