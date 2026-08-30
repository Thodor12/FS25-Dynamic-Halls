-- Shared fixed values used across DynamicHalls' baseplate/marker/warning-stripe logic, kept in
-- one place instead of being duplicated (and risking drifting out of sync) across multiple files.
DynamicHallsConstants = {}

-- Distance the leveling/tip-occlusion protected area extends beyond the baseplate's own
-- footprint, in meters.
DynamicHallsConstants.LEVELING_PADDING = 2

-- Height (Y size) of the testArea overlap-check box, in meters.
DynamicHallsConstants.TEST_AREA_HEIGHT = 10

-- Width of the warning-stripe border tiles, in meters. The collision floor is sized to extend
-- out to the stripe's outer edge, so this must stay in sync with that.
DynamicHallsConstants.STRIP_THICKNESS = 0.5

-- Height (Y position) the warning-stripe tiles sit at above the ground, in meters.
DynamicHallsConstants.STRIP_HEIGHT = 0.01

-- Length of one warning-stripe tile segment, in meters.
DynamicHallsConstants.TILE_LENGTH = 10
