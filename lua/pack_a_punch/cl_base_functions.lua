-- 
-- Client-side pack-a-punch functions
-- 
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

    -- Name
    if UPGRADE.name then
        SWEP.PrintName = UPGRADE.name
        -- If no defined name for a weapon, just call it: "PAP [weapon name]"
    elseif SWEP.PrintName then
        SWEP.PrintName = "PAP " .. LANG.TryTranslation(SWEP.PrintName)
    end

    -- Description
    if UPGRADE.desc and not noDesc and LocalPlayer():HasWeapon(SWEP:GetClass()) then
        chat.AddText("PAP UPGRADE: " .. UPGRADE.desc)
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