---
-- @Liquipedia
-- page=Module:Transfer/References
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Icon = Lua.import('Module:Icon')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')

local Info = Lua.import('Module:Info', {loadData = true})

local TransferRef = {}

local WEB_TYPE = 'web source'
local TOURNAMENT_TYPE = 'tournament source'
local CONTRACT_TYPE = 'contract database'
local INSIDE_TYPE = 'inside source'
local TOURNAMENT_LEAVE_TYPE = 'tournament leave source'

---@alias RefType
---| `WEB_TYPE`
---| `TOURNAMENT_TYPE`
---| `CONTRACT_TYPE`
---| `INSIDE_TYPE`
---| `TOURNAMENT_LEAVE_TYPE`

---@class TransferReference
---@field refType RefType
---@field link string?
---@field text string?
---@field title string?
---@field transTitle string?
---@field language string?
---@field author string?
---@field publisher string?
---@field archiveUrl string?
---@field archiveDate string?

---@param refInput string?
---@return TransferReference[]
function TransferRef.read(refInput)
	local references = Array.parseCommaSeparatedString(refInput, ';;;')

	---@param ref string?
	---@return TransferReference?
	local readReference = function(ref)
		local reference = Json.parseIfTable(ref) or {}

		local refType = (Logic.nilIfEmpty(reference.type) or WEB_TYPE):lower()
		assert(TransferRef.isValidRefType(refType), 'invalid reference type "' .. refType .. '"')

		local link = Logic.nilIfEmpty(reference.url)
		if not link and (refType == WEB_TYPE or refType == TOURNAMENT_TYPE or refType == TOURNAMENT_LEAVE_TYPE) then
			return nil
		end

		return {
			refType = refType,
			link = link,
			title = Logic.nilIfEmpty(reference.title),
			transTitle = Logic.nilIfEmpty(reference.trans_title),
			language = Logic.nilIfEmpty(reference.language),
			author = Logic.nilIfEmpty(reference.author),
			publisher = Logic.nilIfEmpty(reference.publisher),
			archiveUrl = Logic.nilIfEmpty(reference.archiveurl),
			archiveDate = Logic.nilIfEmpty(reference.archivedate),
		}
	end

	return Array.map(references, readReference)
end

---@param refType string
---@return boolean
function TransferRef.isValidRefType(refType)
	return refType == WEB_TYPE or
		refType == TOURNAMENT_TYPE or
		refType == CONTRACT_TYPE or
		refType == INSIDE_TYPE or
		refType == TOURNAMENT_LEAVE_TYPE
end

---@param references TransferReference[]
---@return table
function TransferRef.toStorageData(references)
	local storageData = {}
	Array.forEach(references, function(reference, referenceIndex)
		TransferRef.addReferenceToStorageData(storageData, reference, referenceIndex)
	end)

	return storageData
end

---@param storageData table
---@param reference TransferReference
---@param referenceIndex integer
---@return table
function TransferRef.addReferenceToStorageData(storageData, reference, referenceIndex)
	local prefix = 'reference' .. referenceIndex
	storageData[prefix] = reference.link
	storageData[prefix .. 'type'] = reference.refType
	storageData[prefix .. 'text'] = reference.text
	storageData[prefix .. 'title'] = reference.title
	storageData[prefix .. 'transtitle'] = reference.transTitle
	storageData[prefix .. 'language'] = reference.language
	storageData[prefix .. 'author'] = reference.author
	storageData[prefix .. 'publisher'] = reference.publisher
	storageData[prefix .. 'archiveurl'] = reference.archiveUrl
	storageData[prefix .. 'archivedate'] = reference.archiveDate
	return storageData
end

---@param referencesData table?
---@return TransferReference[]
function TransferRef.fromStorageData(referencesData)
	if Logic.isDeepEmpty(referencesData) then
		return {}
	end
	---@cast referencesData -nil

	return Array.mapIndexes(function(referenceIndex)
		local prefix = 'reference' .. referenceIndex
		local link = referencesData[prefix]
		local refType = referencesData[prefix .. 'type']
		if Logic.isEmpty(refType) then return end
		return {
			link = link,
			refType = refType,
			text = referencesData[prefix .. 'text'],
			title = referencesData[prefix .. 'title'],
			transTitle = referencesData[prefix .. 'transtitle'],
			language = referencesData[prefix .. 'language'],
			author = referencesData[prefix .. 'author'],
			publisher = referencesData[prefix .. 'publisher'],
			archiveUrl = referencesData[prefix .. 'archiveurl'],
			archiveDate = referencesData[prefix .. 'archivedate'],
		}
	end)
end

---@param references TransferReference[]
---@return TransferReference[]
function TransferRef.makeUnique(references)
	local refs = {}
	Array.forEach(references, function(reference)
		if Array.all(refs, function(ref)
			return not Logic.deepEquals(ref, reference)
		end) then
			table.insert(refs, reference)
		end
	end)

	return refs
end

---@param refData TransferReference
---@param date string
---@return string
function TransferRef.createReferenceKey(refData, date)
	return date .. refData.refType .. (refData.link or '')
end

---@param references table?
---@param date string
---@return string
function TransferRef.useReferences(references, date)
	local refs = Array.map(TransferRef.fromStorageData(references), function(reference)
		return TransferRef.useReference(reference, date)
	end)

	return table.concat(refs)
end

---@param reference TransferReference
---@param date string
---@return string
function TransferRef.useReference(reference, date)
	local refKey = TransferRef.createReferenceKey(reference, date)

	if Logic.isEmpty(Variables.varDefault(refKey)) then
		Variables.varDefine(refKey, 'created')
		return TransferRef.createReference(reference, date)
	end

	if TransferRef.isValidRefType(reference.refType) then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				'',
				name = refKey
			}
		}
	end

	return ''
end

---@param refData TransferReference
---@param date string
---@return string
function TransferRef.createReference(refData, date)
	local referenceKey = TransferRef.createReferenceKey(refData, date)

	local refType = refData.refType

	if refType == WEB_TYPE then
		local refCite = mw.getCurrentFrame():expandTemplate{
			title = 'Cite web',
			args = {
				url = refData.link,
				title = refData.title or 'Transfer reference',
				trans_title = refData.transTitle,
				language = refData.language,
				author = refData.author,
				date = date,
				publisher = refData.publisher,
				archiveurl = refData.archiveUrl,
				archivedate = refData.archiveDate,
			}
		}
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				refCite,
				name = referenceKey
			}
		}
	elseif refType == TOURNAMENT_TYPE or refType == TOURNAMENT_LEAVE_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				TransferRef._getTextAndLink(refData, {linkInsideText = true}),
				name = referenceKey
			}
		}
	elseif refType == INSIDE_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				TransferRef._getTextAndLink(refData, {linkInsideText = true}),
				name = referenceKey
			}
		}
	elseif refType == CONTRACT_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				TransferRef._getTextAndLink(refData, {linkInsideText = true}),
				name = referenceKey
			}
		}
	end
	return ''
end

---@param reference TransferReference
---@return string?
function TransferRef.createReferenceIconDisplay(reference)
	local refType = reference.refType
	local text, link = TransferRef._getTextAndLink(reference)
	link = link or reference.link

	if refType == WEB_TYPE then
		return Page.makeExternalLink(Icon.makeIcon{
			iconName = 'reference',
			color = 'wiki-color-dark',
		}, link)
	elseif refType == TOURNAMENT_TYPE or refType == TOURNAMENT_LEAVE_TYPE then
		return Page.makeInternalLink(Abbreviation.make{
			text = Icon.makeIcon{iconName = 'link', color = 'wiki-color-dark'},
			title = text,
		}, link)
	elseif refType == INSIDE_TYPE then
		return Abbreviation.make{
			text = Icon.makeIcon{iconName = 'insidesource', color = 'wiki-color-dark'},
			title = text,
		}
	elseif refType == CONTRACT_TYPE then
		return Page.makeExternalLink(Abbreviation.make{
			text = Icon.makeIcon{iconName = 'transferdatabase', color = 'wiki-color-dark'},
			title = text,
		}, link)
	end

	return nil
end

---@param reference {refType: RefType, link: string?}
---@param options {linkInsideText: boolean?}?
---@return string?, string?
function TransferRef._getTextAndLink(reference, options)
	options = options or {}
	local linkInsideText = options.linkInsideText
	local refType = reference.refType
	local link = reference.link

	if refType == TOURNAMENT_TYPE and link then
		return 'Transfer wasn\'t formally announced, but individual represented team starting with ' ..
			(linkInsideText and '[[' .. link .. '|this tournament]].' or 'this tournament'),
			not linkInsideText and link or nil
	elseif refType == TOURNAMENT_LEAVE_TYPE and link then
		return 'Transfer wasn\'t formally announced, but individual no longer represented team starting with ' ..
			(linkInsideText and '[[' .. link .. '|this tournament]].' or 'this tournament'),
			not linkInsideText and link or nil
	elseif refType == INSIDE_TYPE then
			return 'Liquipedia has gained this information from a trusted inside source.'
	elseif refType == CONTRACT_TYPE then
		local contractDatabase = (Info.config.transfers or {}).contractDatabase
		assert(contractDatabase, 'Contract database type is not available on this wiki')
		link = contractDatabase.link
		local displayText = contractDatabase.display
		return 'Transfer was not formally announced, but was revealed by changes in the ' ..
			(linkInsideText and Page.makeExternalLink(displayText, link) or displayText) .. '.',
			not linkInsideText and link or nil
	end
end

return TransferRef
