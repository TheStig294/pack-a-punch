local UPGRADE = {}
UPGRADE.id = "za_warudo"
UPGRADE.class = "crimson_new"
UPGRADE.name = "ZA WARUDO"
UPGRADE.desc = "Press 'R' to gain damage resistance and\nslow down time, but you move at normal speed!"

UPGRADE.convars = {
    {
        name = "pap_za_warudo_length_secs",
        type = "int"
    },
    {
        name = "pap_za_warudo_dmg_resist_mult",
        type = "float",
        decimal = 1
    },
}

local lengthSecsCvar = CreateConVar("pap_za_warudo_length_secs", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds length of time skip", 0, 60)

local dmgResistCvar = CreateConVar("pap_za_warudo_dmg_resist_mult", 0.5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage resistance multiplier", 0, 1)

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPZaWarudoScreenEffects")
        util.AddNetworkString("TTTPAPZaWarudoScreenEffectsRemove")
    end

    local timername = SWEP:EntIndex() .. "TTTPAPZaWarudoEnd"

    local function StopSkip(wep, owner)
        timer.Remove(timername)

        if IsValid(owner) then
            owner.PAPZaWarudoDmgResist = nil
        end

        net.Start("crimson_new.OwnerSkipStop")
        net.Broadcast()

        if IsValid(wep) then
            wep.InSkip = false
        end

        timer.Simple(0.1, function()
            if SERVER then
                game.SetTimeScale(1)

                timer.Simple(0.1, function()
                    net.Start("crimson_new.SkipStop")
                    net.Broadcast()
                end)
            end

            for _, ply in pairs(player.GetAll()) do
                if SERVER then
                    ply:SetLaggedMovementValue(1)
                end

                ply:SetDSP(0, false)
                ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 200), 0, 0)

                if IsValid(ply:GetViewModel()) then
                    ply:GetViewModel():SetPlaybackRate(1)
                end
            end
        end)

        timer.Simple(0.2, function()
            net.Start("TTTPAPZaWarudoScreenEffectsRemove")
            net.Broadcast()
        end)
    end

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPZaWarudoDmgResist then
            StopSkip(nil, ply)
        end
    end)

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
                    BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/za_warudo/za_warudo.mp3\")")

                    timer.Simple(7.256, function()
                        if not IsValid(owner) or not IsValid(self) then return end
                        self:Skip(true)
                        hook.Remove("StartCommand", "KCSkip")
                        self.worlddrop:Remove()
                        self.dummynpc:Remove()
                        owner.PAPZaWarudoDmgResist = true
                        owner:SetNotSolid(false)

                        for _, ply in ipairs(player.GetAll()) do
                            ply:SetDSP(0, false)
                            ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 200), 0.5, lengthSecsCvar:GetInt() - 0.5)
                            ply:SetFOV(ply:GetFOV() * 1.5, 0.5)

                            timer.Simple(0.5, function()
                                ply:SetFOV(0, 0.25)
                            end)

                            if ply ~= owner then
                                net.Start("crimson_new.OwnerSkip")
                                net.Send(ply)
                            end
                        end

                        util.ScreenShake(owner:GetPos(), 20, 10, 1.5, 1000, true)
                        net.Start("TTTPAPZaWarudoScreenEffects")
                        net.Broadcast()

                        timer.Create(timername, lengthSecsCvar:GetInt(), 1, function()
                            StopSkip(self, owner)
                        end)
                    end)
                end
            end
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPZaWarudoDmgResist then
            dmg:ScaleDamage(dmgResistCvar:GetFloat())
        end
    end)

    if CLIENT then
        -- Adds a blur effect around the edges of the screen
        net.Receive("TTTPAPZaWarudoScreenEffects", function()
            hook.Remove("PostDrawEffects", "Skip")
            local starsMat = Material("effects/kcr_stars")

            hook.Add("RenderScreenspaceEffects", "TTTPAPZaWarudoScreenEffects", function()
                DrawToyTown(4, ScrH() / 1.75)
                surface.SetDrawColor(255, 255, 255, 128)
                surface.SetMaterial(starsMat)
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
            end)
        end)

        net.Receive("TTTPAPZaWarudoScreenEffectsRemove", function()
            hook.Remove("RenderScreenspaceEffects", "TTTPAPZaWarudoScreenEffects")
            surface.PlaySound("weapons/crimson_new/crimson3.wav")
        end)

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

                if IsValid(owner) and isnumber(lupper) and IsValid(randvec1) then
                    owner:ManipulateBonePosition(lupper, randvec1)
                    owner:ManipulateBonePosition(rupper, randvec2)
                end

                local s = math.sin(CurTime()) * 15
                local c = math.cos(CurTime()) * 15

                if IsValid(owner) and isnumber(lupper) and IsValid(Angle(c, s, s)) then
                    owner:ManipulateBoneAngles(lupper, Angle(c, s, s))
                    owner:ManipulateBoneAngles(rupper, Angle(c, c, s))
                    owner:SetupBones()
                end

                render.SetBlend(1)
                arms:SetMaterial(TTTPAP.camo)
                arms:DrawModel()
                arms:Remove()
                local zero = Vector(0, 0, 0)

                if IsValid(owner) and isnumber(lupper) and IsValid(zero) then
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