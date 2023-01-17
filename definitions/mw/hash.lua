-- luacheck: ignore
---@meta mw.hash

---@class Hash
hash = {}

---Hashes a string value with the specified algorithm. Valid algorithms may be fetched using mw.hash.listAlgorithms().
---@param algo string
---@param value any
---@return string
function hash.hashValue(algo, value) end

---Hashes a string value with the specified algorithm. Valid algorithms may be fetched using mw.hash.listAlgorithms().
---@return string[]
function hash.listAlgorithms() end

return hash
