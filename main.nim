import httpclient,strutils,maven
import sequtils

var client = newHttpClient()

proc checkLatestVersion(maven,proj,pattern: string): string=
  let url = maven & proj & "maven-metadata.xml"
  let data = client.getContent(url)
  let meta = loadMetadata(data)
  result = meta.findLatestMatch(pattern)
  echo maven," - ",proj,"|> ",result

proc checkLatestVersion(maven,proj: string): string=
  let url = maven & proj & "maven-metadata.xml"
  let data = client.getContent(url)
  let meta = loadMetadata(data)
  result = meta.latest
  echo maven," - ",proj,"|> ",result

const mc_version = "1.19.3"
const version = "0.1.0+" & mc_version
const maven_group = "io.github.offbeat_stuff"
const archives_base_name = "one_block_testing"
const mod_name = "One Block Testing"
const modid = "one_block_testing"

let ModName = mod_name.replace(" ","")

# qfapi_version = 5.0.0-beta.2
# fapi_version = 0.68.1-1.19.3
# ql_version = 0.18.1-beta.22
# qm_version = 1.19.3-rc1+build.4
# loom_version = 1.0.8

const quilt_maven = "https://maven.quiltmc.org/repository/release/"
let quilted_api_version = checkLatestVersion(quilt_maven,"org/quiltmc/quilted-fabric-api/quilted-fabric-api/")
let ql_version = checkLatestVersion(quilt_maven,"org/quiltmc/quilt-loader/")
let loom_version = checkLatestVersion(quilt_maven,"org/quiltmc/loom/")
let qm_version = checkLatestVersion(quilt_maven,"org/quiltmc/quilt-mappings/")

let tempa = quilted_api_version.split('+')

let qfapi_version = tempa[0]
let fapi_version = tempa[1]

assert fapi_version.split('-')[1] == mc_version
assert qm_version.startsWith(mc_version)

proc genGradleProperties*(): seq[string]=
  template addToResult(val: string)=
    result.add(astToStr(val) & " = " & val)
  addToResult(mc_version)
  addToResult(version)
  addToResult(maven_group)
  addToResult(archives_base_name)
  addToResult(mod_name)
  addToResult(ModName)
  addToResult(modid)

  addToResult(qfapi_version)
  addToResult(fapi_version)

  addToResult(ql_version)
  addToResult(qm_version)
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
