#include "IntegerDivision.bi"
#include "windows.bi"
#include "win\ole2.bi"
#include "win\oleauto.bi"

Function Integer64Division( _
		ByVal LeftValue As LongInt, _
		ByVal RightValue As LongInt _
	)As LongInt
	
	Dim varLeft As VARIANT = Any
	varLeft.vt = VT_I8
	varLeft.llVal = LeftValue
	
	Dim varRight As VARIANT = Any
	varRight.vt = VT_I8
	varRight.llVal = RightValue
	
	Dim varResult As VARIANT = Any
	VariantInit(@varResult)
	
	Dim hr As HRESULT = VarIdiv( _
		@varLeft, _
		@varRight, _
		@varResult _
	)
	If FAILED(hr) Then
		Return 0
	End If
	
	Return varResult.llVal
	
End Function
