local UPGRADE = {}
UPGRADE.id = "time_skip_king_crimson"
UPGRADE.class = "crimson_new"
UPGRADE.name = "Time Skip Fists"
UPGRADE.desc = "Press 'R' to gain damage resistance and\nslow down time, but you move at normal speed!"

UPGRADE.convars = {
    {
        name = "pap_time_skip_king_crimson_length_secs",
        type = "int"
    },
    {
        name = "pap_time_skip_king_crimson_dmg_resist_mult",
        type = "float",
        decimal = 1
    },
}

local lengthSecsCvar = CreateConVar("pap_time_skip_king_crimson_length_secs", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds length of time skip", 0, 60)

local dmgResistCvar = CreateConVar("pap_time_skip_king_crimson_dmg_resist_mult", 0.8, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage resistance multiplier", 0, 1)

local function StopSkip(wep, owner, timername)
    if timername then
        timer.Remove(timername)
    end

    if IsValid(wep) then
        wep.InSkip = false
    end

    if IsValid(owner) then
        owner.PAPTimeSkipKCDmgResist = nil
    end

    timer.Simple(0.1, function()
        if SERVER then
            game.SetTimeScale(1)
        end

        for _, ply in pairs(player.GetAll()) do
            if SERVER then
                ply:SetLaggedMovementValue(1)
            end

            ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 200), 0, 0)

            if IsValid(ply:GetViewModel()) then
                ply:GetViewModel():SetPlaybackRate(1)
            end
        end
    end)

    timer.Simple(0.2, function()
        if SERVER then
            net.Start("TTTPAPTimeSkipKCScreenEffectsRemove")
            net.Broadcast()
        end
    end)
end

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPTimeSkipKCScreenEffects")
        util.AddNetworkString("TTTPAPTimeSkipKCScreenEffectsRemove")
    end

    local timername = SWEP:GetOwner():SteamID64() .. "TTTPAPTimeSkipKCEnd"

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPTimeSkipKCDmgResist then
            StopSkip(nil, ply, timername)
        end
    end)

    function SWEP:Reload()
        if SERVER and self:Clip1() > 0 then
            self.Delay = self.Delay or CurTime()

            if CurTime() >= self.Delay then
                self.Delay = CurTime() + 0.2
                self:TakePrimaryAmmo(1)
                self:SetNextSecondaryFire(CurTime() + lengthSecsCvar:GetInt())
                local owner = self:GetOwner()
                BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/time_skip/time_skip.mp3\")")

                timer.Simple(7.256, function()
                    if not IsValid(owner) or not IsValid(self) then return end
                    game.SetTimeScale(0.5)
                    owner:SetLaggedMovementValue(2)
                    owner.PAPTimeSkipKCDmgResist = true
                    self.InSkip = true

                    for _, ply in player.Iterator() do
                        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 200), 0.5, lengthSecsCvar:GetInt() - 0.5)
                    end

                    util.ScreenShake(owner:GetPos(), 20, 10, 1.5, 1000, true)
                    net.Start("TTTPAPTimeSkipKCScreenEffects")
                    net.Broadcast()

                    timer.Create(timername, lengthSecsCvar:GetInt(), 1, function()
                        StopSkip(self, owner, timername)
                    end)
                end)
            end
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPTimeSkipKCDmgResist then
            dmg:ScaleDamage(dmgResistCvar:GetFloat())
        end
    end)

    if CLIENT then
        local playedSound = false

        -- Adds a blur effect around the edges of the screen
        net.Receive("TTTPAPTimeSkipKCScreenEffects", function()
            local starsMat = Material("effects/kcr_stars")
            playedSound = false

            hook.Add("RenderScreenspaceEffects", "TTTPAPTimeSkipKCScreenEffects", function()
                DrawToyTown(4, ScrH() / 1.75)
                surface.SetDrawColor(255, 255, 255, 128)
                surface.SetMaterial(starsMat)
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
            end)
        end)

        net.Receive("TTTPAPTimeSkipKCScreenEffectsRemove", function()
            hook.Remove("RenderScreenspaceEffects", "TTTPAPTimeSkipKCScreenEffects")

            if not playedSound then
                surface.PlaySound("weapons/crimson_new/crimson3.wav")
                playedSound = true
            end
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
            ent2:SetPAPCamo()
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
                    arms:SetPAPCamo()
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
                arms:SetPAPCamo()
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

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        timer.Remove(ply:SteamID64() .. "TTTPAPTimeSkipKCEnd")
        StopSkip(nil, ply)
    end
end

TTTPAP:Register(UPGRADE)