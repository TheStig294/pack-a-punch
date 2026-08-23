local UPGRADE = {}
UPGRADE.id = "infinite_beacon"
UPGRADE.class = "weapon_ttt_beacon"
UPGRADE.name = "Infinite Beacon"
UPGRADE.desc = "Unlimited beacons! (On a cooldown)"

UPGRADE.convars = {
    {
        name = "pap_infinite_beacon_cooldown_secs",
        type = "int"
    }
}

local cooldownSecsConvar = CreateConVar("pap_infinite_beacon_cooldown_secs", "30", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Seconds between giving beacons", 1, 180)

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PlacedBeacon", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        local timername = "TTTPAPInfiniteBeaconCooldown" .. owner:SteamID64()

        timer.Create(timername, cooldownSecsConvar:GetInt(), 1, function()
            if not IsValid(owner) then
                timer.Remove(timername)

                return
            end

            local highestKind = -1

            for _, wep in ipairs(owner:GetWeapons()) do
                if self:IsValidUpgrade(wep) then return end

                if wep.Kind and wep.Kind > highestKind then
                    highestKind = wep.Kind
                end
            end

            owner:Give(self.class).Kind = highestKind
            TTTPAP:ApplyUpgrade(owner:GetWeapon(self.class), self)
        end)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        timer.Remove("TTTPAPInfiniteBeaconCooldown" .. ply:SteamID64())
    end
end

TTTPAP:Register(UPGRADE)