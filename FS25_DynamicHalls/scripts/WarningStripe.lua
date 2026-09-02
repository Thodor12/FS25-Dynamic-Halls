-- Builds the yellow/black warning-stripe border tiles around a baseplate's footprint.
DynamicHallsWarningStripe = {}

---Loads the 4 tile shapes and places them around a footprint of the given size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.build(placeable, width, length)
    local rootNodeMapping = placeable.i3dMappings["warningStripe"]
    if rootNodeMapping == nil then
        return
    end
    local rootNodeId = rootNodeMapping.nodeId

    local function load(filename, callback)
        g_i3DManager:loadSharedI3DFileAsync(DynamicHallsConstants.MOD_DIRECTORY .. filename, true, true,
            function(_, i3dNode, _, shapeName)
                if i3dNode == 0 then
                    Logging.warning("DynamicHalls: failed to load warning-stripe tile shape '%s'", shapeName)
                    return
                end
                local templateNodeId = getChildAt(i3dNode, 0)
                removeFromPhysics(templateNodeId)
                link(rootNodeId, templateNodeId)
                delete(i3dNode)
                callback(templateNodeId, rootNodeId, width, length)
                delete(templateNodeId)
            end, nil, filename)
    end

    load("models/warningStripe/tileHorizontal.i3d", DynamicHallsWarningStripe.placeHorizontalTiles)
    load("models/warningStripe/tileVertical.i3d", DynamicHallsWarningStripe.placeVerticalTiles)
    load("models/warningStripe/tileCorner.i3d", DynamicHallsWarningStripe.placeCornerTiles)
    load("models/warningStripe/tileCornerInverted.i3d", DynamicHallsWarningStripe.placeCornerInvertedTiles)
end

---Clones templateNodeId and places the clone at the given position/rotation.
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the clone under
-- @param float x local X position
-- @param float z local Z position
-- @param bool rotateY whether to rotate the clone 180 degrees around Y
local function placeClone(templateNodeId, rootNodeId, x, z, rotateY)
    local nodeId = clone(templateNodeId, false, false, false)
    link(rootNodeId, nodeId)
    setTranslation(nodeId, x, DynamicHallsConstants.WARNING_STRIPE_HEIGHT, z)
    if rotateY then
        setRotation(nodeId, 0, math.pi, 0)
    end
    addToPhysics(nodeId)
end

---Places the tiles along the footprint's top and bottom edges.
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the tiles under
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.placeHorizontalTiles(templateNodeId, rootNodeId, width, length)
    local halfLength = length / 2
    local outerHalfLength = halfLength + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2
    local numTiles = width / DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH

    for i = 0, numTiles - 1 do
        local tileX = -width / 2 + DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH / 2 +
            i * DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH
        placeClone(templateNodeId, rootNodeId, tileX, outerHalfLength, true)
        placeClone(templateNodeId, rootNodeId, tileX, -outerHalfLength, false)
    end
end

---Places the tiles along the footprint's left and right edges.
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the tiles under
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.placeVerticalTiles(templateNodeId, rootNodeId, width, length)
    local halfWidth = width / 2
    local outerHalfWidth = halfWidth + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2
    local numTiles = length / DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH

    for i = 0, numTiles - 1 do
        local tileZ = -length / 2 + DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH / 2 +
            i * DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH
        placeClone(templateNodeId, rootNodeId, -outerHalfWidth, tileZ, true)
        placeClone(templateNodeId, rootNodeId, outerHalfWidth, tileZ, false)
    end
end

---Places the tiles at the footprint's top-left and bottom-right corners.
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the tiles under
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.placeCornerTiles(templateNodeId, rootNodeId, width, length)
    local outerHalfWidth = width / 2 + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2
    local outerHalfLength = length / 2 + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2

    placeClone(templateNodeId, rootNodeId, -outerHalfWidth, outerHalfLength, false)
    placeClone(templateNodeId, rootNodeId, outerHalfWidth, -outerHalfLength, false)
end

---Places the tiles at the footprint's top-right and bottom-left corners.
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the tiles under
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsWarningStripe.placeCornerInvertedTiles(templateNodeId, rootNodeId, width, length)
    local outerHalfWidth = width / 2 + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2
    local outerHalfLength = length / 2 + DynamicHallsConstants.WARNING_STRIPE_THICKNESS / 2

    placeClone(templateNodeId, rootNodeId, outerHalfWidth, outerHalfLength, false)
    placeClone(templateNodeId, rootNodeId, -outerHalfWidth, -outerHalfLength, false)
end
