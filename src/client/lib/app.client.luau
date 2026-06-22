local Players = game:GetService("Players")

require("./shootEffects")
require("./guns")

local AmmoHud = require("../components/AmmoHud")
local App = require("../components/App")
local Vide = require("../../../modules/Vide")

local mount = Vide.mount

mount(App, Players.LocalPlayer.PlayerGui)
mount(AmmoHud, Players.LocalPlayer.PlayerGui)
