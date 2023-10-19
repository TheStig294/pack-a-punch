local UPGRADE = {}
UPGRADE.id = "radar_flare"
UPGRADE.class = "weapon_ttt_decoy"
UPGRADE.name = "Radar Flare"
UPGRADE.desc = "Places many decoys around the map!"

function UPGRADE:Apply(SWEP)
    function SWEP:PlacedDecoy(decoy)
        self:GetOwner().decoy = decoy
        self:TakePrimaryAmmo(1)

        if not self:CanPrimaryAttack() then
            self.Planted = true
        end
    end

    function SWEP:DecoyDrop(pos)
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            local decoy = ents.Create("ttt_decoy")

            if IsValid(decoy) then
                decoy:SetPos(pos + Vector(0, 0, 5))
                decoy:SetOwner(ply)
                decoy:Spawn()
                decoy:SetMaterial(TTTPAP.camo)
                local ang = decoy:GetAngles()
                ang:RotateAroundAxis(ang:Right(), 90)
                decoy:SetAngles(ang)
                decoy:PhysWake()
                self:PlacedDecoy(decoy)
            end
        end
    end

    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    function SWEP:PrimaryAttack()
        if CLIENT or not IsFirstTimePredicted() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:EmitSound(throwsound)
        local playerPositions = {}

        for _, ply in ipairs(player.GetAll()) do
            if UPGRADE:IsAlive(ply) then
                table.insert(playerPositions, ply:GetPos())
            end
        end

        for _, ent in ipairs(ents.GetAll()) do
            local classname = ent:GetClass()
            local pos = ent:GetPos()
            local infoEnt = string.StartWith(classname, "info_")

            -- Using the positions of weapon, ammo and player spawns
            if (string.StartWith(classname, "weapon_") or string.StartWith(classname, "item_") or infoEnt) and not IsValid(ent:GetParent()) and math.random() < 0.2 then
                local tooClose = false

                for _, plyPos in ipairs(playerPositions) do
                    -- 100 * 100 = 10,000, so any positions closer than 100 source units to a player are too close to be placed
                    if math.DistanceSqr(pos.x, pos.y, plyPos.x, plyPos.y) < 10000 then
                        tooClose = true
                        break
                    end
                end

                if not tooClose then
                    -- local sharkTrap = ents.Create("ttt_shark_trap")
                    self:DecoyDrop(pos)

                    -- sharkTrap:SetPos(pos + Vector(0, 0, 5))
                    -- Don't remove player spawn points
                    if not infoEnt then
                        ent:Remove()
                    end
                    -- sharkTrap:Spawn()
                end
            end
        end

        if SERVER then
            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)