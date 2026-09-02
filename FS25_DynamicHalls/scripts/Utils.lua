-- Project-wide helper functions, not specific to any one subsystem.
DynamicHallsUtils = {}

---Finds the entry in list (an array of tables each having a value field) whose value matches, or
-- nil if none does.
-- @param table list array of { value = ... } entries
-- @param any value value to match
function DynamicHallsUtils.findByValue(list, value)
    for _, entry in ipairs(list) do
        if entry.value == value then
            return entry
        end
    end
    return nil
end
