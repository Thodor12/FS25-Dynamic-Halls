-- Builds the yellow/black warning-stripe border tiles around a baseplate's footprint.
-- Purely visual - clones a fixed set of template tile shapes (corner, corner-inverted,
-- horizontal, vertical) from the i3d, positions/rotates copies to trace the footprint's outer
-- edge at the given width/length. The templates themselves are hidden (not deleted) afterward,
-- since a future edit/resize mode may need to re-run this and clone fresh tiles again.
DynamicHallsWarningStripe = {}

---Clones and positions the warning-stripe tiles around a footprint of the given size.
-- @param table placeable the placeable instance (used for i3dMappings)
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.build(placeable, width, length)
    local halfWidth = width / 2
    local halfLength = length / 2
    local outerHalfWidth = halfWidth + DynamicHallsConstants.STRIP_THICKNESS / 2
    local outerHalfLength = halfLength + DynamicHallsConstants.STRIP_THICKNESS / 2

    local tileHorizontalMapping = placeable.i3dMappings["tileHorizontal"]
    local tileVerticalMapping = placeable.i3dMappings["tileVertical"]
    local tileCornerMapping = placeable.i3dMappings["tileCorner"]
    local tileCornerInvertedMapping = placeable.i3dMappings["tileCornerInverted"]

    if tileHorizontalMapping == nil or tileVerticalMapping == nil or tileCornerMapping == nil or tileCornerInvertedMapping == nil then
        return
    end

    local rootNodeId = getParent(tileHorizontalMapping.nodeId)
    local numTilesWidth = width / DynamicHallsConstants.TILE_LENGTH
    local numTilesLength = length / DynamicHallsConstants.TILE_LENGTH

    local function placeClone(templateNodeId, x, z, rotateY)
        local nodeId = clone(templateNodeId, false, false, false)
        link(rootNodeId, nodeId)
        setTranslation(nodeId, x, DynamicHallsConstants.STRIP_HEIGHT, z)
        if rotateY then
            setRotation(nodeId, 0, math.pi, 0)
        end
    end

    -- Top and bottom rows (horizontal tiles running along X, spanning exactly width, sitting just outside the footprint)
    for i = 0, numTilesWidth - 1 do
        local tileX = -halfWidth + DynamicHallsConstants.TILE_LENGTH / 2 + i * DynamicHallsConstants.TILE_LENGTH
        placeClone(tileHorizontalMapping.nodeId, tileX, outerHalfLength, true)
        placeClone(tileHorizontalMapping.nodeId, tileX, -outerHalfLength, false)
    end

    -- Left and right columns (vertical tiles running along Z, spanning exactly length, sitting just outside the footprint)
    for i = 0, numTilesLength - 1 do
        local tileZ = -halfLength + DynamicHallsConstants.TILE_LENGTH / 2 + i * DynamicHallsConstants.TILE_LENGTH
        placeClone(tileVerticalMapping.nodeId, -outerHalfWidth, tileZ, true)
        placeClone(tileVerticalMapping.nodeId, outerHalfWidth, tileZ, false)
    end

    -- 4 corner tiles filling the small gap left between the horizontal and vertical runs
    -- Top-right and bottom-left use the inverted variant; top-left and bottom-right use the normal one
    placeClone(tileCornerMapping.nodeId, -outerHalfWidth, outerHalfLength, false)
    placeClone(tileCornerInvertedMapping.nodeId, outerHalfWidth, outerHalfLength, false)
    placeClone(tileCornerInvertedMapping.nodeId, -outerHalfWidth, -outerHalfLength, false)
    placeClone(tileCornerMapping.nodeId, outerHalfWidth, -outerHalfLength, false)

    -- Hide the templates instead of deleting them, so a future edit/resize mode can re-run this
    -- and clone fresh tiles again rather than needing to re-load the whole i3d.
    setVisibility(tileHorizontalMapping.nodeId, false)
    setVisibility(tileVerticalMapping.nodeId, false)
    setVisibility(tileCornerMapping.nodeId, false)
    setVisibility(tileCornerInvertedMapping.nodeId, false)
end
