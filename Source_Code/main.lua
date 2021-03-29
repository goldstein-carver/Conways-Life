function love.load()
	love.graphics.setBackgroundColor(1,1,1);
	love.graphics.setFont(love.graphics.newFont(math.floor(love.graphics.getDimensions()/40)));
	love.keyboard.setTextInput(false);
	--Core Simulation
	mode = "setting";--setting, running, paused, info, egg
	livingPoints = {};--Each Point is a table with two values: x and y
	elapsedTime = 0;
	currentGeneration = 0;
	setNumbers = {p=2, q=3, r=3, s=3};
	--Display System
	guiHeight = 50;
	cellSize = 20;--Includes both lines, so 20 and 1 has cells that are only 18x18
	lineWidth = 1;
	xOffset = 0;--Measured in cells, not pixels (-1 means that the -1st cell is at the left side of the screen)
	yOffset = 0;--Measured in cells, not pixels
	waitTime = 0.25;
	--Touchscreen System
	xTouchDistance = 0;
	yTouchDistance = 0;
	initialCellSize = cellSize;
	initialDistance = 0;
	canChangeLife = false;
	--Mouse System
	scrollWaitTime = 0;
	xMouseDistance = 0;
	yMouseDistance = 0;
	clickOnCell = false;
end
function love.draw()
	love.graphics.setColor(0,0,0);
	local maxx; local maxy;
	maxx,maxy = love.graphics.getDimensions();
	if mode ~= "info" and mode ~= "egg" then
		love.graphics.rectangle("fill",0,guiHeight,lineWidth,maxy-guiHeight);
		local x = cellSize - lineWidth;
		while x < maxx do
			if x + lineWidth <= maxx then
				love.graphics.rectangle("fill",x,guiHeight,2*lineWidth,maxy-guiHeight);
			else
				love.graphics.rectangle("fill",x,guiHeight,maxx-x,maxy-guiHeight);
			end
			x = x+cellSize;
		end
		love.graphics.rectangle("fill",0,guiHeight,maxx,lineWidth);
		local y = guiHeight + cellSize - lineWidth;
		while y < maxy do
			if y + lineWidth <= maxy then
				love.graphics.rectangle("fill",0,y,maxx,2*lineWidth);
			else
				love.graphics.rectangle("fill",0,y,maxx,maxy-y);
			end
			y = y+cellSize;
		end
		for i,v in ipairs(livingPoints) do
			local ymin = yOffset; local xmin = xOffset;
			local ymax = ymin+math.ceil(maxy/cellSize)-1; local xmax = xmin+math.ceil(maxx/cellSize)-1;
			if v.x >= xmin and v.x <= xmax and v.y >= ymin and v.y <= ymax then
				local xpix = (v.x-xmin)*cellSize; local ypix = (v.y-ymin)*cellSize+guiHeight;
				if v.x ~= xmax and v.y ~= ymax then
					love.graphics.rectangle("fill", xpix, ypix, cellSize, cellSize);
				else
					love.graphics.rectangle("fill", xpix, ypix, math.min(maxx-xpix,cellSize), math.min(maxy-ypix,cellSize));
				end
			end
		end
		--Top GUI banner
		love.graphics.setColor(0.5,0.5,0.5);
		love.graphics.rectangle("fill",0,0,maxx,guiHeight-1);
		love.graphics.setColor(0,0,0);
		if mode ~= "setting" then
			--The slow box extends 10% across x, with each triangle taking up 30% of the width of the slow box
			love.graphics.polygon("fill",math.floor(0.02*maxx),0.5*guiHeight,math.floor(0.05*maxx),0.25*guiHeight,math.floor(0.05*maxx),0.75*guiHeight);
			love.graphics.polygon("fill",math.floor(0.05*maxx),0.5*guiHeight,math.floor(0.08*maxx),0.25*guiHeight,math.floor(0.08*maxx),0.75*guiHeight);
			love.graphics.rectangle("fill",math.floor(0.1*maxx)-1,0,2,guiHeight);
			--The fast box extends 10% across x, with same thing
			love.graphics.polygon("fill",math.floor(0.12*maxx),0.25*guiHeight,math.floor(0.12*maxx),0.75*guiHeight,math.floor(0.15*maxx),0.5*guiHeight);
			love.graphics.polygon("fill",math.floor(0.15*maxx),0.25*guiHeight,math.floor(0.15*maxx),0.75*guiHeight,math.floor(0.18*maxx),0.5*guiHeight);
			love.graphics.rectangle("fill",math.floor(0.2*maxx)-1,0,2,guiHeight);
		end
		--The info mark takes up the last 10% of x
		love.graphics.print("?", math.floor(0.94*maxx), math.floor(0.25*guiHeight));
		if mode == "setting" then
			--The Clear button overwrites the slow and fast boxes
			love.graphics.setColor(1,0,0);
			love.graphics.rectangle("fill", 0, 0, math.floor(0.2*maxx), guiHeight);
			love.graphics.setColor(0,0,0);
			love.graphics.print("Clear", math.floor(0.075*maxx), math.floor(0.25*guiHeight));
			--Text extends 50% across x
			love.graphics.print("Click or touch tiles to change them.", math.floor(0.225*maxx), math.floor(0.25*guiHeight));
			--Run button extends another 20%
			love.graphics.setColor(0,1,0);
			love.graphics.rectangle("fill", math.floor(0.7*maxx), 0, math.floor(0.2*maxx), guiHeight);
			love.graphics.setColor(0,0,0);
			love.graphics.print("Run", math.floor(0.775*maxx), math.floor(0.25*guiHeight));
		elseif mode == "paused" then
			--Generation is right 20% (not counting info mark)
			love.graphics.print("Gen: " .. currentGeneration, math.floor(0.75*maxx), math.floor(0.25*guiHeight));
			love.graphics.rectangle("fill",math.floor(0.9*maxx)-1,0,2,guiHeight);
			--Stop button extends 20% across x
			love.graphics.setColor(1,0,0);
			love.graphics.rectangle("fill", math.floor(0.2*maxx), 0, math.floor(0.2*maxx), guiHeight);
			love.graphics.setColor(0,0,0);
			love.graphics.print("Stop", math.floor(0.275*maxx), math.floor(0.25*guiHeight));
			--Continue button extends 30% across x
			love.graphics.setColor(0,1,0);
			love.graphics.rectangle("fill", math.floor(0.4*maxx), 0, math.floor(0.3*maxx), guiHeight);
			love.graphics.setColor(0,0,0);
			love.graphics.print("Continue", math.floor(0.5*maxx), math.floor(0.25*guiHeight));
		elseif mode == "running" then
			--Generation is right 20% (not counting info mark)
			love.graphics.print("Gen: " .. currentGeneration, math.floor(0.75*maxx), math.floor(0.25*guiHeight));
			love.graphics.rectangle("fill",math.floor(0.9*maxx)-1,0,2,guiHeight);
			--Pause button extends across 50% of x
			love.graphics.setColor(1,1,0);
			love.graphics.rectangle("fill", math.floor(0.2*maxx), 0, math.floor(0.5*maxx), guiHeight);
			love.graphics.setColor(0,0,0);
			love.graphics.print("Pause", math.floor(0.4*maxx), math.floor(0.25*guiHeight));
		end
	elseif mode == "info" then
		love.graphics.printf("About Life and its variants\nThe Game of Life is a cellular automaton invented by John Horton Conway. It involves living and dead cells that change every generation based on the status of each cell's eight neighbors. Each generation, the change is determined by three simple rules. Any living cell with 2 or 3 living neighbors survives. Any dead cell with exactly 3 living neighbors becomes a living cell. All other cells die or remain dead.\nIn this game, you can change the numbers. Any living cell with between 'p' and 'q' living neighbors lives, and any dead cell with between 'r' and 's' living neighbors lives. You can change the four numbers below.", 0, 0, maxx, "center");
		love.graphics.setColor(1,0,0);
		love.graphics.rectangle("fill", math.floor(0.975*maxx), 0, math.floor(0.025*maxx), math.floor(0.025*maxx));
		love.graphics.setColor(0,0,0);
		love.graphics.print("X", math.floor(0.98*maxx), 0);
		if oldmode == "paused" then
			love.graphics.printf("Stop simulation to change!", 0, 0.9*maxy, maxx, "center");
		end
		love.graphics.print("p: " .. tostring(setNumbers.p), 0, math.floor(0.8*maxy));
		love.graphics.print("q: " .. tostring(setNumbers.q), math.floor(0.25*maxx), math.floor(0.8*maxy));
		love.graphics.print("r: " .. tostring(setNumbers.r), math.floor(0.5*maxx), math.floor(0.8*maxy));
		love.graphics.print("s: " .. tostring(setNumbers.s), math.floor(0.75*maxx), math.floor(0.8*maxy));
	elseif mode == "egg" then
		love.graphics.setColor(0,0,0);
		love.graphics.rectangle("fill",0,0,maxx,maxy);
		love.graphics.setColor(1,1,1);
		local text = "What is this: " .. evilInput .. "? What is this?\n";
		if elapsedTime < 1 then--Do nothing more
		elseif elapsedTime < 2 then
			text = text .. "This isn't a number!\n";
		elseif elapsedTime < 3 then
			text = text .. "This isn't a number!\nOhhhhhhhh...";
		elseif elapsedTime < 4 then
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\n";
		elseif elapsedTime < 5 then
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\nYou tried to kill me! Break my code! Give me an error!\n";
		elseif elapsedTime < 6 then
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\nYou tried to kill me! Break my code! Give me an error!\nHow could you?\n";
		elseif elapsedTime < 7 then
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\nYou tried to kill me! Break my code! Give me an error!\nHow could you?\nWell, it didn't work. My developer thought of your plans. He thought ahead to stop you from doing that.\n";
		elseif elapsedTime < 9 then
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\nYou tried to kill me! Break my code! Give me an error!\nHow could you?\nWell, it didn't work. My developer thought of your plans. He thought ahead to stop you from doing that.\nYou know, developers say you should never trust the user.\n";
		else
			text = text .. "This isn't a number!\nOhhhhhhhh... You knew that, didn't you?\nYou tried to kill me! Break my code! Give me an error!\nHow could you?\nWell, it didn't work. My developer thought of your plans. He thought ahead to stop you from doing that.\nYou know, developers say you should never trust the user.\nNow I know why. Ugh... how could you... these users are so mean to me... grr grr grump grump........";
		end
		if elapsedTime >= 10 then
			text = text .. "\n[Click or tap anywhere to leave this screen]";
		end
		love.graphics.printf(text, 0, 0, maxx, "left");
	end
end
function love.update(dt)
	scrollWaitTime = math.max(scrollWaitTime-dt,0);
	if mode == "running" then
		elapsedTime = elapsedTime + dt;
		if elapsedTime >= waitTime then
			elapsedTime = elapsedTime - waitTime;
			local otherTable = {};
			for i,v in ipairs(livingPoints) do
				local xgo = -1; local ygo = -1;
				while xgo <= 1 do
					while ygo <= 1 do
						if xgo ~= 0 or ygo ~= 0 then
							local found = false;
							for j,w in ipairs(otherTable) do
								if w.x == v.x+xgo and w.y == v.y+ygo then
									w.num = w.num + 1;
									found = true;
									break;
								end
							end
							if not found then
								table.insert(otherTable, {x=v.x+xgo, y=v.y+ygo, num=1});
							end
						end
						ygo = ygo + 1;
					end
					xgo = xgo + 1;
					ygo = -1;
				end
			end
			local replaceTable = {};
			local p = setNumbers.p; local q = setNumbers.q; local r = setNumbers.r; local s = setNumbers.s;
			for i,v in ipairs(otherTable) do
				local found = false;
				for j,w in ipairs(livingPoints) do
					if w.x == v.x and w.y == v.y then
						found = true;
						break;
					end
				end
				if found then
					if v.num >= p and v.num <= q then
						table.insert(replaceTable,{x=v.x,y=v.y});
					end
				else
					if v.num >= r and v.num <= s then
						table.insert(replaceTable,{x=v.x,y=v.y});
					end
				end
			end
			livingPoints = replaceTable;
			currentGeneration = currentGeneration + 1;
		end
	end
	if mode == "egg" then
		elapsedTime = elapsedTime + dt;
	end
end
function love.touchmoved(id,x,y,dx,dy)
	if mode ~= "egg" and mode ~= "info" then
		canChangeLife = false;
		if y >= guiHeight and y-dy >= guiHeight then
			local numTouches = table.getn(love.touch.getTouches());
			if numTouches == 2 then
				local xdist = nil;
				local ydist = nil;
				for i,id in ipairs(love.touch.getTouches()) do
					if xdist then
						local x; local y;
						x,y = love.touch.getPosition(id);
						xdist = xdist - x;
						ydist = ydist - y;
					else
						xdist,ydist = love.touch.getPosition(id);
					end
				end
				local Distance = math.sqrt(xdist*xdist+ydist*ydist);
				cellSize = math.floor(initialCellSize*Distance/initialDistance);
				if cellSize < 5 then
					cellSize = 5;
				end
				if cellSize > 100 then
					cellSize = 100;
				end
				lineWidth = math.ceil(cellSize/20);
			elseif numTouches == 1 then
				xTouchDistance = xTouchDistance + dx;
				yTouchDistance = yTouchDistance + dy;
				while math.abs(xTouchDistance) > cellSize do
					local sign = math.abs(xTouchDistance)/xTouchDistance;
					xOffset = xOffset - sign;
					xTouchDistance = sign*(math.abs(xTouchDistance) - cellSize);
				end
				while math.abs(yTouchDistance) > cellSize do
					local sign = math.abs(yTouchDistance)/yTouchDistance;
					yOffset = yOffset - sign;
					yTouchDistance = sign*(math.abs(yTouchDistance) - cellSize);
				end
			end
		end
	end
end
function love.touchpressed(id,x,y)
	if mode == "info" then
		local maxx; local maxy;
		maxx, maxy = love.graphics.getDimensions();
		if x >= 0.975*maxx and y <= 0.025*maxy then
			mode = oldmode;
			oldmode = nil;
		elseif y >= 0.8*maxy and oldmode == "setting" then
			if x < 0.25*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "p";
			elseif x < 0.5*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "q";
			elseif x < 0.75*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "r";
			else
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "s";
			end
		end
	elseif mode == "egg" then
		evilInput = nil;
		mode = "info";
	else
		if y >= guiHeight then
			canChangeLife = true;
			xTouchDistance = 0;
			yTouchDistance = 0;
			initialCellSize = cellSize;
			local numTouches = table.getn(love.touch.getTouches());
			if numTouches == 2 then
				canChangeLife = false;
				local xdist = nil;
				local ydist = nil;
				for i,id in ipairs(love.touch.getTouches()) do
					if xdist then
						local x; local y;
						x,y = love.touch.getPosition(id);
						xdist = xdist - x;
						ydist = ydist - y;
					else
						xdist,ydist = love.touch.getPosition(id);
					end
				end
				initialDistance = math.sqrt(xdist*xdist+ydist*ydist);
			end
		else --Handle touches in top GUI Banner
			local maxx = love.graphics.getDimensions();
			if x > 0.9*maxx then
				if mode == "running" then
					oldmode = "paused";
				else
					oldmode = mode;
				end
				mode = "info";
			elseif x < 0.2*maxx then
				if mode == "setting" then
					livingPoints = {};
				elseif x > 0.1*maxx then
					waitTime = math.max(waitTime/2, 0.03125);
				else
					waitTime = math.min(2*waitTime, 4);
				end
			elseif mode == "setting" and x > 0.7*maxx then
				mode = "running";
				elapsedTime = 0;
				currentGeneration = 0;
			elseif mode == "running" and x < 0.7*maxx then
				mode = "paused";
			elseif mode == "paused" and x < 0.4*maxx then
				mode = "setting";
			elseif mode == "paused" and x < 0.7*maxx then
				mode = "running";
				elapsedTime = waitTime;
			end
		end
	end
end
function love.touchreleased(id,x,y)
	if mode ~= "egg" and mode ~= "info" then
		if canChangeLife and mode == "setting" then
			local xcell = math.floor(x/cellSize) + xOffset;
			local ycell = math.floor((y-guiHeight)/cellSize) + yOffset;
			local found = nil;
			for i,v in ipairs(livingPoints) do
				if v.x == xcell and v.y == ycell then
					found = i;
				end
			end
			if found then
				table.remove(livingPoints, found);
			else
				table.insert(livingPoints, {x=xcell,y=ycell});
			end
			canChangeLife = false;
		end
	end
end
function love.wheelmoved(x,y)
	if mode ~= "egg" and mode ~= "info" then
		if y > 0 and scrollWaitTime == 0 then
			scrollWaitTime = 0.1;
			cellSize = math.min(cellSize + 5, 100);
			lineWidth = math.ceil(cellSize/20);
		end
		if y < 0 and scrollWaitTime == 0 then
			scrollWaitTime = 0.1;
			cellSize = math.max(cellSize - 5, 10);
			lineWidth = math.ceil(cellSize/20);
		end
	end
end
function love.mousemoved(x,y,dx,dy)
	if mode ~= "egg" and mode ~= "info" then
		if love.mouse.isDown(1,2) then
			clickOnCell = false;
			xMouseDistance = xMouseDistance + dx;
			yMouseDistance = yMouseDistance + dy;
			while math.abs(xMouseDistance) > cellSize do
				local sign = math.abs(xMouseDistance)/xMouseDistance;
				xOffset = xOffset - sign;
				xMouseDistance = sign*(math.abs(xMouseDistance) - cellSize);
			end
			while math.abs(yMouseDistance) > cellSize do
				local sign = math.abs(yMouseDistance)/yMouseDistance;
				yOffset = yOffset - sign;
				yMouseDistance = sign*(math.abs(yMouseDistance) - cellSize);
			end
		end
	end
end
function love.mousepressed(x,y,button)
	if mode == "info" and (button == 1 or button == 2) then
		local maxx; local maxy;
		maxx, maxy = love.graphics.getDimensions();
		if x >= 0.975*maxx and y <= 0.025*maxy then
			mode = oldmode;
			oldmode = nil;
		elseif y >= 0.8*maxy and oldmode == "setting" then
			if x < 0.25*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "p";
			elseif x < 0.5*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "q";
			elseif x < 0.75*maxx then
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "r";
			else
				love.keyboard.setTextInput(true, 0, 0.8*maxy, maxx, 0.1*maxy);
				numberToChange = "s";
			end
		end
	elseif mode == "egg" and (button == 1 or button == 2) then
		evilInput = nil;
		mode = "info";
	elseif button == 1 or button == 2 then
		xMouseDistance = 0;
		yMouseDistance = 0;
		if y >= guiHeight and button == 1 then
			clickOnCell = true;
		elseif button == 1 then
			local maxx = love.graphics.getDimensions();
			if x > 0.9*maxx then
				if mode == "running" then
					oldmode = "paused";
				else
					oldmode = mode;
				end
				mode = "info";
			elseif x < 0.2*maxx then
				if mode == "setting" then
					livingPoints = {};
				elseif x > 0.1*maxx then
					waitTime = math.max(waitTime/2, 0.03125);
				else
					waitTime = math.min(2*waitTime, 4);
				end
			elseif mode == "setting" and x > 0.7*maxx then
				mode = "running";
				elapsedTime = 0;
				currentGeneration = 0;
			elseif mode == "running" and x < 0.7*maxx then
				mode = "paused";
			elseif mode == "paused" and x < 0.4*maxx then
				mode = "setting";
			elseif mode == "paused" and x < 0.7*maxx then
				mode = "running";
				elapsedTime = waitTime;
			end
		end
	end
end
function love.mousereleased(x,y,button)
	if clickOnCell and button == 1 and mode == "setting" then
		local xcell = math.floor(x/cellSize) + xOffset;
		local ycell = math.floor((y-guiHeight)/cellSize) + yOffset;
		local found = nil;
		for i,v in ipairs(livingPoints) do
			if v.x == xcell and v.y == ycell then
				found = i;
			end
		end
		if found then
			table.remove(livingPoints, found);
		else
			table.insert(livingPoints, {x=xcell,y=ycell});
		end
		clickOnCell = false;
	end
end
function love.visible(visible)
	if mode == "running" and not visible then
		mode = "paused";
	end
end
function love.textinput(text)
	love.keyboard.setTextInput(false);
	local num = tonumber(text);
	if num then
		local wouldbe = {p=setNumbers.p,q=setNumbers.q,r=setNumbers.r,s=setNumbers.s};
		wouldbe[numberToChange] = num;
		if num >= 0 and num <= 8 and wouldbe.p <= wouldbe.q and wouldbe.r <= wouldbe.s then
			setNumbers[numberToChange] = num;
		else
			love.system.vibrate(0.2);
		end
	else
		evilInput = text;
		mode = "egg";
		elapsedTime = 0;
	end
	numberToChange = nil;
end
function love.lowmemory()
	collectgarbage(); collectgarbage();
end


