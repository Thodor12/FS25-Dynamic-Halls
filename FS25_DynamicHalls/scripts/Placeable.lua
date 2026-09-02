-- The DynamicHallsPlaceable specialization for the baseplate placeable. Reads the player's chosen
-- width/length configuration and delegates to DynamicHallsAreaMarkers/DynamicHallsWarningStripe
-- for the actual area-marker and visual setup.
DynamicHallsPlaceable = {}

---Returns whether this specialization's prerequisites are met. Always true; this spec has none.
-- @param table specializations specializations already present on the placeable type
function DynamicHallsPlaceable.prerequisitesPresent(specializations)
    return true
end

---Registers the width/length store configuration types.
function DynamicHallsPlaceable.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsWidth", "Width", "dynamicHallsWidth",
        PlaceableConfigurationItem)
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsLength", "Length", "dynamicHallsLength",
        PlaceableConfigurationItem)
end

---Registers this specialization's own instance functions on the placeable type.
-- @param table placeableType the placeable type to register onto
function DynamicHallsPlaceable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onInteractionTriggerCallback",
        DynamicHallsPlaceable.onInteractionTriggerCallback)
end

---Registers this specialization's event listeners on the placeable type.
-- @param table placeableType the placeable type to register onto
function DynamicHallsPlaceable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", DynamicHallsPlaceable)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", DynamicHallsPlaceable)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", DynamicHallsPlaceable)
end

---Registers the xml schema for this specialization's own placeable.xml fields.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPlaceable.registerXMLPaths(schema, basePath)
    local widthConfigPath = basePath ..
        ".dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, widthConfigPath .. "#value", "Footprint width in meters")

    local lengthConfigPath = basePath ..
        ".dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, lengthConfigPath .. "#value", "Footprint length in meters")
end

---Registers the xml schema for this specialization's own savegame fields.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPlaceable.registerSavegameXMLPaths(schema, basePath)
    DynamicHallsPlacedWallPiece.registerSavegameXMLPaths(schema, basePath .. ".wallPieces.wallPiece(?)")
    DynamicHallsPlacedTilePiece.registerSavegameXMLPaths(schema, basePath .. ".tilePieces.tilePiece(?)")
end

---Reads the width/length configuration and sets up the area markers and warning stripe.
-- @param table savegame savegame xml/key info, or nil for a freshly placed placeable
function DynamicHallsPlaceable:onLoad(savegame)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    local widthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsWidth"], 1)
    local widthConfigKey = string.format(
        "placeable.dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(%d)",
        widthConfigurationId - 1)
    spec.width = self.xmlFile:getValue(widthConfigKey .. "#value", 10)

    local lengthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsLength"], 1)
    local lengthConfigKey = string.format(
        "placeable.dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(%d)",
        lengthConfigurationId - 1)
    spec.length = self.xmlFile:getValue(lengthConfigKey .. "#value", 10)

    DynamicHallsAreaMarkers.repositionLevelingArea(self, spec.width, spec.length)
    DynamicHallsAreaMarkers.repositionTestArea(self, spec.width, spec.length)
    DynamicHallsAreaMarkers.repositionCollisionFloor(self, spec.width, spec.length)
    DynamicHallsAreaMarkers.repositionInteractionTrigger(self, spec.width, spec.length)

    DynamicHallsWarningStripe.build(self, spec.width, spec.length)

    self.interactionTriggerActivatable = DynamicHallsInteractionTriggerActivatable.new(self)

    spec.wallPieces = {}
    spec.tilePieces = {}
end

---Writes the placed wall/tile pieces to the savegame.
-- @param table xmlFile XMLFile to write to
-- @param string key xml path to this specialization's savegame element
-- @param table usedModNames set of mod names referenced by the savegame
function DynamicHallsPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    for i, wallPiece in ipairs(spec.wallPieces) do
        wallPiece:saveToXMLFile(xmlFile, string.format("%s.wallPieces.wallPiece(%d)", key, i - 1))
    end

    for i, tilePiece in ipairs(spec.tilePieces) do
        tilePiece:saveToXMLFile(xmlFile, string.format("%s.tilePieces.tilePiece(%d)", key, i - 1))
    end
end

---Reads the placed wall/tile pieces back from the savegame.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to this specialization's savegame element
-- @param bool resetVehicles whether vehicles are being reset on load
function DynamicHallsPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    for _, wallPieceKey in xmlFile:iterator(key .. ".wallPieces.wallPiece") do
        local wallPiece = DynamicHallsPlacedWallPiece.new()
        if wallPiece:loadFromXMLFile(xmlFile, wallPieceKey) then
            table.insert(spec.wallPieces, wallPiece)
        end
    end

    for _, tilePieceKey in xmlFile:iterator(key .. ".tilePieces.tilePiece") do
        local tilePiece = DynamicHallsPlacedTilePiece.new()
        if tilePiece:loadFromXMLFile(xmlFile, tilePieceKey) then
            table.insert(spec.tilePieces, tilePiece)
        end
    end
end

---Registers the interaction trigger callback once placement is finalized.
function DynamicHallsPlaceable:onFinalizePlacement()
    local interactionTriggerMapping = self.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping ~= nil then
        addTrigger(interactionTriggerMapping.nodeId, "onInteractionTriggerCallback", self)
    end

    -- TODO: test-only seed data to verify save/load, remove once confirmed working. Overwrites on
    -- every load for now so it's easy to tweak while iterating.
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]
    spec.wallPieces = {}
    spec.tilePieces = {}

    local testWallPiece = DynamicHallsPlacedWallPiece.new()
    testWallPiece.pieceKey = "wallBasic"
    testWallPiece.row = 0
    testWallPiece.column = 0
    testWallPiece.direction = DynamicHallsPlacedWallPiece.DIRECTION_HORIZONTAL
    table.insert(spec.wallPieces, testWallPiece)

    local testWindowPiece = DynamicHallsPlacedWallPiece.new()
    testWindowPiece.pieceKey = "wallWindow"
    testWindowPiece.row = 0
    testWindowPiece.column = 1
    testWindowPiece.direction = DynamicHallsPlacedWallPiece.DIRECTION_HORIZONTAL
    table.insert(spec.wallPieces, testWindowPiece)

    local testTilePiece = DynamicHallsPlacedTilePiece.new()
    testTilePiece.pieceKey = "floorBasic"
    testTilePiece.row = 0
    testTilePiece.column = 0
    table.insert(spec.tilePieces, testTilePiece)
end

---Removes the interaction trigger.
function DynamicHallsPlaceable:onDelete()
    local interactionTriggerMapping = self.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping ~= nil then
        removeTrigger(interactionTriggerMapping.nodeId)
    end
end

---Adds/removes the "open menu" activatable while the local player is inside the trigger.
-- @param integer triggerId the trigger node
-- @param integer otherId the actor that entered/left/stayed
-- @param bool onEnter true if the actor just entered
-- @param bool onLeave true if the actor just left
-- @param bool onStay true if the actor is still inside
function DynamicHallsPlaceable:onInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
        return
    end

    if onEnter then
        g_currentMission.activatableObjectsSystem:addActivatable(self.interactionTriggerActivatable)
    elseif onLeave then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.interactionTriggerActivatable)
    end
end
