AddCSLuaFile()
ENT.Base = "ttt_bomb_station"
ENT.PrintName = "Directed By Bomb"
ENT.Type = "anim"

if SERVER then
    util.AddNetworkString("TTTPAPBombStationPopup")
end

function ENT:Trigger(ply)
    self.BaseClass.Trigger(self, ply)
    if self.PAPTriggered then return end
    self.PAPTriggered = true

    timer.Simple(self.ExplosionTime + 3, function()
        if IsValid(ply) then
            net.Start("TTTPAPBombStationPopup")
            net.Send(ply)
        end
    end)
end

if CLIENT then
    net.Receive("TTTPAPBombStationPopup", function()
        local directedByMaterial = Material("ttt_pack_a_punch/bomb_station/directedby1.png")

        timer.Simple(0.93, function()
            directedByMaterial = Material("ttt_pack_a_punch/bomb_station/directedby2.png")
        end)

        timer.Simple(4.16, function()
            directedByMaterial = Material("ttt_pack_a_punch/bomb_station/directedby3.png")
        end)

        timer.Simple(7.49, function()
            directedByMaterial = Material("ttt_pack_a_punch/bomb_station/directedby4.png")
        end)

        surface.PlaySound("ttt_pack_a_punch/bomb_station/directed_by.mp3")
        surface.PlaySound("ttt_pack_a_punch/bomb_station/directed_by.mp3")

        hook.Add("HUDPaintBackground", "TTTPAPBombStationPopup", function()
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(directedByMaterial)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end)

        timer.Simple(10.176, function()
            hook.Remove("HUDPaintBackground", "TTTPAPBombStationPopup")
        end)
    end)
end