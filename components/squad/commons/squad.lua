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
local Widget = require('Module:Infobox/Widget/All')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

---@class Squad
---@operator call:Squad
---@field args table
---@field root Html
---@field rows WidgetTableRow[]
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

	self.rows = {}

	local status = (self.args.status or 'active'):upper()

	self.type = SquadType[status] or SquadType.ACTIVE

	return self
end

---@return self
function Squad:title()
	local defaultTitle
	if self.type == SquadType.FORMER then
		defaultTitle = 'Former Squad'
	elseif self.type == SquadType.INACTIVE then
		defaultTitle = 'Inactive Players'
	end

	local titleText = Logic.emptyOr(self.args.title, defaultTitle)

	if String.isEmpty(titleText) then
		return self
	end

	table.insert(self.rows, Widget.TableRow{
		css = {['font-weight'] = 'bold'},
		cells = {Widget.TableCell:addContent(titleText)}
	})

	return self
end

---@return self
function Squad:header()
	local isInactive = self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE
	local isFormer = self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE
	local cellArgs = {classes = {'divCell'}}
	table.insert(self.rows, Widget.TableRow{
		classes = {'HeaderRow'},
		css = {['font-weight'] = 'bold'},
		cells = {
			Widget.TableCell(cellArgs):addContent('ID'),
			Widget.TableCell(cellArgs), -- "Team Icon" (most commmonly used for loans)
			Widget.TableCell(cellArgs):addContent('Name'),
			Widget.TableCell(cellArgs), -- Role
			Widget.TableCell(cellArgs):addContent('Join Date'),
			isInactive and Widget.TableCell(cellArgs):addContent('Inactive Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('Leave Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('New Team') or nil,
		}
	})

	return self
end

---@param row WidgetTableRow
---@return self
function Squad:row(row)
	table.insert(self.rows, row)
	return self
end

---@return Html
function Squad:create()
	local dataTable = Widget.Table{
		classes = {'wikitable', 'wikitable-striped', 'roster-card'},
		rows = self.rows,
	}
	local wrapper = mw.html.create('div'):addClass('table-responsive'):css('margin-bottom', '10px')
	for _, node in ipairs(WidgetFactory.work(dataTable)) do
		wrapper:node(node)
	end
	return wrapper
end

return Squad
