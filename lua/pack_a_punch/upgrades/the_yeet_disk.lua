local UPGRADE = {}
UPGRADE.id = "the_yeet_disk"
UPGRADE.class = "weapon_ttt_dislocator"
UPGRADE.name = "The Yeet Disk"
UPGRADE.desc = "x2 ammo and fling power!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    local mult = 2

    local values = {"InitialSpeed", "MaxFlightTime", "PunchSpeed", "FinalBonusUpVelocity", "PunchMax", "ViewDistortDelay"}

    function SWEP:CreateDisk(pos, ang)
        local disk = ents.Create("ttt_dislocator_disk")
        disk:SetPos(pos)
        disk:SetAngles(ang)
        disk.WeaponClass = self:GetClass()
        disk:SetOwner(self:GetOwner())
        disk:Spawn()
        disk:Activate()
        disk:SetPAPCamo()
        disk.TrailColour = COLOR_ORANGE
        disk.TTTPAPTheYeetDisk = true

        for _, value in ipairs(values) do
            disk[value] = disk[value] * mult
        end

        disk.PunchSound = "ttt_pack_a_punch/the_yeet_disk/yeet.mp3"
        disk.PunchSoundAlt = "ttt_pack_a_punch/the_yeet_disk/yeet.mp3"
    end
end

TTTPAP:Register(UPGRADE)