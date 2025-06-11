---
-- @Liquipedia
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local Injector = Lua.import('Module:Widget/Injector')
local Show = Lua.import('Module:Infobox/Show')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class Starcraft2ShowInfobox: ShowInfobox
local CustomShow = Class.new(Show)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomShow.run(frame)
	local show = CustomShow(frame)
	show:setWidgetInjector(CustomInjector(show))

	if Namespace.isMain() and show.args.edate == nil then
		show:categories('Active Shows')
	end

	return show:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'No. of episodes', content = {args['num_episodes']}},
			Cell{name = 'Original Release', content = {self.caller:_getReleasePeriod(args.sdate, args.edate)}}
		)
	end

	return widgets
end

---@param sdate string?
---@param edate string?
---@return string?
function CustomShow:_getReleasePeriod(sdate, edate)
	if not sdate then return nil end
	return sdate .. ' - ' .. (edate or '<b>Present</b>')
end

return CustomShow
