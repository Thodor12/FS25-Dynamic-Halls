-- Spawns the visible geometry for a baseplate's placed edge/tile pieces.
DynamicHallsPiecePlacement = {}

---Spawns geometry for every currently placed edge/tile piece on the given placeable.
-- @param table placeable the placeable instance
function DynamicHallsPiecePlacement.build(placeable)
    local spec = placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    for _, placedPiece in ipairs(spec.edgePieces) do
        DynamicHallsPiecePlacement.spawn(placeable, placedPiece)
    end
    for _, placedPiece in ipairs(spec.tilePieces) do
        DynamicHallsPiecePlacement.spawn(placeable, placedPiece)
    end
end

---Spawns geometry for a single placed piece, loading its piece type's clone-source template the
-- first time that type is needed on this placeable and reusing it for every later placement of
-- the same type. Skips the piece (with a warning) if it doesn't fit within the baseplate's grid.
-- @param table placeable the placeable instance
-- @param table placedPiece the PlacedEdgePiece/PlacedTilePiece to spawn
function DynamicHallsPiecePlacement.spawn(placeable, placedPiece)
    local rootNodeMapping = placeable.i3dMappings["pieces"]
    if rootNodeMapping == nil then
        return
    end
    local rootNodeId = rootNodeMapping.nodeId

    local pieceDefinition = g_dynamicHallsPackDefinitionManager:getPieceByKey(placedPiece.packKey, placedPiece.pieceKey)
    if pieceDefinition == nil then
        Logging.warning("DynamicHalls: unknown piece '%s.%s'", placedPiece.packKey, placedPiece.pieceKey)
        return
    end

    local spec = placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]
    local gridWidth = spec.width / DynamicHallsConstants.PIECE_CELL_SIZE
    local gridLength = spec.length / DynamicHallsConstants.PIECE_CELL_SIZE
    if not pieceDefinition.placement:isWithinGridBounds(placedPiece.row, placedPiece.column, placedPiece.rotation,
        gridWidth, gridLength) then
        Logging.warning("DynamicHalls: piece '%s.%s' at row=%d column=%d rotation=%d is outside the grid",
            placedPiece.packKey, placedPiece.pieceKey, placedPiece.row, placedPiece.column, placedPiece.rotation)
        return
    end

    DynamicHallsPiecePlacement.getOrLoadTemplateNodeId(placeable, placedPiece.packKey, pieceDefinition,
        function(templateNodeId)
            DynamicHallsPiecePlacement.placeClone(pieceDefinition, templateNodeId, rootNodeId, placeable, placedPiece)
        end)
end

---Calls callback(templateNodeId) with pieceDefinition's clone-source template node, loading it
-- the first time that piece type is needed on this placeable and reusing it for every later call.
-- Never calls callback if the load fails.
-- @param table placeable the placeable instance
-- @param string packKey pack key pieceDefinition belongs to
-- @param table pieceDefinition the piece whose template to get/load
-- @param function callback function(templateNodeId) called once the template is ready
function DynamicHallsPiecePlacement.getOrLoadTemplateNodeId(placeable, packKey, pieceDefinition, callback)
    local rootNodeMapping = placeable.i3dMappings["pieces"]
    if rootNodeMapping == nil then
        return
    end
    local rootNodeId = rootNodeMapping.nodeId

    local spec = placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]
    spec.pieceTemplateNodeIds = spec.pieceTemplateNodeIds or {}
    local templateKey = packKey .. "." .. pieceDefinition.key

    local templateNodeId = spec.pieceTemplateNodeIds[templateKey]
    if templateNodeId ~= nil then
        callback(templateNodeId)
        return
    end

    g_i3DManager:loadSharedI3DFileAsync(pieceDefinition.i3dFilename, true,
        true, function(_, i3dNode, _, _)
            if i3dNode == 0 then
                Logging.warning("DynamicHalls: failed to load piece i3d '%s'", pieceDefinition.i3dFilename)
                return
            end

            local meshNodeId = DynamicHallsPiecePlacement.findChildByName(i3dNode, "mesh")
            if meshNodeId == nil then
                Logging.warning("DynamicHalls: piece i3d '%s' has no 'mesh' node", pieceDefinition.i3dFilename)
                delete(i3dNode)
                return
            end

            removeFromPhysics(meshNodeId)
            link(rootNodeId, meshNodeId)
            setVisibility(meshNodeId, false)
            delete(i3dNode)

            spec.pieceTemplateNodeIds[templateKey] = meshNodeId
            callback(meshNodeId)
        end, nil, nil)
end

---Returns the direct child of nodeId with the given name, or nil if none has it.
-- @param integer nodeId node to search the children of
-- @param string name name to look for
function DynamicHallsPiecePlacement.findChildByName(nodeId, name)
    for i = 0, getNumOfChildren(nodeId) - 1 do
        local childNodeId = getChildAt(nodeId, i)
        if getName(childNodeId) == name then
            return childNodeId
        end
    end
    return nil
end

---Clones templateNodeId and places the clone at the given placed piece's grid position/rotation,
-- using pieceDefinition's own placement type to resolve the piece's visual center.
-- @param table pieceDefinition the piece being placed
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the clone under
-- @param table placeable the placeable instance
-- @param table placedPiece the PlacedEdgePiece/PlacedTilePiece to place
function DynamicHallsPiecePlacement.placeClone(pieceDefinition, templateNodeId, rootNodeId, placeable, placedPiece)
    local nodeId = DynamicHallsPiecePlacement.cloneAtGridPosition(pieceDefinition, templateNodeId, rootNodeId,
        placeable, placedPiece.row, placedPiece.column, placedPiece.rotation)
    addToPhysics(nodeId)
end

---Clones templateNodeId and moves/rotates the clone to the given grid position, using
-- pieceDefinition's own placement type to resolve the piece's visual center. Does not add the
-- clone to physics - callers that place the piece permanently must do that themselves.
-- @param table pieceDefinition the piece being placed
-- @param integer templateNodeId node to clone
-- @param integer rootNodeId node to link the clone under
-- @param table placeable the placeable instance
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
function DynamicHallsPiecePlacement.cloneAtGridPosition(pieceDefinition, templateNodeId, rootNodeId, placeable, row,
    column, rotation)
    local nodeId = clone(templateNodeId, false, false, false)
    link(rootNodeId, nodeId)
    setVisibility(nodeId, true)
    DynamicHallsPiecePlacement.updateNodePosition(pieceDefinition, nodeId, placeable, row, column, rotation)
    return nodeId
end

---Moves/rotates an already-placed/cloned node to the given grid position, using pieceDefinition's
-- own placement type to resolve the piece's visual center.
-- @param table pieceDefinition the piece being moved
-- @param integer nodeId node to move/rotate
-- @param table placeable the placeable instance
-- @param integer row grid row of the piece's own corner
-- @param integer column grid column of the piece's own corner
-- @param float rotation rotation around the piece's own corner, in degrees
function DynamicHallsPiecePlacement.updateNodePosition(pieceDefinition, nodeId, placeable, row, column, rotation)
    local spec = placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    local centerRow, centerColumn = pieceDefinition.placement:getWorldGridPosition(row, column, rotation)
    local x = -spec.width / 2 + centerColumn * DynamicHallsConstants.PIECE_CELL_SIZE
    local z = -spec.length / 2 + centerRow * DynamicHallsConstants.PIECE_CELL_SIZE

    setTranslation(nodeId, x, 0, z)
    setRotation(nodeId, 0, math.rad(rotation), 0)
end
