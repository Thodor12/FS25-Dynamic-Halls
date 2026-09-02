-- One piece placed along a grid edge on a baseplate: which piece, where, and how rotated.
DynamicHallsPlacedEdgePiece = {}
local DynamicHallsPlacedEdgePiece_mt = Class(DynamicHallsPlacedEdgePiece)

---Registers the xml schema for a placed edge piece's savegame fields under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPlacedEdgePiece.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#packKey", "Pack definition key")
    schema:register(XMLValueType.STRING, basePath .. "#pieceKey", "Piece definition key, unique within its pack")
    schema:register(XMLValueType.INT, basePath .. "#row", "Grid row")
    schema:register(XMLValueType.INT, basePath .. "#column", "Grid column")
    schema:register(XMLValueType.FLOAT, basePath .. "#rotation", "Rotation around the piece's own pivot, in degrees")
end

---Creates a new, empty placed edge piece.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPlacedEdgePiece.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsPlacedEdgePiece_mt)
    self.packKey = nil
    self.pieceKey = nil
    self.row = 0
    self.column = 0
    self.rotation = 0
    return self
end

---Writes this piece's fields to the savegame.
-- @param table xmlFile XMLFile to write to
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedEdgePiece:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#packKey", self.packKey)
    xmlFile:setValue(key .. "#pieceKey", self.pieceKey)
    xmlFile:setValue(key .. "#row", self.row)
    xmlFile:setValue(key .. "#column", self.column)
    xmlFile:setValue(key .. "#rotation", self.rotation)
end

---Reads this piece's fields back from the savegame. Always returns true.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to this piece's savegame element
function DynamicHallsPlacedEdgePiece:loadFromXMLFile(xmlFile, key)
    self.packKey = xmlFile:getValue(key .. "#packKey")
    self.pieceKey = xmlFile:getValue(key .. "#pieceKey")
    self.row = xmlFile:getValue(key .. "#row", self.row)
    self.column = xmlFile:getValue(key .. "#column", self.column)
    self.rotation = xmlFile:getValue(key .. "#rotation", self.rotation)
    return true
end
