-- Repositions every i3d area marker that scales with a baseplate's footprint: leveling, testArea,
-- collision floor, interaction trigger.
DynamicHallsAreaMarkers = {}

---Repositions the leveling area's start/width/height marker nodes to match the given footprint
-- size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsAreaMarkers.repositionLevelingArea(placeable, width, length)
    local startNode = placeable.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#startNode", nil,
        placeable.components, placeable.i3dMappings)
    local widthNode = placeable.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#widthNode", nil,
        placeable.components, placeable.i3dMappings)
    local heightNode = placeable.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#heightNode", nil,
        placeable.components, placeable.i3dMappings)

    local halfWidth = width / 2
    local halfLength = length / 2
    local bottomEdgePadding = DynamicHallsConstants.LEVELING_PADDING +
        DynamicHallsConstants.LEVELING_BOTTOM_EDGE_EXTRA_PADDING

    if startNode ~= nil then
        setTranslation(startNode, -halfWidth - DynamicHallsConstants.LEVELING_PADDING, 0, -halfLength - bottomEdgePadding)
    end

    if widthNode ~= nil then
        setTranslation(widthNode, 0, 0, length + DynamicHallsConstants.LEVELING_PADDING + bottomEdgePadding)
    end

    if heightNode ~= nil then
        setTranslation(heightNode, width + 2 * DynamicHallsConstants.LEVELING_PADDING, 0, 0)
    end
end

---Repositions the testArea start/end marker nodes to match the given footprint size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsAreaMarkers.repositionTestArea(placeable, width, length)
    local testAreaStartMapping = placeable.i3dMappings["testAreaStart"]
    local testAreaEndMapping = placeable.i3dMappings["testAreaEnd"]

    if testAreaStartMapping ~= nil then
        setTranslation(testAreaStartMapping.nodeId, -width / 2 - DynamicHallsConstants.TEST_AREA_PADDING, 0,
            -length / 2 - DynamicHallsConstants.TEST_AREA_PADDING)
    end

    if testAreaEndMapping ~= nil then
        setTranslation(testAreaEndMapping.nodeId, width + 2 * DynamicHallsConstants.TEST_AREA_PADDING,
            DynamicHallsConstants.TEST_AREA_HEIGHT, length + 2 * DynamicHallsConstants.TEST_AREA_PADDING)
    end

    local placementSpec = placeable.spec_placement
    if placementSpec ~= nil and placementSpec.testAreas ~= nil then
        for i, area in ipairs(placementSpec.testAreas) do
            local key = string.format("placeable.placement.testAreas.testArea(%d)", i - 1)
            placeable:loadTestArea(placeable.xmlFile, key, area)
        end
    end
end

---Scales the collision floor to match the given footprint size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsAreaMarkers.repositionCollisionFloor(placeable, width, length)
    local collisionFloorMapping = placeable.i3dMappings["collisionFloor"]
    if collisionFloorMapping ~= nil then
        setTranslation(collisionFloorMapping.nodeId, 0, 0, 0)
        setScale(collisionFloorMapping.nodeId, width, 1, length)
    end
end

---Repositions the interaction trigger to match the given footprint size.
-- @param table placeable the placeable instance
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsAreaMarkers.repositionInteractionTrigger(placeable, width, length)
    local interactionTriggerMapping = placeable.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping ~= nil then
        setTranslation(interactionTriggerMapping.nodeId,
            -width / 2 + DynamicHallsConstants.INTERACTION_TRIGGER_WIDTH / 2, 0,
            -length / 2 - DynamicHallsConstants.INTERACTION_ZONE_GAP -
            DynamicHallsConstants.INTERACTION_TRIGGER_DEPTH / 2)
    end
end

