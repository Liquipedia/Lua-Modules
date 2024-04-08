---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')
local Widget = Lua.import('Module:Infobox/Widget/All')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class Squad
---@operator call:Squad
---@field args table
---@field root Html
---@field private injector WidgetInjector?
---@field rows WidgetTableRowNew[]
---@field type integer
local Squad = Class.new()


---@param args table
---@param injector WidgetInjector?
---@return self
function Squad:init(args, injector)
	self.args = Arguments.getArgs(args)
	self.rows = {}

	self.injector = injector
	self.type =
		(SquadUtils.SquadTypeToStorageValue[self.args.type] and self.args.type) or
		SquadUtils.statusToSquadType(self.args.status) or
		SquadUtils.SquadType.ACTIVE

	return self
end

---@return self
function Squad:title()
	local defaultTitle
	if self.type == SquadUtils.SquadType.FORMER or self.type == SquadUtils.SquadType.FORMER_INACTIVE then
		defaultTitle = 'Former Squad'
	elseif self.type == SquadUtils.SquadType.INACTIVE then
		defaultTitle = 'Inactive Players'
	end

	local titleText = Logic.emptyOr(self.args.title, defaultTitle)

	if String.isEmpty(titleText) then
		return self
	end

	table.insert(self.rows, Widget.TableRowNew{
		children = {Widget.TableCellNew{content = {titleText}, colSpan = 10, header = true}}
	})

	return self
end

---@return self
function Squad:header()
	local isInactive = self.type == SquadUtils.SquadType.INACTIVE or self.type == SquadUtils.SquadType.FORMER_INACTIVE
	local isFormer = self.type == SquadUtils.SquadType.FORMER or self.type == SquadUtils.SquadType.FORMER_INACTIVE
	table.insert(self.rows, Widget.TableRowNew{
		classes = {'HeaderRow'},
		children = Array.append({},
			Widget.TableCellNew{content = {'ID'}, header = true},
			Widget.TableCellNew{header = true}, -- "Team Icon" (most commmonly used for loans)
			Widget.Customizable{id = 'header_name',
				children = {Widget.TableCellNew{content = {'Name'}, header = true}}
			},
			Widget.Customizable{id = 'header_role',
				children = {Widget.TableCellNew{header = true}}
			},
			Widget.TableCellNew{content = {'Join Date'}, header = true},
			isInactive and Widget.Customizable{id = 'header_inactive', children = {
				Widget.TableCellNew{content = {'Inactive Date'}, header = true},
			}} or nil,
			isFormer and Widget.Customizable{id = 'header_former', children = {
				Widget.TableCellNew{content = {'Leave Date'}, header = true},
				Widget.TableCellNew{content = {'New Team'}, header = true},
			}} or nil
		)
	})

	return self
end

---@param row WidgetTableRowNew
---@return self
function Squad:row(row)
	table.insert(self.rows, row)
	return self
end

---@return Html
function Squad:create()
	local dataTable = Widget.TableNew{
		css = {['margin-bottom'] = '10px'},
		classes = {'wikitable-striped', 'roster-card'},
		children = self.rows,
	}
	local wrapper = mw.html.create()
	for _, node in ipairs(WidgetFactory.work(dataTable, self.injector)) do
		wrapper:node(node)
	end
	return wrapper
end

return Squad
