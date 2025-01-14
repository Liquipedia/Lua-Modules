---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/BracketTemplate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local BracketTemplateDisplay = {propTypes = {}}

---Display component showing an empty tournament bracket with no opponents. Used by Template:BracketDocumentation.

--Entry point called from Template:BracketDocumentation
---@param frame Frame
---@return Html
function BracketTemplateDisplay.TemplateBracketTemplate(frame)
	local args = Arguments.getArgs(frame)
	return BracketTemplateDisplay.BracketContainer({
		bracketId = args.bracketId,
	})
end

---@param props {bracketId: string, config: BracketConfigOptions}
---@return Html
function BracketTemplateDisplay.BracketContainer(props)
	return BracketTemplateDisplay.Bracket({
		config = props.config,
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId) --[[@as MatchGroupUtilBracket]],
	})
end

---@param props {bracket: MatchGroupUtilBracket, config: BracketConfigOptions}
---@return Html
function BracketTemplateDisplay.Bracket(props)
	return BracketDisplay.Bracket({
		bracket = props.bracket,
		config = Table.merge(props.config, {
			OpponentEntry = BracketTemplateDisplay.OpponentEntry,
			matchHasDetails = function() return false end,
		})
	})
end

---@param props table
---@return Html
function BracketTemplateDisplay.OpponentEntry(props)
	return mw.html.create('div'):addClass('brkts-opponent-entry')
end

return Class.export(BracketTemplateDisplay)
