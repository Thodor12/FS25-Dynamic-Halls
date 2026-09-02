DynamicHallsGui = {}

---Loads the overview and build screens.
-- @param integer mapNode root node of the loaded map
function DynamicHallsGui:loadMap(mapNode)
    g_dynamicHallsOverviewScreen = DynamicHallsOverviewScreen.new()
    g_gui:loadGui(DynamicHallsConstants.MOD_DIRECTORY .. "gui/DynamicHallsOverviewScreen.xml",
        "dynamicHallsOverviewScreen", g_dynamicHallsOverviewScreen)

    g_dynamicHallsBuildScreen = DynamicHallsBuildScreen.new()
    g_gui:loadGui(DynamicHallsConstants.MOD_DIRECTORY .. "gui/DynamicHallsBuildScreen.xml",
        "dynamicHallsBuildScreen", g_dynamicHallsBuildScreen)
end

addModEventListener(DynamicHallsGui)
