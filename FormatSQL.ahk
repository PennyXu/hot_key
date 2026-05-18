#Requires AutoHotkey v2.0
; SQL 格式化快捷键: Ctrl+Alt+F
; 选中 SQL 文本后按快捷键，自动格式化并替换

^!f:: {
  ; 清空剪贴板并复制选中内容
  A_Clipboard := ""
  Send("^c")
  if !ClipWait(2)
    return

  sql := A_Clipboard
  if (sql = "")
    return

  inFile  := A_Temp "\sql_in.txt"
  outFile := A_Temp "\sql_out.txt"

  ; 写入临时文件
  FileOpen(inFile, "w", "UTF-8").Write(sql)

  ; 调用 Node.js 格式化
  RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\format-sql.js" "' inFile '" "' outFile '"', , "Hide")

  ; 读取结果并粘贴
  if FileExist(outFile) {
    result := FileOpen(outFile, "r", "UTF-8").Read()
    if (result != "") {
      A_Clipboard := result
      ClipWait(2)
      Send("^v")
    }
  }

  ; 清理临时文件
  try {
    FileDelete(inFile)
  }
  try {
    FileDelete(outFile)
  }
}
