AddCSLuaFile()

if SERVER then
    util.AddNetworkString("TTTPAPApply")
    util.AddNetworkString("TTTPAPApplySound")
end

if CLIENT then
    LANG.AddToLanguage("english", "pap_name", "Pack-A-Punch")
    LANG.AddToLanguage("english", "pap_desc", "Upgrades your held weapon!\n\nHold out the weapon you want to upgrade in your hands, then buy this item!")
end

-- Registering the passive item
hook.Add("InitPostEntity", "TTTPAPRegister", function()
    EQUIP_PAP = (GenerateNewEquipmentID and GenerateNewEquipmentID()) or 2048

    local pap = {
        id = EQUIP_PAP,
        loadout = false,
        type = "item_passive",
        material = "vgui/ttt/ttt_pack_a_punch.png",
        name = "pap_name",
        desc = "pap_desc"
    }

    table.insert(EquipmentItems[ROLE_TRAITOR], pap)
    table.insert(EquipmentItems[ROLE_DETECTIVE], pap)
end)

hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, equipment, is_item)
    if is_item and math.floor(equipment) == EQUIP_PAP then
        local wep = ply:GetActiveWeapon()

        -- Preventing purchase if the currently held weapon is invalid
        if not IsValid(wep) then
            ply:PrintMessage(HUD_PRINTCENTER, "Invalid weapon, try again")
            ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")

            return false
        elseif istable(wep.CanBuy) and not table.IsEmpty(wep.CanBuy) and wep.CanBuy ~= {} then
            -- Preventing purchase if held weapon is a buyable weapon and it has no custom PaP upgrade
            local class = wep:GetClass()

            if not TTT_PAP_UPGRADES[class] and not weapons.Get(class .. "_pap") then
                ply:PrintMessage(HUD_PRINTCENTER, "Can't be upgraded, try a different weapon")
                ply:PrintMessage(HUD_PRINTTALK, "The weapon you're holding out can't be upgraded, try a different one\nIf you spent a credit, it was refunded")

                return false
            end
        end
    end
end)

-- Applying PAP shoot sound on the server
local PAPSound = Sound("ttt_pack_a_punch/shoot.mp3")

local function OverrideWeaponSound(wep)
    if not IsValid(wep) or not wep.Primary then return end
    wep.Primary.Sound = PAPSound
end

hook.Add("WeaponEquip", "TTTPAPSoundChange", function(wep, ply)
    timer.Create("TTTPAPSoundChange", 0.1, 1, function()
        if not wep:GetNWBool("IsPackAPunched") then return end
        OverrideWeaponSound(wep)
        net.Start("TTTPAPApplySound")
        net.WriteEntity(wep)
        net.Send(ply)
    end)
end)

-- Applies all pack-a-punch effects
local function ApplyPAP(wep, upgradeData)
    -- NWBool, camo and sound is applied on all weapons
    wep:SetNWBool("IsPackAPunched", true)
    wep:SetMaterial(TTT_PAP_CAMO)
    OverrideWeaponSound(wep)

    -- Firerate
    if isnumber(wep.Primary.Delay) then
        wep.Primary.Delay = wep.Primary.Delay / upgradeData.firerateMult
    end

    -- Damage
    if isnumber(wep.Primary.Damage) then
        wep.Primary.Damage = wep.Primary.Damage * upgradeData.damageMult
    end

    -- Spread
    if isnumber(wep.Primary.Cone) then
        wep.Primary.Cone = wep.Primary.Cone * upgradeData.spreadMult
    end

    -- Ammo
    if isnumber(wep.Primary.ClipSize) then
        local oldClipSize = wep.Primary.ClipSize
        wep.Primary.ClipSize = wep.Primary.ClipSize * upgradeData.ammoMult
        wep.Primary.ClipMax = wep.Primary.ClipMax * upgradeData.ammoMult
        wep.Primary.DefaultClip = wep.Primary.DefaultClip * upgradeData.ammoMult
        -- Set ammo relative to leftover ammo
        wep:SetClip1((upgradeData.oldClip / oldClipSize) * wep.Primary.ClipSize)
    end

    -- Recoil
    if isnumber(wep.Primary.Recoil) then
        wep.Primary.Recoil = wep.Primary.Recoil * upgradeData.recoilMult
    end

    -- Automatic
    if isbool(wep.Primary.Automatic) then
        wep.Primary.Automatic = upgradeData.automatic
    end

    -- Extras function
    if isfunction(upgradeData.func) then
        upgradeData.func(wep)
    end

    net.Start("TTTPAPApply")
    net.WriteEntity(wep)
    net.WriteFloat(wep.Primary.Delay)
    net.WriteFloat(wep.Primary.Damage)
    net.WriteFloat(wep.Primary.Cone)
    net.WriteFloat(wep.Primary.ClipSize)
    net.WriteFloat(wep.Primary.Recoil)
    net.WriteBool(wep.Primary.Automatic)
    net.Broadcast()
end

-- Applying pack-a-punch effects client-side
if CLIENT then
    net.Receive("TTTPAPApply", function()
        local wep = net.ReadEntity()
        if not IsValid(wep) then return end
        -- Stats
        wep.Primary.Delay = net.ReadFloat()
        wep.Primary.Damage = net.ReadFloat()
        wep.Primary.Cone = net.ReadFloat()
        wep.Primary.ClipSize = net.ReadFloat()
        wep.Primary.ClipMax = wep.Primary.ClipSize
        wep.Primary.DefaultClip = wep.Primary.ClipSize
        wep.Primary.Recoil = net.ReadFloat()
        wep.Primary.Automatic = net.ReadBool()
        -- Name
        local upgradeData = TTT_PAP_UPGRADES[wep.ClassName]

        if upgradeData and upgradeData.name then
            wep.PrintName = upgradeData.name
            -- If no defined name for a gun, shove "PAP" in front
        elseif wep.PrintName and not string.EndsWith(wep.ClassName, "_pap") then
            wep.PrintName = "PAP " .. LANG.TryTranslation(wep.PrintName)
        end

        -- Description
        local description

        if upgradeData and upgradeData.desc then
            description = upgradeData.desc
        elseif wep.PAPDesc then
            description = wep.PAPDesc
        end

        if description then
            chat.AddText("PAP UPGRADE: " .. description)
        end
    end)

    -- Camo
    local appliedCamo = false

    hook.Add("PreDrawViewModel", "TTTPAPApplyCamo", function(vm, ply, weapon)
        if not IsValid(weapon) then return end

        if weapon:GetNWBool("IsPackAPunched") then
            vm:SetMaterial(TTT_PAP_CAMO)
            appliedCamo = true
        elseif appliedCamo then
            vm:SetMaterial("")
            appliedCamo = false
        end
    end)

    -- Sound
    hook.Add("EntityEmitSound", "TTTPAPApplySound", function(data)
        if not IsValid(data.Entity) or not data.Entity:GetNWBool("IsPackAPunched") then return end
        local current_sound = data.SoundName:lower()
        local fire_start, _ = string.find(current_sound, ".*weapons/.*fire.*%..*")
        local shot_start, _ = string.find(current_sound, ".*weapons/.*shot.*%..*")
        local shoot_start, _ = string.find(current_sound, ".*weapons/.*shoot.*%..*")

        if fire_start or shot_start or shoot_start then
            data.SoundName = PAPSound

            return true
        end
    end)

    net.Receive("TTTPAPApplySound", function()
        local wep = net.ReadEntity()
        OverrideWeaponSound(wep)
    end)
end

-- Making the passive item do something on purchase
hook.Add("TTTOrderedEquipment", "TTTPAPPurchase", function(ply, equipment, is_item)
    if equipment ~= EQUIP_PAP then return end
    local wep = ply:GetActiveWeapon()

    if not IsValid(wep) then
        ply:PrintMessage(HUD_PRINTCENTER, "Invalid Weapon, try again")
        ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")
        ply:AddCredits(1)

        return
    end

    ply:EmitSound("ttt_pack_a_punch/upgrade.mp3")
    local classname = wep:GetClass()
    local oldClip = wep:Clip1()
    ply:StripWeapon(classname)

    timer.Simple(3.4, function()
        for _, w in ipairs(ply:GetWeapons()) do
            if w.Kind == weapons.Get(classname).Kind then
                ply:StripWeapon(w.ClassName)
                break
            end
        end

        local papClass = weapons.Get(classname .. "_pap")

        if papClass then
            classname = classname .. "_pap"
        end

        wep = ply:Give(classname)
        ply:SelectWeapon(classname)
    end)

    timer.Simple(3.5, function()
        if not IsValid(wep) then return end
        local upgradeData = TTT_PAP_UPGRADES[classname]
        upgradeData = upgradeData or {}
        -- Default gun stats for PAP
        -- By default, weapons get a 1.5 firerate upgrade
        -- Unless specified in the upgrades table
        upgradeData.firerateMult = upgradeData.firerateMult or 1.5
        upgradeData.damageMult = upgradeData.damageMult or 1
        upgradeData.spreadMult = upgradeData.spreadMult or 1
        upgradeData.ammoMult = upgradeData.ammoMult or 1
        upgradeData.recoilMult = upgradeData.recoilMult or 1

        if upgradeData.automatic == nil then
            upgradeData.automatic = wep.Primary.Automatic
        end

        upgradeData.oldClip = oldClip

        if upgradeData then
            ApplyPAP(wep, upgradeData)
        end
    end)
end)