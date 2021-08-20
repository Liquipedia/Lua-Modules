local Arguments = require('Module:Arguments')
local BracketDisplay = require('Module:MatchGroup/Display/Bracket')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Table = require('Module:Table')

local BracketTemplateDisplay = {propTypes = {}}

--[[
Display component showing an empty tournament bracket with no opponents. Used
by Template:BracketDocumentation.
]]

--Entry point called from Template:BracketDocumentation
function BracketTemplateDisplay.TemplateBracketTemplate(frame)
	local args = Arguments.getArgs(frame)
	return BracketTemplateDisplay.BracketContainer({
		bracketId = args.bracketId,
	})
end

function BracketTemplateDisplay.BracketContainer(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.BracketContainer)
	return BracketTemplateDisplay.Bracket({
		config = props.config,
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
	})
end

function BracketTemplateDisplay.Bracket(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.Bracket)
	return BracketDisplay.Bracket({
		bracket = props.bracket,
		config = Table.merge(props.config, {
			OpponentEntry = BracketTemplateDisplay.OpponentEntry,
			matchHasDetails = function() return false end,
		})
	})
end

function BracketTemplateDisplay.OpponentEntry(props)
	return mw.html.create('div'):addClass('brkts-opponent-entry')
end

return Class.export(BracketTemplateDisplay)
