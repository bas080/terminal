minetest.register_node("terminal:client", {
  drawtype = "nodebox",
  tiles = {"terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_off.png"},
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {},
  description="Client",
  on_punch = function (pos)
    minetest.sound_play("terminal_on",{pos=pos,gain=0.7,max_hear_distance=32})
    local facing = minetest.env:get_node(pos).param2
    minetest.env:set_node(pos, { name="terminal:client_on", param2=facing })
  end,
  sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("terminal:client_on", {
  drawtype = "nodebox",
  tiles = {"terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client.png"},
  paramtype = "light",
  paramtype2 = "facedir",
  light_source = 3,
  groups = {},
  description = "Client",
  on_construct = function(pos)
    local meta = minetest.env:get_meta(pos)
    meta:set_string("formspec", "field[text;;${text}]")
  end,
  on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		fields.text = fields.text or ""
		meta:set_string("text", fields.text)
		local terminal_output = terminal_command(fields.text, sender, pos)
		if (terminal_output == "exit") then
		  local facing = minetest.env:get_node(pos).param2
		  minetest.env:set_node(pos, { name="terminal:client", param2=facing })
		else
		  meta:set_string("infotext", terminal_output)
		end
	end,
  on_punch = function (pos, node, puncher)
    local meta = minetest.env:get_meta(pos)
    local command = meta:get_string("text")
    local terminal_output = terminal_command(command, puncher, pos)
		meta:set_string("infotext", terminal_output)
  end,
  sounds = default.node_sound_wood_defaults(),
})

function terminal_command(command, sender, pos)
  print((sender:get_player_name() or "").." executed \""..command.."\" on client at "..minetest.pos_to_string(pos))
  if (command == "exit") then
    return "exit"
  end
  local state = os.execute(command.." | tee -i > output")
  local f = io.open("output", "r")
  if f then
    local contents = f:read("*all")
    if (contents == nil or contents == "") then
      return "> "..command
    else
      return "> "..command.."\n"..contents
    end
  end
  return "error"
end
