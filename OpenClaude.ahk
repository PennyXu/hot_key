#Requires AutoHotkey v2.0
; Ctrl+Alt+P: 模糊搜索文件夹并打开 Claude

^!p:: ShowClaudeSearch()

ShowClaudeSearch() {
  cacheFile := "D:\tools\sql-formatter\folder_cache.txt"

  ; 首次使用自动构建索引
  if !FileExist(cacheFile) {
    ToolTip("正在构建文件夹索引，请稍候...")
    RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\open-claude.js" build', , "Hide")
    ToolTip()
  }

  ; 加载文件夹列表（UTF-8）
  folders := []
  LoadCache(folders, cacheFile)

  ; 创建 GUI
  g := Gui("+AlwaysOnTop", "Open Claude")
  g.SetFont("s10", "Consolas")

  g.Add("Text",, "搜索文件夹:")
  edSearch := g.Add("Edit", "w700")
  lbResults := g.Add("ListBox", "w700 r20")
  chkMemory := g.Add("CheckBox",, "带记忆打开 (claude -c)")
  btnOpen := g.Add("Button", "Default w100", "打开")
  btnRebuild := g.Add("Button", "wp", "重建索引")

  ; 显示初始结果
  UpdateResults(lbResults, folders, "")

  ; 事件绑定
  edSearch.OnEvent("Change", (*) => UpdateResults(lbResults, folders, edSearch.Value))
  lbResults.OnEvent("DoubleClick", (*) => OpenFolder(g, lbResults, chkMemory))
  btnOpen.OnEvent("Click", (*) => OpenFolder(g, lbResults, chkMemory))
  btnRebuild.OnEvent("Click", (*) => RebuildIndex(g, lbResults, folders))
  g.OnEvent("Close", (*) => g.Destroy())

  edSearch.Focus()
  g.Show()
}

UpdateResults(lb, folders, query) {
  lb.Delete()
  count := 0
  q := StrLower(query)
  for f in folders {
    if (count >= 30)
      break
    if (q = "" || FuzzyMatch(q, StrLower(f))) {
      lb.Add([f])
      count++
    }
  }
}

FuzzyMatch(query, text) {
  qi := 1
  Loop Parse text {
    if (qi > StrLen(query))
      return true
    if (A_LoopField = SubStr(query, qi, 1))
      qi++
  }
  return qi > StrLen(query)
}

OpenFolder(g, lb, chk) {
  folder := lb.Text
  if (folder = "")
    return
  useMemory := chk.Value
  g.Destroy()

  cmd := useMemory ? "claude -c" : "claude"
  Run('cmd /k ' cmd, folder, "Max")
}

RebuildIndex(g, lb, folders) {
  ToolTip("正在重建文件夹索引...")
  cacheFile := "D:\tools\sql-formatter\folder_cache.txt"
  FileDelete(cacheFile)
  RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\open-claude.js" build', , "Hide")
  ToolTip()

  folders.Length := 0
  LoadCache(folders, cacheFile)
  UpdateResults(lb, folders, "")
}

LoadCache(folders, cacheFile) {
  file := FileOpen(cacheFile, "r", "UTF-8")
  while !file.AtEOF {
    folders.Push(RTrim(file.ReadLine(), "`r`n"))
  }
  file.Close()
}
