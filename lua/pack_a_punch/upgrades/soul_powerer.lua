local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"
UPGRADE.desc = "All Soulbound abilities are upgraded!"

UPGRADE.convars = {
    {
        name = "pap_soul_powerer_clown_transform_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_clown_transform_delay",
        type = "int"
    },
}

local clown_transform_uses = CreateConVar("pap_soul_powerer_clown_transform_uses", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of clown transform, 0 = infinite", 0, 10)

local clown_transform_delay = CreateConVar("pap_soul_powerer_clown_transform_delay", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs delay of clown transform", 2, 60)

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

        UPGRADE:AddHook("EntityTakeDamage", function(target, dmginfo)
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
            end, "TTTSoulboundBeeBarrelDamage")
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
    -- 
    -- Box
    -- 
    ABILITY = SOULBOUND.Abilities["box"]
    ABILITY.Name = "Place zombie box"
    ABILITY.Description = "Place a big box with a zombie inside"
    local box_uses = GetConVar("ttt_soulbound_box_uses")
    local box_cooldown = GetConVar("ttt_soulbound_box_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundBoxUses", box_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundBoxNextUse", CurTime())

        UPGRADE:AddHook("PropBreak", function(attacker, prop)
            if prop.PAPSoulboundZombieBox then
                local zombie = ents.Create("npc_zombie")
                zombie:SetPos(prop:GetPos())
                zombie:Spawn()
            end
        end, "TTTPAPSoulboundZombieBox")
    end

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 64
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 40) + fwd
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/props_junk/wood_crate001a.mdl")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:SetModelScale(2)
        ent:Activate()
        ent:SetMaterial(TTTPAP.camo)
        ent.PAPSoulboundZombieBox = true
        local uses = soulbound:GetNWInt("TTTSoulboundBoxUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundBoxUses", uses)
        soulbound:SetNWFloat("TTTSoulboundBoxNextUse", CurTime() + box_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["box"] = ABILITY
    -- 
    -- Confetti
    -- 
    ABILITY = SOULBOUND.Abilities["confetti"]
    ABILITY.Name = "Clown transform"
    ABILITY.Description = "Transform a non-traitor player into an active clown (with a " .. clown_transform_delay:GetInt() .. " second delay)"

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundConfettiUses", clown_transform_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundConfettiNextUse", CurTime())
    end

    function ABILITY:Condition(soulbound, target)
        if target:IsTraitorTeam() then
            soulbound:ChatPrint("Cannot transform traitors")

            return false
        end

        if not soulbound:IsInWorld() then return false end
        if clown_transform_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundConfettiUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundConfettiNextUse") then return false end

        return true
    end

    local ActivateClown

    if SERVER then
        local clown_activation_credits = GetConVar("ttt_clown_activation_credits")
        local clown_use_traps_when_active = GetConVar("ttt_clown_use_traps_when_active")
        local clown_heal_on_activate = GetConVar("ttt_clown_heal_on_activate")
        local clown_heal_bonus = GetConVar("ttt_clown_heal_bonus")

        function ActivateClown(clown)
            SetClownTeam(true)
            clown:QueueMessage(MSG_PRINTBOTH, "KILL THEM ALL!")
            clown:AddCredits(clown_activation_credits:GetInt())

            if clown_heal_on_activate:GetBool() then
                local heal_bonus = clown_heal_bonus:GetInt()
                local health = clown:GetMaxHealth() + heal_bonus
                clown:SetHealth(health)

                if heal_bonus > 0 then
                    clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed (with a bonus)!")
                else
                    clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
                end
            end

            net.Start("TTT_ClownActivate")
            net.WritePlayer(clown)
            net.Broadcast()

            -- Give the clown their shop items if purchase was delayed
            if clown.bought and GetConVar("ttt_clown_shop_delay"):GetBool() then
                clown:GiveDelayedShopItems()
            end

            -- Enable traitor buttons for them, if that's enabled
            TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = clown_use_traps_when_active:GetBool()
        end
    end

    function ABILITY:Use(soulbound, target)
        soulbound:QueueMessage(MSG_PRINTCENTER, target:Nick() .. " will transform in " .. clown_transform_delay:GetInt() .. " seconds!")
        local timerName = "TTTPAPSoulboundClownTransform" .. target:SteamID64()

        timer.Create(timerName, 1, clown_transform_delay:GetInt(), function()
            if not IsValid(target) or GetRoundState() ~= ROUND_ACTIVE then
                timer.Remove(timerName)

                return
            end

            local countdown = timer.RepsLeft(timerName)

            if countdown > 0 then
                target:PrintMessage(HUD_PRINTCENTER, "A Soulbound used their power to transform you into a Clown in: " .. countdown)
            else
                target:SetRole(ROLE_CLOWN)

                if SERVER then
                    SendFullStateUpdate()
                    ActivateClown(target)
                end
            end
        end)

        local uses = soulbound:GetNWInt("TTTSoulboundConfettiUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundConfettiUses", uses)
        soulbound:SetNWFloat("TTTSoulboundConfettiNextUse", CurTime() + clown_transform_delay:GetInt())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = clown_transform_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundConfettiUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to transform player into clown"
            local next_use = soulbound:GetNWFloat("TTTSoulboundConfettiNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["confetti"] = ABILITY
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