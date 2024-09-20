---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Squad/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')
local Widgets = Lua.import('Module:Widget/All')
local Widget = Lua.import('Module:Widget')

---@class SquadWidget: Widget
---@operator call:SquadWidget
---@field private injector WidgetInjector?
---@field type SquadType
---@field title string?
local Squad = Class.new(Widget, function(self, props)
	self.injector = props.injector
	self.type = props.type
	self.title = props.title
end)

---@param children string[]
---@return string
function Squad:make(children)
	local title = self._title(self.type, self.title)
	local header = self._header(self.type)

	local allChildren = Array.extend(title, header, children)

	return Widgets.TableNew{
		css = {['margin-bottom'] = '10px'},
		classes = {'wikitable-striped', 'roster-card'},
		children = allChildren,
	}:tryMake(self.injector) or ''
end

---@param type SquadType
---@param title string?
---@return WidgetTableRowNew?
function Squad._title(type, title)
	local defaultTitle
	if type == SquadUtils.SquadType.FORMER or type == SquadUtils.SquadType.FORMER_INACTIVE then
		defaultTitle = 'Former Squad'
	elseif type == SquadUtils.SquadType.INACTIVE then
		defaultTitle = 'Inactive Players'
	end

	local titleText = Logic.emptyOr(title, defaultTitle)

	if String.isEmpty(titleText) then
		return
	end

	return Widgets.TableRowNew{
		children = {Widgets.TableCellNew{content = {titleText}, colSpan = 10, header = true}}
	}
end

---@param type SquadType
---@return WidgetTableRowNew
function Squad._header(type)
	local isInactive = type == SquadUtils.SquadType.INACTIVE or type == SquadUtils.SquadType.FORMER_INACTIVE
	local isFormer = type == SquadUtils.SquadType.FORMER or type == SquadUtils.SquadType.FORMER_INACTIVE
	return Widgets.TableRowNew{
		classes = {'HeaderRow'},
		children = Array.append({},
			Widgets.TableCellNew{content = {'ID'}, header = true},
			Widgets.TableCellNew{header = true}, -- "Team Icon" (most commmonly used for loans)
			Widgets.Customizable{id = 'header_name',
				children = {Widgets.TableCellNew{content = {'Name'}, header = true}}
			},
			Widgets.Customizable{id = 'header_role',
				children = {Widgets.TableCellNew{header = true}}
			},
			Widgets.TableCellNew{content = {'Join Date'}, header = true},
			isInactive and Widgets.Customizable{id = 'header_inactive', children = {
				Widgets.TableCellNew{content = {'Inactive Date'}, header = true},
			}} or nil,
			isFormer and Widgets.Customizable{id = 'header_former', children = {
				Widgets.TableCellNew{content = {'Leave Date'}, header = true},
				Widgets.TableCellNew{content = {'New Team'}, header = true},
			}} or nil
		)
	}
end

return Squad
