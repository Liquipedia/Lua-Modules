---
-- @Liquipedia
-- wiki=smash
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _series

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	_series = Series(frame)

	_series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series.addToLpdb = CustomSeries.addToLpdb
	_series.createLiquipediaTierDisplay = function() return nil end

	return _series:createInfobox()
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
		return {
			Cell{
				name = 'Type',
				content = { mw.language.getContentLanguage():ucfirst(_series.args.type or '') }
		}}
	end

	return widgets
end

---@param lpdbData table
---@return table
function CustomSeries:addToLpdb(lpdbData)
	lpdbData.game = _series.args.game or 'none'
	lpdbData.launcheddate = _series.args.sdate
	lpdbData.defunctdate = _series.args.edate
	lpdbData.extradata = {
		leagueiconsmall = _series.args.leagueiconsmall
	}

	return lpdbData
end

return CustomSeries
