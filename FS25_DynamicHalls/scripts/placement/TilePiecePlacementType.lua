-- Footprint size and grid-bounds/placement math for pieces placed onto grid cells.
DynamicHallsTilePiecePlacementType = {}
local DynamicHallsTilePiecePlacementType_mt = Class(DynamicHallsTilePiecePlacementType)

---Registers the xml schema for a tile placement definition under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsTilePiecePlacementType.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".width", "Number of grid cells the piece spans along X")
    schema:register(XMLValueType.INT, basePath .. ".depth", "Number of grid cells the piece spans along Z")
end

---Creates a new, empty tile placement definition.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsTilePiecePlacementType.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsTilePiecePlacementType_mt)
    self.width = 1
    self.depth = 1
    return self
end

---Loads this placement's fields from its xml file. Returns false if the file is invalid.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to the tile element
function DynamicHallsTilePiecePlacementType:loadFromXMLFile(xmlFile, key)
    self.width = xmlFile:getValue(key .. ".width", self.width)
    self.depth = xmlFile:getValue(key .. ".depth", self.depth)
    return true
end

---Returns whether a tile piece placed at (row, column) with the given rotation stays within a
-- grid of the given size. A 90/270 degree rotation swaps which axis width/depth extend along.
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
-- @param integer gridWidth grid width, in cells
-- @param integer gridLength grid length, in cells
function DynamicHallsTilePiecePlacementType:isWithinGridBounds(row, column, rotation, gridWidth, gridLength)
    if row < 0 or row > gridLength or column < 0 or column > gridWidth then
        return false
    end

    local spanColumns, spanRows
    if rotation == 0 or rotation == 180 then
        spanColumns, spanRows = self.width, self.depth
    elseif rotation == 90 or rotation == 270 then
        spanColumns, spanRows = self.depth, self.width
    else
        return false
    end

    local endRow = row + spanRows
    local endColumn = column + spanColumns
    return endRow >= 0 and endRow <= gridLength and endColumn >= 0 and endColumn <= gridWidth
end

---Returns the grid row/column a tile piece's visual center sits at, given its own corner and
-- rotation.
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
function DynamicHallsTilePiecePlacementType:getWorldGridPosition(row, column, rotation)
    local spanColumns, spanRows = self.width, self.depth
    if rotation == 90 or rotation == 270 then
        spanColumns, spanRows = self.depth, self.width
    end

    return row + spanRows / 2, column + spanColumns / 2
end
