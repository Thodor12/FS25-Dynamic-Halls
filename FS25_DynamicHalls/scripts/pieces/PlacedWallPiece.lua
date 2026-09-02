DynamicHallsPlacedWallPiece = {}
local DynamicHallsPlacedWallPiece_mt = Class(DynamicHallsPlacedWallPiece)

DynamicHallsPlacedWallPiece.DIRECTION_HORIZONTAL = "horizontal"
DynamicHallsPlacedWallPiece.DIRECTION_VERTICAL = "vertical"

---Registers the xml schema for a placed wall piece's savegame fields under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPlacedWallPiece.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#pieceKey", "Piece definition key")
    schema:register(XMLValueType.INT, basePath .. "#row", "Grid row")
    schema:register(XMLValueType.INT, basePath .. "#column", "Grid column")
    schema:register(XMLValueType.STRING, basePath .. "#direction", "horizontal or vertical")
end

---Creates a new, empty placed wall piece.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPlacedWallPiece.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsPlacedWallPiece_mt)
    self.pieceKey = nil
    self.row = 0
    self.column = 0
    self.direction = DynamicHallsPlacedWallPiece.DIRECTION_HORIZONTAL
    return self
end

---Writes this piece's fields to the savegame.
-- @param table xmlFile XMLFile to write to
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedWallPiece:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#pieceKey", self.pieceKey)
    xmlFile:setValue(key .. "#row", self.row)
    xmlFile:setValue(key .. "#column", self.column)
    xmlFile:setValue(key .. "#direction", self.direction)
end

---Reads this piece's fields back from the savegame. Always returns true.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedWallPiece:loadFromXMLFile(xmlFile, key)
    self.pieceKey = xmlFile:getValue(key .. "#pieceKey")
    self.row = xmlFile:getValue(key .. "#row", self.row)
    self.column = xmlFile:getValue(key .. "#column", self.column)
    self.direction = xmlFile:getValue(key .. "#direction", self.direction)
    return true
end
