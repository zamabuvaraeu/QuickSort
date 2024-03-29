#include once "InputDataDialogProc.bi"
#include once "win\commctrl.bi"
#include once "win\ole2.bi"
#include once "IntegerDivision.bi"
#include once "QuickSort.bi"
#include once "Resources.RH"

#ifdef UNICODE
#define _i64tot(value, buffer, radix) _i64tow(value, buffer, radix)
#else
#define _i64tot(value, buffer, radix) _i64toa(value, buffer, radix)
#endif

' wParam � index
' lParam � NULL
#define PM_STARTFILLVECTOR WM_USER

' wParam � index
' lParam � NULL
#define PM_ENDFILLVECTOR WM_USER + 1

' wParam � index
' lParam � NULL
#define PM_STARTSORTING WM_USER + 2

' wParam � index
' lParam � PerformanceMeasure Ptr
#define PM_ENDSORTING WM_USER + 3

' wParam � length
' lParam � PerformanceMeasure Ptr
#define PM_FINISHSORTING WM_USER + 4

Const C_COLUMNS As Integer = 3
Const SORTED_TIME_COUNT As Integer = 10
Const VECTOR_CAPACITY As Integer = 50 * 1000 * 1000

Type PerformanceMeasure
	Dim ElapsedMilliseconds As LARGE_INTEGER
	Dim PartitionsCount As Integer
End Type

Function SortVector( _
		ByVal lpParameter As LPVOID _
	)As DWORD
	
	Dim hwndDlg As HWND = Cast(HWND, lpParameter)
	
	Dim pPerformanceMeasure As PerformanceMeasure Ptr = CoTaskMemAlloc( _
		SORTED_TIME_COUNT * SizeOf(PerformanceMeasure) _
	)
	
	If pPerformanceMeasure <> NULL Then
		
		Dim pVector As LARGE_DOUBLE Ptr = VirtualAlloc( _
			NULL, _
			VECTOR_CAPACITY * SizeOf(LARGE_DOUBLE), _
			MEM_COMMIT Or MEM_RESERVE, _
			PAGE_READWRITE _
		)
		
		If pVector <> NULL Then
			Dim Frequency As LARGE_INTEGER = Any
			QueryPerformanceFrequency(@Frequency)
			
			For i As Integer = 0 To SORTED_TIME_COUNT - 1
				
				srand(0)
				
				PostMessage(hwndDlg, PM_STARTFILLVECTOR, i, NULL)
				Scope
					FillVector(pVector, VECTOR_CAPACITY)
				End Scope
				PostMessage(hwndDlg, PM_ENDFILLVECTOR, i, NULL)
				
				PostMessage(hwndDlg, PM_STARTSORTING, i, NULL)
				Scope
					Dim StartTime As LARGE_INTEGER = Any
					QueryPerformanceCounter(@StartTime)
					
					pPerformanceMeasure[i].PartitionsCount = QuickSort(pVector, 0, VECTOR_CAPACITY - 1)
					
					Dim EndTime As LARGE_INTEGER = Any
					QueryPerformanceCounter(@EndTime)
					
					pPerformanceMeasure[i].ElapsedMilliseconds.QuadPart = Integer64Division( _
						(EndTime.QuadPart - StartTime.QuadPart) * 1000, _
						Frequency.QuadPart _
					)
					
					
				End Scope
				PostMessage(hwndDlg, PM_ENDSORTING, i, Cast(LPARAM, @pPerformanceMeasure[i]))
				
			Next
			
			VirtualFree( _
				pVector, _
				0, _
				MEM_RELEASE _
			)
			
		End If
		
	End If
	
	PostMessage(hwndDlg, PM_FINISHSORTING, SORTED_TIME_COUNT, Cast(LPARAM, pPerformanceMeasure))
	
	Return 0
	
End Function

Sub ListViewAppendRow( _
		ByVal hListInterest As HWND, _
		ByVal Index As Integer, _
		ByVal PartitionsCount As Integer, _
		ByVal Elapsed As LongInt _
	)
	
	Dim buf(1023) As TCHAR = Any
	
	_i64tot(Index + 1, @buf(0), 10)
	
	Dim Item As LVITEM = Any
	With Item
		.mask = LVIF_TEXT ' Or LVIF_STATE Or LVIF_IMAGE
		.iItem  = Index
		.iSubItem = 0
		' .state = 0
		' .stateMask = 0
		.pszText = @buf(0)
		' .cchTextMax = 0
		' .iImage = i
		' lParam as LPARAM
		' iIndent as long
		' iGroupId as long
		' cColumns as UINT
		' puColumns as PUINT
	End With
	
	ListView_InsertItem(hListInterest, @Item)
	
	_i64tot(PartitionsCount, @buf(0), 10)
	Item.iSubItem = 1
	Item.pszText = @buf(0)
	ListView_SetItem(hListInterest, @Item)
	
	_i64tot(Elapsed, @buf(0), 10)
	Item.iSubItem = 2
	Item.pszText = @buf(0)
	ListView_SetItem(hListInterest, @Item)
	
End Sub

Function InputDataDialogProc( _
		ByVal hwndDlg As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR
	
	Select Case uMsg
		
		Case WM_INITDIALOG
			Dim hInst As HINSTANCE = GetModuleHandle(NULL)
			/'
			Dim hIcon As HICON = LoadIcon(hInst, CPtr(LPCTSTR, IDI_MAIN))
			SendMessage(hwndDlg, WM_SETICON, ICON_BIG, Cast(LPARAM, hIcon))
			'/
			
			Dim hListInterest As HWND = GetDlgItem(hwndDlg, IDC_LVW_ELAPSED)
			ListView_SetExtendedListViewStyle(hListInterest, LVS_EX_FULLROWSELECT Or LVS_EX_GRIDLINES)
			
			Scope
				Dim szText(265) As TCHAR = Any
				
				Dim Column As LVCOLUMN = Any
				With Column
					.mask = LVCF_FMT Or LVCF_WIDTH Or LVCF_TEXT Or LVCF_SUBITEM
					.fmt = LVCFMT_RIGHT
					.cx = 50
					.pszText = @szText(0)
					' .cchTextMax = 0
					' iSubItem as long
					' iImage as long
					' iOrder as long
				End With
				
				LoadString(hInst, IDS_NUMBER, @szText(0), 264)
				Column.iSubItem = 0
				ListView_InsertColumn(hListInterest, 0, @Column)
				
				Column.cx = 140
				For i As Integer = 1 To C_COLUMNS - 1
					LoadString(hInst, IDS_NUMBER + i, @szText(0), 264)
					Column.iSubItem = i
					ListView_InsertColumn(hListInterest, i, @Column)
				Next
			End Scope
			
		Case WM_COMMAND
			
			Select Case HIWORD(wParam)
				
				Case 0
					
					Select Case LOWORD(wParam)
						
						Case IDCANCEL
							EndDialog(hwndDlg, 0)
							
						Case IDOK
							SetDlgItemText(hwndDlg, IDC_EDT_AVERAGE, NULL)

							Dim hListInterest As HWND = GetDlgItem(hwndDlg, IDC_LVW_ELAPSED)
							ListView_DeleteAllItems(hListInterest)
							
							Dim hwndCANCEL As HANDLE = GetDlgItem(hwndDlg, IDOK)
							SetFocus(hwndCANCEL)
							
							Dim hwndOK As HANDLE = GetDlgItem(hwndDlg, IDOK)
							EnableWindow(hwndOK, False)
							
							Const DefaultStackSize As DWORD = 0
							Const CreationFlags As DWORD = 0
							Dim hThread As HANDLE = CreateThread( _
								NULL, _
								DefaultStackSize, _
								@SortVector, _
								hwndDlg, _
								CreationFlags, _
								NULL _
							)
							CloseHandle(hThread)
							
					End Select
					
			End Select
			
		Case PM_ENDSORTING
			Dim Index As Integer = wParam
			Dim pPerformanceMeasure As PerformanceMeasure Ptr = Cast(PerformanceMeasure Ptr, lParam)
			
			If pPerformanceMeasure <> NULL Then
				
				Dim hListInterest As HWND = GetDlgItem(hwndDlg, IDC_LVW_ELAPSED)
				ListViewAppendRow( _
					hListInterest, _
					Index, _
					pPerformanceMeasure->PartitionsCount, _
					pPerformanceMeasure->ElapsedMilliseconds.QuadPart _
				)
				
			End If
			
		Case PM_FINISHSORTING
			Dim Count As Integer = wParam
			Dim pPerformanceMeasure As PerformanceMeasure Ptr = Cast(PerformanceMeasure Ptr, lParam)
			
			If pPerformanceMeasure <> NULL Then
				Dim Summ As LARGE_INTEGER = Any
				Summ.QuadPart = pPerformanceMeasure[0].ElapsedMilliseconds.QuadPart
				
				For i As Integer = 1 To Count - 1
					Summ.QuadPart += pPerformanceMeasure[i].ElapsedMilliseconds.QuadPart
				Next
				
				Dim Average As LARGE_INTEGER = Any
				Average.QuadPart = Integer64Division( _
					Summ.QuadPart, _
					Count _
				)
				
				Dim buf(1023) As TCHAR = Any
				_i64tot(Average.QuadPart, @buf(0), 10)
				SetDlgItemText(hwndDlg, IDC_EDT_AVERAGE, @buf(0))
				
				CoTaskMemFree(pPerformanceMeasure)
			End If
			
			Dim hwndOK As HANDLE = GetDlgItem(hwndDlg, IDOK)
			EnableWindow(hwndOK, True)
			
		Case WM_CLOSE
			EndDialog(hwndDlg, 0)
			
		Case Else
			Return False
			
	End Select
	
	Return True
	
End Function
