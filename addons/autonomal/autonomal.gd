@tool
extends EditorPlugin

const SETTING_PREFIX = "autonormal/"
const PROPERTIES = [
    { "name": SETTING_PREFIX + "normal suffix",
      "type": TYPE_STRING,
      "hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
      "hint_string": "suffix of normal maps",
      "default": "_n" }
  ]
const MENU_ITEM = "Generate CanvasTextures based on normal maps"
const EXTENSIONS = ["png"] # TODO: more formats

var normal_suffix = PROPERTIES[0].get("default", "_n") # default

func _enter_tree() -> void:
  var settings = get_editor_interface().get_editor_settings()
  
  for prop in PROPERTIES:
    if not settings.has_setting(prop.name):
      settings.set_setting(prop.name, prop.get("default", null))
      settings.add_property_info(prop)

  add_tool_menu_item(MENU_ITEM, generate_all)
  normal_suffix = settings.get_setting(SETTING_PREFIX + "normal suffix")


func _exit_tree() -> void:
  remove_tool_menu_item(MENU_ITEM)

# generate all canvas textures according to the configurations
func generate_all() -> void:
  var textures = scan("res://") # TODO: config scan pathes
  for txt in textures:
    generate(txt)

# scan the given path to get all image files
# that have corresponding normal maps
# path: String, the given path to be scanned
# return: Array[String], an array of images that have normal maps
func scan(path: String) -> Array[String]:
  var queue = [path]
  var res: Array[String] = []
  
  while not queue.is_empty():
    var cur = queue.pop_front()
    var dir = DirAccess.open(cur)
    if dir == null:
      continue # TODO: how?
    dir.list_dir_begin()
    var filename = dir.get_next()
    while filename != "":
      var full_path = cur.path_join(filename)
      if dir.current_is_dir():
        queue.push_back(full_path)
      else:
        var nm_file = get_normal_map(full_path)
        if FileAccess.file_exists(nm_file):
          res.push_back(full_path)
      filename = dir.get_next()
    dir.list_dir_end()
  
  return res

# compute the normal map file name
# return empty string if the given file is not a valid texture file
# file: String, the given diffuse file
# return: String, the corresponding normal map file name
func get_normal_map(file: String) -> String:
  var basename = file.get_basename()
  var ext = file.get_extension()
  # TODO: allow normal maps in different formats/paths?
  if ext not in EXTENSIONS:
    return ""
  else:
    return basename + normal_suffix + "." + ext

# generate the canvas texture by the given diffuse texture
# and normal map
# it assumes that both files exist
func generate(file: String) -> void:
  var basename = file.get_basename()
  var normal_map = get_normal_map(file)
  var output = basename + ".tres"
  
  var ct = CanvasTexture.new()
  ct.diffuse_texture = load(file)
  ct.normal_texture = load(normal_map)
  ResourceSaver.save(ct, output)
