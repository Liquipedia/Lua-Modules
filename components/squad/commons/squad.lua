---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Arguments = require('Module:Arguments')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Widget = require('Module:Widget/All')
local WidgetFactory = require('Module:Widget/Factory')

---@class Squad
---@operator call:Squad
---@field args table
---@field root Html
---@field content WidgetTable
---@field type integer
local Squad = Class.new()

---@enum SquadType
local SquadType = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3,
}
Squad.SquadType = SquadType

---@param args table
---@return self
function Squad:init(args)
	self.args = Arguments.getArgs(args)
	self.root = mw.html.create('div')
	self.root:addClass('table-responsive')
	-- TODO: is this needed?
		:css('margin-bottom', '10px')
	-- TODO: is this needed?
		:css('padding-bottom', '0px')

	self.content = Widget.Table{
		classes = {'wikitable', 'wikitable-striped', 'roster-card'}
	}

	if not String.isEmpty(self.args.team) then
		self.args.isLoan = true
	end

	local status = (self.args.status or 'active'):upper()

	self.type = SquadType[status] or SquadType.ACTIVE

	return self
end

---@return Squad
function Squad:title()
	local defaultTitle
	if self.type == SquadType.FORMER then
		defaultTitle = 'Former Squad'
	elseif self.type == SquadType.INACTIVE then
		defaultTitle = 'Inactive Players'
	end

	local titleText = Logic.emptyOr(self.args.title, defaultTitle)

	if String.isNotEmpty(titleText) then
		local titleContainer = Widget.TableRow{css = {['font-weight'] = 'bold'}}

		titleContainer:addCell(Widget.TableCell:addContent(titleText))
		self.content:addRow(titleContainer)
	end

	return self
end

---@return self
function Squad:header()
	local headerRow = Widget.TableRow{classes = 'HeaderRow', css = {['font-weight'] = 'bold'}}

	local cellArgs = {classes = 'divCell'}
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('ID'))
	headerRow:addCell(Widget.TableCell(cellArgs)) -- "Team Icon" (most commmonly used for loans)
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('Name'))
	headerRow:addCell(Widget.TableCell(cellArgs)) -- "Role"
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('Join Date'))

	if self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE then
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('Inactive Date'))
	end

	if self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE then
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('Leave Date'))
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('New Team'))
	end

	self.content:addRow(headerRow)

	return self
end

---@param row WidgetTableRow
---@return self
function Squad:row(row)
	self.content:addRow(row)
	return self
end

---@return Html
function Squad:create()
	for _, node in ipairs(WidgetFactory.work(self.content)) do
		self.root:node(node)
	end
	return self.root
end

return Squad
