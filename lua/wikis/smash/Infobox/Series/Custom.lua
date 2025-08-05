---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local CustomInjector = Class.new(Injector)

---@class SmashSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	return series:createInfobox()
end

---@param args table
---@return string
function CustomSeries:createLiquipediaTierDisplay(args)
	return ''
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'type' then
		return {
			Cell{
				name = 'Type',
				content = {mw.language.getContentLanguage():ucfirst(self.caller.args.type or '')}
		}}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomSeries:addToLpdb(lpdbData, args)
	lpdbData.game = args.game or 'none'
	lpdbData.launcheddate = args.sdate
	lpdbData.defunctdate = args.edate
	lpdbData.extradata = {
		leagueiconsmall = args.leagueiconsmall
	}

	return lpdbData
end

return CustomSeries
