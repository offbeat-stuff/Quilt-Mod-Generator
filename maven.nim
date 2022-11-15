import xmlparser,xmltree,strutils

type MavenMetadata = object
  latest*,release* : string
  versions* : seq[string]

proc loadMetadata* (x: string): MavenMetadata=
  var xml = parseXml(x)
  assert xml.tag == "metadata"

  let release = xml.findAll("release")
  assert release.len == 1
  result.release = release[0].innerText

  let latest = xml.findAll("latest")
  assert latest.len == 1
  result.latest = latest[0].innerText

  for i in xml.findAll("version"):
    result.versions.add(i.innerText)

proc doesItMatch(x,pattern: string): bool=
  var strPos,patPos: int
  while patPos < pattern.len():
    if pattern[patPos] == '*':
      patPos.inc()
      while x[strPos] in Digits:
        strPos.inc()
        if strPos == x.len():
          return if patPos == pattern.len(): true
          else: false
    else:
      if pattern[patPos] != x[strPos]:
        return false
      patPos.inc()
      strPos.inc()
    if x.len() - strPos < pattern.len() - patPos:
      return false
  return x.len() - strPos == 0

import algorithm

proc findLatestMatch* (meta: MavenMetadata,pattern: string): string=
  if meta.latest.doesItMatch(pattern):
    return meta.latest
  for i in meta.versions.reversed():
    if i.doesItMatch(pattern):
      return i
  return ""