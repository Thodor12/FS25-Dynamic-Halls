DynamicHallsInteractionTriggerActivatable = {}
local DynamicHallsInteractionTriggerActivatable_mt = Class(DynamicHallsInteractionTriggerActivatable)

---Creates a new activatable for the given placeable's interaction trigger.
-- @param table placeable the placeable instance
function DynamicHallsInteractionTriggerActivatable.new(placeable)
    local self = setmetatable({}, DynamicHallsInteractionTriggerActivatable_mt)
    self.placeable = placeable
    self.activateText = g_i18n:getText("dynamichalls_openMenu")
    return self
end

---Returns the distance from the given world position to the interaction trigger.
-- @param float x world X position
-- @param float y world Y position
-- @param float z world Z position
function DynamicHallsInteractionTriggerActivatable:getDistance(x, y, z)
    local interactionTriggerMapping = self.placeable.i3dMappings["interactionTrigger"]
    if interactionTriggerMapping == nil then
        return math.huge
    end

    local tx, ty, tz = getWorldTranslation(interactionTriggerMapping.nodeId)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---Opens the overview screen for this placeable.
function DynamicHallsInteractionTriggerActivatable:run()
    DynamicHallsOverviewScreen.show(self.placeable)
end
