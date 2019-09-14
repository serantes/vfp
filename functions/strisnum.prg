*--
*-- StrIsNum(cNumber [, cDecimalPoint [, cSeparator [ , nFlags]]])
*--
*--	Parameters:
*--		cNumber	--	Number as string.
*--		cDecimalPoint	--	Decimal point, if ommited Set("Point") is used.
*--		cSeparator		--	Separator, if ommited Set("Separator") is used.
*--		nFlags			--	Output, funcion execution flags.
*--							 0	- Can't be converted.
*--							 1	- Evaluate() check passed, Evaluate() can be used to convert to number.
*--							 2	- Val() check passed, VAl() can be used to convert to number.
*--							 4	- DecimalPoint and Separator are the same character.
*--							 8	- Separator wrong interval.
*--							16	- Decimal point duplicated.
*--
*-- Warnings:
*--		· Function return .f. (False) with numbers greater than VFP limits.
*--		· Function tries to use Evaluate() but, it fails, it used alternate method.
*--		· Function check separator usage and point usage.
*--		· Function supports point and separator as parameters. If no parameter is passed
*--			then Set('Point') and/or Set('cSeparator') is used.
*--
Lparameters cNumber As String, cDecimalPoint As Character, cSeparator As Character, nFlags As Integer

#DEFINE	c_FLAG_EVALUATE					2^0
#DEFINE	c_FLAG_VAL						2^1
#DEFINE	c_FLAG_ERROR_POINT_SEPARATOR	2^2
#DEFINE	c_FLAG_ERROR_SEPARATOR			2^3
#DEFINE	c_FLAG_ERROR_POINT_DUPLICATED	2^4


If Empty(m.cNumber)
	Return .f.		&& <-- Quick exit.
EndIf

Local ;
	lResult As Logical, ;
	lUseAlternativeMethod As Logical, ;
	i As Integer, ;
	cPoint As String, ;
	nPointPos As Integer, ;
	cNumberAux As String, ;
	cCalculatedNumber As String, ;
	nSeparatorElementsCount As Integer

Local Array aSeparatorElements(1)

m.nFlags = 0
m.lResult = .f.
m.cPoint = Set('Point')
If (Vartype(m.cDecimalPoint) <> 'C')
	m.cDecimalPoint = m.cPoint
EndIf
If (Vartype(m.cSeparator) <> 'C')
	m.cSeparator = Set('Separator')
EndIf
If (m.cDecimalPoint = m.cSeparator)
	m.nFlags = m.nFlags + c_FLAG_ERROR_POINT_SEPARATOR
	Return .f.		&& <-- Quick exit.
EndIf
m.lUseAlternativeMethod = (m.cPoint <> '.') or (Len(Alltrim(m.cNumber)) > 16)

*-- Checking separator usage.
If (At(m.cSeparator, m.cNumber) > 0)
	m.cNumberAux = StrExtract(m.cNumber, '', m.cDecimalPoint)
	If Empty(m.cNumberAux)
		m.cNumberAux = m.cNumber
	EndIf
	m.nSeparatorElementsCount = ALines(aSeparatorElements, m.cNumberAux, 2, m.cSeparator)
	If (Len(aSeparatorElements(1)) > 3)
		m.nFlags = m.nFlags + c_FLAG_ERROR_SEPARATOR
		Return .f.		&& <-- Quick exit.
	EndIf
	For m.i = 2 to m.nSeparatorElementsCount
		If (Len(m.aSeparatorElements(m.i)) <> 3)
			m.nFlags = m.nFlags + c_FLAG_ERROR_SEPARATOR
			Return .f.	&& <-- Quick exit.
		EndIf
	EndFor
EndIf

*-- Checking only one point.
If (At(m.cDecimalPoint, m.cNumber, 2) > 0)
	m.nFlags = m.nFlags + c_FLAG_ERROR_POINT_DUPLICATED
	Return .f.		&& <-- Quick exit.
EndIf

*-- Check Val() conversion.
If (m.cDecimalPoint = '.') and (At(m.cSeparator, m.cNumber) = 0)
	m.nFlags = m.nFlags + c_FLAG_VAL
EndIf

*-- m.cNumber sanitization, separator are removed and point is fixed.
m.cNumber = Alltrim(Chrtran(m.cNumber, m.cDecimalPoint + m.cSeparator, '.' + ''))

If not m.lUseAlternativeMethod
	Try
		m.lResult = (Vartype(Evaluate(m.cNumber)) = 'N')
		m.nFlags = m.nFlags + c_FLAG_EVALUATE
		*? Evaluate(m.cNumber)
	Catch
		m.lUseAlternativeMethod = .t.
	EndTry
EndIf

If m.lUseAlternativeMethod
	m.nPointPos = At(m.cPoint, m.cNumber)
	If (m.nPointPos > 0)
		*-- Calculamos la parte decimal.
		m.cNumberAux = Transform(Val(StrExtract(m.cNumber, m.cPoint, '')))
		m.cCalculatedNumber = m.cPoint + ;
								Padr(m.cNumberAux, Len(StrExtract(m.cNumber, m.cPoint, '')), '0')
		m.cNumberAux = StrExtract(m.cNumber, '', m.cPoint)
	Else
		m.cCalculatedNumber = '' && No hay parte decimal.
		m.cNumberAux = m.cNumber
	EndIf

	*-- Calculamos la parte entera.
	m.cCalculatedNumber = Padl(Transform(Val(m.cNumberAux)), Len(m.cNumberAux), '0') + m.cCalculatedNumber
	*? 'cNumber:', m.cNumber, '| cCalculatedNumber:', m.cCalculatedNumber
	*?

	m.lResult = (Chrtran(m.cCalculatedNumber, m.cPoint, '.') == m.cNumber)
EndIf

Return m.lResult
