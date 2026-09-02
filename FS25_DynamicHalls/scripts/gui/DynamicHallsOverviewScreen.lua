DynamicHallsOverviewScreen = {}
local DynamicHallsOverviewScreen_mt = Class(DynamicHallsOverviewScreen, ScreenElement)

---Shows the overview screen for the given placeable.
-- @param table placeable the placeable instance
function DynamicHallsOverviewScreen.show(placeable)
    g_dynamicHallsOverviewScreen:setPlaceable(placeable)
    g_gui:showGui("dynamicHallsOverviewScreen")
end

---Creates a new overview screen controller.
-- @param table custom_mt optional metatable to use instead of the default
function DynamicHallsOverviewScreen.new(custom_mt)
    local self = ScreenElement.new(nil, custom_mt or DynamicHallsOverviewScreen_mt)
    return self
end

---Sets the placeable this screen shows the overview for.
-- @param table placeable the placeable instance
function DynamicHallsOverviewScreen:setPlaceable(placeable)
    self.placeable = placeable
end

---Wires up the piece list's data source and selects the (only) tab.
function DynamicHallsOverviewScreen:onGuiSetupFinished()
    DynamicHallsOverviewScreen:superClass().onGuiSetupFinished(self)
    self.pieceList:setDataSource(self)
    self.tabOverview:setSelected(true)
end

---Rebuilds the piece summary and materials marquee for the current placeable.
function DynamicHallsOverviewScreen:onOpen()
    DynamicHallsOverviewScreen:superClass().onOpen(self)
    self:updatePieceSummary()
    self.pieceList:reloadData()
    self.totalPriceText:setValue(self.totalPrice)
    self:populateMaterialsMarquee()
end

---Advances the materials marquee scroll animation.
-- @param integer dt frame delta time in ms
function DynamicHallsOverviewScreen:update(dt)
    DynamicHallsOverviewScreen:superClass().update(self, dt)
    self:updateMaterialsMarqueeAnimation(dt)
end

---Recomputes pieceRows/totalPrice/totalMaterials from the placeable's currently placed pieces.
function DynamicHallsOverviewScreen:updatePieceSummary()
    local spec = self.placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    local countsByPieceKey = {}
    for _, placedPiece in ipairs(spec.wallPieces) do
        countsByPieceKey[placedPiece.pieceKey] = (countsByPieceKey[placedPiece.pieceKey] or 0) + 1
    end
    for _, placedPiece in ipairs(spec.tilePieces) do
        countsByPieceKey[placedPiece.pieceKey] = (countsByPieceKey[placedPiece.pieceKey] or 0) + 1
    end

    self.pieceRows = {}
    self.totalPrice = 0

    local totalAmountByFillType = {}
    local isAlternateGroup = false
    for pieceKey, qty in pairs(countsByPieceKey) do
        local pieceDefinition = g_dynamicHallsPieceDefinitionManager:getPieceByKey(pieceKey)
        if pieceDefinition ~= nil then
            local price = pieceDefinition.price * qty
            self.totalPrice = self.totalPrice + price

            for materialIndex, material in ipairs(pieceDefinition.materials) do
                local amount = material.amount * qty

                local existing = totalAmountByFillType[material.fillType]
                totalAmountByFillType[material.fillType] = (existing or 0) + amount

                table.insert(self.pieceRows, {
                    name = materialIndex == 1 and pieceDefinition.name or nil,
                    qty = materialIndex == 1 and qty or nil,
                    price = materialIndex == 1 and price or nil,
                    fillType = material.fillType,
                    amount = amount,
                    isAlternate = isAlternateGroup,
                })
            end

            isAlternateGroup = not isAlternateGroup
        end
    end

    self.totalMaterials = {}
    for fillType, amount in pairs(totalAmountByFillType) do
        table.insert(self.totalMaterials, { fillType = fillType, amount = amount })
    end
    table.sort(self.totalMaterials, function(a, b)
        return a.fillType.name < b.fillType.name
    end)
end

---Returns the number of rows in the piece list.
-- @param table list the SmoothList requesting the count
-- @param integer section list section index
function DynamicHallsOverviewScreen:getNumberOfItemsInSection(list, section)
    return #self.pieceRows
end

---Fills a piece list row's cell with its piece/quantity/price/material data.
-- @param table list the SmoothList requesting the cell
-- @param integer section list section index
-- @param integer index row index within the section
-- @param table cell the cell element to populate
function DynamicHallsOverviewScreen:populateCellForItemInSection(list, section, index, cell)
    local row = self.pieceRows[index]
    cell:getAttribute("pieceName"):setText(row.name or "")
    cell:getAttribute("qty"):setText(row.qty and ("x" .. row.qty) or "")
    if row.price ~= nil then
        cell:getAttribute("price"):setValue(row.price)
    else
        cell:getAttribute("price"):setText("")
    end
    cell:getAttribute("materialIcon"):setImageFilename(row.fillType.hudOverlayFilename)
    cell:getAttribute("materialAmount"):setText(string.format("%d l", row.amount))
    cell:getAttribute("rowBackground"):applyProfile(
        row.isAlternate and "fs25_dynamicHallsPieceListItemRowAlternate" or "fs25_dynamicHallsPieceListItemRow")
end

---Rebuilds the materials marquee's icon/amount elements from totalMaterials and starts/stops its
-- scroll animation depending on whether the content overflows the visible width.
function DynamicHallsOverviewScreen:populateMaterialsMarquee()
    local iconsBox = self.materialsMarqueeIconsBox
    local amountsBox = self.materialsMarqueeAmountsBox

    for i = #iconsBox.elements, 1, -1 do
        local element = iconsBox.elements[i]
        if element ~= self.materialsMarqueeIconTemplate then
            element:delete()
        end
    end
    for i = #amountsBox.elements, 1, -1 do
        local element = amountsBox.elements[i]
        if element ~= self.materialsMarqueeAmountTemplate then
            element:delete()
        end
    end

    local totalWidth = 0
    for _, material in ipairs(self.totalMaterials) do
        local icon = self.materialsMarqueeIconTemplate:clone(iconsBox)
        icon:setVisible(true)
        icon:setImageFilename(material.fillType.hudOverlayFilename)
        totalWidth = totalWidth + icon.absSize[1] + icon.margin[1] + icon.margin[3]

        local amountText = self.materialsMarqueeAmountTemplate:clone(amountsBox)
        amountText:setVisible(true)
        amountText:setText(DynamicHallsOverviewScreen.formatMaterialAmount(material.amount) .. ' l')
    end

    iconsBox:setSize(totalWidth, nil)
    iconsBox:setPosition(0, nil)
    amountsBox:setSize(totalWidth, nil)
    amountsBox:setPosition(0, nil)
    iconsBox:invalidateLayout()
    amountsBox:invalidateLayout()

    local visibleWidth = self.materialsMarqueeClip.absSize[1]
    if visibleWidth < totalWidth then
        self.materialsMarqueeTime = 0
    else
        self.materialsMarqueeTime = nil
    end
end

---Advances the ping-pong scroll offset of the materials marquee.
-- @param integer dt frame delta time in ms
function DynamicHallsOverviewScreen:updateMaterialsMarqueeAnimation(dt)
    if self.materialsMarqueeTime == nil then
        return
    end

    local iconsBox = self.materialsMarqueeIconsBox
    local contentWidth = iconsBox.absSize[1]
    local visibleWidth = self.materialsMarqueeClip.absSize[1]
    local scrollAmount = contentWidth - visibleWidth
    local scrollLengthFactor = contentWidth / visibleWidth
    local scrollDuration = 5000 * scrollLengthFactor

    local time = self.materialsMarqueeTime + dt
    if scrollDuration <= time then
        time = -scrollDuration
    end

    local alpha = MathUtil.smoothstep(0.1, 0.9, math.abs(time) / scrollDuration)
    local offset = scrollAmount * alpha
    iconsBox:setPosition(-offset, nil)
    self.materialsMarqueeAmountsBox:setPosition(-offset, nil)
    self.materialsMarqueeTime = time
end

---Formats a liter amount as a rough k/m-abbreviated string for the materials marquee.
-- @param float amount amount in liters
function DynamicHallsOverviewScreen.formatMaterialAmount(amount)
    if amount < 10000 then
        return tostring(math.floor(amount))
    elseif amount < 1000000 then
        return math.floor(amount / 1000) .. "k"
    elseif amount < 1000000000 then
        return math.floor(amount / 1000000) .. "m"
    else
        return "999m+"
    end
end

---Closes the overview screen.
function DynamicHallsOverviewScreen:onClickBack()
    self:changeScreen(nil)
end

---Opens the build screen for the current placeable.
function DynamicHallsOverviewScreen:onClickOpenBuildMenu()
    DynamicHallsBuildScreen.show(self.placeable)
end

---Buys and places every remaining piece instantly.
function DynamicHallsOverviewScreen:onClickBuyInstantly()
    -- TODO: buy-instantly flow
end

---Starts the gradual construction flow.
function DynamicHallsOverviewScreen:onClickConstruct()
    -- TODO: construction flow
end
