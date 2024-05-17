---
-- @Liquipedia
-- wiki=commons
-- page=Module:Transfer/Refences
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local TransferRef = {}

local _ref_counter = 0

local WEB_TYPE = 'web source'
local TOURNAMENT_TYPE = 'tournament source'
local CONTRACT_TYPE = 'contract database'
local INSIDE_TYPE = 'inside source'

---@alias RefType
---| `WEB_TYPE`
---| `TOURNAMENT_TYPE`
---| `CONTRACT_TYPE`
---| `INSIDE_TYPE`

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
		if not link and (refType == WEB_TYPE or refType == TOURNAMENT_TYPE) then
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
		refType == INSIDE_TYPE
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

	--fallback processing for pre standardized TRef data, so we do not break stuff
	--to be removed after switching to standardized and having everything purged
	if Logic.isEmpty(referencesData.reference1type) then
		return TransferRef.fromLegacyStorageData(referencesData)
	end

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

---@deprecated
---to be removed after switching to standardized and having everything purged
---@param referencesData table
---@return TransferReference[]
function TransferRef.fromLegacyStorageData(referencesData)
	return Array.mapIndexes(function(referenceIndex)
		local tempArray = mw.text.split(referencesData['reference' .. referenceIndex] or '', ',,,', true)
		local refType = tempArray[1]

		if not TransferRef.isValidRefType(refType) then return end

		local link = Logic.nilIfEmpty(tempArray[2])
		if Logic.isEmpty(refType) or refType == WEB_TYPE and not link then return end
		return {
			link = link,
			refType = refType,
			text = Logic.nilIfEmpty(tempArray[3]),
			title = Logic.nilIfEmpty(tempArray[4]),
			transTitle = Logic.nilIfEmpty(tempArray[5]),
			language = Logic.nilIfEmpty(tempArray[6]),
			author = Logic.nilIfEmpty(tempArray[7]),
			publisher = Logic.nilIfEmpty(tempArray[8]),
			archiveUrl = Logic.nilIfEmpty(tempArray[9]),
			archiveDate = Logic.nilIfEmpty(tempArray[10]),
		}
	end)
end

---@param references TransferReference[]
---@return TransferReference[]
function TransferRef.makeUnique(references)
	local refs = {}
	Array.forEach(references, function(reference)
		if Array.all(refs, function(ref)
			return Logic.deepEquals(ref, reference)
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

---@param references table
---@param date string
---@return string
function TransferRef.useFirstReference(references, date)
	return TransferRef.useReference(TransferRef.fromStorageData(references)[1], date)
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
		if not refData.title then
			_ref_counter = _ref_counter + 1
			refData.title = 'Transfer reference ' .. _ref_counter
		end

		local refCite = mw.getCurrentFrame():expandTemplate{
			title = 'Cite web',
			args = {
				url = refData.link,
				title = refData.title,
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
	elseif refType == TOURNAMENT_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				'Transfer wasn\'t formally announced, but individual represented team starting with ' ..
					'[[' .. refData.link .. '|this tournament]].',
				name = referenceKey
			}
		}
	elseif refType == INSIDE_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				'Liquipedia has gained this information from a trusted inside source.',
				name = referenceKey
			}
		}
	elseif refType == CONTRACT_TYPE then
		return mw.getCurrentFrame():callParserFunction{
			name = '#tag:ref',
			args = {
				'Transfer was not formally announced, but was revealed by changes in the ' ..
					'[https://docs.google.com/spreadsheets/d/1Y7k5kQ2AegbuyiGwEPsa62e883FYVtHqr6UVut9RC4o/pubhtml# ' ..
					'LoL Esports League-Recognized Contract Database].',
				name = referenceKey
			}
		}
	end
	return ''
end

return TransferRef
