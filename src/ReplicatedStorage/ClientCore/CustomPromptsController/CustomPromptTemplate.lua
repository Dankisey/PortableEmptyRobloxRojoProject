local UserInputService = game:GetService("UserInputService")
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
local PromptsGui = PlayerGui:WaitForChild("CustomPrompts")

local CustomPromptTemplate = {}

local function adaptButtonTextToDevice(controlType: string, gui: UIBase)
	local frame = gui:WaitForChild("Background", 2)

	if not frame then return end

	if controlType == "Desktop" then
		frame.ActivationButton.InputIcon.Visible = false
		frame.ActivationButton.InputText.Visible = true
		frame.ActivationButton.InputText.Text = "E"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif controlType:match("Mobile") then
		frame.ActivationButton.InputText.Visible = false
		frame.ActivationButton.InputIcon.Visible = true
	else
		frame.ActivationButton.InputIcon.Visible = false
		frame.ActivationButton.InputText.Visible = true

		frame.ActivationButton.InputText.Text = "X"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(92, 135, 255)

		--[[
		frame.ActivationButton.InputText.Text = "□"
		frame.ActivationButton.InputText.TextColor3 = Color3.fromRGB(255, 107, 255)
		]]
	end
end

--[[
	Кому промпт разрешено ловить мышью и пальцем. Возвращает true, если кнопка
	вообще нажимаема на этом устройстве.

	BillboardGui.Active = true — единственный способ сделать кнопку промпта
	нажимаемой, но он же заставляет билборд ТОПИТЬ ввод мыши. Плейс играется
	от первого лица: курсор залочен по центру экрана и скрыт совсем, поэтому
	появившийся под прицелом промпт съедал движение мыши — камера переставала
	вращаться, пока игрок не отойдёт от рыбы. Тем же путём уезжал и ЛКМ:
	клик становился gameProcessed, ToolsController его отбрасывал, и вместо
	заброса срабатывал подбор.

	На ПК и консоли жать промпт нечем и незачем — то же самое делают E и ButtonX,
	а курсора там нет вовсе. Ввод оставляем только там, где кнопка единственный
	способ, — на тач-устройствах.

	Условие обязано быть тем же, по которому adaptButtonTextToDevice рисует
	подпись клавиши: разъехавшись, они врут игроку — подпись обещает одно,
	а нажимается другое.
]]
local function adaptInputToDevice(controlType: string, gui: BillboardGui): boolean
	local isTouch = controlType:match("Mobile") ~= nil

	gui.Active = isTouch

	return isTouch
end

function CustomPromptTemplate:Enable(prompt: ProximityPrompt)
	local part = prompt.Parent or prompt.AncestryChanged:Wait()
	self._guiPerPrompt[prompt] = self._gui:Clone()
	self._guiPerPrompt[prompt].Parent = PromptsGui
	self._guiPerPrompt[prompt].Adornee = part

	local controlType = self._inputController:GetControllType()
	adaptButtonTextToDevice(controlType, self._guiPerPrompt[prompt])

	local isTouch = adaptInputToDevice(controlType, self._guiPerPrompt[prompt])

	if self.OnEnabled then
		self:OnEnabled(prompt, self._guiPerPrompt[prompt])
	end

	local gui = self._guiPerPrompt[prompt]

	--[[
		Кнопку подключаем только там, где по ней жмут. На ПК и консоли билборд
		ввод не принимает вовсе, а подключённая кнопка держала бы вечный
		HoveringTask и считала бы залоченный по центру курсор наведением —
		звук наведения играл бы на каждый показ промпта.
	]]
	if isTouch then
		task.spawn(function()
			local button = gui:WaitForChild("Background", 1)

			if not button then return end

			button = button:WaitForChild("ActivationButton", 1)

			if not button then return end

			-- промпт мог успеть скрыться, пока ждали кнопку
			if self._guiPerPrompt[prompt] ~= gui then return end

			self._buttonsInteractionsConnector:ConnectButton(button, self.Use, self, prompt)
		end)
	end

	self._inputConnections[prompt] = UserInputService.InputBegan:Connect(function(input)
		--[[
			ГВАРД ИМЕННО НА НАБОР ТЕКСТА, А НЕ НА gameProcessed.

			Ввод промпта забирает сам ProximityPromptService: он биндит KeyboardKeyCode
			через ContextActionService и помечает нажатие как обработанное игрой.
			Поэтому кастомный шаблон обязан слушать СЫРОЙ InputBegan — проверка
			gameProcessed съедает каждое E, и подбор перестаёт работать вовсе,
			молча и без единой ошибки в консоли. Уже наступали.
		]]
		if UserInputService:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
			self:Use(prompt)
		end
	end)

	--[[
		GUI живёт ровно столько, сколько живёт сам инстанс промпта. Нужно тем,
		кто не гасится по использованию (см. KeepShownOnUse): их промпт исчезает
		вместе с объектом, а PromptHidden в этот момент уже не придёт — билборд
		остался бы висеть сиротой.
	]]
	self._ancestryConnections = self._ancestryConnections or {}
	self._ancestryConnections[prompt] = prompt.AncestryChanged:Connect(function(_, parent)
		if parent then return end

		self:Disable(prompt)
	end)

	self._guiPerPrompt[prompt].Enabled = true
end

function CustomPromptTemplate:Disable(prompt: ProximityPrompt)
	local gui = self._guiPerPrompt[prompt]

	if gui then
		self._guiPerPrompt[prompt] = nil

		--[[
			Обязательно отключаем кнопку до Destroy: ButtonsInteractionsConnector
			держит на каждую подключённую кнопку вечный HoveringTask.
			Без этого каждый показ промпта оставлял за собой живой цикл.
		]]
		local background = gui:FindFirstChild("Background")
		local button = background and background:FindFirstChild("ActivationButton")

		if button then
			self._buttonsInteractionsConnector:DisconnectButton(button)
		end

		gui:Destroy()
	end

	if self._inputConnections[prompt] then
		self._inputConnections[prompt]:Disconnect()
		self._inputConnections[prompt] = nil
	end

	if self._ancestryConnections and self._ancestryConnections[prompt] then
		self._ancestryConnections[prompt]:Disconnect()
		self._ancestryConnections[prompt] = nil
	end

	if self.OnDisabled then
		self:OnDisabled(prompt)
	end
end

function CustomPromptTemplate:Use(prompt: ProximityPrompt)
	if not prompt then
		warn("prompt not found while using custom prompt")

		return
	end

	self:OnUsed(prompt)

	--[[
		KeepShownOnUse — для промптов, которым сервер МОЖЕТ ОТКАЗАТЬ (подбор рыбы:
		полный инвентарь, кулдаун, дистанция). Гасить такие по нажатию нельзя:
		PromptShown повторно не придёт, и промпт пропадал насовсем, пока игрок
		не выйдет из радиуса и не вернётся. Они снимаются по исчезновению самого
		инстанса промпта (см. Enable) либо обычным PromptHidden.
	]]
	if self.KeepShownOnUse then return end

	self:Disable(prompt)
end

return CustomPromptTemplate