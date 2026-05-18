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

  ; 加载缓存：path<TAB>desc
  entries := []
  LoadCache(entries, cacheFile)

  ; 创建 GUI
  g := Gui("+AlwaysOnTop", "Open Claude")
  g.SetFont("s10", "Consolas")

  g.Add("Text",, "搜索项目名称或功能:")
  edSearch := g.Add("Edit", "w900")
  lbResults := g.Add("ListBox", "w900 r20")
  chkMemory := g.Add("CheckBox",, "带记忆打开 (claude -c)")
  chkVSCode := g.Add("CheckBox",, "VS Code 打开")
  btnOpen := g.Add("Button", "Default w100", "打开")
  btnAI := g.Add("Button", "wp", "AI搜索")
  btnRebuild := g.Add("Button", "wp", "重建索引")

  ; 显示初始结果
  UpdateResults(lbResults, entries, "")

  edSearch.OnEvent("Change", (*) => UpdateResults(lbResults, entries, edSearch.Value))
  lbResults.OnEvent("DoubleClick", (*) => OpenFolder(g, lbResults, entries, chkMemory, chkVSCode))
  btnOpen.OnEvent("Click", (*) => OpenFolder(g, lbResults, entries, chkMemory, chkVSCode))
  btnAI.OnEvent("Click", (*) => AISearch(g, lbResults, entries, edSearch))
  btnRebuild.OnEvent("Click", (*) => RebuildIndex(g, lbResults, entries))
  g.OnEvent("Close", (*) => g.Destroy())

  edSearch.Focus()
  g.Show()
}

UpdateResults(lb, entries, query) {
  lb.Delete()
  q := StrLower(query)

  if (q = "") {
    count := 0
    for e in entries {
      if (count >= 30)
        break
      lb.Add([e.display])
      count++
    }
    return
  }

  ; 评分排序
  sortStr := ""
  for e in entries {
    score := MatchScore(q, StrLower(e.path), StrLower(e.desc))
    if (score > 0)
      sortStr .= score "|" e.display "`n"
  }

  sortStr := Sort(sortStr, "R N")

  count := 0
  loop parse sortStr, "`n" {
    if (count >= 30 || A_LoopField = "")
      break
    pos := InStr(A_LoopField, "|")
    lb.Add([SubStr(A_LoopField, pos + 1)])
    count++
  }
}

MatchScore(query, pathLower, descLower) {
  ; 提取文件夹名
  SplitPath pathLower, &name
  nameL := StrLower(name)

  ; 文件夹名完全匹配
  if (nameL = query)
    return 10000
  ; 描述完全包含
  if (descLower != "" && InStr(descLower, query))
    return 8000
  ; 文件夹名前缀
  if (SubStr(nameL, 1, StrLen(query)) = query)
    return 5000
  ; 文件夹名包含
  if (InStr(nameL, query))
    return 3000
  ; 路径包含
  if (InStr(pathLower, query))
    return 1000
  ; 描述模糊
  if (descLower != "" && FuzzyMatch(query, descLower))
    return 800
  ; 文件夹名模糊
  if (FuzzyMatch(query, nameL))
    return 500
  ; 路径模糊
  if (FuzzyMatch(query, pathLower))
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

OpenFolder(g, lb, entries, chkMem, chkCode) {
  sel := lb.Text
  if (sel = "")
    return

  ; 从显示文本提取路径（| 之前的部分）
  folder := sel
  pipePos := InStr(sel, "  |  ")
  if (pipePos > 0)
    folder := Trim(SubStr(sel, 1, pipePos - 1))

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

AISearch(g, lb, entries, ed) {
  query := ed.Value
  if (query = "")
    return

  ToolTip("AI 语义搜索中...")
  cacheFile := "D:\tools\sql-formatter\folder_cache.txt"
  outFile := A_Temp "\ai_search_out.txt"
  RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\ai-search.js" "' query '" "' cacheFile '" > "' outFile '"', , "Hide")
  ToolTip()

  lb.Delete()
  if FileExist(outFile) {
    file := FileOpen(outFile, "r", "UTF-8")
    while !file.AtEOF {
      line := RTrim(file.ReadLine(), "`r`n")
      if (line != "")
        lb.Add([line])
    }
    file.Close()
    FileDelete(outFile)
  }
}

RebuildIndex(g, lb, entries) {
  ToolTip("正在重建文件夹索引...")
  cacheFile := "D:\tools\sql-formatter\folder_cache.txt"
  FileDelete(cacheFile)
  RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\open-claude.js" build', , "Hide")
  ToolTip()

  entries.Length := 0
  LoadCache(entries, cacheFile)
  UpdateResults(lb, entries, "")
}

LoadCache(entries, cacheFile) {
  file := FileOpen(cacheFile, "r", "UTF-8")
  while !file.AtEOF {
    line := RTrim(file.ReadLine(), "`r`n")
    if (line = "")
      continue
    ; 格式: path<TAB>desc
    tabPos := InStr(line, "`t")
    if (tabPos > 0) {
      p := SubStr(line, 1, tabPos - 1)
      d := SubStr(line, tabPos + 1)
      entries.Push({ path: p, desc: d, display: p "  |  " d })
    } else {
      entries.Push({ path: line, desc: "", display: line })
    }
  }
  file.Close()
}
