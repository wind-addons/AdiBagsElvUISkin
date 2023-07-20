local n, ns = ...

local E = _G.ElvUI and _G.ElvUI[1]
local S = E and E:GetModule("Skins")
local AB = _G.LibStub("AceAddon-3.0"):GetAddon("AdiBags", true)

local function hook(className, method, pre, post, disableRawFunction)
    local class = AB and AB.GetClass and AB:GetClass(className)
    local rawFunction = class and class.metatable and class.metatable.__index[method]
    if rawFunction then
        if class and class.metatable and class.metatable.__index then
            class.metatable.__index[method] = function(self, ...)
                local result
                local argTable = {...}
                if pre then
                    pre(self, argTable)
                end

                if not disableRawFunction then
                    result = rawFunction(self, unpack(argTable))
                end

                if post then
                    result = post(self, argTable, result)
                end

                return result
            end
        end
    end
end

local function postHandleFrame(class, method, func)
    local rawFunction = class and class[method]
    if rawFunction then
        class[method] = function(...)
            local frame = rawFunction(...)
            if frame then
                func(frame)
            end
            return frame
        end
    end
end

local function handleExistingFrames(name, func)
    local pool = AB.GetPool and AB:GetPool(name)
    if pool then
        for frame in pool:IterateAllObjects() do
            func(frame)
        end
    end
end

local skin = {}

function skin:AdiBags_CreateBagSlotPanel()
    if self.__adiBagsElvUISkin then
        return
    end

    self:SetTemplate("Transparent")
    self.SetBackdrop = E.noop
    self.SetBackdropColor = E.noop
    self.SetBackdropBorderColor = E.noop

    self.__adiBagsElvUISkin = true

    ns.callApi("frame", self)
end

function skin:Container_OnCreate()
    if self.__adiBagsElvUISkin then
        return
    end

    self:SetTemplate("Transparent")
    self.SetBackdrop = E.noop
    self.SetBackdropColor = E.noop
    self.SetBackdropBorderColor = E.noop

    self.CloseButton.Text:Hide()
    self.CloseButton.isSkinned = false
    S:HandleCloseButton(self.CloseButton)
    self.CloseButton:SetHitRectInsets(1, 1, 2, 2)

    self.BagSlotButton:CreateBackdrop()
    self.BagSlotButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
    self.BagSlotButton:SetCheckedTexture(E.Media.Textures.White8x8)
    self.BagSlotButton:GetCheckedTexture():SetVertexColor(1, 1, 1, 0.5)
    self.BagSlotButton:SetHighlightTexture(E.Media.Textures.White8x8)
    self.BagSlotButton:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)

    local searchBox = _G[self:GetName() .. "SearchBox"]
    S:HandleEditBox(searchBox)

    self.__adiBagsElvUISkin = true

    ns.callApi("frame", self)
end

function skin:Container_CreateModuleButton(argTable, button)
    S:HandleButton(button)
    ns.callApi("moduleButton", button)
    return button
end

function skin:ItemButton_OnCreate()
    if not (self.GetObjectType and self:GetObjectType() == "Button") then
        return
    end

    if self.__adiBagsElvUISkin then
        return
    end

    self:SetTemplate("Transparent")
    self:StyleButton()

    self.SetBackdrop = E.noop
    self.SetBackdropColor = E.noop

    local setBackdropBorderColor = self.SetBackdropBorderColor
    self.SetBackdropBorderColor = E.noop

    if self.Cooldown then
        E:RegisterCooldown(self.Cooldown, "bags")
    end

    local questOverlay = self:CreateTexture(nil, "OVERLAY")
    questOverlay:SetTexture(E.Media.Textures.BagQuestIcon)
    questOverlay:SetTexCoord(0, 1, 0, 1)
    questOverlay:SetAllPoints(self.Center)
    questOverlay:Hide()

    local junkOverlay = self:CreateTexture(nil, "OVERLAY")
    junkOverlay:SetTexture(E.Media.Textures.White8x8)
    junkOverlay:SetVertexColor(0.5, 0.5, 0.5, 1)
    junkOverlay:SetAllPoints(self.Center)
    junkOverlay:SetBlendMode("MOD")
    junkOverlay:Hide()

    local normalTex = self.NormalTexture or _G[self:GetName() .. "NormalTexture"]
    if normalTex then
        normalTex:SetAlpha(0)
    end

    self:SetHighlightTexture(E.Media.Textures.White8x8)
    self:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)

    self:SetPushedTexture(E.Media.Textures.White8x8)
    self:GetPushedTexture():SetVertexColor(1, 1, 1, 0.3)

    self.icon:SetTexCoord(unpack(E.TexCoords))
    self.icon:SetInside()

    if self.IconTexture and self.IconTexture:GetObjectType() == "Texture" then
        local setTexture = self.IconTexture.SetTexture
        self.IconTexture:SetTexCoord(unpack(E.TexCoords))
        self.IconTexture.SetTexCoord = E.noop
        hooksecurefunc(
            self.IconTexture,
            "SetTexture",
            function(texture, path)
                if texture and path and path == [[Interface\BUTTONS\UI-EmptySlot]] then
                    setTexture(texture, "")
                end
            end
        )
    end

    if self.IconBorder then
        self.IconBorder:SetTexture("")
        self.IconBorder:Hide()
        self.IconBorder.Show = E.noop
        self.IconBorder.SetTexture = E.noop

        hooksecurefunc(
            self.IconBorder,
            "SetVertexColor",
            function(tex)
                local r, g, b, a = tex:GetVertexColor()
                if not (r == 1 and g == 1 and b == 1) then
                    setBackdropBorderColor(self, r, g, b, a)
                    junkOverlay:Hide()
                else
                    setBackdropBorderColor(self, unpack(E.media.bordercolor))
                    junkOverlay:Show()
                end
            end
        )

        hooksecurefunc(
            self.IconBorder,
            "Hide",
            function(tex)
                setBackdropBorderColor(self, unpack(E.media.bordercolor))
                junkOverlay:Hide()
            end
        )
    end

    if self.IconQuestTexture then
        local isShown = self.IconQuestTexture:IsShown()
        self.IconQuestTexture:SetTexture("")
        self.IconQuestTexture:Hide()

        self.IconQuestTexture.Show = function()
            questOverlay:Show()
            setBackdropBorderColor(self, 1, 0.8, 0, 1)
        end
        self.IconQuestTexture.Hide = function()
            questOverlay:Hide()
            setBackdropBorderColor(self, unpack(E.media.bordercolor))
        end

        if isShown then
            self.IconQuestTexture:Show()
        else
            self.IconQuestTexture:Hide()
        end
    end

    self.__adiBagsElvUISkin = true

    ns.callApi("itemButton", self)
end

function ns.reskin()
    if not AB or not E or not S then
        return
    end

    if
        AB.db.profile["modules"] and
            (AB.db.profile["modules"]["Masque"] == nil or AB.db.profile["modules"]["Masque"] == true)
     then
        AB.db.profile["modules"]["Masque"] = false

        local locale = GetLocale()
        if locale == "zhCN" then
            print("|cffff8800AdiBags ElvUI 皮肤|r: 已自动禁用 AdiBags Masque 支持模块.")
        elseif locale == "zhTW" then
            print("|cffff8800AdiBags ElvUI 皮膚|r: 已自動禁用 AdiBags Masque 支持模組.")
        else
            print("|cffff8800AdiBags ElvUI Skin|r: Automatically disabled Masque module of AdiBags.")
        end
    end

    postHandleFrame(AB, "CreateBagSlotPanel", skin.AdiBags_CreateBagSlotPanel)
    hook("Container", "OnCreate", nil, skin.Container_OnCreate, false)
    hook("Container", "CreateModuleButton", nil, skin.Container_CreateModuleButton, false)
    hook("BagSlotButton", "OnCreate", nil, skin.ItemButton_OnCreate, false)
    hook("ItemButton", "OnCreate", nil, skin.ItemButton_OnCreate, false)
    hook("BankItemButton", "OnCreate", nil, skin.ItemButton_OnCreate, false)
    handleExistingFrames("ItemButton", skin.ItemButton_OnCreate)
    handleExistingFrames("BankItemButton", skin.ItemButton_OnCreate)
    handleExistingFrames("Container", skin.Container_OnCreate)
end
