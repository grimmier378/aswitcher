local mq        = require('mq')
local Actors    = require('actors')

local MySelf    = mq.TLO.Me
local MyName    = MySelf.CleanName()
local MyActor   = nil

local isRunning = true

-- ACTORS --

local function ActorsHandler()
	MyActor = Actors.register('actorswitcher', function(message)
		local newMessage = message()

		if newMessage.Subject == 'switch' and newMessage.Who:lower() == MyName:lower() then
			mq.cmd("/foreground")
			return
		end
	end)
end


local function CommandHandler(...)
	local args = { ..., }

	if args[1] == 'quit' or args[1] == 'exit' then
		printf("Exiting ActorsSwitcher...")
		isRunning = false
		return
	end
	if args[1] ~= nil then
		if MyActor then
			MyActor:send({ mailbox = 'actorswitcher', }, {
				Subject = 'switch',
				From = MyName,
				Who = args[1],
			})
			return
		else
			mq.cmdf("/echo No actor registered for switching.")
		end
	else
		mq.cmdf("/echo Unknown command: %s", args[1])
	end
end

------------------------- Main --------------
local function Init()
	-- initialize Actors
	ActorsHandler()
	mq.bind("/aswitch", CommandHandler)

	printf("ActorsSwitcher initialized for %s", MyName)
	printf("Use /aswitch name to switch to another actor.")
	printf("Use /aswitch quit to exit the Script.")
	isRunning = true
end

local function Main()
	while isRunning do
		mq.delay(100)
	end
	mq.unbind("/aswitch")
end

Init()
Main()
