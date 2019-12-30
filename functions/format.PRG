*
* --< HELP_BEGIN >--
*
* Usage:
* 	Format(<String>, Par1 [, Par2] [, ...] [, Par40]
* 	Format(<Par1>)
*
* String:
* 	A string se le puede indicar el tag %s que se sustituirá por el valor del parámetro que se corresponda.
*
* 	%s soporta opciones atendiendo a la siguiente sintaxis:
*	%s[#1][:[#2][z][p][n][t|r|c|l][i][d][m][y][s][$][.#][,#][v][:| |%]]
*
*	#1		--	un valor numérico que identifica el parámetro que hay que asignar. Si no se indica
*				se asigna el que le corresponda según su orden.
*	:		--	indica que empiezan las opciones y que terminan y es obligatorio añadirlo detrás 
*				de #1.
*	#2		--	el tamaño, valor numérico siempre en primera posición. Si no se indica o no está en
*				la primera posición se ignora.
*	z		--	añade ceros a la izquierda en los valores numéricos.
*	p		--	no imprime el punto decimal en los valores numéricos.
*	n		--	desactiva el alltrim() que se hace por defecto a todos los strings.
*	r		--	aplicar padl usando espacios teniendo en cuenta el tamaño indicado para alinear a la derecha.
*	c		--	aplicar padc usando espacios teniendo en cuenta el tamaño indicado para alinear al centro.
*	l		--	aplicar padr usando espacios teniendo en cuenta el tamaño indicado para alinear a la izquierda.
*	t		--	indica que se debe truncar el string al tamaño indicado, es un alias de l.
*	o		--	fecha y fecha hora listas para hacer un CToD() o un CToT().
*	i		--	fecha y fecha hora en formato ISO.
*	d		--	devuelve el día de la semana de la fecha o fecha hora.
*	m		--	devuelve el mes de la fecha o fecha hora.
*	y		--	formato para año largo :4l.0: o corto :2l.0:, que también vale para mes y día, usar
*				la opción "s" para el formato corto.
*	s		--	versión corta de 'm', 'd' e 'y'.
*	$		--	añade la moneda a los valores numéricos.
*	.#		--	el número detrás del punto, este carácter es necesario, indica los decimales de los
*				valores numéricos. Si se indica tamaño y no	se indican decimales se asumen por 
*				defecto 2 decimales.
*	,?		--	el carácter indicado en vez de ? se utilizará como punto decimal.
*	v		--	devuelve el texto formateado para CSV añadiendo las comillas dobles si es necesario.
*				Es decir, se añaden comillas dobles cuando hay una comilla doble o intros.
*	e		--	En caso de valores numéricos, expande el resultado no cabe.
*	\n		--	se convierte en Chr(13) + Chr(10).
*	\t		--	se convierte en Chr(9).
*	\		--	usar para imprimir \n, \t y %s.
*
* NOTA: con la excepción del tamaño, que siempre va en primer lugar, el resto de las opciones pueden ir en cualquier orden.
*
* NOTA: los dos puntos son necesarios siempre como finalizador si no hay un espacio o un % y para que se muestren los ":".
*		Como referencia las siguientes entradas producirán los siguientes resultados:
*				Format('"%s:hola adiós"'	, 'a')		== "a adiós"		-- no finalizamos así que hola se ignora o da error y se aplicarán opciones por defecto.
*				Format('"%s::hola adiós"'	, 'a')		== "ahola adiós"	-- no tiene opciones el parámetro.
*				Format('"%s:::hola adiós"'	, 'a')		== "a:hola adiós"	-- tras las opciones añadimos :.
*				Format('"%s: hola adiós"'	, 'a')		== "a: hola adiós"	-- hay espacio así que no se necesitan : adicionales.
*				Format('" %s:%s: "'			, 'a', 'b')	== " a:b: "			-- hay % así que no se necesitan : adicionales.
*
* Adaptación a Fisterra:
*   Se crearía una función Formatear() que sería un Wrapper de Format()
*
* 	Formatear('Esto es {tienda} del año {año}: {tienda}->{año}', 'tienda', ValorTienda, 'año', ValorAño)
* 
*	sería un wrapper de la llamada.
*
*	Format('Esto es %s1: del año %s2::: {%s1::->%s2::}', ValorTienda, ValorAño)
*
* --< HELP_END >--

*--
*-- Defines
*--
#DEFINE	c_DEBUG						.f.		&& Enable/Disable debug code.
#DEFINE	c_UNIT_TEST 				.t.		&& Enable/Disable unit test code.

#DEFINE	c_ERROR_ON_UNKNOWN_OPTION	.f.		&& Throw an error with unknown options, otherwise unknown options are ignored.

#DEFINE	c_SPECIAL_CHAR_1			Chr(1)	&& Used to convert c_TEXTMERGE_LEFT_DELIMITER, this character is reserved and can not be used.
#DEFINE	c_SPECIAL_CHAR_2			Chr(2)	&& Used to convert c_TEXTMERGE_RIGHT_DELIMITER, this character is reserved and can not be used.
#DEFINE	c_SPECIAL_CHAR_3 			Chr(3)	&& Used to convert c_ESCAPE_CHAR, this character is reserved and can not be used.
#DEFINE	c_ENTER						Chr(13) + Chr(10)
#DEFINE	c_TAB						Chr(9)
#DEFINE	c_MARK						'%s'
#DEFINE	c_MARK_LEN					Len(c_MARK)
#DEFINE	c_MARK_FINISHER				Left(c_MARK, 1)	&& Caution, only one char is supported.
#DEFINE	c_MARK_OPTIONS_DELIMITER	':'
#DEFINE	c_ESCAPE_CHAR				'\'

#DEFINE	c_TEXTMERGE_LEFT_DELIMITER	'<<'	&& Only one to c_SPECIAL_CHARS so different chars are not supported.
#DEFINE	c_TEXTMERGE_RIGHT_DELIMITER	'>>'	&& Only one to c_SPECIAL_CHARS so different chars are not supported.
#DEFINE	c_SPECIAL_CHARS				Left(c_TEXTMERGE_LEFT_DELIMITER, 1) + Left(c_TEXTMERGE_RIGHT_DELIMITER, 1)	&& Caution, only one char is supported.

#DEFINE	c_LABEL_TRUE				'Verdadero'
#DEFINE	c_LABEL_FALSE				'Falso'

#DEFINE	c_MONTHS_LONG				'|Enero|Febrero|Marzo|Abril|Mayo|Junio|Julio|Agosto|Septiembre|Octubre|Noviembre|Diciembre'
#DEFINE	c_MONTHS_SHORT				'|Ene|Feb|Mar|Abr|May|Jun|Jul|Ago|Sep|Oct|Nov|Dic'

#DEFINE	c_WEEKDAYS_LONG				'|Domingo|Lunes|Martes|Miércoles|Jueves|Viernes|Sábado|'
#DEFINE	c_WEEKDAYS_SHORT			'|D|L|M|X|J|V|S|'

#DEFINE	c_DATE_EMPTY_FOR_I			'1900-01-01T00:00:00'
#DEFINE	c_DATE_EMPTY_FOR_O			''

*--
*-- Functions
*--
Function Format
Lparameters m.Str, m.Par1, m.Par2, m.Par3, m.Par4, m.Par5, m.Par6, m.Par7, m.Par8, m.Par9, m.Par10, ;
			m.Par11, m.Par12, m.Par13, m.Par14, m.Par15, m.Par16, m.Par17, m.Par18, m.Par19, m.Par20, ;
			m.Par21, m.Par22, m.Par23, m.Par24, m.Par25, m.Par26, m.Par27, m.Par28, m.Par29, m.Par30, ;
			m.Par31, m.Par32, m.Par33, m.Par34, m.Par35, m.Par36, m.Par37, m.Par38, m.Par39, m.Par40

	Local ;
		m.ItemsCount As Integer, ;
		m.ParamsCount As Integer, ;
		m.i As Integer, ;
		m.Char As Character, ;
		m.Id As String, ;
		m.StrOut As String, ;
		m.CurrentParam As String, ;
		m.OldCurrentParam As String, ;
		m.Width As Integer, ;
		m.Decimals As Integer, ;
		m.CerosIzq As Logical, ;
		m.QuitarEspacios As Logical, ;
		m.SinPuntoDecimal As Logical, ;
		m.Truncar As Logical, ;
		m.PadMethod As String, ;
		m.DateFormat As String, ;
		m.FormatoFecha As String, ;
		m.Modo As Integer, ;
		m.NumTamaño As String, ;
		m.NumDecimales As String, ;
		m.AnadirMoneda As String, ;
		m.Evaluar As Logical, ;
		m.DecimalPoint As String, ;
		m.OldDecimalPoint As String, ;
		m.CSVCompatible As Logical, ;
		m.ExpandirNumeros As Logical, ;
		m.SinParametros As Logical

	Local Array m.aItems(1)
	Store '' To ;
		m.aItems

	If (Pcount() = 1)
		*-- Caso especial, equivale a pasar '%s'.
		m.Par1 = m.Str
		m.Str = c_MARK
	EndIf

	If (Vartype(m.Str) <> 'C')
		Error 'Incorrect syntax using Format(). With two or more parameters the first one must be a string.'
		Return ''
	EndIf

	m.ItemsCount = ALines(aItems, Chrtran(m.Str, c_SPECIAL_CHARS, c_SPECIAL_CHAR_1 + c_SPECIAL_CHAR_2), 16, c_MARK)

	*-- Hack para simplificar la lógica.
	If (Right(m.aItems(m.ItemsCount), c_MARK_LEN) = c_MARK)
		m.ItemsCount = m.ItemsCount + 1
		Dimension m.aItems(m.ItemsCount)
		m.aItems(m.ItemsCount) = ''
	EndIf

	#IF c_DEBUG
		Clear
		? 'Array:'
		Display Memory like aItems
	#ENDIF

	m.StrOut = ''
	m.CurrentParam = ''

	For m.i = 1 To m.ItemsCount
		m.Char = ''
		If (m.i < m.ItemsCount)
			m.Escape = (Right(m.aItems(m.i), c_MARK_LEN + 1) = c_ESCAPE_CHAR)
			m.Length = Iif(not m.Escape and (Right(m.aItems(m.i), c_MARK_LEN) == c_MARK), Len(m.aItems(m.i)) - c_MARK_LEN, Len(m.aItems(m.i)))
			If m.Escape
				m.StrOut = m.StrOut + Left(m.aItems(m.i), m.Length - (c_MARK_LEN + 1)) + c_MARK
				Loop
			Else
				m.StrOut = m.StrOut + Left(m.aItems(m.i), m.Length)	
			EndIf
			
			*-- Procesamos los parámetros.
			m.Pos = 1
			m.Id = '0' && El cero a la izquierda devuelve 0.
			If (m.aItems(m.i + 1) = ' ') && Espacio se acabó.
				m.CurrentParam = 'm.Par' + Transform(m.i)
			Else
				*-- Miramos en primer lugar si hay Id, en caso contrario se selecciona el parámetro equivalente al número de %s.
				Do While IsDigit(Substr(m.aItems(m.i + 1), m.Pos, 1))
					m.Id = m.Id + Substr(m.aItems(m.i + 1), m.Pos, 1)
					m.Pos = m.Pos + 1	
				EndDo
				m.CurrentParam = 'm.Par' + Transform(Val(m.Id))
				If (m.CurrentParam == 'm.Par0')
					m.CurrentParam = 'm.Par' + Transform(m.i)
				EndIf
			EndIf
			
			*-- Parseamos las opciones del parámetro si es que hay.
			*-- Ponemos los valores por defecto.
			m.Width = -1 				&& w				-- Todos pero se ve afectado por el tipo.
			m.Decimals = -1 			&& .#				-- Numéricos.
			m.LeadingZeroes = .f. 		&& z				-- Numéricos.
			m.ApplyAlltrim = .t. 		&& not n			-- Strings.
			m.WithoutDecimalPoint = .f. && p				-- Numéricos.
			m.ApplyTrunc = .f. 			&& l, c, r, t		-- Todos, se hace siempre al final y requiere un tamaño.
			m.PadMethod = ''			&& l, c, r'			-- Usar PadR, PadC or PadL dependiendo del parámetro.
			m.DateFormat = '' 			&& '', s, o, m, d	-- Normal, Fecha iso, fecha para Dtoc() o Ttoc(), Mes, Día semana.
			m.AddCurrencyLabel = .f.	&& $				-- Añade la moneda.
			m.WorkMode = 1				&& Para saber si estamos detectando el tamaño o el nº de decimales.
			m.StrWidth = ''				&& Almacenamiento temporal del tamaño extraído de las opciones.
			m.StrDecimals = ''			&& Almacenamiento temporal de los decimales extraídos de las opciones.
			m.EvaluateParam = .t.		&& Indica si el parámetro se debe evaluar con Textmerge() o no.
			m.WithoutOptions = .t.		&& Indica que el parámetro no tiene opciones.
			m.DecimalPoint = ''			&& Almacenamos el punto decimal que se ha indicado como opción.
			m.OldDecimalPoint = ''		&& Almacenamos al punto decimal para restaurarlo.
			m.ExpandirNumeros = .f.		&& Expande los números si el valor no cabe y se muestran *.
			m.CSVCompatible = .f.		&& Determina si la salida debe ser compatible con CSV.
			If (Substr(m.aItems(m.i + 1), m.Pos, 1) = c_MARK_OPTIONS_DELIMITER)
				m.Pos = m.Pos + 1
				m.Char = Substr(m.aItems(m.i + 1), m.Pos, 1)
				Do While not Empty(m.Char) and not InList(m.Char, ' ', c_MARK_OPTIONS_DELIMITER, c_MARK_FINISHER) && Terminadores.
					m.WithoutOptions = .f.
					Do Case
						Case (InList(m.WorkMode, 1, 4) and (IsDigit(m.Char)))
							*-- Tamaño o decimales
							Do Case
								Case (m.WorkMode = 1)
									m.StrWidth = m.StrWidth + m.Char
									m.WorkMode = m.WorkMode + 1
								
								Case (m.WorkMode = 4)
									m.StrDecimals = m.StrDecimals + m.Char
									m.WorkMode = m.WorkMode + 1
								
								&&Otherwise
									*-- Se ignora
							EndCase
						Case (m.Char = 'c')
							m.ApplyTrunc = .t.
							m.PadMethod = 'Padc'
						Case (m.Char = 'e')
							m.ExpandirNumeros = .t.
						Case InList(m.Char, 'i', 'd', 'm', 'o', 's', 'y')
							If (m.Char = 's')
								If Empty(m.DateFormat)
									m.DateFormat = m.Char
								Else
									If InList(m.DateFormat, 'D', 'M', 'Y')
										m.DateFormat = Lower(m.DateFormat)
									EndIf
								EndIf 
							Else
								If InList(m.Char, 'd', 'm', 'y')
									If (m.DateFormat = 's')
										m.DateFormat = m.Char
									Else
										m.DateFormat = Upper(m.Char)
									EndIf
								Else
									m.DateFormat = m.Char
								EndIf
							EndIf
						Case Inlist(m.Char, 'l', 't')
							m.ApplyTrunc = .t.
							m.PadMethod = 'Padr'
						Case (m.Char = 'n')
							m.ApplyAlltrim = .f.
						Case (m.Char = 'p')
							m.WithoutDecimalPoint = .t.
						Case (m.Char = 'r')
							m.ApplyTrunc = .t.
							m.PadMethod = 'Padl'
						Case (m.Char = 'v')
							m.CSVCompatible = .t.
						Case (m.Char = 'z')
							m.LeadingZeroes = .t.
						Case (m.Char = '$')
							m.AddCurrencyLabel = .t.
						Case (m.Char = '.')
							*-- Decimales.
							m.WorkMode = 5
						Case (m.Char = ',')
							*-- Decimales.
							m.Pos = m.Pos + 1
							m.Char = Substr(m.aItems(m.i + 1), m.Pos, 1)
							m.DecimalPoint = m.Char
						#IF c_ERROR_ON_UNKNOWN_OPTION
						Otherwise
							Error '"' + m.Char + '" is an unknown option'
							Return ''
						#ENDIF
					EndCase

					If InList(m.WorkMode, 1, 2, 4, 5)
						m.WorkMode = m.WorkMode - 1
					EndIf
					m.Pos = m.Pos + 1
					m.Char = Substr(m.aItems(m.i + 1), m.Pos, 1)
				EndDo
				If (m.Char <> c_MARK_OPTIONS_DELIMITER)
					*-- Sólo perdemos el c_MARK_OPTIONS_DELIMITER.
					m.Pos = m.Pos - 1
				EndIf
				
				Do Case
					Case (m.DateFormat = 'Y')
						m.StrWidth = '4'
						m.StrDecimals = '0'
						m.LeadingZeroes = .t.
						m.DateFormat = ''
					Case (m.DateFormat = 'y')
						m.StrWidth = '2'
						m.StrDecimals = '0'
						m.LeadingZeroes = .t.
						m.DateFormat = ''
					&&Otherwise
						*-- Nada.
				EndCase

				If not Empty(m.StrWidth)
					m.Width = Val(m.StrWidth)
					If Empty(m.PadMethod)
						m.PadMethod = 'Padr'
					EndIf
				EndIf 
				
				If not Empty(m.StrDecimals)
					m.Decimals = Val(m.StrDecimals)
					If (m.Decimals < 1)
						m.WithoutDecimalPoint = .t. && Si no hay decimales forzamos que no haya punto.
					EndIf
				EndIf
			
			Else
				If not (m.Id == '0')
					*-- Descartamos el Id ya que no había c_MARK_OPTIONS_DELIMITER.
					m.Pos = 1
					m.CurrentParam = 'm.Par' + Transform(m.i)
				EndIf
			EndIf

			m.ParamType = Vartype(Evaluate(m.CurrentParam))
			Do case
				Case InList(m.ParamType, 'D', 'T')
					Do Case
						Case (m.DateFormat = 'o')
							If Empty(Evaluate(m.CurrentParam))
								m.CurrentParam = c_DATE_EMPTY_FOR_O
							Else
								If (m.ParamType = 'D')
									m.CurrentParam = '^' ;
														+ Transform(Year(Evaluate(m.CurrentParam)), "@L 9999") ;
														+ '-' + Transform(Month(Evaluate(m.CurrentParam)), "@L 99") ; 
														+ '-' + Transform(Day(Evaluate(m.CurrentParam)), "@L 99")
								Else
									m.CurrentParam = '^' ;
														+ Transform(Year(Evaluate(m.CurrentParam)), "@L 9999") ;
														+ '-' + Transform(Month(Evaluate(m.CurrentParam)), "@L 99") ; 
														+ '-' + Transform(Day(Evaluate(m.CurrentParam)), "@L 99") ;
														+ ' ' ;
														+ Transform(Hour(Evaluate(m.CurrentParam)), "@L 99") ;
														+ ':' ;
														+ Transform(Minute(Evaluate(m.CurrentParam)), "@L 99") ;
														+ ':' ;
														+ Transform(Sec(Evaluate(m.CurrentParam)), "@L 99")
								EndIf
							EndIf
							
						Case (m.DateFormat = 'i')
							If Empty(Evaluate(m.CurrentParam))
								m.CurrentParam = c_DATE_EMPTY_FOR_I
							Else
								m.CurrentParam = Ttoc(Evaluate(m.CurrentParam), 3)
								If (m.ParamType = 'D')
									m.CurrentParam = Left(m.CurrentParam, 10)
								EndIf
							EndIf

						Case (m.DateFormat = 'D')
							m.CurrentParam = StrExtract(c_WEEKDAYS_LONG, '|', '|', Dow(Evaluate(m.CurrentParam), 1))

						Case (m.DateFormat = 'd')
							m.CurrentParam = StrExtract(c_WEEKDAYS_SHORT, '|', '|', Dow(Evaluate(m.CurrentParam), 1))
							
						Case (m.DateFormat = 'M')
							m.CurrentParam = StrExtract(c_MONTHS_LONG, '|', '|', Month(Evaluate(m.CurrentParam)))
							
						Case (m.DateFormat = 'm')
							m.CurrentParam = StrExtract(c_MONTHS_SHORT, '|', '|', Month(Evaluate(m.CurrentParam)))
							
						Otherwise
							m.CurrentParam = Iif((m.ParamType = 'D'), Dtoc(Evaluate(m.CurrentParam)), Ttoc(Evaluate(m.CurrentParam)))
					EndCase
					m.EvaluateParam = .f.
					
				Case InList(m.ParamType, 'G')
					m.CurrentParam = '(general)'
					m.EvaluateParam = .f.

				Case InList(m.ParamType, 'L')
					m.CurrentParam = Iif(Evaluate(m.CurrentParam), c_LABEL_TRUE, c_LABEL_FALSE)
					m.EvaluateParam = .f.

				Case InList(m.ParamType, 'N', 'Y')
					m.OldCurrentParam = m.CurrentParam
					If m.WithoutOptions
						*-- Si no hay parámetros hacemos sólo un Transform().
						m.CurrentParam = 'Transform(' + m.CurrentParam + ')'
					Else
						If m.CSVCompatible
							*-- Forzamos la utilización del . decimal.
							m.DecimalPoint = Iif(Set('Point') = '.', '', '.')
						Else
							If (m.Decimals = -1)
								*-- Si no hay decimales nos quedamos con los decimales definidos en la aplicación.
								m.Decimals = Set('Decimals')
							EndIf
						EndIf
						
						If (m.Width > -1)
							If m.AddCurrencyLabel
								*-- Descontamos el tamaño de la moneda.
								m.Width = m.Width - Len(Set('Currency', 1))
							EndIf
							m.CurrentParam = 'Transform(' + m.CurrentParam + ', "@' + Iif(m.LeadingZeroes, 'L ', '') + Iif(m.AddCurrencyLabel, '$ ', ' ') + Replicate('9', Max(m.Width - m.Decimals - Iif(m.WithoutDecimalPoint, 0, 1), 0)) + '.' + Replicate('9', m.Decimals) + '")'
						Else
							If m.CSVCompatible
								If m.AddCurrencyLabel
									m.CurrentParam = 'AllTrim(Transform(' + m.CurrentParam + ', "@' + Iif(m.AddCurrencyLabel, '$ ', ' ')+ '"))'
								Else
									m.CurrentParam = 'AllTrim(Transform(' + m.CurrentParam + '))'
								EndIf
							Else
								*-- Con parámetros y si no es CSV asignamos un tamaño de 18.
								m.Width = 18
								If m.AddCurrencyLabel
									*-- Descontamos el tamaño de la moneda.
									m.Width = m.Width - Len(Set('Currency', 1))
								EndIf
								m.CurrentParam = 'AllTrim(Transform(' + m.CurrentParam + ', "@' + Iif(m.AddCurrencyLabel, '$ ', ' ') + Replicate('9', Max(m.Width - m.Decimals - Iif(m.WithoutDecimalPoint, 0, 1), 0)) + '.' + Replicate('9', m.Decimals) + '"))'
							EndIf
						EndIf
						If (m.WithoutDecimalPoint)
							m.CurrentParam = 'ChrTran(' + m.CurrentParam + ', "' + Set('Point') + '", "")'
						EndIf

						If (m.Width > -1) and m.ApplyTrunc
							m.CurrentParam = m.PadMethod + '(Alltrim(' + m.CurrentParam + '), ' + Transform(m.Width) + ', " ")'
						EndIf

					EndIf
					If not Empty(m.DecimalPoint)
						m.CurrentParam = 'Chrtran(' + m.CurrentParam + ', "' + Set('Point') + '", "' + m.DecimalPoint + '")'
					EndIf
			
					If m.ExpandirNumeros and (Textmerge(c_TEXTMERGE_LEFT_DELIMITER + m.CurrentParam + c_TEXTMERGE_RIGHT_DELIMITER, .f., c_TEXTMERGE_LEFT_DELIMITER, c_TEXTMERGE_RIGHT_DELIMITER) = '*')
						*-- Si no cabe el nº y hemos indicado que en estos casos se expande.
						m.CurrentParam = 'Transform(' + m.OldCurrentParam + ')'
					EndIf
								
				Case InList(m.ParamType, 'O')
					m.CurrentParam = '(varbinary or blob)'
					m.EvaluateParam = .f.						
			
				Case InList(m.ParamType, 'Q')
					m.CurrentParam = '(object)'
					m.EvaluateParam = .f.						
					
				Case InList(m.ParamType, 'U')
					m.CurrentParam = '(unknown)'
					m.EvaluateParam = .f.
					
				Case InList(m.ParamType, 'X')
					m.CurrentParam = Set("Nulldisplay")
					m.EvaluateParam = .f.
					
				Otherwise && Los string.
					If m.ApplyAlltrim
						m.CurrentParam = 'AllTrim(' + m.CurrentParam + ')'
					EndIf

					If (m.Width > -1)
						If (m.ApplyTrunc or (Len(Textmerge(c_TEXTMERGE_LEFT_DELIMITER + m.CurrentParam + c_TEXTMERGE_RIGHT_DELIMITER)) <= m.Width))
							m.CurrentParam = m.PadMethod + '(' + m.CurrentParam + ', ' + Transform(m.Width) + ', " ")'
						EndIf
					EndIf
			EndCase
		EndIf
			
		If (m.i < Alen(m.aItems, 1))
			If m.CSVCompatible
				If m.EvaluateParam
					m.CurrentParam = Evaluate(m.CurrentParam)
					m.EvaluateParam = .f.
				EndIf
				If ((At('"', m.CurrentParam) > 0) or (At(Chr(13), m.CurrentParam) > 0) or (At(Chr(10), m.CurrentParam) > 0))
					m.CurrentParam = '"' + Strtran(m.CurrentParam, '"', '""') + '"'
				EndIf
			EndIf
			m.aItems(m.i + 1) = Iif(m.EvaluateParam, c_TEXTMERGE_LEFT_DELIMITER, '') + m.CurrentParam + Iif(m.EvaluateParam, c_TEXTMERGE_RIGHT_DELIMITER, '') + Iif((m.Pos = 1), m.aItems(m.i + 1), Substr(m.aItems(m.i + 1), m.Pos + 1))
		Else
			*-- Añadimos el último elemento si es necesario.
			m.StrOut = m.StrOut + m.aItems(m.i)
		EndIf
	EndFor

	*-- Final, procesamos \n \t.
	m.StrOut = Strtran(m.StrOut, c_ESCAPE_CHAR + c_ESCAPE_CHAR, c_SPECIAL_CHAR_3)
	m.StrOut = Strtran(m.StrOut, c_ESCAPE_CHAR + 'n', c_ENTER)
	m.StrOut = Strtran(m.StrOut, c_ESCAPE_CHAR + 't', c_TAB)
	m.StrOut = Strtran(m.StrOut, c_SPECIAL_CHAR_3, c_ESCAPE_CHAR)

	#IF c_DEBUG
		_cliptext = 'Chrtran(Textmerge(' + m.StrOut + '), Chr(1) + Chr(0), "' + c_SPECIAL_CHARS + '")'
		? 'String:', m.StrOut
		? 'Result:', Chrtran(Textmerge(m.StrOut), c_SPECIAL_CHAR_1 + c_SPECIAL_CHAR_2, c_SPECIAL_CHARS)
		?
	#ENDIF

	Return Chrtran(Textmerge(m.StrOut, .f., c_TEXTMERGE_LEFT_DELIMITER, c_TEXTMERGE_RIGHT_DELIMITER), c_SPECIAL_CHAR_1 + c_SPECIAL_CHAR_2, c_SPECIAL_CHARS)

EndFunc



*
* UNIT TEST.
*
#IF c_UNIT_TEST
#DEFINE	c_DEFAULT_TEST_ITERATIONS	1
#DEFINE	c_COLUMN_TEST_WIDTH			110
#DEFINE	c_COLUMN_RESULT_WIDTH		60

Function _test_header
Lparameters m.TestName
	Clear
	_screen.ForeColor = RGB(0,0,0)
	? ' ' + Replicate('=', 37) 															Font 'Lucida Console', 8 Style 'B'
	? ' ' + '| Unit test for ' + TestName + ' |'										Font 'Lucida Console', 8 Style 'B'
	? ' ' + Replicate('=', 37)															Font 'Lucida Console', 8 Style 'B'
	?
	? ' ' + Replicate('-', 4) + ' ' + Replicate('-', c_COLUMN_TEST_WIDTH) + ' ' + Replicate('-', c_COLUMN_RESULT_WIDTH)		Font 'Lucida Console', 8
	? ' ' + Space(3) + '#' + ' ' + 'Test' + Space(c_COLUMN_TEST_WIDTH - Len('Test')) + ' ' + 'Result'						Font 'Lucida Console', 8
	? ' ' + Replicate('-', 4) + ' ' + Replicate('-', c_COLUMN_TEST_WIDTH) + ' ' + Replicate('-', c_COLUMN_RESULT_WIDTH)		Font 'Lucida Console', 8
EndFunc

Function _test_footer
Lparameters m.aCounters, m.Seconds	
	Local m.OldDecimals
	
	_screen.ForeColor = RGB(0,0,0)
	? ' ' + Replicate('-', 6 + c_COLUMN_TEST_WIDTH + c_COLUMN_RESULT_WIDTH)													Font 'Lucida Console', 8
	?
	? ' Unit test finished with a '																							Font 'Lucida Console', 8 Style 'B'
	If (m.aCounters(3) = 0)
		_screen.ForeColor = RGB(100,200,0)
		?? 'Passed'																											Font 'Lucida Console', 8 Style 'B'
		_screen.ForeColor = RGB(0,0,0)
		?? ': All ' + Transform(m.aCounters(2)) + ' test passed'															Font 'Lucida Console', 8 Style 'B'
	Else
		_screen.ForeColor = RGB(255,0,0)
		?? 'Failed'																											Font 'Lucida Console', 8 Style 'B'	
		_screen.ForeColor = RGB(0,0,0)
		?? ': ' + Transform(m.aCounters(3)) + ' test failed, ' + Transform(m.aCounters(2)) + ' test passed'					Font 'Lucida Console', 8 Style 'B'
	EndIf
	? ' ' + c_TAB + 'Test counter: ' + Transform(m.aCounters(1)) + ' tests'													Font 'Lucida Console', 8 Style 'B'
	m.OldDecimals = Set('Decimals')
	Set Decimals To 6
	? ' ' + c_TAB + '   Test time: ' + Transform(m.Seconds) + ' seconds, ' + Transform(m.Seconds/m.aCounters(1)) + ' seconds for test'	Font 'Lucida Console', 8 Style 'B'
	Set Decimals To	m.OldDecimals
	?

EndFunc

Function _test_do
Lparameters m.aCounters, m.Test, m.OkResult

	m.aCounters(1) = m.aCounters(1) + 1
	If (&Test == m.OkResult)
		m.aCounters(2) = m.aCounters(2) + 1
		If not m.Silent
			_screen.ForeColor = RGB(100,200,0)
			? ' ' + Transform(m.aCounters(1), '@L 9999') + ' ' 					Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,255)
			?? m.Test + Space(Max(c_COLUMN_TEST_WIDTH - Len(m.Test), 0)) + ' '	Font 'Lucida Console', 8
			_screen.ForeColor = RGB(100,200,0)
			?? 'Passed'															Font 'Lucida Console', 8
			_screen.ForeColor = RGB(0,0,0)
			?? ' Result: '														Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,255)							
			?? ['] + &Test + [']												Font 'Lucida Console', 8
			_screen.ForeColor = RGB(0,0,0)
		EndIf
	Else
		m.aCounters(3) = m.aCounters(3) + 1
		If not m.Silent
			_screen.ForeColor = RGB(255,0,0)
			? ' ' + Transform(m.aCounters(1), '@L 9999') + ' '					Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,255)
			?? m.Test + Space(Max(c_COLUMN_TEST_WIDTH - Len(m.Test), 0)) + ' '	Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,0)
			?? 'Failed'															Font 'Lucida Console', 8
			_screen.ForeColor = RGB(0,0,0)
			?? ' Obtained: '													Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,255)
			?? ['] + &Test + [']												Font 'Lucida Console', 8
			_screen.ForeColor = RGB(0,0,0)	
			?? c_TAB + 'Expected: '												Font 'Lucida Console', 8
			_screen.ForeColor = RGB(255,0,255)
			?? ['] + m.OkResult + [']											Font 'Lucida Console', 8
			_screen.ForeColor = RGB(0,0,0)
		EndIf
	EndIf

EndFunc


Function Format_Test
	Lparameters m.Iterations

	Local m.i As Integer, ;
			m.Seconds As Double

	Local Array m.aCounters(3)
	
	Private m.Silent
	
	Store 0 To ;
		m.aCounters
		
	_test_header('function "Format()"')
	
	If (Vartype(m.Iterations) <> 'N') or (m.Iterations <= 0)
		m.Iterations = c_DEFAULT_TEST_ITERATIONS
	EndIf 

	m.Silent = (m.Iterations <> 1)
	
	m.Seconds = Seconds()

	For m.i = 1 To m.Iterations
		*-- Basic test.		
		_test_do(@m.aCounters, [Format(1)]															, '1')
		_test_do(@m.aCounters, [Format(1000.01)]													, '1000' + Set('Point') + '01')
		_test_do(@m.aCounters, [Format('This is a simple text')]									, 'This is a simple text')
		_test_do(@m.aCounters, [Format(.t.)]														, 'Verdadero')
		_test_do(@m.aCounters, [Format(.f.)]														, 'Falso')
		_test_do(@m.aCounters, [Format({^2000-01-01})]												, Dtoc({^2000-01-01}))
		_test_do(@m.aCounters, [Format({^2000-01-01 10:01:02})]										, Ttoc({^2000-01-01 10:01:02}))
		_test_do(@m.aCounters, [Format(null)]														, Set('NullDisplay'))
		
		*-- String format.
		_test_do(@m.aCounters, [Format('"%s:10l:" "%s1:10c:" "%s1:10r:"', 'test')]					, '"test      " "   test   " "      test"')
		_test_do(@m.aCounters, [Format('"%s" "%s1:n:" "%s1:3rn:"'       , ' test ')]				, '"test" " test " " te"')
		_test_do(@m.aCounters, [Format('"%s:3r:" "%s1:3t:"'             , ' test ')]				, '"tes" "tes"')
                    
		*-- Numeric format.         
		_test_do(@m.aCounters, [Format('"%s1:5:" "%s1:5p:" "%s1:5pz:"'  , 1.1)]						, '" 1' + Set('Point') + '10" "  110" "00110"')
		_test_do(@m.aCounters, [Format('%s:5:'                          , -1.1)]					, '-1' + Set('Point') + '10')
		_test_do(@m.aCounters, [Format('"%s:10l:" "%s1:10c:" "%s1:10r:"', 1.1)]						, '"1' + Set('Point') + '10      " "   1' + Set('Point') + '10   " "      1' + Set('Point') + '10"')
		_test_do(@m.aCounters, [Format('%s:10$.2:'                      , 1000.1)]					, '' + Transform(1000.1, '@$ 99999.99') + '')
		_test_do(@m.aCounters, [Format('%s:10$.2,.:'                    , 1.1)]						, '' + Chrtran(Transform(1.1, '@$ 99999.99'), Set('Point'), '.') + '')
		_test_do(@m.aCounters, [Format('%s:10$,..2:'                    , 1.1)]						, '' + Chrtran(Transform(1.1, '@$ 99999.99'), Set('Point'), '.') + '')
		_test_do(@m.aCounters, [Format('%s:4.0: %s:4e.0: %s:4.0e:'      , 12345, 12345, 12345)]		, '**** 12345 12345')
		
		*-- Date & DateTime format.
		_test_do(@m.aCounters, [Format('%s %s'                          , {^2000-01-01}, {^2000-01-01 10:01:02})]	, Dtoc({^2000-01-01}) + ' ' + Ttoc({^2000-01-01 10:01:02}))
		_test_do(@m.aCounters, [Format('%s1:i: %s1:o:'                  , {^2000-01-01})]			, '2000-01-01 ^2000-01-01')
		_test_do(@m.aCounters, [Format('%s1:i: %s1:o:'                  , {^2000-01-01 10:01:02})]	, '2000-01-01T10:01:02 ^2000-01-01 10:01:02')
		_test_do(@m.aCounters, [Format('%s1:d: %s1:sd: %s1:m: %s1:ms:'  , {^2000-08-01 10:01:02})]	, 'Martes M Agosto Ago')
		_test_do(@m.aCounters, [Format('%s:y:-%s:ys:-%s:sy:'            , Year({^2000-01-01}), Month({^2000-01-01}), Day({^2000-01-01}))], '2000-01-01')
		_test_do(@m.aCounters, [Format('|%s:o:| |%s:i:|'                , {}, {})]					, '|' + c_DATE_EMPTY_FOR_O + '| |' + c_DATE_EMPTY_FOR_I + '|')
		
		*-- \n & \t format.
		_test_do(@m.aCounters, [Format('\n\t%s:o:\n\tIntro'             , {^2000-01-01})]			, c_ENTER + c_TAB + '^2000-01-01' + c_ENTER + c_TAB + 'Intro')
		_test_do(@m.aCounters, [Format('\\t\\n%s:o:\\nIntro'            , {^2000-01-01})]			, '\t\n^2000-01-01\nIntro')
		_test_do(@m.aCounters, [Format('\t%s1:o: \\t%s1:o:'             , {^2000-01-01})]			, c_TAB + '^2000-01-01 \t^2000-01-01')
		
		*-- v related.      
		_test_do(@m.aCounters, [Format('%s:v:,%s:10$.2v:,%s:v:,%s:v:'   , 1, 1.1, 'Test"CSV"', 'hola y ' + Chr(10) + 'adios')]	, '1,' + Chrtran(Transform(1.1, '@$ 99999.99'), Set('Point'), '.') + ',"Test""CSV""","hola y ' + Chr(10) + 'adios"')
		_test_do(@m.aCounters, [Format('%s:v:,%s:v:'                    , {^2000-08-01 10:01:02}, {^2000-08-01})], Ttoc({^2000-08-01 10:01:02}) + ',' + Dtoc({^2000-08-01}))

		*-- Bad options.
		_test_do(@m.aCounters, [Format('%s1:aeiou:'                     , 'Test')]					, 'Test')
                
		*-- Parameters with ids.       
		_test_do(@m.aCounters, [Format('%s1:%s2:%s3: %s3:%s1:%s2:'      , 1, 2, 3)]					, '123 312')
		_test_do(@m.aCounters, [Format('%s2:%s3:%s1: %s1:%s1:%s1:'      , 1, 2, 3)]					, '231 111')
		_test_do(@m.aCounters, [Format('%s2:%s2:%s2: %s3:%s3:%s3:'      , 1, 2, 3)]					, '222 333')
		_test_do(@m.aCounters, [Format('%s1: %s2: %s3:'                 , 1, 2, 3)]					, '1 2 3')
		_test_do(@m.aCounters, [Format('%s1: %s2::: {%s1::->%s2::}'     , 1, 2)]					, '1 2: {1->2}')
                
		*-- Parameters without ids.     
		_test_do(@m.aCounters, [Format('%s%s%s'                         , 1, 2, 3)]					, '123')
		_test_do(@m.aCounters, [Format('%s%s%s '                        , 1, 2, 3)]					, '123 ')
		_test_do(@m.aCounters, [Format('%s:%s:%s:%s::%s::%s::'          , 1, 2, 3, 1, 2, 3)]		, '1:2:3:123')
		_test_do(@m.aCounters, [Format('%s %s %s'                       , 1, 2, 3)]					, '1 2 3')
		_test_do(@m.aCounters, [Format('%s1 %s2 %s3'                    , 1, 2, 3)]					, '11 22 33')
		_test_do(@m.aCounters, [Format('%s1%s2%s3'                      , 1, 2, 3)]					, '112233')
                
		*-- Especial characters related.
		_test_do(@m.aCounters, [Format('\%s %s%'                        , 1, 100)]					, '%s 100%')
		_test_do(@m.aCounters, [Format('"%s:6.2:%" "%s1:6.2::"'         , 100)]						, '"100' + Set('Point') + '00%" "100' + Set('Point') + '00:"')
                    
		*-- Regressions.        
		_test_do(@m.aCounters, [Format('] + c_TEXTMERGE_LEFT_DELIMITER + [m.Par1] + c_TEXTMERGE_RIGHT_DELIMITER + [ %s'                  , 'Test')]	, c_TEXTMERGE_LEFT_DELIMITER + 'm.Par1' + c_TEXTMERGE_RIGHT_DELIMITER + ' Test')
		_test_do(@m.aCounters, [Format('%s1:%s:1'                       , 100)]						, '100Falso')
		_test_do(@m.aCounters, [Format('%s1:%s:1'                       , 100, 100)]				, '100,**')
		_test_do(@m.aCounters, [Format('%s1:%s:1.0'                     , 100, 100)]				, '100*')
		_test_do(@m.aCounters, [Format('a\na')]														, 'a\na')
		_test_do(@m.aCounters, [Format('a\na'                           , '')]						, 'a' + c_ENTER + 'a')
		_test_do(@m.aCounters, [Format('"%s:10:"'                       , 'a')]						, '"a         "')
	EndFor
		
	_test_footer(@m.aCounters, Seconds() - m.Seconds)
	
EndFunc
#ENDIF

* Define Class UnitTest As Custom
* oUT = CreateObject('UnitTest')
* oUT.AddTest('<test>', '<result>', id)
* out.ListTest()
* oUT.RemoveTest(id)
* oUT.RemoveTests
* oUT.RunTest()
* oUT.RunProfiler()

Define Class UnitTest As Custom
	Dimension aTests(1, 3)
	Caption = 'Unit Test'
	ProfilerCounter = 1000
	TestsCount = 0
	Silent = .f.
	

	Function Init
	Lparameters m.Caption, m.ProfilerCounter
	
		This.Caption = m.Caption
		This.ProfilerCounter = Iif(Empty(m.ProfilerCounter), This.ProfilerCounter, m.ProfilerCounter)
		
		This.TestsCount = 0
		Dimension This.aTests(1, 3)
		Store .f. To ;
			This.aTests
		
	EndFunc
	
	Function Destroy
	
	EndFunc
	
	Function AddTest ;
	HelpString 'Adds a new unit test, returns ID or 0 if operation failed'
	
	EndFunc
	
	Function ListTest ;
	HelpString 'List a test identified by id'
	
	EndFunc

	Function ListTests ;
	HelpString 'List all tests'
	
	EndFunc

	Function RunTest ;
	HelpString 'Run a test identified by id'

	Lparameters m.TestId

		This.PreRun(m.TestId)
		This._Test_Do(@m.aCounters, This.aTests(m.TestId, 2), This.aTests(m.Testid, 3))
		This.PostRun(m.TestId)

	EndFunc

	Function RunTests ;
	HelpString 'Run all tests'

		Local m.i As Integer, ;
				m.Seconds As Double

		Local Array m.aCounters(3)
		
		Store 0 To ;
			m.aCounters
			
		This.Silent = .t.

		This.PreRun(0)
		This._Test_Header()
		
		This.Silent = .f.
		
		m.Seconds = Seconds()

		For m.i = 1 To This.TestsCounts
			This.RunTest(This.aTests(m.i, 1))
		EndFor
			
		This._Test_Footer(@m.aCounters, Seconds() - m.Seconds)
		This.PostRun(0)

	EndFunc

	Function RemoveTest ;
	HelpString 'Remove a test using test id'
	
	EndFunc
	
	Function PreRun ;
	HelpString 'This method is executed before running a tests. Receives the current test ID or 0 if this is the '
	
	Lparameters m.TestId
	
	EndFunc
	
	
	Function PostRun ;
	HelpString 'This method is executed after running a tests'
	
	Lparameters m.TestId

	EndFunc
	

	Function _test_header
	Lparameters m.TestName
		Clear
		_screen.ForeColor = RGB(0,0,0)
		? ' ' + Replicate('=', 37) 															Font 'Lucida Console', 8 Style 'B'
		? ' ' + '| Unit test for ' + TestName + ' |'										Font 'Lucida Console', 8 Style 'B'
		? ' ' + Replicate('=', 37)															Font 'Lucida Console', 8 Style 'B'
		?
		? ' ' + Replicate('-', 4) + ' ' + Replicate('-', c_COLUMN_TEST_WIDTH) + ' ' + Replicate('-', c_COLUMN_RESULT_WIDTH)		Font 'Lucida Console', 8
		? ' ' + Space(3) + '#' + ' ' + 'Test' + Space(c_COLUMN_TEST_WIDTH - Len('Test')) + ' ' + 'Result'						Font 'Lucida Console', 8
		? ' ' + Replicate('-', 4) + ' ' + Replicate('-', c_COLUMN_TEST_WIDTH) + ' ' + Replicate('-', c_COLUMN_RESULT_WIDTH)		Font 'Lucida Console', 8
	EndFunc

	Function _test_footer
	Lparameters m.aCounters, m.Seconds	
		Local m.OldDecimals
		
		_screen.ForeColor = RGB(0,0,0)
		? ' ' + Replicate('-', 6 + c_COLUMN_TEST_WIDTH + c_COLUMN_RESULT_WIDTH)													Font 'Lucida Console', 8
		?
		? ' Unit test finished with a '																							Font 'Lucida Console', 8 Style 'B'
		If (m.aCounters(3) = 0)
			_screen.ForeColor = RGB(100,200,0)
			?? 'Passed'																											Font 'Lucida Console', 8 Style 'B'
			_screen.ForeColor = RGB(0,0,0)
			?? ': All ' + Transform(m.aCounters(2)) + ' test passed'															Font 'Lucida Console', 8 Style 'B'
		Else
			_screen.ForeColor = RGB(255,0,0)
			?? 'Failed'																											Font 'Lucida Console', 8 Style 'B'	
			_screen.ForeColor = RGB(0,0,0)
			?? ': ' + Transform(m.aCounters(3)) + ' test failed, ' + Transform(m.aCounters(2)) + ' test passed'					Font 'Lucida Console', 8 Style 'B'
		EndIf
		? ' ' + c_TAB + 'Test counter: ' + Transform(m.aCounters(1)) + ' tests'													Font 'Lucida Console', 8 Style 'B'
		m.OldDecimals = Set('Decimals')
		Set Decimals To 6
		? ' ' + c_TAB + '   Test time: ' + Transform(m.Seconds) + ' seconds, ' + Transform(m.Seconds/m.aCounters(1)) + ' seconds for test'	Font 'Lucida Console', 8 Style 'B'
		Set Decimals To	m.OldDecimals
		?

	EndFunc

	Function _test_do
	Lparameters m.aCounters, m.Test, m.OkResult

		m.aCounters(1) = m.aCounters(1) + 1
		If (&Test == m.OkResult)
			m.aCounters(2) = m.aCounters(2) + 1
			If not m.Silent
				_screen.ForeColor = RGB(100,200,0)
				? ' ' + Transform(m.aCounters(1), '@L 9999') + ' ' 					Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,255)
				?? m.Test + Space(Max(c_COLUMN_TEST_WIDTH - Len(m.Test), 0)) + ' '	Font 'Lucida Console', 8
				_screen.ForeColor = RGB(100,200,0)
				?? 'Passed'															Font 'Lucida Console', 8
				_screen.ForeColor = RGB(0,0,0)
				?? ' Result: '														Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,255)							
				?? ['] + &Test + [']												Font 'Lucida Console', 8
				_screen.ForeColor = RGB(0,0,0)
			EndIf
		Else
			m.aCounters(3) = m.aCounters(3) + 1
			If not m.Silent
				_screen.ForeColor = RGB(255,0,0)
				? ' ' + Transform(m.aCounters(1), '@L 9999') + ' '					Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,255)
				?? m.Test + Space(Max(c_COLUMN_TEST_WIDTH - Len(m.Test), 0)) + ' '	Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,0)
				?? 'Failed'															Font 'Lucida Console', 8
				_screen.ForeColor = RGB(0,0,0)
				?? ' Obtained: '													Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,255)
				?? ['] + &Test + [']												Font 'Lucida Console', 8
				_screen.ForeColor = RGB(0,0,0)	
				?? c_TAB + 'Expected: '												Font 'Lucida Console', 8
				_screen.ForeColor = RGB(255,0,255)
				?? ['] + m.OkResult + [']											Font 'Lucida Console', 8
				_screen.ForeColor = RGB(0,0,0)
			EndIf
		EndIf

	EndFunc

EndDefine


Function rununittest

EndFunc
