-- Shared fixed values used across DynamicHalls' baseplate/marker/warning-stripe logic.
-- Named <SUBSYSTEM>_<PROPERTY> throughout so each constant's owner is clear at a glance.
DynamicHallsConstants = {}

-- This mod's own root folder. g_currentModDirectory is only valid while a mod's own source files
-- are being loaded, so it must be captured here rather than read again later (e.g. from a
-- loadMap event listener, which runs after loading finishes).
DynamicHallsConstants.MOD_DIRECTORY = g_currentModDirectory

-- Distance the leveling/tip-occlusion protected area extends beyond the baseplate's own
-- footprint on every side, in meters.
DynamicHallsConstants.LEVELING_PADDING = 2

-- Distance the placement overlap-check area (testArea) extends beyond the baseplate's own
-- footprint on every side, in meters.
DynamicHallsConstants.TEST_AREA_PADDING = 1

-- Height (Y size) of the testArea overlap-check box, in meters.
DynamicHallsConstants.TEST_AREA_HEIGHT = 10

-- Width of the warning-stripe border tiles, in meters.
DynamicHallsConstants.WARNING_STRIPE_THICKNESS = 0.5

-- Height (Y position) the warning-stripe tiles sit at above the ground, in meters.
DynamicHallsConstants.WARNING_STRIPE_HEIGHT = 0.01

-- Length of one warning-stripe tile segment, in meters.
DynamicHallsConstants.WARNING_STRIPE_TILE_LENGTH = 10

-- Distance below the baseplate's bare (unpadded) footprint edge that the interaction zone starts
-- at, in meters.
DynamicHallsConstants.INTERACTION_ZONE_GAP = 1

-- Width (X size) and depth (Z size) of the interaction trigger, in meters.
DynamicHallsConstants.INTERACTION_TRIGGER_WIDTH = 2
DynamicHallsConstants.INTERACTION_TRIGGER_DEPTH = 2

-- Depth (Z size) of the material unloadTrigger (constructible-mode material delivery spot), in
-- meters.
DynamicHallsConstants.INTERACTION_UNLOAD_TRIGGER_DEPTH = 1

-- Extra padding on the bottom edge's leveling/tip-occlusion area only, so it also covers the
-- interaction zone. The trigger and unloadTrigger sit side by side, not stacked, so only the
-- deeper of the two is added.
DynamicHallsConstants.LEVELING_BOTTOM_EDGE_EXTRA_PADDING = DynamicHallsConstants.INTERACTION_ZONE_GAP +
    math.max(DynamicHallsConstants.INTERACTION_TRIGGER_DEPTH, DynamicHallsConstants.INTERACTION_UNLOAD_TRIGGER_DEPTH)

-- Valid piece shop categories, in display order.
DynamicHallsConstants.PIECE_CATEGORIES = {
    { value = "wall",  titleKey = "dynamichalls_categoryWalls" },
    { value = "floor", titleKey = "dynamichalls_categoryFloors" },
    { value = "roof",  titleKey = "dynamichalls_categoryRoofs" },
}

-- Valid piece placement types, in display order.
DynamicHallsConstants.PIECE_PLACEMENT_TYPES = {
    { value = "wall", titleKey = "dynamichalls_placementTypeWall" },
    { value = "tile", titleKey = "dynamichalls_placementTypeTile" },
}
