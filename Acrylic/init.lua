-- Initialize DepthOfFieldEffect
local DepthOfField = Instance.new("DepthOfFieldEffect")
DepthOfField.FarIntensity = 0
DepthOfField.InFocusRadius = 0.1
DepthOfField.NearIntensity = 1
DepthOfField.Parent = game:GetService("Lighting")

local AcrylicBlur = require(script.AcrylicBlur)

return {
	AcrylicBlur = AcrylicBlur,
	DepthOfField = DepthOfField
}
