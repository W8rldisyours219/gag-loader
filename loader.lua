-- Public-facing loader. Contains no game logic — safe to distribute freely.
-- Buyers set getgenv().key before running this.
--
-- EDIT THIS before distributing: your tunneled key-server URL (the SAME
-- value as KEY_SERVER_URL in W8rldisyours219.lua's checkLicenseKey()).
local KEY_SERVER_URL = "https://keys.w8rldisyours.com"

-- Only used while KEY_SERVER_URL is blank (local development before you've
-- deployed the key server) — points at your own repo. Make that repo
-- PRIVATE once you release publicly; this fallback then only works for you.
local DEV_SOURCE_URL = "https://raw.githubusercontent.com/W8rldisyours219/gag-stock-weather-executor/main/W8rldisyours219.lua"

assert(type(loadstring) == "function", "[W8rldisyours219] loadstring is not available in this executor")

local function computeHwid()
	local ok, id = pcall(function()
		if gethwid then
			return tostring(gethwid())
		end
		return tostring(game:GetService("RbxAnalyticsService"):GetClientId())
	end)
	return (ok and id and tostring(id) ~= "") and id or "unknown-hwid"
end

local function encodeQueryValue(value)
	return tostring(value or ""):gsub("([^%w%-_%.~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end)
end

local function promptForKey()
	local player = game:GetService("Players").LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "W8rldisyours219KeyPrompt"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999
	local parented = pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)
	if not parented then
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(320, 150)
	frame.Position = UDim2.new(0.5, -160, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Text = "W8rldisyours219 — Enter License Key"
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 0, 36)
	box.Position = UDim2.fromOffset(10, 50)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderText = "XXXXX-XXXXX-XXXXX-XXXXX"
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	box.Text = ""
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 36)
	button.Position = UDim2.fromOffset(10, 96)
	button.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = "Submit"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.Parent = frame
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

	local submittedKey = nil
	local function submit()
		local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if text ~= "" then
			submittedKey = text
		end
	end
	button.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)

	local wait = (task and task.wait) or wait
	while not submittedKey do
		wait(0.1)
	end
	gui:Destroy()
	return submittedKey
end

local function fetchGatedSource()
	local env = (getgenv and getgenv()) or _G
	local key = tostring(env["key"] or env["W8rldisyours219Key"] or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if key == "" then
		key = promptForKey()
		env["key"] = key
	end

	local hwid = computeHwid()
	local okEncode, payload = pcall(function()
		return game:GetService("HttpService"):JSONEncode({ key = key, hwid = hwid })
	end)
	assert(okEncode, "[W8rldisyours219] Failed to build the license request")

	local responseBody, lastError = nil, "no reachable key server"
	local requestFn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
	if requestFn then
		local ok, result = pcall(function()
			return requestFn({
				Url = KEY_SERVER_URL .. "/script/fetch",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload,
			})
		end)
		if ok and type(result) == "table" then
			local statusCode = tonumber(result.StatusCode or result.Status or result.statusCode) or 0
			if statusCode >= 200 and statusCode < 300 then
				responseBody = result.Body or result.body
			else
				local decodeOk, decoded = pcall(function()
					return game:GetService("HttpService"):JSONDecode(result.Body or result.body or "")
				end)
				lastError = (decodeOk and decoded and decoded.error) or ("HTTP " .. tostring(statusCode))
			end
		end
	end

	if not responseBody then
		-- GET-bridge fallback for executors whose request() is blocked.
		local url = KEY_SERVER_URL .. "/script/fetch?payload=" .. encodeQueryValue(payload)
		local ok, text = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(text) == "string" and text ~= "" then
			-- A JSON error object means the key check failed; real source
			-- never starts with "{" in this codebase.
			local looksLikeError = text:sub(1, 1) == "{"
			if looksLikeError then
				local decodeOk, decoded = pcall(function()
					return game:GetService("HttpService"):JSONDecode(text)
				end)
				lastError = (decodeOk and decoded and decoded.error) or "invalid response"
			else
				responseBody = text
			end
		end
	end

	assert(responseBody, "[W8rldisyours219] License check failed: " .. tostring(lastError))
	return responseBody
end

local ok, source
if KEY_SERVER_URL ~= "" then
	ok, source = pcall(fetchGatedSource)
	assert(ok, tostring(source))
else
	ok, source = pcall(function()
		return game:HttpGet(DEV_SOURCE_URL)
	end)
	assert(ok, "[W8rldisyours219] HttpGet failed: " .. tostring(source))
end

assert(type(source) == "string" and source ~= "", "[W8rldisyours219] Empty script source received")

local chunk, compileError = loadstring(source)
assert(chunk, "[W8rldisyours219] compile failed: " .. tostring(compileError))

return chunk()
