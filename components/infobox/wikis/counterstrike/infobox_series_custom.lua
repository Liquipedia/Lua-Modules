---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier/Custom')

local Game = Lua.import('Module:Game', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomSeries = {}

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args

	series.createWidgetInjector = CustomSeries.createWidgetInjector

	_args.liquipediatier = Tier.toNumber(_args.liquipediatier)

	return series:createInfobox()
end

---@return WidgetInjector
function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'type' then
		return {Cell{
				name = 'Type',
				content = {String.isNotEmpty(_args.type) and mw.getContentLanguage():ucfirst(_args.type) or nil}
			}}
	end
	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Fate',
			content = {_args.fate}
		},
		Cell{
			name = 'Games',
			content = Array.map(Game.listGames({ordered = true}), function (gameIdentifier)
					return _args[gameIdentifier] and Game.text{game = gameIdentifier} or nil
				end)
		}
	}
end

return CustomSeries
