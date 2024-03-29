#include once "windows.bi"
#include once "IntegerDivision.bi"
#include once "QuickSort.bi"
#include once "Resources.RH"
#include once "WriteString.bi"

#ifdef UNICODE
#define _i64tot(value, buffer, radix) _i64tow(value, buffer, radix)
#else
#define _i64tot(value, buffer, radix) _i64toa(value, buffer, radix)
#endif

Const TabString = __TEXT(!"\t")
Const CrLfString = __TEXT(!"\r\n")
Const GenerateString = __TEXT(!"Generating...\r\n")
Const SortingString = __TEXT(!"Sorting...\r\n")
Const AverageString = __TEXT(!"Average\t")

Const SORTED_TIME_COUNT As Integer = 10
Const VECTOR_CAPACITY As Integer = 50 * 1000 * 1000

Sub ConsoleAppendRow( _
		ByVal Index As Integer, _
		ByVal PartitionsCount As Integer, _
		ByVal Elapsed As LongInt _
	)
	
	Dim bufIndex(1023) As TCHAR = Any
	_i64tot(Index + 1, @bufIndex(0), 10)
	
	Dim bufQuickSorts(1023) As TCHAR = Any
	_i64tot(PartitionsCount, @bufQuickSorts(0), 10)
	
	Dim bufQuickElapsedTime(1023) As TCHAR = Any
	_i64tot(Elapsed, @bufQuickElapsedTime(0), 10)
	
	WriteString(@bufIndex(0), lstrlen(@bufIndex(0)))
	WriteString(StrPtr(TabString), Len(TabString))
	
	WriteString(@bufQuickSorts(0), lstrlen(@bufQuickSorts(0)))
	WriteString(StrPtr(TabString), Len(TabString))
	
	WriteString(@bufQuickElapsedTime(0), lstrlen(@bufQuickElapsedTime(0)))
	WriteString(StrPtr(CrLfString), Len(CrLfString))
	
End Sub

Function wMain Alias "wMain"()As Long
	
	Dim ElapsedMilliseconds(SORTED_TIME_COUNT - 1) As LARGE_INTEGER = Any
	Dim PartitionsCount(SORTED_TIME_COUNT - 1) As Integer = Any
	
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
			
			WriteString(StrPtr(GenerateString), Len(GenerateString))
			Scope
				
				FillVector(pVector, VECTOR_CAPACITY)
				
			End Scope
			
			WriteString(StrPtr(SortingString), Len(SortingString))
			Scope
				Dim StartTime As LARGE_INTEGER = Any
				QueryPerformanceCounter(@StartTime)
				
				PartitionsCount(i) = QuickSort(pVector, 0, VECTOR_CAPACITY - 1)
				
				Dim EndTime As LARGE_INTEGER = Any
				QueryPerformanceCounter(@EndTime)
				
				ElapsedMilliseconds(i).QuadPart = Integer64Division( _
					(EndTime.QuadPart - StartTime.QuadPart) * 1000, _
					Frequency.QuadPart _
				)
			End Scope
			
			ConsoleAppendRow(i, PartitionsCount(i), ElapsedMilliseconds(i).QuadPart)
			
		Next
		
		VirtualFree( _
			pVector, _
			0, _
			MEM_RELEASE _
		)
		
		Dim Summ As LARGE_INTEGER = Any
		Summ.QuadPart = ElapsedMilliseconds(0).QuadPart
		
		For i As Integer = 1 To SORTED_TIME_COUNT - 1
			Summ.QuadPart += ElapsedMilliseconds(i).QuadPart
		Next
		
		Dim Average As LARGE_INTEGER = Any
		Average.QuadPart = Integer64Division( _
			Summ.QuadPart, _
			SORTED_TIME_COUNT _
		)
		
		WriteString(StrPtr(AverageString), Len(AverageString))
		Scope
			Dim bufAverage(1023) As TCHAR = Any
			_i64tot(Average.QuadPart, @bufAverage(0), 10)
			WriteString(@bufAverage(0), lstrlen(@bufAverage(0)))
		End Scope
		WriteString(StrPtr(CrLfString), Len(CrLfString))
		
	End If
	
	Return 0
	
End Function