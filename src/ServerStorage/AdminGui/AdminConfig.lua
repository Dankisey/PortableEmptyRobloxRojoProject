--[[ outside Configs: this config travels inside AdminGui and reaches only DevelopersConfig clients ]]
local AdminConfig = {}

AdminConfig.Currency = "Cash"
AdminConfig.RequestCooldown = .25 -- seconds between commands of one player
AdminConfig.MaxAmount = 1e15 -- limit of one AddCash
AdminConfig.DefaultAmount = 1000000 -- the number in the field when the panel is given
AdminConfig.ConfirmWindow = 3 -- seconds for the second press of a confirmed command
AdminConfig.ConfirmText = "Tap again!"
AdminConfig.ClientReadyAttribute = "IsClientInitialized" -- the panel is given after ClientCore starts
AdminConfig.DeveloperPurchasesAttribute = "DeveloperPurchasesEnabled" -- mirrored on the panel clone by AdminService

AdminConfig.FreePurchasesText = {
	On = "Free purchases: ON";
	Off = "Free purchases: OFF";
}

AdminConfig.FreePurchasesColor = {
	On = Color3.fromRGB(60, 160, 170);
	Off = Color3.fromRGB(96, 112, 146);
}

-- button name in Panel = command name; NeedsAmount reads the Amount field, NeedsConfirm asks for a second press
AdminConfig.Commands = {
	AddCash = {NeedsAmount = true};
	FreePurchases = {};
	Reset = {NeedsConfirm = true};
}

return AdminConfig
