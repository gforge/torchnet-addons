package = "torchnet-addons"
version = "scm-1"
source = {
    url = "https://github.com/gforge/torchnet-addons/archive/master.tar.gz",
    dir = "torchnet-addons-master"
}
description = {
    summary = "Addons for torchnet",
    detailed = [[
       A set of addons to the torchnet pacakge from Facebook
    ]],
    homepage = "https://github.com/gforge/torchnet-addons",
    license = "MIT/X11",
    maintainer = "Max Gordon"
}
dependencies = {
    "lua >= 5.1",
    "torch >= 7.0",
    "argcheck >= 2.0",
    "luafilesystem >= 1.6.3",
    "paths",
    "torchnet >= 1.0",
    "threads >= 1.0",
    "nn"
}
build = {
   type = "cmake",
   variables = {
      CMAKE_BUILD_TYPE="Release",
      LUA_PATH="$(LUADIR)",
      LUA_CPATH="$(LIBDIR)"
   }
}
