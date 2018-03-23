Sub qingchu()
   With Sheet2
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet4
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet6
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet8
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet10
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet12
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet14
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet16
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet18
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet20
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet22
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet24
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet26
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet28
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet30
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet32
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet34
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet36
      .Range("A1:AH2500").ClearContents
   End With
    With Sheet38
      .Range("A1:AH2500").ClearContents
   End With
    With Sheet40
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet42
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet44
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet46
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet48
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet51
      .Range("A1:AH2500").ClearContents
   End With
   With Sheet52
      .Range("A1:AH2500").ClearContents
   End With
End Sub











Sub clear()
For i = 0 To Worksheets.Count Step 2        'worksheets.count:统计工作表总数。
'for i=2 to ..... 从2开始循环，一直到工作表总数，每次循环，i值增加1
Dim myrange As Range    '声明一个类型为Range(引用)的变量myrange
Set myrange = Sheets(i).Range("A1:AH2500") 
              
For Each c In myrange    'for each ... in....关键字。在某集合(myrange)中遍历所有子元素(c)
c.ClearContents   
Next       
Next      
End Sub



Sub qingchu2()
   With Sheet2
      .Range("A1:CT100").ClearContents
   End With
   With Sheet4
      .Range("A1:CT100").ClearContents
   End With
   With Sheet6
      .Range("A1:CT100").ClearContents
   End With
   With Sheet8
      .Range("A1:CT100").ClearContents
   End With
   With Sheet10
      .Range("A1:CT100").ClearContents
   End With
   With Sheet12
      .Range("A1:CT100").ClearContents
   End With
   With Sheet14
      .Range("A1:CT100").ClearContents
   End With
End Sub












