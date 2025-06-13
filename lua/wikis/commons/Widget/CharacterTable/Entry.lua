---
-- @Liquipedia
-- page=Module:Widget/CharacterTable/Entry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Character = Lua.import('Module:Character')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Tr = HtmlWidgets.Tr
local Td = HtmlWidgets.Td

---@class CharacterTableEntryParams
---@field name string
---@field fontSize string?
---@field size string?
---@field alias string?
---@field character StandardCharacter?

---@class CharacterTableEntry: Widget
---@operator call(CharacterTableEntryParams): CharacterTableEntry
---@field character StandardCharacter
---@field name string
---@field props CharacterTableEntryParams
local CharacterTableEntry = Class.new(Widget,
	---@param self self
	---@param input CharacterTableEntryParams
	function (self, input)
		---@param name string
		---@param alias string?
		---@return StandardCharacter
		local function fetchCharacterInformation(name, alias)
			assert(Logic.isNotEmpty(name), 'Invalid name')
			local nameAlias = name
			if Logic.isNotEmpty(alias) then
				local NameAliases = Lua.requireIfExists('Module:' .. alias, {loadData = true}) or {}
				nameAlias = NameAliases[name:lower()] or name
			end
			assert(Logic.isNotEmpty(nameAlias), 'Invalid name')
			local character = Character.getCharacterByName(nameAlias)
			assert(character, 'No character with name ' .. input.name .. ' found')
			return character
		end

		self.character = Logic.emptyOr(input.character, fetchCharacterInformation(input.name, input.alias))
	end
)

CharacterTableEntry.DEFAULT_BACKGROUND_CLASS = 'gray-bg'

CharacterTableEntry.defaultProps = {
	fontSize = '0.9em',
	size = '85px'
}

---@return Widget
function CharacterTableEntry:render()
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
function CharacterTableEntry:_buildUpper()
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
function CharacterTableEntry:_buildLower()
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
								link = self.character.pageName,
								children = self.character.name
							}
						}
					}
				}}
			}}
		}
	}
end

---@protected
---@return string|Widget?
function CharacterTableEntry:getCharacterIcon()
	return IconImage{
		imageLight = self.character.iconLight,
		imageDark = self.character.iconDark,
		size = self.props.size
	}
end

---@return string
function CharacterTableEntry:getBackgroundClass()
	return CharacterTableEntry.DEFAULT_BACKGROUND_CLASS
end

return CharacterTableEntry
