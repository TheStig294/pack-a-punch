-- 
-- Creating the Pack-a-Punch passive item, and all the core upgrade logic
-- 
if SERVER then
    util.AddNetworkString("TTTPAPApply")
    util.AddNetworkString("TTTPAPApplySound")
end

-- Registering the passive item
hook.Add("InitPostEntity", "TTTPAPRegister", function()
    if CLIENT then
        LANG.AddToLanguage("english", "pap_name", "Pack-A-Punch")
        LANG.AddToLanguage("english", "pap_desc", "Upgrades your held weapon!\n\nHold out the weapon you want to upgrade in your hands, then buy this item!")
    end

    EQUIP_PAP = GenerateNewEquipmentID and GenerateNewEquipmentID() or 2048

    local pap = {
        id = EQUIP_PAP,
        loadout = false,
        type = "item_passive",
        material = "vgui/ttt/ttt_pack_a_punch.png",
        name = "pap_name",
        desc = "pap_desc"
    }

    -- Prevent roles from getting the PaP in their buy menu that shouldn't
    local bannedRoles = {}

    if not GetConVar("ttt_pap_detective"):GetBool() then
        bannedRoles[ROLE_DETECTIVE] = true
    end

    if not GetConVar("ttt_pap_traitor"):GetBool() then
        bannedRoles[ROLE_TRAITOR] = true
    end

    -- Would be too powerful
    if ROLE_ASSASSIN then
        bannedRoles[ROLE_ASSASSIN] = true
    end

    -- Is supposed to have just randomats to buy
    if ROLE_RANDOMAN then
        bannedRoles[ROLE_RANDOMAN] = true
    end

    -- For some reason the PaP is becoming buyable for the Jester/Swapper even though they aren't shop roles?
    -- SHOP_ROLES[ROLE_JESTER]/SHOP_ROLES[ROLE_SWAPPER] is true
    if ROLE_JESTER then
        bannedRoles[ROLE_JESTER] = true
    end

    if ROLE_SWAPPER then
        bannedRoles[ROLE_SWAPPER] = true
    end

    -- Mad scientist has the death radar but no basic shop items so it probably shouldn't have the PaP by default
    if ROLE_MADSCIENTIST then
        bannedRoles[ROLE_MADSCIENTIST] = true
    end

    -- Check that the PaP item hasn't been added already
    local function HasItemWithPropertyValue(tbl, key, val)
        if not tbl or not key then return end

        for _, v in pairs(tbl) do
            if v[key] and v[key] == val then return true end
        end

        return false
    end

    -- Add the PaP to every role's buy menu that isn't banned
    hook.Add("TTTBeginRound", "TTTPAPRegister", function()
        for role, equTable in pairs(EquipmentItems) do
            -- Check:
            -- Role is not banned
            -- Role doesn't already have the PaP
            -- CR is not installed, or role has a shop
            if not bannedRoles[role] and not HasItemWithPropertyValue(EquipmentItems[role], "id", EQUIP_PAP) and (not SHOP_ROLES or SHOP_ROLES[role]) then
                table.insert(equTable, pap)
            end
        end

        hook.Remove("TTTBeginRound", "TTTPAPRegister")
    end)
end)

local function PAPErrorMessage(ply)
    ply:PrintMessage(HUD_PRINTCENTER, "Can't be upgraded, try a different weapon")
    ply:PrintMessage(HUD_PRINTTALK, "The weapon you're holding out can't be upgraded, try a different one\nIf you spent a credit, it was refunded")
end

hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, equipment, is_item)
    if is_item and math.floor(equipment) == EQUIP_PAP then
        local SWEP = ply:GetActiveWeapon()
        local class = SWEP:GetClass()
        local upgrades = TTTPAP.upgrades[class]

        if not IsValid(SWEP) then
            -- Preventing purchase if the currently held weapon is invalid
            ply:PrintMessage(HUD_PRINTCENTER, "Invalid weapon, try again")
            ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")

            return false
        elseif ConVarExists("ttt_pap_" .. class) and not GetConVar("ttt_pap_" .. class):GetBool() then
            -- Preventing purchase if the current weapon has had its upgrade disabled via convar
            PAPErrorMessage(ply)

            return false
        elseif not upgrades and (not SWEP.AutoSpawnable or not GetConVar("ttt_pap_apply_generic_upgrades"):GetBool()) then
            -- Preventing purchase if held weapon is not a floor weapon or generic upgrades are turned off, and the weapon has no PaP upgrade
            PAPErrorMessage(ply)

            return false
        elseif upgrades then
            -- Preventing purchase if all upgrades' condition functions return false
            for id, UPGRADE in pairs(upgrades) do
                if UPGRADE:Condition() then return end
            end

            PAPErrorMessage(ply)

            return false
        elseif not upgrades then
            -- Preventing purchase if all generic upgrades' condition functions return false or all have had their convars disabled
            for id, UPGRADE in pairs(TTTPAP.genericUpgrades) do
                -- If even one generic upgrade's condition returns true, and its convar is on, we're good, return out of printing an error
                if UPGRADE:Condition() and GetConVar("ttt_pap_" .. UPGRADE.id):GetBool() then return end
            end

            PAPErrorMessage(ply)

            return false
        end
    end
end)

-- Applying PAP shoot sound on the server
local PAPSound = Sound("ttt_pack_a_punch/shoot.mp3")

local function OverrideWeaponSound(SWEP)
    if not IsValid(SWEP) or not SWEP.Primary then return end
    SWEP.Primary.Sound = PAPSound
end

hook.Add("WeaponEquip", "TTTPAPSoundChange", function(SWEP, ply)
    timer.Simple(0.1, function()
        if not SWEP.PAPUpgrade then return end
        OverrideWeaponSound(SWEP)
        net.Start("TTTPAPApplySound")
        net.WriteEntity(SWEP)
        net.Send(ply)
    end)
end)

-- Applies all pack-a-punch effects
local function ApplyPAP(SWEP, UPGRADE)
    -- Apply the upgrade function!
    UPGRADE:Apply(SWEP)
    table.insert(TTTPAP.activeUpgrades, UPGRADE)

    if not UPGRADE.noCamo then
        SWEP:SetMaterial(TTTPAP.camo)
    end

    OverrideWeaponSound(SWEP)

    -- Firerate
    if isnumber(SWEP.Primary.Delay) then
        SWEP.Primary.Delay = SWEP.Primary.Delay / UPGRADE.firerateMult
    elseif isnumber(SWEP.Primary.RPM) then
        SWEP.Primary.RPM = SWEP.Primary.RPM * UPGRADE.firerateMult
    end

    -- Damage
    if isnumber(SWEP.Primary.Damage) then
        SWEP.Primary.Damage = SWEP.Primary.Damage * UPGRADE.damageMult
    end

    -- Spread
    if isnumber(SWEP.Primary.Cone) then
        SWEP.Primary.Cone = SWEP.Primary.Cone * UPGRADE.spreadMult
    elseif isnumber(SWEP.Primary.Spread) then
        SWEP.Primary.Spread = SWEP.Primary.Spread * UPGRADE.spreadMult
    end

    -- Ammo
    if isnumber(SWEP.Primary.ClipSize) and isnumber(SWEP.Primary.ClipMax) and isnumber(SWEP.Primary.DefaultClip) then
        local oldClipSize = SWEP.Primary.ClipSize
        SWEP.Primary.ClipSize = SWEP.Primary.ClipSize * UPGRADE.ammoMult
        SWEP.Primary.ClipMax = SWEP.Primary.ClipMax * UPGRADE.ammoMult
        SWEP.Primary.DefaultClip = SWEP.Primary.DefaultClip * UPGRADE.ammoMult
        -- Set ammo relative to leftover ammo
        SWEP:SetClip1(SWEP.PAPOldClip / oldClipSize * SWEP.Primary.ClipSize)
    end

    -- Recoil
    if isnumber(SWEP.Primary.Recoil) then
        SWEP.Primary.Recoil = SWEP.Primary.Recoil * UPGRADE.recoilMult
    elseif isnumber(SWEP.Primary.StaticRecoilFactor) then
        SWEP.Primary.StaticRecoilFactor = SWEP.Primary.StaticRecoilFactor * UPGRADE.recoilMult
    end

    -- Automatic
    if isbool(SWEP.Primary.Automatic) and isbool(UPGRADE.automatic) then
        SWEP.Primary.Automatic = UPGRADE.automatic
    end

    -- Add upgrade table to the weapon entity itself for easy reference
    -- Used for Pack-a-Punch camo, sound and some upgrades themselves for detecting if a weapon is Pack-a-Punched
    SWEP.PAPUpgrade = UPGRADE
    -- Client-side changes
    net.Start("TTTPAPApply")
    net.WriteEntity(SWEP)
    net.WriteFloat(SWEP.Primary.Delay or -1)
    net.WriteFloat(SWEP.Primary.RPM or -1)
    net.WriteFloat(SWEP.Primary.Damage or -1)
    net.WriteFloat(SWEP.Primary.Cone or -1)
    net.WriteFloat(SWEP.Primary.Spread or -1)
    net.WriteFloat(SWEP.Primary.ClipSize or -1)
    net.WriteFloat(SWEP.Primary.Recoil or -1)
    net.WriteFloat(SWEP.Primary.StaticRecoilFactor or -1)
    net.WriteBool(SWEP.Primary.Automatic or false)
    net.WriteString(UPGRADE.id)
    -- Generic upgrades do not have a weapon class defined
    net.WriteBool(not UPGRADE.class)
    net.Broadcast()
end

-- Applying pack-a-punch effects client-side
if CLIENT then
    net.Receive("TTTPAPApply", function()
        local SWEP = net.ReadEntity()
        if not IsValid(SWEP) then return end
        -- Stats
        SWEP.Primary.Delay = net.ReadFloat()
        SWEP.Primary.RPM = net.ReadFloat()
        SWEP.Primary.Damage = net.ReadFloat()
        SWEP.Primary.Cone = net.ReadFloat()
        SWEP.Primary.Spread = net.ReadFloat()
        SWEP.Primary.ClipSize = net.ReadFloat()
        SWEP.Primary.ClipMax = SWEP.Primary.ClipSize
        SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize
        SWEP.Primary.Recoil = net.ReadFloat()
        SWEP.Primary.StaticRecoilFactor = net.ReadFloat()
        SWEP.Primary.Automatic = net.ReadBool()
        local upgradeID = net.ReadString()
        local isGenericUpgrade = net.ReadBool()
        local UPGRADE

        -- Generic upgrades do not have a weapon class defined
        if isGenericUpgrade then
            UPGRADE = TTTPAP.genericUpgrades[upgradeID]
        else
            UPGRADE = TTTPAP.upgrades[SWEP.ClassName][upgradeID]
        end

        -- Apply upgrade function on the client
        UPGRADE:Apply(SWEP)
        table.insert(TTTPAP.activeUpgrades, UPGRADE)

        -- Name
        if UPGRADE.name then
            SWEP.PrintName = UPGRADE.name
            -- If no defined name for a weapon, just call it: "PAP [weapon name]"
        elseif SWEP.PrintName then
            SWEP.PrintName = "PAP " .. LANG.TryTranslation(SWEP.PrintName)
        end

        -- Description
        if UPGRADE.desc then
            chat.AddText("PAP UPGRADE: " .. UPGRADE.desc)
        end

        -- Add upgrade table to the weapon entity itself for easy reference
        SWEP.PAPUpgrade = UPGRADE
    end)

    -- Camo
    local appliedCamo = false

    hook.Add("PreDrawViewModel", "TTTPAPApplyCamo", function(vm, _, SWEP)
        if not IsValid(SWEP) then return end

        if SWEP.PAPUpgrade and not SWEP.PAPUpgrade.noCamo then
            vm:SetMaterial(TTTPAP.camo)
            appliedCamo = true
        elseif appliedCamo then
            vm:SetMaterial("")
            appliedCamo = false
        end
    end)

    -- Sound
    hook.Add("EntityEmitSound", "TTTPAPApplySound", function(data)
        if not IsValid(data.Entity) or not data.Entity.PAPUpgrade then return end
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
        local SWEP = net.ReadEntity()
        OverrideWeaponSound(SWEP)
    end)
end

local function OrderPAP(ply)
    local SWEP = ply:GetActiveWeapon()

    if not IsValid(SWEP) then
        ply:PrintMessage(HUD_PRINTCENTER, "Invalid Weapon, try again")
        ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")
        ply:AddCredits(1)

        return
    end

    ply:EmitSound("ttt_pack_a_punch/upgrade.mp3")
    local classname = SWEP:GetClass()
    local oldClip = SWEP:Clip1()
    ply:StripWeapon(classname)

    timer.Simple(3.4, function()
        for _, w in ipairs(ply:GetWeapons()) do
            if w.Kind == weapons.Get(classname).Kind then
                ply:StripWeapon(w.ClassName)
                break
            end
        end

        SWEP = ply:Give(classname)
    end)

    timer.Simple(3.5, function()
        if not ply:HasWeapon(classname) then return end

        if not IsValid(SWEP) then
            SWEP = ply:GetWeapon(classname)
        end

        -- Choose a random upgrade from available ones to give to the weapon
        -- Else, pick a random generic upgrade if no upgrade is found
        local upgrades = TTTPAP.upgrades[classname]
        local isGenericUpgrade = false

        if not upgrades then
            upgrades = TTTPAP.genericUpgrades
            isGenericUpgrade = true
        end

        local UPGRADE

        -- Check for an upgrade that has its condition met, and has its convar enabled
        -- (There is garunteed to be at least one by the TTTCanOrderEquipment hook)
        for id, upg in RandomPairs(upgrades) do
            if not upg:Condition() then continue end
            if isGenericUpgrade and not GetConVar("ttt_pap_" .. id):GetBool() then continue end
            if not isGenericUpgrade and not GetConVar("ttt_pap_" .. upg.class .. "_" .. upg.id):GetBool() then continue end
            UPGRADE = upg
            break
        end

        -- Give the player a completely new base weapon instead if one is specified
        if UPGRADE.newClass then
            ply:StripWeapon(classname)
            classname = UPGRADE.newClass
            SWEP = ply:Give(classname)

            timer.Simple(0.1, function()
                if not ply:HasWeapon(classname) then return end

                if not IsValid(SWEP) then
                    SWEP = ply:GetWeapon(classname)
                end

                -- If we don't want the player to hold the weapon straight away, block it
                if not UPGRADE.noSelectWep then
                    ply:SelectWeapon(classname)
                end

                -- The gun's current clip is needed to scale it properly if there's an ammo upgrade
                SWEP.PAPOldClip = oldClip
                -- Apply the upgrade!
                ApplyPAP(SWEP, UPGRADE)
            end)
        else
            if not UPGRADE.noSelectWep then
                ply:SelectWeapon(classname)
            end

            SWEP.PAPOldClip = oldClip
            ApplyPAP(SWEP, UPGRADE)
        end
    end)
end

concommand.Add("ttt_pap_order", OrderPAP, nil, "Simulates ordering the Pack-a-Punch item", FCVAR_CHEAT)

-- Making the passive item do something on purchase
hook.Add("TTTOrderedEquipment", "TTTPAPPurchase", function(ply, equipment, _)
    if equipment ~= EQUIP_PAP then return end
    OrderPAP(ply)
end)