local UPGRADE = {}
UPGRADE.id = "za_warudo"
UPGRADE.class = "crimson_new"
UPGRADE.name = "ZA WARUDO"
UPGRADE.desc = "Press 'R' to time skip!"

UPGRADE.convars = {
    {
        name = "pap_za_warudo_length_secs",
        type = "int"
    }
}

local lengthSecsCvar = CreateConVar("pap_za_warudo_length_secs", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds length of time skip", 0, 60)

function UPGRADE:Apply(SWEP)
    function SWEP:Reload()
        if SERVER and self:Clip1() > 0 then
            self.Delay = self.Delay or CurTime()

            if CurTime() >= self.Delay then
                self:SetAMode(not self:GetAMode())
                self.Delay = CurTime() + 0.2

                if self:GetAMode() then
                    self:TakePrimaryAmmo(1)
                    self:SetNextSecondaryFire(CurTime() + lengthSecsCvar:GetInt())
                    local owner = self:GetOwner()
                    owner:EmitSound("ttt_pack_a_punch/za_warudo/za_warudo.mp3", 0)

                    timer.Simple(7.256, function()
                        self:Skip(true)
                        net.Start("crimson_new.SkipStop")
                        net.Broadcast()
                        owner:SetFOV(owner:GetFOV() * 1.5, 0.5)

                        timer.Simple(0.5, function()
                            owner:SetFOV(0, 0.25)
                        end)

                        timer.Simple(lengthSecsCvar:GetInt(), function()
                            self:StopSkip(true)
                        end)
                    end)
                end
            end
        end
    end

    if CLIENT then
        function SWEP:PostDrawViewModel(vm, wep, ply)
            local model = ""

            if util.IsValidModel("models/player/jojo4/kingarms.mdl") then
                model = "models/player/jojo4/kingarms.mdl"
            elseif util.IsValidModel("models/arms/kcr1.mdl") then
                model = "models/arms/kcr1.mdl"
            else
                return true
            end

            local ent2 = ClientsideModel(model, RENDERGROUP_VIEWMODEL_TRANSLUCENT)
            ent2:SetParent(vm)
            ent2:AddEffects(EF_BONEMERGE or EF_BONEMERGE_FASTCULL or EF_PARENT_ANIMATES)
            ent2:SetAngles(EyeAngles())
            vm:ManipulateBonePosition(0, Vector(0, 0, 0))
            vm:ManipulateBonePosition(1, Vector(0, 3, 0))
            vm:ManipulateBonePosition(21, Vector(0, 3, 0))
            local cyc = vm:GetCycle()

            if self:GetInAttack() then
                vm:SetCycle(math.Rand(0, 1))
            end

            vm:SetupBones()
            render.SuppressEngineLighting(true)
            render.SetBlend(1)
            render.SetModelLighting(0, 0.3, 0.3, 0.3)
            render.SetModelLighting(1, 0.3, 0.3, 0.3)
            render.SetModelLighting(2, 0.3, 0.3, 0.3)
            render.SetModelLighting(3, 0.3, 0.3, 0.3)
            render.SetModelLighting(4, 0.3, 0.3, 0.3)
            render.SetModelLighting(5, 0.3, 0.3, 0.3)
            ent2:SetMaterial(TTTPAP.camo)
            ent2:DrawModel()
            render.SuppressEngineLighting(false)
            vm:SetCycle(cyc)
            vm:SetupBones()
            vm:ManipulateBonePosition(0, Vector(0, 0, 0))
            vm:ManipulateBonePosition(1, Vector(0, 0, 0))
            vm:ManipulateBonePosition(21, Vector(0, 0, 0))
            ent2:Remove()
        end

        function SWEP:DrawWorldModel()
            local model = ""

            if util.IsValidModel("models/player/jojo4/kingarms.mdl") then
                model = "models/player/jojo4/kingarms.mdl"
            elseif util.IsValidModel("models/arms/kcr1.mdl") then
                model = "models/arms/kcr1.mdl"
            else
                return true
            end

            local rupper, lupper, rlower, llower
            local owner = self:GetOwner()

            if IsValid(owner) then
                rupper, lupper, rlower, llower = owner:LookupBone("ValveBiped.Bip01_R_UpperArm"), owner:LookupBone("ValveBiped.Bip01_L_UpperArm"), owner:LookupBone("ValveBiped.Bip01_R_ForeArm"), owner:LookupBone("ValveBiped.Bip01_L_ForeArm")
            end

            if self:GetInAttack() then
                for i = 0, 5 do
                    local resetAnim = owner:GetCycle()
                    owner:SetCycle(owner:GetCycle() + math.Rand(0.3, 0.8))
                    local arms = ClientsideModel(model)
                    arms:SetPos(owner:GetPos())
                    arms.DontAfterimage = true
                    self.DontAfterimage = true
                    arms:SetParent(owner)
                    arms:AddEffects(EF_BONEMERGE or EF_BONEMERGE_FASTCULL or EF_PARENT_ANIMATES)
                    local randvec1 = VectorRand() * 10
                    randvec1 = Vector(randvec1.x / 4, randvec1.y, randvec1.z)
                    local randvec2 = VectorRand() * 10
                    randvec2 = Vector(randvec2.x / 4, randvec2.y, randvec2.z)
                    owner:ManipulateBonePosition(lupper, randvec1)
                    owner:ManipulateBonePosition(llower, owner:GetManipulateBonePosition(lupper) / 2)
                    owner:ManipulateBonePosition(rupper, randvec2)
                    owner:ManipulateBonePosition(rlower, owner:GetManipulateBonePosition(rupper) / 2)
                    owner:ManipulateBoneAngles(lupper, Angle(math.random(-angadj, angadj), math.random(-angadj, angadj), math.random(-angadj, angadj)))
                    owner:ManipulateBoneAngles(rupper, Angle(math.random(-angadj, angadj), math.random(-angadj, angadj), math.random(-angadj, angadj)))
                    owner:SetupBones()
                    render.SetBlend(math.Rand(0.1, 0.9))
                    arms:SetMaterial(TTTPAP.camo)
                    arms:DrawModel()
                    arms:Remove()
                    owner:SetCycle(resetAnim)
                    local zero = Vector(0, 0, 0)
                    owner:ManipulateBonePosition(lupper, zero)
                    owner:ManipulateBonePosition(llower, zero)
                    owner:ManipulateBonePosition(rupper, zero)
                    owner:ManipulateBonePosition(rlower, zero)
                    owner:ManipulateBoneAngles(lupper, Angle(0, 0, 0))
                    owner:ManipulateBoneAngles(rupper, Angle(0, 0, 0))
                    render.SetBlend(1)
                end
            else
                local arms = ClientsideModel(model)

                if IsValid(owner) then
                    arms:SetPos(owner:GetPos())
                    arms:SetParent(owner)
                end

                arms:AddEffects(EF_BONEMERGE or EF_BONEMERGE_FASTCULL or EF_PARENT_ANIMATES)
                local randvec1 = Vector(3, 5, -5)
                local randvec2 = Vector(1, 5, 5)

                if IsValid(owner) and IsValid(lupper) and IsValid(randvec1) then
                    owner:ManipulateBonePosition(lupper, randvec1)
                    owner:ManipulateBonePosition(rupper, randvec2)
                end

                local s = math.sin(CurTime()) * 15
                local c = math.cos(CurTime()) * 15

                if IsValid(owner) and IsValid(lupper) and IsValid(Angle(c, s, s)) then
                    owner:ManipulateBoneAngles(lupper, Angle(c, s, s))
                    owner:ManipulateBoneAngles(rupper, Angle(c, c, s))
                    owner:SetupBones()
                end

                render.SetBlend(1)
                arms:SetMaterial(TTTPAP.camo)
                arms:DrawModel()
                arms:Remove()
                local zero = Vector(0, 0, 0)

                if IsValid(owner) and IsValid(lupper) and IsValid(zero) then
                    owner:ManipulateBonePosition(lupper, zero)
                    owner:ManipulateBonePosition(llower, zero)
                    owner:ManipulateBonePosition(rupper, zero)
                    owner:ManipulateBonePosition(rlower, zero)
                    owner:ManipulateBoneAngles(lupper, Angle(0, 0, 0))
                    owner:ManipulateBoneAngles(rupper, Angle(0, 0, 0))
                end

                render.SetBlend(1)
            end

            if IsValid(owner) then
                owner:SetupBones()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)