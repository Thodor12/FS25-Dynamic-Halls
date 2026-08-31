-- The DynamicHallsPlaceable specialization for the baseplate placeable. Reads the player's chosen
-- width/length configuration and delegates to DynamicHallsAreaMarkers/DynamicHallsWarningStripe
-- for the actual area-marker and visual setup.
DynamicHallsPlaceable = {}

function DynamicHallsPlaceable.prerequisitesPresent(specializations)
    return true
end

function DynamicHallsPlaceable.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsWidth", "Width", "dynamicHallsWidth",
        PlaceableConfigurationItem)
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsLength", "Length", "dynamicHallsLength",
        PlaceableConfigurationItem)
end

function DynamicHallsPlaceable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onInteractionTriggerCallback",
        DynamicHallsPlaceable.onInteractionTriggerCallback)
end

function DynamicHallsPlaceable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", DynamicHallsPlaceable)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", DynamicHallsPlaceable)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", DynamicHallsPlaceable)
end

function DynamicHallsPlaceable.registerXMLPaths(schema, basePath)
    local widthConfigPath = basePath ..
        ".dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, widthConfigPath .. "#value", "Footprint width in meters")

    local lengthConfigPath = basePath ..
        ".dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, lengthConfigPath .. "#value", "Footprint length in meters")
end

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
end

function DynamicHallsPlaceable:onFinalizePlacement()
    local interactionTriggerMapping = self.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping ~= nil then
        addTrigger(interactionTriggerMapping.nodeId, "onInteractionTriggerCallback", self)
    end
end

function DynamicHallsPlaceable:onDelete()
    local interactionTriggerMapping = self.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping ~= nil then
        removeTrigger(interactionTriggerMapping.nodeId)
    end
end

function DynamicHallsPlaceable:onInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
        return
    end

    -- TODO: open the info/build menu here once implemented
    if onEnter then
        Logging.info("DynamicHallsPlaceable: player entered interaction trigger")
    elseif onLeave then
        Logging.info("DynamicHallsPlaceable: player left interaction trigger")
    end
end
