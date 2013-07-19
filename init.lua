minetest.register_node("terminal:client", {
  drawtype = "nodebox",
  tiles = {"terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_side.png", "terminal_client_off.png"},
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {dig_immediate=2},
  description="Client",
  on_construct = function(pos)
    local meta = minetest.env:get_meta(pos)
    meta:set_string("infotext", "")
  end,
  on_rightclick = function (pos)
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
    meta:set_string("formspec", "field[text;;${command}]")
    meta:set_string("channel", "terminal")
    meta:set_string("command", "")
  end,
  on_receive_fields = function(pos, formname, fields, sender)
    local meta = minetest.get_meta(pos)
    meta:set_string("command", fields.text)
    local terminal_output = terminal_command(fields.text, sender:get_player_name(), pos)
    if (terminal_output == "exit") then
      local facing = minetest.env:get_node(pos).param2
      minetest.env:set_node(pos, { name="terminal:client", param2=facing })
    else
      meta:set_string("infotext", terminal_output)
    end
  end,
  on_punch = function (pos, node, puncher)
    local meta = minetest.env:get_meta(pos)
    local command = meta:get_string("command")
    local terminal_output = terminal_command(command, (puncher:get_player_name()), pos)
    meta:set_string("infotext", terminal_output)
  end,
  mesecons = { effector = {
    action_on = function (pos, node)
      local meta = minetest.env:get_meta(pos)
      local command = meta:get_string("command")
      local terminal_output = terminal_command(command, "mesecons", pos)
      meta:set_string("infotext", terminal_output)
    end,
  }},
  digiline = { receptor = {},
    effector = {
      action = function(pos, node, channel, msg)
        local setchan = minetest.env:get_meta(pos):get_string("channel")
        if setchan ~= channel then return end
        local meta = minetest.env:get_meta(pos)
        local command = meta:get_string("command")
        local terminal_output = terminal_command(command, "digilines", pos)
        meta:set_string("infotext", terminal_output)
      end
    },
  },
})

function terminal_command(command, sender, pos)
  print(sender.." executed \""..command.."\" on client at "..minetest.pos_to_string(pos))
  if (command == "exit" or command == "logout") then
    return "exit"
  end
  if (string.sub(command, 1,9) == "digilines") then
    local meta = minetest.env:get_meta(pos)
    local channel = string.sub(command,11)
    meta:set_string("channel", string.sub(command,11))
    print(meta:get_string("channel"))
    return "> "..command.."\n Terminal channel has been renamed to "..channel
  end
  local state = os.execute(command.." > output")
  local f = io.open("output", "r")
  os.execute("rm output")
  if f then
    local contents = f:read("*all")
    if (contents == nil or contents == "" or contents == "\n") then
      return "> "..command.."\n..."
    else
      return "> "..command.."\n"..contents
    end
  end
  minetest.sound_play("terminal_on",{pos=pos,gain=0.7,max_hear_distance=32})
  return "error"
end
