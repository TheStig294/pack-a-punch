local UPGRADE = {}
UPGRADE.id = "instant_army"
UPGRADE.class = "surprisesoldiers"
UPGRADE.name = "Instant Army"
UPGRADE.desc = "Spawns all 10 surprise soldier NPCs at once!"

function UPGRADE:Apply(SWEP)
    function SWEP:PAPSpawnNPC(CombineNumber)
        local CombineType = {"npc_manhack", "npc_cscanner", "npc_rollermine", "npc_clawscanner", "npc_stalker", "npc_metropolice", "npc_combine_s", "npc_combine_s", "npc_combine_s", "npc_metropolice"}

        local Combine = CombineType[CombineNumber]
        local owner = self:GetOwner()
        owner:SetAnimation(PLAYER_ATTACK1)
        local Nom = ents.Create(Combine)
        Nom:SetOwner(owner)
        Nom:SetHealth(150)
        Nom.Controller = owner
        local tr = owner:GetEyeTrace()
        local hitpos = tr.HitPos
        local hitV = Vector(hitpos)
        local MeV = Vector(self:GetPos())

        -- Spawn out of Walls
        if (hitV[1] + 10) < MeV[1] then
            local vecXP = Vector(25, 0, 0)
            hitpos:Add(vecXP)
        else
            if (hitV[1] - 10) > MeV[1] then
                local vecXN = Vector(-25, 0, 0)
                hitpos:Add(vecXN)
            end
        end

        if (hitV[2] + 10) < MeV[2] then
            local vecYP = Vector(0, 25, 0)
            hitpos:Add(vecYP)
        else
            if (hitV[2] - 10) > MeV[2] then
                local vecYN = Vector(0, -25, 0)
                hitpos:Add(vecYN)
            end
        end

        Nom:SetPos(hitpos)
        Nom:Spawn()
        Nom:Activate()
        Nom:SetMaxHealth(350)
        Nom:SetHealth(350)
        Nom:SetPAPCamo()

        --Giving Combine Soldiers their weapons
        if CombineNumber == 10 then
            Nom:Give("weapon_crowbar")
        end

        if CombineNumber == 9 then
            Nom:Give("weapon_smg1")
        end

        if CombineNumber == 8 then
            Nom:Give("weapon_ar2")
        end

        if CombineNumber == 7 then
            Nom:Give("weapon_shotgun")
        end

        if CombineNumber == 6 then
            Nom:Give("weapon_stunstick")
        end

        self:TakePrimaryAmmo(1)
        Nom:AddEntityRelationship(owner, D_LI, 99)

        --If you spawn them, everyone with your class is also cafe from them. Example: If Traitor spawnns them every other Traitor ist Safe. But: If a Detectiv spawns them every Detectiv is safe, but the Innocents arent
        for k, v in pairs(player.GetAll()) do
            if not v:IsValid() then continue end

            if v:GetRole() == owner:GetRole() then
                Nom:AddEntityRelationship(v, D_LI, 99)
            end
        end

        Nom:AddRelationship("npc_antlion D_LI 99") --Add positiv Relationsship between spawnable NPCs
        Nom:AddRelationship("npc_antlionguard D_LI 99")
        Nom:AddRelationship("npc_fastzombie D_LI 99")
        Nom:AddRelationship("npc_headcrab D_LI 99")
        Nom:AddRelationship("npc_headcrab_black D_LI 99")
        Nom:AddRelationship("npc_headcrab_fast D_LI 99")
        Nom:AddRelationship("npc_poisonzombie D_LI 99")
        Nom:AddRelationship("npc_zombie D_LI 99")
        Nom:AddRelationship("npc_zombie_torso D_LI 99")
    end

    SWEP.PAPHasFired = false

    timer.Simple(0.1, function()
        SWEP.Primary.ClipSize = -1
        SWEP:SetClip1(-1)
    end)

    function SWEP:PrimaryAttack()
        if self.PAPHasFired then return end
        self.PAPHasFired = true
        self:EmitSound("Weapon_Pistol.Single")
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

        if SERVER then
            local timername = "TTTPAPAllSoldiersSummoner" .. self:EntIndex()

            timer.Create(timername, 0.3, 10, function()
                if IsValid(self) then
                    self:PAPSpawnNPC(timer.RepsLeft(timername) + 1)
                else
                    timer.Remove(timername)
                end

                if timer.RepsLeft(timername) <= 0 then
                    self:Remove()
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)