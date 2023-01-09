local ns = select(2, ...)

ns.addon = CreateFrame("Frame")

local checkList = {
    adiBags = false,
    elvui = false
}

ns.addon:SetScript(
    "OnEvent",
    function(self, event, addon)
        if not checkList.adiBags and IsAddOnLoaded("AdiBags") then
            checkList.adiBags = true
        end

        if not checkList.elvui and IsAddOnLoaded("ElvUI") then
            checkList.elvui = true
        end

        if checkList.adiBags and checkList.elvui then
            self:UnregisterEvent("ADDON_LOADED")

            if _G.ElvUI[1].initialized then
                ns.reskin()
            else
                hooksecurefunc(
                    _G.ElvUI[1],
                    "Initialize",
                    function()
                        ns.reskin()
                    end
                )
            end
        end
    end
)

ns.addon:RegisterEvent("ADDON_LOADED")
