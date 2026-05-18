#Requires AutoHotkey v2.0
; 翻译选中中文为 snake_case 字段名: Ctrl+Alt+T

^!t:: {
  A_Clipboard := ""
  Send("^c")
  if !ClipWait(2)
    return

  text := A_Clipboard
  if (text = "")
    return

  inFile  := A_Temp "\translate_in.txt"
  outFile := A_Temp "\translate_out.txt"

  FileOpen(inFile, "w", "UTF-8").Write(text)

  RunWait('"C:\Program Files\nodejs\node.exe" "D:\tools\sql-formatter\translate-field.js" "' inFile '" "' outFile '"', , "Hide")

  if FileExist(outFile) {
    result := FileOpen(outFile, "r", "UTF-8").Read()
    if (result != "") {
      A_Clipboard := result
      ClipWait(2)
      Send("^v")
    }
  }

  try {
    FileDelete(inFile)
  }
  try {
    FileDelete(outFile)
  }
}
