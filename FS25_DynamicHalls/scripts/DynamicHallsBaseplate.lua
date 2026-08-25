DynamicHallsBaseplate = {}

function DynamicHallsBaseplate.prerequisitesPresent(specializations)
    return true
end

function DynamicHallsBaseplate.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsWidth", "Width", "dynamicHallsWidth", PlaceableConfigurationItem)
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsLength", "Length", "dynamicHallsLength", PlaceableConfigurationItem)
end

function DynamicHallsBaseplate.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", DynamicHallsBaseplate)
end

function DynamicHallsBaseplate.registerXMLPaths(schema, basePath)
    local widthConfigPath = basePath .. ".dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, widthConfigPath .. "#value", "Footprint width in meters")

    local lengthConfigPath = basePath .. ".dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, lengthConfigPath .. "#value", "Footprint length in meters")
end

function DynamicHallsBaseplate:onLoad(savegame)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsBaseplate"]

    local widthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsWidth"], 1)
    local widthConfigKey = string.format("placeable.dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(%d)", widthConfigurationId - 1)
    spec.width = self.xmlFile:getValue(widthConfigKey .. "#value", 10)

    local lengthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsLength"], 1)
    local lengthConfigKey = string.format("placeable.dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(%d)", lengthConfigurationId - 1)
    spec.length = self.xmlFile:getValue(lengthConfigKey .. "#value", 10)

    local startNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#startNode", nil, self.components, self.i3dMappings)
    local widthNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#widthNode", nil, self.components, self.i3dMappings)
    local heightNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#heightNode", nil, self.components, self.i3dMappings)

    local levelingPad = 1
    local halfWidth = spec.width / 2
    local halfLength = spec.length / 2

    if startNode ~= nil then
        setTranslation(startNode, -halfWidth - levelingPad, 0, -halfLength - levelingPad)
    end

    if widthNode ~= nil then
        setTranslation(widthNode, halfWidth + levelingPad, 0, -halfLength - levelingPad)
    end

    if heightNode ~= nil then
        setTranslation(heightNode, -halfWidth - levelingPad, 0, halfLength + levelingPad)
    end

    local markerMapping = self.i3dMappings["marker"]
    if markerMapping ~= nil then
        local markerBaseSize = 0.25
        setTranslation(markerMapping.nodeId, 0, 0, 0)
        setScale(markerMapping.nodeId, spec.width / markerBaseSize, 1, spec.length / markerBaseSize)
    end
end
