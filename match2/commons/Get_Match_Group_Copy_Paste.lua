--[[

bracket finder (and code generator) / matchlist code generator

]]--

local copyPaste = {}
local getArgs = require('Module:Arguments').getArgs
local Lua = require("Module:Lua")
local BracketAlias = Lua.moduleExists("Module:BracketAlias") and mw.loadData('Module:BracketAlias') or {}
local WikiSpecific = require("Module:GetMatchGroupCopyPaste/wiki")

local args

function copyPaste._generateID()
	local id = ''

	for i = 1, 10 do
		local rnd = math.random(62)
		if rnd <= 10 then
			id = id .. (rnd-1)
		elseif rnd <= 36 then
			id = id .. string.char(54 + rnd)
		else
			id = id .. string.char(60 + rnd)
		end
	end

	if mw.ext.Brackets.checkBracketDuplicate(id) ~= 'ok' then
		id = copyPaste._generateID()
	end

	return id
end

function copyPaste._getBracketData(templateid)
	templateid = 'Bracket/' .. templateid
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateid)

	assert(type(matches) == "table")
	local bracketData = {}
	local count = false

	for index, match in ipairs(matches) do
		local id = string.gsub(match.match2id, match.match2bracketid .. '_', '')
		local _, b, _, d = string.match(id, '(R0*)(%d+)(%-M0*)(%d+)')

		if b and d then
			id = 'R' .. b .. 'M' .. d
		end

		count = true

		bracketData[index] = {
			id = id,
			header = (match.match2bracketdata.header or '') ~= '' and match.match2bracketdata.header or nil,
		}
	end

	if not count then
		error(templateid .. ' does not exist. If you should need it please ask a contributor with reviewer+ rights for help.')
	end

	return bracketData
end

function copyPaste._getHeader(headerCode, customHeader, match)
	local header = ''

	if not headerCode then
		return header
	end

	headerCode = mw.text.split(string.gsub(headerCode, '$', '!'), '!')
	local index = 1
	if (headerCode[1] or '') == '' then
		index = 2
	end
	header = mw.message.new('brkts-header-' .. headerCode[index]):params(headerCode[index + 1] or ''):plain()

	header = mw.text.split(header, ',')[1]

	header = '\n\n' .. mw.text.nowiki('<!--') .. ' ' .. header .. ' ' .. mw.text.nowiki('-->') .. (customHeader and ('\n|' .. match.id .. 'header=') or '')
	return header
end

function copyPaste.bracket(frame)
	if not args then
		args = getArgs(frame)
	end

	local empty = args.empty == 'true'
	local customHeader = args.customHeader == 'true'
	local bestof = tonumber(args.bestof or 3) or 3
	local opponents = tonumber(args.opponents or 2) or 2
	local mode = WikiSpecific.getMode(args.mode)

	args.id = (args.id or '') and args.id or (args.template or '') and args.template or args.name or ''
	args.id = string.gsub(string.gsub(args.id, '^Bracket/', ''), '^bracket/', '')
	local templateid = BracketAlias[string.lower(args.id)] or args.id

	local out = '<pre class="selectall" width=50%>' .. WikiSpecific.getStart(templateid, copyPaste._generateID(), 'bracket', args)

	local bracketData = copyPaste._getBracketData(templateid)

	for index, match in ipairs(bracketData) do
		if match.id == 'RxMTP' or match.id == 'RxMBR' then
			if args.extra == 'true' then
				local header
				if match.id == 'RxMTP' then
					header = '\n\n' .. mw.text.nowiki('<!--') .. ' Third Place Match ' .. mw.text.nowiki('-->') .. '\n|' .. match.id .. 'header='
				else
					header = '\n\n' .. mw.text.nowiki('<!--') .. ' Bracket Reset ' .. mw.text.nowiki('-->') .. '\n|' .. match.id .. 'header='
				end
				if empty then
					out = out .. header .. '\n|' .. match.id .. '='
				else
					out = out .. header .. '\n|' .. match.id .. '=' .. WikiSpecific.getMatchCode(bestof, mode, index, opponents, args)
				end
			end
		else
			if empty then
				out = out .. copyPaste._getHeader(match.header, customHeader, match) .. '\n|' .. match.id .. '='
			else
				out = out .. copyPaste._getHeader(match.header, customHeader, match).. '\n|' .. match.id .. '=' .. WikiSpecific.getMatchCode(bestof, mode, index, opponents, args)
			end
		end
	end

	return out .. '\n}}</pre>'
end

function copyPaste.matchlist(frame)
	if not args then
		args = getArgs(frame)
	end

	local empty = args.empty == 'true'
	local customHeader = args.customHeader == 'true'
	local bestof = tonumber(args.bestof or 3) or 3
	local matches = tonumber(args.matches or 5) or 5
	local opponents = tonumber(args.opponents or 2) or 2
	local mode = WikiSpecific.getMode(args.mode)

	local out = '<pre class="selectall" width=50%>' .. WikiSpecific.getStart(templateid, copyPaste._generateID(), 'matchlist', args)

	for index = 1, matches do
		if customHeader then
			out = out .. '\n|M' .. index .. 'header='
		end

		out = out .. '\n|M' .. index .. '=' .. (not empty and WikiSpecific.getMatchCode(bestof, mode, index, opponents, args) or '')
	end

	return out .. '\n}}</pre>'
end

return copyPaste
