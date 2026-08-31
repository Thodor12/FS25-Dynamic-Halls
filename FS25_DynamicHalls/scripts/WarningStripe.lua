-- Builds the yellow/black warning-stripe border tiles around a baseplate's footprint. Purely
-- visual.
DynamicHallsWarningStripe = {}

---Clones and positions the warning-stripe tiles around a footprint of the given size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.build(placeable, width, length)
    local halfWidth = width / 2
    local halfLength = length / 2
    local outerHalfWidth = halfWidth + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2
    local outerHalfLength = halfLength + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2

    local tileHorizontalMapping = placeable.i3dMappings["tileHorizontal"]
    local tileVerticalMapping = placeable.i3dMappings["tileVertical"]
    local tileCornerMapping = placeable.i3dMappings["tileCorner"]
    local tileCornerInvertedMapping = placeable.i3dMappings["tileCornerInverted"]

    if tileHorizontalMapping == nil or tileVerticalMapping == nil or tileCornerMapping == nil or tileCornerInvertedMapping == nil then
        return
    end

    local rootNodeId = getParent(tileHorizontalMapping.nodeId)
    local numTilesWidth = width / DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH
    local numTilesLength = length / DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH

    local function placeClone(templateNodeId, x, z, rotateY)
        local nodeId = clone(templateNodeId, false, false, false)
        link(rootNodeId, nodeId)
        setTranslation(nodeId, x, DynamicHallsConstants.WARNING_STRIPE_HEIGHT, z)
        if rotateY then
            setRotation(nodeId, 0, math.pi, 0)
        end
    end

    for i = 0, numTilesWidth - 1 do
        local tileX = -halfWidth + DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH / 2 + i * DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH
        placeClone(tileHorizontalMapping.nodeId, tileX, outerHalfLength, true)
        placeClone(tileHorizontalMapping.nodeId, tileX, -outerHalfLength, false)
    end

    for i = 0, numTilesLength - 1 do
        local tileZ = -halfLength + DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH / 2 + i * DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH
        placeClone(tileVerticalMapping.nodeId, -outerHalfWidth, tileZ, true)
        placeClone(tileVerticalMapping.nodeId, outerHalfWidth, tileZ, false)
    end

    placeClone(tileCornerMapping.nodeId, -outerHalfWidth, outerHalfLength, false)
    placeClone(tileCornerInvertedMapping.nodeId, outerHalfWidth, outerHalfLength, false)
    placeClone(tileCornerInvertedMapping.nodeId, -outerHalfWidth, -outerHalfLength, false)
    placeClone(tileCornerMapping.nodeId, outerHalfWidth, -outerHalfLength, false)

    setVisibility(tileHorizontalMapping.nodeId, false)
    setVisibility(tileVerticalMapping.nodeId, false)
    setVisibility(tileCornerMapping.nodeId, false)
    setVisibility(tileCornerInvertedMapping.nodeId, false)
end
