-- 
-- Client-side pack-a-punch functions
-- 
net.Receive("TTTPAPApply", function()
    local SWEP = net.ReadEntity()
    if not IsValid(SWEP) then return end
    -- Reading data from server
    local delay = net.ReadFloat()
    local RPM = net.ReadFloat()
    local damage = net.ReadFloat()
    local cone = net.ReadFloat()
    local spread = net.ReadFloat()
    local clipSize = net.ReadFloat()
    local recoil = net.ReadFloat()
    local staticRecoilFactor = net.ReadFloat()
    local automatic = net.ReadBool()
    local upgradeID = net.ReadString()
    local upgradeClass = net.ReadString()
    local noDesc = net.ReadBool()
    local UPGRADE

    -- Generic upgrades do not have a weapon class defined
    if upgradeClass == "" then
        UPGRADE = TTTPAP.genericUpgrades[upgradeID]
    else
        UPGRADE = TTTPAP.upgrades[upgradeClass][upgradeID]
    end

    -- Apply upgrade function on the client
    UPGRADE:Apply(SWEP)
    table.insert(TTTPAP.activeUpgrades, UPGRADE)

    -- Stats
    if istable(SWEP.Primary) then
        SWEP.Primary.Delay = delay
        SWEP.Primary.RPM = RPM
        SWEP.Primary.Damage = damage
        SWEP.Primary.Cone = cone
        SWEP.Primary.Spread = spread
        SWEP.Primary.ClipSize = clipSize
        SWEP.Primary.ClipMax = clipSize
        SWEP.Primary.Recoil = recoil
        SWEP.Primary.StaticRecoilFactor = staticRecoilFactor
        SWEP.Primary.Automatic = automatic
    end

    -- Name
    if UPGRADE.name then
        SWEP.PrintName = UPGRADE.name
        -- If no defined name for a weapon, just call it: "PAP [weapon name]"
    elseif SWEP.PrintName then
        SWEP.PrintName = "PAP " .. LANG.TryTranslation(SWEP.PrintName)
    end

    -- Description
    if UPGRADE.desc and not noDesc then
        -- Need to check this is the player actually holding the weapon!
        for _, wep in ipairs(LocalPlayer():GetWeapons()) do
            if wep == SWEP then
                chat.AddText("PAP UPGRADE: " .. UPGRADE.desc)
                break
            end
        end
    end

    -- Upgraded flag
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

    if SWEP.Primary then
        SWEP.Primary.Sound = TTTPAP.shootSound
    end
end)