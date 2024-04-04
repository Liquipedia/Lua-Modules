---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Widget = require('Module:Infobox/Widget/All')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

---@class Squad
---@operator call:Squad
---@field args table
---@field root Html
---@field private injector WidgetInjector?
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
---@param injector WidgetInjector?
---@return self
function Squad:init(args, injector)
	self.args = args
	self.rows = {}

	local status = (args.status or 'active'):upper()

	self.type = SquadType[status] or SquadType.ACTIVE
	self.injector = injector

	return self
end

---@return self
function Squad:title()
	local defaultTitle
	if self.type == SquadType.FORMER or SquadType.FORMER_INACTIVE then
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
	table.insert(self.rows, Widget.TableRow{
		classes = {'HeaderRow'},
		css = {['font-weight'] = 'bold'},
		cells = {
			Widget.TableCell{}:addContent('ID'),
			Widget.TableCell{}, -- "Team Icon" (most commmonly used for loans)
			Widget.TableCell{}:addContent('Name'),
			Widget.Customizable{id = 'header_role', children = {Widget.TableCell{}}}, -- Role
			Widget.TableCell{}:addContent('Join Date'),
			isInactive and Widget.TableCell{}:addContent('Inactive Date') or nil,
			isFormer and Widget.TableCell{}:addContent('Leave Date') or nil,
			isFormer and Widget.TableCell{}:addContent('New Team') or nil,
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
	for _, node in ipairs(WidgetFactory.work(dataTable, self.injector)) do
		wrapper:node(node)
	end
	return wrapper
end

return Squad
