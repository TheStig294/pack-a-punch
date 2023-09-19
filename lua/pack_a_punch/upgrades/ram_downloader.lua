local UPGRADE = {}
UPGRADE.id = "ram_downloader"
UPGRADE.class = "weapon_ttt_popupgun"
UPGRADE.name = "RAM Downloader"
UPGRADE.desc = "Temporarily blocks the victim's screen with lots of popups at once!"
UPGRADE.ammoMult = 0.05

if SERVER then
    util.AddNetworkString("TTTPAPRamDownloader")
end

function UPGRADE:Apply(SWEP)
    -- Gun has 1 ammo and deals 1 damage to trigger the bullet.Callback function below
    SWEP.Primary.Damage = 1
    SWEP.Primary.Ammo = "AirboatGun"

    timer.Simple(0.1, function()
        SWEP:GetOwner():SetAmmo(0, "AirboatGun")
    end)

    -- Override the popup gun's shoot function with our own
    function SWEP:ShootBullet(dmg, recoil, numbul, cone)
        self:SendWeaponAnim(self.PrimaryAnim)
        self:GetOwner():MuzzleFlash()
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        local sights = self:GetIronsights()
        numbul = numbul or 1
        cone = cone or 0.01
        local bullet = {}
        bullet.Num = numbul
        bullet.Src = self:GetOwner():GetShootPos()
        bullet.Dir = self:GetOwner():GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 4
        bullet.TracerName = self.Tracer or "Tracer"
        bullet.Force = 10
        bullet.Damage = dmg

        bullet.Callback = function(_, tr, _)
            if CLIENT and tr.HitWorld and tr.MatType == MAT_METAL then
                local eff = EffectData()
                eff:SetOrigin(tr.HitPos)
                eff:SetNormal(tr.HitNormal)
                util.Effect("cball_bounce", eff)
            end

            local ply = tr.Entity

            if SERVER and UPGRADE:IsPlayer(ply) then
                net.Start("TTTPAPRamDownloader")
                net.WriteBool(false)
                net.Send(ply)
            end
        end

        self:GetOwner():FireBullets(bullet)
        -- Owner can die after firebullets
        if not IsValid(self:GetOwner()) or not self:GetOwner():Alive() or self:GetOwner():IsNPC() then return end

        if game.SinglePlayer() and SERVER or not game.SinglePlayer() and CLIENT and IsFirstTimePredicted() then
            -- reduce recoil if ironsighting
            recoil = sights and recoil * 0.6 or recoil
            local eyeang = self:GetOwner():EyeAngles()
            eyeang.pitch = eyeang.pitch - recoil
            self:GetOwner():SetEyeAngles(eyeang)
        end
    end

    -- Remove a player's popups after they die
    self:AddHook("PostPlayerDeath", function(ply)
        net.Start("TTTPAPRamDownloader")
        net.WriteBool(true)
        net.Send(ply)
    end)
end

-- Remove all popups for everyone after the round restarts
function UPGRADE:Reset()
    if SERVER then
        net.Start("TTTPAPRamDownloader")
        net.WriteBool(true)
        net.Broadcast()
    end
end

if CLIENT then
    -- List of popup images, and their dimensions
    local popups = {
        {
            width = 500,
            height = 375,
            name = "bluescreen.jpg"
        },
        {
            width = 500,
            height = 500,
            name = "jackpot.jpg"
        },
        {
            width = 500,
            height = 268,
            name = "self_destruct.jpg"
        },
        {
            width = 500,
            height = 281,
            name = "robux.jpg"
        },
        {
            width = 480,
            height = 263,
            name = "download_more_ram.jpg"
        },
        {
            width = 500,
            height = 390,
            name = "something_happened.jpg"
        },
        {
            width = 500,
            height = 329,
            name = "task_failed_successfully.jpg"
        },
        {
            width = 500,
            height = 287,
            name = "driver_update.jpg"
        },
        {
            width = 500,
            height = 151,
            name = "windows_update.jpg"
        },
        {
            width = 417,
            height = 135,
            name = "too_many_errors.jpg"
        },
        {
            width = 500,
            height = 330,
            name = "adblock.jpg"
        },
        {
            width = 199,
            height = 170,
            name = "clippy.jpg"
        },
        {
            width = 500,
            height = 291,
            name = "video_not_available.jpg"
        },
        {
            width = 500,
            height = 361,
            name = "download_free_virus.jpg"
        },
        {
            width = 500,
            height = 106,
            name = "activatewindows.jpg"
        },
        {
            width = 500,
            height = 257,
            name = "cookies.jpg"
        },
        {
            width = 750,
            height = 72,
            name = "hypercam.jpg"
        },
        {
            width = 500,
            height = 275,
            name = "newsletter.jpg"
        }
    }

    -- Puts a popup on the player's screen and stores it for later so they can be automatically closed after the player dies or the round restarts
    local frames = {}

    local function MakePopup()
        local popup = popups[math.random(#popups)]
        local xPos = math.random(0, ScrW() - popup.width)
        local yPos = math.random(0, ScrH() - popup.height)
        local frame = vgui.Create("DFrame")
        frame:SetPos(xPos, yPos)
        frame:SetSize(popup.width, popup.height)
        frame:ShowCloseButton(false)
        frame:SetTitle("")
        local image = vgui.Create("DImage", frame)
        image:SetImage("ttt_pack_a_punch/ram_downloader/" .. popup.name)
        image:SetPos(0, 0)
        image:SetSize(popup.width, popup.height)
        table.insert(frames, frame)

        -- Popups start closing after they have finished being put onto the screen
        timer.Simple(10, function()
            if IsValid(frame) then
                frame:Close()
            end
        end)
    end

    -- Puts popups on the player's screen in time with the sound effects
    local errorSoundDelays = {0, 1.47, 2.15, 2.6, 2.94, 3.27, 3.95, 4.41, 4.75, 5.08, 5.76, 6.21, 6.65, 7.56, 8.02, 8.45, 8.6, 8.71}

    local stopPopups = false

    net.Receive("TTTPAPRamDownloader", function()
        local removePopups = net.ReadBool()

        if removePopups then
            stopPopups = true

            for _, frame in ipairs(frames) do
                if IsValid(frame) then
                    frame:Remove()
                end
            end

            table.Empty(frames)
            LocalPlayer():StopSound("ttt_pack_a_punch/ram_downloader/error_sounds.mp3")
        else
            stopPopups = false
            LocalPlayer():EmitSound("ttt_pack_a_punch/ram_downloader/error_sounds.mp3")

            for _, delay in ipairs(errorSoundDelays) do
                timer.Simple(delay, function()
                    if not stopPopups then
                        MakePopup()
                    end
                end)
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)