---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/CharacterTable/Entry/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Tr = HtmlWidgets.Tr
local Td = HtmlWidgets.Td

---@class CharacterTableEntryParams
---@field name string
---@field fontSize string?
---@field size string?
---@field alias string?

---@class BaseCharacterTableEntry: Widget
---@operator call(table): BaseCharacterTableEntry
---@field lpdbProperties datapoint
---@field name string
---@field props CharacterTableEntryParams
local BaseCharacterTableEntry = Class.new(Widget,
	---@param self self
	---@param input CharacterTableEntryParams
	function (self, input)
		if Logic.isNotEmpty(input.alias) then
			local NameAliases = Lua.requireIfExists('Module:' .. input.alias, {loadData = true}) or {}
			self.name = Logic.emptyOr(NameAliases[input.name:lower()])
		else
			self.name = input.name
		end
        assert(Logic.isNotEmpty(self.name), 'Invalid name')
		local query = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[type::character]] AND [[name::'.. self.name ..']]',
		})[1]
		assert(Logic.isNotEmpty(query))
		self.lpdbProperties = query
	end
)

BaseCharacterTableEntry.DEFAULT_BACKGROUND_CLASS = 'gray-bg'

BaseCharacterTableEntry.defaultProps = {
	fontSize = '0.9em',
	size = '85px'
}

---@return Widget
function BaseCharacterTableEntry:render()
	return Div{
		classes = { 'zoom-container' },
		css = {
			display = 'inline-table'
		},
		children = {
			self:_buildUpper(),
			self:_buildLower()
		}
	}
end

---@return Widget
function BaseCharacterTableEntry:_buildUpper()
	return HtmlWidgets.Table{
		classes = { self:getBackgroundClass() },
		css = {
			['margin-bottom'] = '2px',
			['border-spacing'] = 0,
			['border-radius'] = '0.5em 0.5em 0 0',
			overflow = 'hidden',
			width = '95px'
		},
		children = {
			Tr{children = {
				Td{children = {
					Div{
						css = {
							width = self.props.size,
							height = self.props.size,
							display = 'flex',
							['align-items'] = 'center',
							['justify-content'] = 'center',
							overflow = 'hidden',
							margin = '2px auto'
						},
						children = { self:getCharacterIcon() }
					}
				}}
			}}
		}
	}
end

---@return Widget
function BaseCharacterTableEntry:_buildLower()
	return HtmlWidgets.Table{
		classes = { self:getBackgroundClass() },
		css = {
			['margin-bottom'] = '10px',
			['border-spacing'] = 0,
			['border-radius'] = '0 0 0.5em 0.5em',
			overflow = 'hidden',
			width = '95px'
		},
		children = {
			Tr{children = {
				Td{children = {
					Div{
						css = {
							['font-weight'] = 'bold',
							['word-break'] = 'break-word',
							['font-size'] = self.props.fontSize,
							['margin-bottom'] = '2px'
						},
						children = {
							Link{
								link = self.lpdbProperties.pagename,
								children = self.lpdbProperties.name
							}
						}
					}
				}}
			}}
		}
	}
end

---@return string|Widget?
function BaseCharacterTableEntry:getCharacterIcon()
	return Image.display('Transparent icon.png', nil, {size = self.props.size})
end

---@return string
function BaseCharacterTableEntry:getBackgroundClass()
	return BaseCharacterTableEntry.DEFAULT_BACKGROUND_CLASS
end

return BaseCharacterTableEntry
