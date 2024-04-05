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
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')

---@class Squad
---@field args table
---@field root Html
---@field content Html
---@field type integer
local Squad = Class.new()

---@param frame table|Frame
---@return self
function Squad:init(frame)
	self.args = Arguments.getArgs(frame)
	self.root = mw.html.create('div')
	self.root:addClass('table-responsive')
	-- TODO: is this needed?
		:css('margin-bottom', '10px')
	-- TODO: is this needed?
		:css('padding-bottom', '0px')

	self.content = mw.html.create('table')
	self.content:addClass('wikitable wikitable-striped roster-card')

	if not String.isEmpty(self.args.team) then
		self.args.isLoan = true
	end

	self.type =
		(SquadUtils.SquadTypeToStorageValue[self.args.type] and self.args.type) or
		SquadUtils.statusToSquadType(self.args.status) or
		SquadUtils.SquadType.ACTIVE

	return self
end

---@return Squad
function Squad:title()
	local defaultTitle
	if self.type == SquadUtils.SquadType.FORMER then
		defaultTitle = 'Former Squad'
	elseif self.type == SquadUtils.SquadType.INACTIVE then
		defaultTitle = 'Inactive Players'
	end

	local titleText = Logic.emptyOr(self.args.title, defaultTitle)

	if String.isNotEmpty(titleText) then
		local titleContainer = mw.html.create('tr')

		local titleRow = mw.html.create('th')
		titleRow:addClass('large-only')
			:attr('colspan', '1')
			:wikitext(titleText)

		local titleRow2 = mw.html.create('th')
		titleRow2:addClass('large-only')
			:attr('colspan', '10')
			:addClass('roster-title-row2-border')
			:wikitext(titleText)

		titleContainer:node(titleRow):node(titleRow2)
		self.content:node(titleContainer)
	end

	return self
end

---@return self
function Squad:header()
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow:node(makeHeader('ID'))
		:node(makeHeader()) -- "Team Icon" (most commmonly used for loans)
		:node(makeHeader('Name'))
		:node(makeHeader()) -- "Role"
		:node(makeHeader('Join Date'))
	if self.type == SquadUtils.SquadType.FORMER then
		headerRow:node(makeHeader('Leave Date'))
			:node(makeHeader('New Team'))
	elseif self.type == SquadUtils.SquadType.INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end

	self.content:node(headerRow)

	return self
end

---@param row Html
---@return self
function Squad:row(row)
	self.content:node(row)
	return self
end

---@return Html
function Squad:create()
	return self.root:node(self.content)
end

return Squad
