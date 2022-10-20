import httpclient,strutils

var client = newHttpClient()

proc checkLatestVersion(maven,proj: string): string=
  let url = maven & proj & "maven-metadata.xml"
  let data = client.getContent(url)
  let a = data.find("<latest>")
  let b = data.find("</latest>")
  if a != -1 and b != -1:
    return data[a + 8 .. b - 1]

const minecraft_version* = "1.19.2"
const version* = "0.1.0+" & minecraft_version
const maven_group* = "io.github.offbeat_stuff"
const archives_base_name* = "save_blocker"
const mod_name* = "Save Blocker"
const modid* = "save_blocker"

let ModName = mod_name.replace(" ","")

# quilt_mappings = 3
# quilt_loader = 0.17.1
# qsl = 4.0.0-beta.12
# fabric_api = 0.61.0
# loom_version = 1.0.3

const quilt_maven = "https://maven.quiltmc.org/repository/release/"
let quilted_api_version = checkLatestVersion(quilt_maven,"org/quiltmc/quilted-fabric-api/quilted-fabric-api/")
let tempa = quilted_api_version.split('+')

let qsl = tempa[0]
let fabric_api = tempa[1].split('-')[0]

assert tempa[1].split('-')[1] == minecraft_version

let quilt_loader = checkLatestVersion(quilt_maven,"org/quiltmc/quilt-loader/")
let loom_version = checkLatestVersion(quilt_maven,"org/quiltmc/loom/")

let quilt_mapping_version = "1.19.2+build.21" #checkLatestVersion(quilt_maven,"org/quiltmc/quilt-mappings/")
assert quilt_mapping_version[0 .. minecraft_version.len() + 6] == minecraft_version & "+build."
let quilt_mappings = quilt_mapping_version[minecraft_version.len() + 7 .. ^1]

proc genGradleProperties*(): seq[string]=
  template addToResult(val: string)=
    result.add(astToStr(val) & " = " & val)
  addToResult(minecraft_version)
  addToResult(version)
  addToResult(maven_group)
  addToResult(archives_base_name)
  addToResult(mod_name)
  addToResult(ModName)
  addToResult(modid)

  addToResult(qsl)
  addToResult(fabric_api)

  addToResult(quilt_loader)
  addToResult(quilt_mappings)
  addToResult(loom_version)

import os

createDir(mod_name)
copyFile("files/gitignore",mod_name & "/.gitignore")
copyFile("files/.editorconfig",mod_name & "/.editorconfig")
for i in ["build.gradle","settings.gradle"]:
  copyFile("files/" & i,mod_name & "/" & i)

writeFile(mod_name & "/gradle.properties",readFile("files/gradle.properties") & "\n" & genGradleProperties().join("\n"))

createDir(mod_name & "/src")
createDir(mod_name & "/src/main")
createDir(mod_name & "/src/main/java")

createDir(mod_name & "/src/main/resources")
createDir(mod_name & "/src/main/resources/assets")
createDir(mod_name & "/src/main/resources/assets/" & modid)
copyFile("files/src/main/resources/assets/example_mod/icon.png",mod_name & "/src/main/resources/assets/" & modid & "/icon.png")
writeFile(mod_name & "/src/main/resources/" & modid & ".mixins.json",readFile("files/src/main/resources/example_mod.mixins.json").replace("com.example.example_mod",maven_group & "." & archives_base_name))
copyFile("files/src/main/resources/quilt.mod.json",mod_name & "/src/main/resources/quilt.mod.json")

block createJavaSrcDir:
  let temp = (maven_group & "." & archives_base_name).split('.')
  for i in temp.low .. temp.high:
    createDir mod_name & "/src/main/java/" & temp[0 .. i].join("/")
  createDir mod_name & "/src/main/java/" & temp.join("/") & "/mixin"
  let a = readFile("files/src/main/java/com/example/example_mod/ExampleMod.java")
  let b = readFile("files/src/main/java/com/example/example_mod/mixin/TitleScreenMixin.java")
  writeFile mod_name & "/src/main/java/" & temp.join("/") & "/" & ModName & "Mod.java",a
  writeFile mod_name & "/src/main/java/" & temp.join("/") & "/mixin/TitleScreenMixin.java",b
