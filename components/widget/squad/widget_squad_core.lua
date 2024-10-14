---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Squad/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')
local Widgets = Lua.import('Module:Widget/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

local DataTable, Tr, Th = Widgets.DataTable, Widgets.Tr, Widgets.Th

---@class SquadWidget: Widget
---@operator call(table): SquadWidget
local Squad = Class.new(Widget)

---@return WidgetDataTable
function Squad:render()
	local title = self:_title(self.props.type, self.props.title)
	local header = self:_header(self.props.type)

	local allChildren = WidgetUtil.collect(title, header, unpack(self.props.children))

	return DataTable{
		classes = {'wikitable-striped', 'roster-card'},
		wrapperClasses = {'roster-card-wrapper'},
		children = allChildren,
	}
end

---@param type SquadType
---@param title string?
---@return WidgetTr?
function Squad:_title(type, title)
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

	return Tr{
		children = {Th{children = {titleText}, attributes={colspan = 10}}}
	}
end

---@param type SquadType
---@return WidgetTr
function Squad:_header(type)
	local isInactive = type == SquadUtils.SquadType.INACTIVE or type == SquadUtils.SquadType.FORMER_INACTIVE
	local isFormer = type == SquadUtils.SquadType.FORMER or type == SquadUtils.SquadType.FORMER_INACTIVE

	local name = self:useContext(SquadContexts.NameSection, {Th{children = {'Name'}}})
	local inactive = isInactive and self:useContext(SquadContexts.InactiveSection, {
		Th{children = {'Inactive Date'}}
	}) or nil
	local former = isFormer and self:useContext(SquadContexts.FormerSection, {
		Th{children = {'Leave Date'}},
		Th{children = {'New Team'}},
	}) or nil
	local role = {Th{children = {self:useContext(SquadContexts.RoleTitle)}}}

	return Tr{
		classes = {'HeaderRow'},
		children = WidgetUtil.collect(
			Th{children = {'ID'}},
			Th{}, -- "Team Icon" (most commmonly used for loans)
			name,
			role,
			Th{children = {'Join Date'}},
			inactive,
			former
		)
	}
end

return Squad
