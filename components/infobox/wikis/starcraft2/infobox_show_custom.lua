---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Show = Lua.import('Module:Infobox/Show', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomShow = Class.new()

local _show
local _args

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomShow.run(frame)
	local customShow = Show(frame)
	_show = customShow
	_args = customShow.args
	customShow.createWidgetInjector = CustomShow.createWidgetInjector
	return customShow:createInfobox()
end

function CustomShow:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Cell{name = 'No. of episodes', content = {_args['num_episodes']}},
		Cell{name = 'Original Release', content = {CustomShow:_getReleasePeriod(_args.sdate, _args.edate)}}
	)

	if Namespace.isMain() and _args.edate == nil then
		_show.infobox:categories('Active Shows')
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
