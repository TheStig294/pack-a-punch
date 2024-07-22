local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"
UPGRADE.desc = "All Soulbound abilities are upgraded!"

function UPGRADE:Apply(SWEP)
    -- Make a backup of old ability functionality
    if not SOULBOUND.PAPOldAbilities then
        SOULBOUND.PAPOldAbilities = {}
        SOULBOUND.PAPOldAbilities = table.Copy(SOULBOUND.Abilities)
    end

    -- Add PaP border to icons
    if CLIENT then
        -- Travels down the panel hierarchy of the buy menu, and returns a table of all buy menu icons
        local function GetItemIconPanels()
            local DFrame

            -- Look for the title name of the Soulbound buy menu, will break if the language placeholder name is changed...
            for _, child in ipairs(vgui.GetWorldPanel():GetChildren()) do
                if child.GetTitle and child:GetTitle() == LANG.GetTranslation("sbd_abilities_title") then
                    DFrame = child
                    break
                end
            end

            if not DFrame then return end

            -- First is the base panel parented to the DFrame, second is the scroll panel, third is the "EquipSelect" custom gui element from base TTT,
            -- containing all buy menu icons as "LayeredIcon" vgui elements
            -- A table of those "LayeredIcon"(s) is returned (The buy menu icons)
            local panelHierachy = {5, 2, 1}

            local buyMenu = DFrame:GetChildren()

            -- From here, things get unavoidably arbitrary
            -- Hopefully Panel:GetChildren() always returns these child panels the same way every time since they don't have any sort of ID
            -- Being super careful here to check for nil or empty table values at each step,
            -- since Gmod store skins or future updates for the buy menu could render it unusable otherwise
            for _, childIndex in ipairs(panelHierachy) do
                if not buyMenu or table.IsEmpty(buyMenu) then return end
                buyMenu = buyMenu[childIndex]
                if not buyMenu then return end
                buyMenu = buyMenu:GetChildren()
            end

            return buyMenu
        end

        local iconsWithUpgrades = {
            ["vgui/ttt/roles/sbd/abilities/icon_beebarrel.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_box.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_confetti.png"] = true,
            ["vgui/ttt/icon_beacon"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_discombob.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_dropweapon.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_explosivebarrel.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_body.png"] = true,
            ["vgui/ttt/icon_c4"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_gunshots.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_headcrab.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_heal.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_incendiary.png"] = true,
            ["vgui/ttt/ttt_pack_a_punch.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_poisonheadcrab.png"] = true,
            ["vgui/ttt/icon_polter"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_possession.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_reveal.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_smoke.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_swapinventory.png"] = true
        }

        self:AddHook("OnContextMenuOpen", function()
            -- This code is copied from the soulbound buy menu opening hook to ensure we're only looking for the soulbound buy menu when we should be
            if GetRoundState() ~= ROUND_ACTIVE then return end

            if not client then
                client = LocalPlayer()
            end

            if not client:IsSoulbound() then return end

            timer.Simple(0.1, function()
                local itemIcons = GetItemIconPanels()
                if not itemIcons or table.IsEmpty(itemIcons) then return end

                for _, iconPanel in ipairs(itemIcons) do
                    if not iconsWithUpgrades[iconPanel:GetIcon()] then continue end
                    local icon = vgui.Create("DImage")
                    icon:SetImage("ttt_pack_a_punch/soul_powerer/pap_camo_frame")
                    icon:SetTooltip("Upgraded")
                    -- Set the icon to be faded if the buy menu icon is faded (e.g. weapon is already bought)
                    icon:SetImageColor(iconPanel.Icon:GetImageColor())

                    -- This is how other overlayed icons are done in vanilla TTT, so we do the same here
                    -- This normally used for the slot icon and custom item icon
                    icon.PerformLayout = function(s)
                        s:SetSize(64, 64)
                    end

                    iconPanel:AddLayer(icon)
                    iconPanel:EnableMousePassthrough(icon)
                end
            end)
        end)
    end

    -- 
    -- Bee barrel
    -- 
    local ABILITY = SOULBOUND.Abilities["beebarrel"]
    ABILITY.Name = "Place Upgraded Bee Barrel"
    ABILITY.Description = "Place an upgraded bee barrel that will release big invincible bees when it explodes!"
    local beebarrel_uses = GetConVar("ttt_soulbound_beebarrel_uses")
    local beebarrel_bees = GetConVar("ttt_soulbound_beebarrel_bees")
    local beebarrel_cooldown = GetConVar("ttt_soulbound_beebarrel_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", beebarrel_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime())

        hook.Add("EntityTakeDamage", "TTTSoulboundBeeBarrelDamage", function(target, dmginfo)
            -- Spawned bees are invincible
            if target.TTTPAPSoulboundBee then return true end
            if target:GetClass() ~= "prop_physics" then return end
            if dmginfo:GetDamage() < 1 then return end
            local model = target:GetModel()
            if model ~= "models/bee_drum/beedrum002_explosive.mdl" then return end
            local pos = target:GetPos()
            local isUpgradedBarrel = target:GetMaterial() == TTTPAP.camo

            timer.Create("TTTSoulboundBeeBarrelSpawn", 0.1, beebarrel_bees:GetInt(), function()
                local spos = pos + Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 100))
                local headBee = ents.Create("npc_manhack")
                headBee:SetPos(spos)
                headBee:Spawn()
                headBee:Activate()
                headBee:SetNPCState(NPC_STATE_ALERT)

                if scripted_ents.Get("ttt_beenade_proj") ~= nil then
                    local bee = ents.Create("prop_dynamic")
                    bee:SetModel("models/lucian/props/stupid_bee.mdl")
                    bee:SetPos(spos)
                    bee:SetParent(headBee)
                    headBee:SetNoDraw(true)

                    if isUpgradedBarrel then
                        bee:SetModelScale(5, 0.0001)
                        bee:Activate()
                        bee:SetMaterial(TTTPAP.camo)
                        bee.TTTPAPSoulboundBee = true
                        headBee:SetModelScale(5, 0.0001)
                        headBee:Activate()
                        headBee.TTTPAPSoulboundBee = true
                    end
                end

                headBee:SetHealth(100000)
            end)
        end)
    end

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 48
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 15) + fwd
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/bee_drum/beedrum002_explosive.mdl")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:SetMaterial(TTTPAP.camo)
        local uses = soulbound:GetNWInt("TTTSoulboundBeeBarrelUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", uses)
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime() + beebarrel_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["beebarrel"] = ABILITY
end

function UPGRADE:Reset()
    -- Hopefully restore the Soulbound abilities to what they were
    -- (I've had problems with this in the past with the French randomat restoring old role names to English,
    -- but this is way less complicated than that so it will hopefully *just work*)
    if SOULBOUND.PAPOldAbilities then
        SOULBOUND.Abilities = table.Copy(SOULBOUND.PAPOldAbilities)
    end
end

TTTPAP:Register(UPGRADE)