TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_qua_bomb_station = {
    name = "Bom bom bom",
    desc = "A player that activates this sees\nthe 'Directed by Robert B. Weide' meme!",
    func = function(SWEP)
        local throwsound = Sound("Weapon_SLAM.SatchelThrow")

        function SWEP:BombDrop()
            if SERVER then
                local ply = self:GetOwner()
                if not IsValid(ply) then return end
                if self.Planted then return end
                local vsrc = ply:GetShootPos()
                local vang = ply:GetAimVector()
                local vvel = ply:GetVelocity()
                local vthrow = vvel + vang * 200
                local bomb = ents.Create("ttt_bomb_station_pap")

                if IsValid(bomb) then
                    bomb:SetPos(vsrc + vang * 10)
                    bomb:Spawn()
                    bomb:SetPlacer(ply)
                    bomb:PhysWake()
                    local phys = bomb:GetPhysicsObject()

                    if IsValid(phys) then
                        phys:SetVelocity(vthrow)
                    end

                    self:Remove()
                    self.Planted = true
                end
            end

            self:EmitSound(throwsound)
        end
    end
}