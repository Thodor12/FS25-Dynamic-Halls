DynamicHallsPlacedTilePiece = {}
local DynamicHallsPlacedTilePiece_mt = Class(DynamicHallsPlacedTilePiece)

---Registers the xml schema for a placed tile piece's savegame fields under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPlacedTilePiece.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#pieceKey", "Piece definition key")
    schema:register(XMLValueType.INT, basePath .. "#row", "Grid row")
    schema:register(XMLValueType.INT, basePath .. "#column", "Grid column")
end

---Creates a new, empty placed tile piece.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPlacedTilePiece.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsPlacedTilePiece_mt)
    self.pieceKey = nil
    self.row = 0
    self.column = 0
    return self
end

---Writes this piece's fields to the savegame.
-- @param table xmlFile XMLFile to write to
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedTilePiece:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#pieceKey", self.pieceKey)
    xmlFile:setValue(key .. "#row", self.row)
    xmlFile:setValue(key .. "#column", self.column)
end

---Reads this piece's fields back from the savegame. Always returns true.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedTilePiece:loadFromXMLFile(xmlFile, key)
    self.pieceKey = xmlFile:getValue(key .. "#pieceKey")
    self.row = xmlFile:getValue(key .. "#row", self.row)
    self.column = xmlFile:getValue(key .. "#column", self.column)
    return true
end
