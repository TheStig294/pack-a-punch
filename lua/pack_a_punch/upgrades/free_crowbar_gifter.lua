local UPGRADE = {}
UPGRADE.id = "free_crowbar_gifter"
UPGRADE.class = "fkg_gifter_swep"
UPGRADE.name = "Free Crowbar Gifter"
UPGRADE.desc = "Forces them to use a crowbar instead!"

function UPGRADE:Apply(SWEP)
    if self.Applied then return end
    self.Applied = true
    local PAPOldFkgTarget = FkgTarget

    function FkgTarget(att, path, dmginfo)
        PAPOldFkgTarget(att, path, dmginfo)
        local ply = path.Entity

        if SERVER and self:IsPlayer(ply) then
            local timername = ply:SteamID64() .. "TTTPAPFreeCrowbarGifter"

            timer.Create(timername, 3, 0, function()
                if not IsValid(ply) or not ply:Alive() or ply:IsSpec() or GetRoundState() == ROUND_PREP then
                    timer.Remove(timername)

                    return
                end

                ply:StripWeapons()
                local wep = ply:Give("weapon_zm_improvised")

                if IsValid(wep) then
                    wep.AllowDrop = false
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)