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

    -- Camo (SWEP construction kit weapons)
    if not UPGRADE.noCamo then
        if SWEP.VElements and istable(SWEP.VElements) then
            for _, element in pairs(SWEP.VElements) do
                element.material = TTTPAP.camo
            end
        end

        if SWEP.WElements and istable(SWEP.WElements) then
            for _, element in pairs(SWEP.WElements) do
                element.material = TTTPAP.camo
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
    elseif appliedCamo or vm:GetMaterial() == TTTPAP.camo then
        vm:SetMaterial("")
        appliedCamo = false
    end
end)

-- Extra camo reset
local vm

hook.Add("TTTPrepareRound", "TTTPAPRemoveCamo", function()
    timer.Simple(0.1, function()
        if not IsValid(vm) then
            local client = LocalPlayer()
            if not IsValid(client) then return end
            vm = client:GetViewModel()
            if not IsValid(vm) then return end
        end

        if vm:GetMaterial() == TTTPAP.camo then
            vm:SetMaterial("")
            appliedCamo = false
        end
    end)
end)

-- Sound
hook.Add("EntityEmitSound", "TTTPAPApplySound", function(data)
    if not IsValid(data.Entity) or not data.Entity.PAPUpgrade or data.Entity.PAPUpgrade.noSound then return end
    local current_sound = data.SoundName:lower()
    local fire_start, _ = string.find(current_sound, ".*weapons/.*fire.*%..*")
    local shot_start, _ = string.find(current_sound, ".*weapons/.*shot.*%..*")
    local shoot_start, _ = string.find(current_sound, ".*weapons/.*shoot.*%..*")

    if fire_start or shot_start or shoot_start then
        data.SoundName = TTTPAP.shootSound

        return true
    end
end)

net.Receive("TTTPAPApplySound", function()
    local SWEP = net.ReadEntity()

    if SWEP.Primary then
        SWEP.Primary.Sound = TTTPAP.shootSound
    end
end)