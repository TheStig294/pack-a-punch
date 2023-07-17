AddCSLuaFile()

-- Create convar to disable trying to apply the default upgrade on weapons without one
local genericUpgradesCvar = CreateConVar("ttt_pap_apply_generic_upgrade", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow weapons without designated upgrades to *try* to be upgraded, with a 1.5x increase in fire rate", 0, 1)

-- Convars to turn off detective/traitor being able to buy the Pack-a-Punch for vanilla TTT (Custom Roles users can just use the role weapons system)
local detectiveCvar = CreateConVar("ttt_pap_detective", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Detectives can buy PaP (Requires map change)", 0, 1)

local traitorCvar = CreateConVar("ttt_pap_traitor", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Traitors can buy PaP (Requires map change)", 0, 1)

if SERVER then
    util.AddNetworkString("TTTPAPApply")
    util.AddNetworkString("TTTPAPApplySound")
    util.AddNetworkString("TTTPAPToggleEnabledConvar")
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

    -- Add the Pack-a-Punch to every role's buy menu
    for role, equTable in pairs(EquipmentItems) do
        if role == ROLE_DETECTIVE and not detectiveCvar:GetBool() then continue end
        if role == ROLE_TRAITOR and not traitorCvar:GetBool() then continue end
        table.insert(equTable, pap)
    end

    -- Create convars for each weapon to disable being upgradable
    for _, SWEP in ipairs(weapons.GetList()) do
        -- Only create convars for TTT-compatible weapons
        if SWEP.Kind then
            local class = SWEP.ClassName or SWEP.Classname

            -- Check weapon actually has a unique PaP upgrade
            if TTT_PAP_UPGRADES[class] or weapons.Get(class .. "_pap") ~= nil then
                CreateConVar("ttt_pap_" .. class, 1, {FCVAR_NOTIFY, FCVAR_REPLICATED})
            end
        end
    end
end)

if SERVER then
    net.Receive("TTTPAPToggleEnabledConvar", function(len, ply)
        if not ply:IsAdmin() then return end
        local cvarName = net.ReadString()
        if not ConVarExists(cvarName) then return end
        local enabledCvar = GetConVar(cvarName)

        if enabledCvar:GetBool() then
            enabledCvar:SetBool(false)
        else
            enabledCvar:SetBool(true)
        end
    end)
end

hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, equipment, is_item)
    if is_item and math.floor(equipment) == EQUIP_PAP then
        local wep = ply:GetActiveWeapon()

        -- Preventing purchase if the currently held weapon is invalid
        if not IsValid(wep) then
            ply:PrintMessage(HUD_PRINTCENTER, "Invalid weapon, try again")
            ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")

            return false
        elseif ConVarExists("ttt_pap_" .. wep:GetClass()) and not GetConVar("ttt_pap_" .. wep:GetClass()):GetBool() then
            -- Preventing purchase if the current weapon has had its upgrade disabled via convar
            ply:PrintMessage(HUD_PRINTCENTER, "Can't be upgraded, try a different weapon")
            ply:PrintMessage(HUD_PRINTTALK, "The weapon you're holding out can't be upgraded, try a different one\nIf you spent a credit, it was refunded")

            return false
        elseif not genericUpgradesCvar:GetBool() or not wep.AutoSpawnable then
            -- Preventing purchase if held weapon is not a floor weapon or generic upgrades are turned off, and the weapon has no custom PaP upgrade
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
    net.WriteBool(upgradeData.defaultPaPUpgrade)
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
        local defaultPaPUpgrade = net.ReadBool()
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

        if defaultPaPUpgrade then
            description = "x1.5 fire rate increase!"
        elseif upgradeData and upgradeData.desc then
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
    local specialPaPUpgrade = false

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
            specialPaPUpgrade = true
        end

        wep = ply:Give(classname)
        ply:SelectWeapon(classname)
    end)

    timer.Simple(3.5, function()
        if not IsValid(wep) then return end
        local upgradeData = TTT_PAP_UPGRADES[classname]

        if upgradeData then
            upgradeData.defaultPaPUpgrade = false
        else
            upgradeData = {}

            if not specialPaPUpgrade then
                upgradeData.defaultPaPUpgrade = true
            end
        end

        -- Default gun stats for PAP
        -- By default, weapons get a 1.5 firerate upgrade
        -- Unless specified in the upgrades table
        upgradeData.firerateMult = upgradeData.firerateMult or 1.5
        upgradeData.damageMult = upgradeData.damageMult or 1
        upgradeData.spreadMult = upgradeData.spreadMult or 1
        upgradeData.ammoMult = upgradeData.ammoMult or 1
        upgradeData.recoilMult = upgradeData.recoilMult or 1

        -- By default, go by the gun's specified automatic/non-automatic fire
        if upgradeData.automatic == nil then
            upgradeData.automatic = wep.Primary.Automatic
        end

        -- The gun's current clip is needed to scale it properly if there's an ammo upgrade
        upgradeData.oldClip = oldClip

        if upgradeData then
            ApplyPAP(wep, upgradeData)
        end
    end)
end)