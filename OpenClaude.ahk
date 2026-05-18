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
  chkVSCode := g.Add("CheckBox",, "VS Code 打开")
  btnOpen := g.Add("Button", "Default w100", "打开")
  btnRebuild := g.Add("Button", "wp", "重建索引")

  ; 显示初始结果
  UpdateResults(lbResults, folders, "")

  ; 事件绑定
  edSearch.OnEvent("Change", (*) => UpdateResults(lbResults, folders, edSearch.Value))
  lbResults.OnEvent("DoubleClick", (*) => OpenFolder(g, lbResults, chkMemory, chkVSCode))
  btnOpen.OnEvent("Click", (*) => OpenFolder(g, lbResults, chkMemory, chkVSCode))
  btnRebuild.OnEvent("Click", (*) => RebuildIndex(g, lbResults, folders))
  g.OnEvent("Close", (*) => g.Destroy())

  edSearch.Focus()
  g.Show()
}

UpdateResults(lb, folders, query) {
  lb.Delete()
  q := StrLower(query)

  if (q = "") {
    count := 0
    for f in folders {
      if (count >= 30)
        break
      lb.Add([f])
      count++
    }
    return
  }

  ; 评分，拼成 "分数|路径" 格式的字符串
  sortStr := ""
  for f in folders {
    score := MatchScore(q, StrLower(f))
    if (score > 0)
      sortStr .= score "|" f "`n"
  }

  ; 按分数倒序排列
  sortStr := Sort(sortStr, "R N")

  ; 取前30个
  count := 0
  loop parse sortStr, "`n" {
    if (count >= 30 || A_LoopField = "")
      break
    pos := InStr(A_LoopField, "|")
    lb.Add([SubStr(A_LoopField, pos + 1)])
    count++
  }
}

MatchScore(query, text) {
  SplitPath text, &name
  nameL := StrLower(name)

  ; 文件夹名完全匹配
  if (nameL = query)
    return 10000
  ; 文件夹名以查询开头
  if (SubStr(nameL, 1, StrLen(query)) = query)
    return 5000
  ; 文件夹名包含查询
  if (InStr(nameL, query))
    return 3000
  ; 路径包含查询
  if (InStr(text, query))
    return 1000
  ; 文件夹名模糊匹配
  if (FuzzyMatch(query, nameL))
    return 500
  ; 全路径模糊匹配
  if (FuzzyMatch(query, text))
    return 100
  return 0
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

OpenFolder(g, lb, chkMem, chkCode) {
  folder := lb.Text
  if (folder = "")
    return
  useMemory := chkMem.Value
  useVSCode := chkCode.Value
  g.Destroy()

  cmd := useMemory ? "claude -c" : "claude"

  if useVSCode {
    Run('"C:\Users\xupeng0117\AppData\Local\Programs\Microsoft VS Code\Code.exe" "' folder '"')
    Sleep(3000)
    WinActivate("ahk_exe Code.exe")
    Sleep(500)
    SendInput("^``")
    Sleep(800)
    SendInput(cmd "{Enter}")
  } else {
    Run('cmd /k ' cmd, folder, "Max")
  }
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
