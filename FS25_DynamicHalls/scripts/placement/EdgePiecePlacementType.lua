-- Footprint size and grid-bounds/placement math for pieces placed along a grid edge.
DynamicHallsEdgePiecePlacementType = {}
local DynamicHallsEdgePiecePlacementType_mt = Class(DynamicHallsEdgePiecePlacementType)

---Registers the xml schema for an edge placement definition under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsEdgePiecePlacementType.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".length", "Number of grid edges the piece spans")
end

---Creates a new, empty edge placement definition.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsEdgePiecePlacementType.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsEdgePiecePlacementType_mt)
    self.length = 1
    return self
end

---Loads this placement's fields from its xml file. Returns false if the file is invalid.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to the edge element
function DynamicHallsEdgePiecePlacementType:loadFromXMLFile(xmlFile, key)
    self.length = xmlFile:getValue(key .. ".length", self.length)
    return true
end

---Returns whether an edge piece placed at (row, column) with the given rotation stays within a
-- grid of the given size.
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
-- @param integer gridWidth grid width, in cells
-- @param integer gridLength grid length, in cells
function DynamicHallsEdgePiecePlacementType:isWithinGridBounds(row, column, rotation, gridWidth, gridLength)
    if row < 0 or row > gridLength or column < 0 or column > gridWidth then
        return false
    end

    local endRow, endColumn = row, column
    if rotation == 0 then
        endColumn = column + self.length
    elseif rotation == 90 then
        endRow = row + self.length
    elseif rotation == 180 then
        endColumn = column - self.length
    elseif rotation == 270 then
        endRow = row - self.length
    else
        return false
    end

    return endRow >= 0 and endRow <= gridLength and endColumn >= 0 and endColumn <= gridWidth
end

---Returns the grid row/column an edge piece's visual center sits at, given its own start corner
-- and rotation.
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
function DynamicHallsEdgePiecePlacementType:getWorldGridPosition(row, column, rotation)
    local halfLength = self.length / 2

    if rotation == 0 then
        column = column + halfLength
    elseif rotation == 90 then
        row = row + halfLength
    elseif rotation == 180 then
        column = column - halfLength
    elseif rotation == 270 then
        row = row - halfLength
    end

    return row, column
end
