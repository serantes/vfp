*#DEFINE	c_DEFAULT_OUTPUT			'_Automatic'
*#DEFINE	c_DEFAULT_OUTPUT			'_ClipText'
#DEFINE	c_DEFAULT_OUTPUT			'_PutFile'

#DEFINE	c_ERROR_GENERIC				-1
#DEFINE	c_ERROR_PARAMETERS			-2
#DEFINE	c_ERROR_FILE_NOT_FOUND		-3
#DEFINE	c_ERROR_FILE_UNSUPPORTED	-4
#DEFINE	c_ERROR_IMPORT_XLSX			-5
#DEFINE	c_ERROR_USER_CANCELLED		-6

#DEFINE	c_ENTER Chr(13) + Chr(10)

#DEFINE	c_DEFAULT_START_ROW		2
#DEFINE	c_DEFAULT_HEADER_ROW	1
#DEFINE	c_DEFAULT_SHEET			''

Lparameters tcName As String, ;
	tcFileName As String, ;
	tvParam3, ;					&& Logical llCloseAlias, Numeric lnStartRow
	tvParam4, ;					&& Logical llCloseAlias, Numeric lnHeaderRow
	tvParam5, ;					&& Logical llCloseAlias, String lcSheet
	tvParam6					&& Logical llCloseAlias

Local ;
	llCloseAlias As Logical, ;
	lnStartRow As Integer, ;
	lnHeaderRow As Integer, ;
	lcSheet As String, ;
	lcAlias As String, ;
	lcDummy As String, ;
	lcFileName As String, ;
	llToClipBoard As Logical, ;
	lcBuffer As String, ;
	lcOldAlias As String, ;
	lnOldRecno As Integer, ;
	lnRecCount As Integer, ;
	lnFieldsCount As Integer, ;
	lcLine As String, ;
	lcField As String, ;
	loForm As Form				&& Required to display information if _screen.visible = .f.
		
Local Array m.AFields(1)

*-- Parameters parse.
If Empty(m.tcName)
	m.tcName = GetFile('xlsx')
	If Empty(m.tcName)
		Return c_ERROR_PARAMETERS
	EndIf
EndIf

m.llCloseAlias = .f.
m.lnStartRow = c_DEFAULT_START_ROW
m.lnHeaderRow = c_DEFAULT_HEADER_ROW
m.lcSheet = c_DEFAULT_SHEET

If (Pcount() >= 6)
	m.llCloseAlias = Iif((Vartype(m.tvPar6) = 'L'), .f., m.tvPar6)
EndIf 

If (Pcount() >= 5)
	m.lcDummy = Vartype(m.tvPar5)
	Do case
		Case (m.lcDummy = 'C')
			m.lcSheet = m.tvPar5	
		Case (m.lcDummy = 'L')
			m.llCloseAlias = m.tvPar5
		Otherwise
			Return c_ERROR_PARAMETERS
	EndCase
EndIf

If (Pcount() >= 4)
	m.lcDummy = Vartype(m.tvPar4)
	Do case
		Case (m.lcDummy = 'N')
			m.lnHeaderRow = m.tvPar4	
		Case (m.lcDummy = 'L')
			m.llCloseAlias = m.tvPar4
		Otherwise
			Return c_ERROR_PARAMETERS
	EndCase
EndIf

If (Pcount() >= 3)
	m.lcDummy = Vartype(m.tvPar3)
	Do case
		Case (m.lcDummy = 'N')
			m.lnStartRow = m.tvPar3
		Case (m.lcDummy = 'L')
			m.llCloseAlias = m.tvPar3
		Otherwise
			Return c_ERROR_PARAMETERS
	EndCase
EndIf

If Empty(m.tcFileName)
	m.lcFileName = c_DEFAULT_OUTPUT
EndIf


Do case
	
	Case (Lower(Alltrim(m.lcFileName)) == '_putfile')
		m.lcFileName = Putfile('', JustStem(m.tcName), 'md')
		If Empty(m.lcFileName)
			Return c_ERROR_USER_CANCELLED
		Else
			If File(m.lcFileName)
				Delete File (m.lcFilename) Recycle
			EndIf
		EndIf

	Case (Lower(Alltrim(m.lcFileName)) == '_automatic')
		m.lcFileName = ForceExt(m.tcName, 'md')
	
	Otherwise
		*-- Nada
		
EndCase


m.lcOldAlias = Alias()
If not Used(m.tcName)
	If not File(m.tcName)
		Return c_ERROR_FILE_NOT_FOUND
	EndIf
	Do case
		Case (Upper(Alltrim(JustExt(m.tcName))) == 'XLSX')
			If (_screen.Visible = .f.) and (Vartype(m.loForm) <> 'O')
				m.loForm = CreateObject('Form')
			EndIf		
			m.lcAlias = ImportFromXlsx(m.tcName, m.lnStartRow, m.lcSheet, .t., .f., m.lnHeaderRow)
			If Empty(m.lcAlias)
				Return c_ERROR_IMPORT_XLSX
			EndIf
			m.llCloseAlias = .t.
		Otherwise
			Return c_ERROR_FILE_UNSUPPORTED
	EndCase
Else
	m.lcAlias = m.tcName
EndIf

lnFieldsCount = 0

m.llToClipboard = (Lower(Alltrim(m.lcFileName)) == '_cliptext')

m.lnOldRecno = Iif(m.llCloseAlias or Eof(m.lcAlias), 0, Recno(m.lcAlias))
m.lnRecCount = Reccount(m.lcAlias)

Select (m.lcAlias)

Do While File(m.lcFileName)
	m.lcFileName = JustPath(m.lcFileName) + '\' + JustStem(m.lcFilename) + '_' +Ttoc(Datetime(), 1) + '.' + JustExt(m.lcFileName)
	If Left(m.lcFileName, 1) = '\'
		m.lcFilename = '.' + m.lcFileName
	EndIf
EndDo

If m.llToClipboard
	m.lcBuffer = ''
Else
	StrToFile('', m.lcFileName, 0)
EndIf

m.lnFieldsCount = AFields(aFields, m.lcAlias)

*-- Header.
m.lcLine = '|'
For m.i = 1 to m.lnFieldsCount
	m.lcLine = m.lcLine + ' ' + m.AFields(m.i, 1) + ' |'
EndFor
*m.lcLine = m.lcLine
If m.llToClipboard
	m.lcBuffer = m.lcBuffer + m.lcLine
Else
	StrToFile(m.lcLine, m.lcFileName, 1)
EndIf

*-- Table configuration.
m.lcLine =  '| '
For m.i = 1 to m.lnFieldsCount
	Do case
		Case InList(m.AFields(m.i, 2), 'N', 'I','Y')
			m.lcLine = m.lcLine + ' ---: |'
		Otherwise
			m.lcLine = m.lcLine + ' --- |'
	EndCase
		
EndFor
m.lcLine = c_ENTER + m.lcLine
If m.llToClipboard
	m.lcBuffer = m.lcBuffer + m.lcLine
Else
	StrToFile(m.lcLine, m.lcFileName, 1)
EndIf

*-- Table scan.
Scan
	m.lcLine = '|'
	For m.i = 1 to m.lnFieldsCount
		Do case
			Case InList(m.AFields(m.i, 2), 'N', 'I','Y')
				m.lcLine = m.lcLine + ' ' + Transform(Evaluate(m.AFields(m.i, 1))) + ' |'
			Case InList(m.AFields(m.i, 2), 'C')
				m.lcLine = m.lcLine + ' ' + Alltrim(Evaluate(m.AFields(m.i, 1))) + ' |'
			Case InList(m.AFields(m.i, 2), 'D')
				m.lcLine = m.lcLine + ' ' + DToC(Evaluate(m.AFields(m.i, 1))) + ' |'
			Case InList(m.AFields(m.i, 2), 'T')
				m.lcLine = m.lcLine + ' ' + TToC(Evaluate(m.AFields(m.i, 1))) + ' |'
			Otherwise
				m.lcLine = m.lcLine + ' ' + Transform(Evaluate(m.AFields(m.i, 1))) + ' |'
		EndCase
	EndFor

	m.lcLine = c_ENTER + m.lcLine
	If m.llToClipboard
		m.lcBuffer = m.lcBuffer + m.lcLine
	Else
		StrToFile(m.lcLine, m.lcFileName, 1)
	EndIf
EndScan


*-- Finalization.
If (_screen.Visible = .f.) and (Vartype(m.loForm) <> 'O')
	m.loForm = CreateObject('Form')
EndIf

If m.llToClipboard
	_ClipText = m.lcBuffer
	MessageBox('Data copied to the ClipBoard.', 0 + 64)
Else
	MessageBox('Data saved to file "' + m.lcFileName + '".', 0 + 64)
EndIf

If (Vartype(m.loForm) = 'O')
	loForm.Release()
EndIf

If (m.lnOldRecno <> 0)
	Go (m.lnOldRecno) ;
		In (m.lcAlias)
EndIf

If not Empty(m.lcOldAlias)
	Select (m.lcOldAlias)
EndIf

If (m.llCloseAlias) and Used(m.lcAlias)
	Use In ;
		(m.lcAlias)
EndIf

Return m.lnRecCount + 2


Function ImportFromXlsx
* Version 4.0
LPARAMETERS lcFileName,lnStartRows,lcSheet,llCursor,llEmptyCells,lnHeader,lcTableName
* Parameters
* lcFileName		name of the xlsx
					* nom de xlsx
					* numele xlsx-ului
* lnStartRows		starting row (the first lnStartRows - 1 rows are skipped) ; optional ; default 1 (all rows)
					* a partir rangée (les premiers lnStartRows - 1 lignes sont passées) ; optionnel ; défaut 1 (tous les champs lignes)
					* primul rand (primele lnStartRows - 1 randuri ale tabelului din docx sunt omise); optional; implicit 1 (toate randurile)
* lcSheet			sheet name | number	; optional ; default ''
					* nom | nomber de la feuille ; optionnel ; défaut ''
					* numele |numarul foii	; optional ; implicit ''
* llCursor			when .T., the result is a cursor instead of a DBF ; optional ; default .F.
					* lorsque .T, le résultat est un cursor au lieu d'un DBF; optionnel; défaut .F.
					* cand este .T., rezultatul este un cursor si nu un DBF; optional; implicit .F.
* llEmptyCells		when .T., the source contains empty cells (slower import); optional ; default .F.
					* lorsque .T., la source contient des cellules vides (d'importation plus lent); optionnel ; défaut .F.
					* cand este .T., documentul sursa contine celule goale (importul este mai lent); optional; implicit .F.
* lnHeader			the row that contains column headers (lnHeader < lnStartRows); optional ; default 0
					* nombre de la ligne d'en-tête (lnHeader < lnStartRows); optionnel ; défaut 0
					* linia care contine antetele coloanelor (lnHeader < lnStartRows); optional; implicit 0
* lcTableName		name of the dbf	/ cursor; optional ; default '' (? for SaveAs - only for table)
					* nom de dbf / cursor ; optionnel ; défaut '' (? pour SaveAs)
					* numele dbf-ului / cursor; optional ; implicit '' (? pentru SaveAs - doar pentru tabele)
	DECLARE Sleep IN WIN32API INTEGER 
	DECLARE INTEGER ShellExecute IN shell32.dll INTEGER , STRING , STRING , STRING , STRING , INTEGER
	#DEFINE ERRLANG "Es"
	#IF ERRLANG = "Es"
		#DEFINE ERRMESS0 "Error"
		#DEFINE ERRMESS1 "Nada que importar"
		#DEFINE ERRMESS3 "Hoja no encontrada"
		#DEFINE ERRMESS4 "Error abriendo fichero"
		#DEFINE ERRMESS5 "Demasiadas columnas"
	#ELIF ERRLANG = "Ro"
		#DEFINE ERRMESS0 "Eroare"
		#DEFINE ERRMESS1 "Nimic de importat"
		#DEFINE ERRMESS3 "Foaie inexistenta"
		#DEFINE ERRMESS4 "Eroare la deschiderea"
		#DEFINE ERRMESS5 "Prea multe coloane"
	#ELIF ERRLANG = "Fr"
		#DEFINE ERRMESS0 "Erreur"
		#DEFINE ERRMESS1 "Rien a ajouter"
		#DEFINE ERRMESS3 "Feuille introuvable"
		#DEFINE ERRMESS4 "Erreur d'ouverture"
		#DEFINE ERRMESS5 "Trop de collones"
	#ELIF ERRLANG = "Nl" && Koen Piller
		#DEFINE ERRMESS0 "Fout"
		#DEFINE ERRMESS1 "Niets te importeren"
		#DEFINE ERRMESS3 "Blad niet gevonden"
		#DEFINE ERRMESS4 "Fout bij openen"
		#DEFINE ERRMESS5 "Te veel kolommen"
	#ELSE
		#DEFINE ERRMESS0 "Error"
		#DEFINE ERRMESS1 "Nothing to append"
		#DEFINE ERRMESS3 "Sheet not found"
		#DEFINE ERRMESS4 "Error opening"
		#DEFINE ERRMESS5 "Too many columns"
	#ENDIF
	***************************************************************
	* If you prefer to extract files with Winrar, uncomment this
	***************************************************************
	*#DEFINE archiveWinRar .T.

	LOCAL lcDir,cCurStr,lSetTalk,lnColsNo,laFields[1],laEmptyCells[1],llChars,lnSelect,lcDBF,laFiles[1],cCurStyle,lcCur,laDimRef[2,2],lcStrBad,llServer
	lcStrBad = ''
	llServer = OS(11) > '1'
	FOR lni = 0 TO 31
		IF !INLIST(m.lni,9,10,13)
			lcStrBad = m.lcStrBad + CHR(m.lni)
		ENDIF
	NEXT
	lnSelect = SELECT(0)

	IF PCOUNT() < 1 
		MESSAGEBOX(ERRMESS1,16,ERRMESS0)
		RETURN
	ELSE
		IF VARTYPE(m.lcFileName) $ "CV"
			lcFileName = FORCEEXT(m.lcFileName,"xlsx")
			IF !FILE(m.lcFileName)
				MESSAGEBOX(ERRMESS1,16,ERRMESS0)
				RETURN
			ENDIF
		ELSE
			MESSAGEBOX(ERRMESS1,16,ERRMESS0)
			RETURN
		ENDIF
	ENDIF
	IF PCOUNT() < 2
		lnStartRows = 1
	ELSE
		IF VARTYPE(m.lnStartRows) <> "N"
			lnStartRows = 1
		ENDIF
	ENDIF
	IF PCOUNT()<3
		lcSheet = ""
	ELSE
		IF NOT (VARTYPE(m.lcSheet) $ "CN")
			lcSheet = ""
		ENDIF
	ENDIF
	IF PCOUNT() < 4
		llCursor = .F.
	ELSE
		IF VARTYPE(m.llCursor) <> "L"
			llCursor = .F.
		ENDIF
	ENDIF
	IF PCOUNT() < 5
		llEmptyCells = .F.
	ELSE
		IF VARTYPE(m.llEmptyCells) <> "L"
			llEmptyCells = .F.
		ENDIF
	ENDIF
	IF PCOUNT() < 6
		lnHeader = 0
	ELSE
		IF VARTYPE(m.lnHeader) <> "N"
			lnHeader = 0
		ENDIF
	ENDIF
	IF m.lnHeader >= m.lnStartRows
		lnHeader = 0
	ENDIF

	IF PCOUNT() < 7
		lcTableName = ''
	ELSE
		IF NOT VARTYPE(m.lcFileName) $ "CV"
			lcTableName = ''
		ENDIF
	ENDIF

	lSetTalk = SET("Talk")
	SET TALK OFF 

	lcDir = extract(m.lcFileName,m.llServer)
	lcDBF = ""

	lcSheet = get_sheet(ADDBS(m.lcDir) + "workbook.xml",m.lcSheet)
	IF EMPTY(m.lcSheet)
		MESSAGEBOX(ERRMESS3,16,'Error')
		cleanup(m.lcDir,m.llServer)
		SET TALK &lSetTalk
		SELECT (m.lnSelect)
		RETURN m.lcDBF
	ENDIF

	llChars = ADIR(laFiles,ADDBS(m.lcDir) + "sharedStrings.xml") > 0
	IF m.llChars
		cCurStr = get_strings(ADDBS(m.lcDir) + "sharedStrings.xml")
		IF EMPTY(m.cCurStr)
			cleanup(m.lcDir,m.llServer)
			SET TALK &lSetTalk
			SELECT (m.lnSelect)
			RETURN m.lcDBF
		ENDIF
	ELSE
		cCurStr = ''
	ENDIF

	cCurStyle = get_styles(ADDBS(m.lcDir) + "styles.xml")
	IF EMPTY(m.cCurStyle)
		cleanup(m.lcDir,m.llServer)
		IF USED(m.cCurStr)
			USE IN (m.cCurStr)
		ENDIF
		SET TALK &lSetTalk
		SELECT (m.lnSelect)
		RETURN m.lcDBF
	ENDIF

	IF m.llServer
		lcCur = gen_table(ADDBS(ADDBS(m.lcDir) + 'worksheets') + FORCEEXT(m.lcSheet,"xml"),@lnStartRows,m.lcSheet,@lnColsNo,@laFields,m.cCurStyle,m.llEmptyCells,@laEmptyCells,m.lnHeader,m.cCurStr,m.llCursor,@laDimRef)
	ELSE
		lcCur = gen_table(ADDBS(m.lcDir) + FORCEEXT(m.lcSheet,"xml"),@lnStartRows,m.lcSheet,@lnColsNo,@laFields,m.cCurStyle,m.llEmptyCells,@laEmptyCells,m.lnHeader,m.cCurStr,m.llCursor,@laDimRef)
	ENDIF
	IF EMPTY(m.lcCur)
		cleanup(m.lcDir,m.llServer)
		IF USED(m.cCurStr)
			USE IN (m.cCurStr)
		ENDIF
		IF USED(m.cCurStyle)
			USE IN (m.cCurStyle)
		ENDIF
		SET TALK &lSetTalk
		SELECT (m.lnSelect)
		RETURN m.lcDBF
	ENDIF

	IF m.llServer
		lcDBF = get_cells(ADDBS(ADDBS(m.lcDir) + 'worksheets') + FORCEEXT(m.lcSheet,"xml"),@lcCur,m.cCurStr,m.lnColsNo,@laFields,m.lnStartRows,m.lcFileName,m.llCursor,m.llEmptyCells,m.cCurStyle,@laEmptyCells,@laDimRef,m.lcTableName)
	ELSE
		lcDBF = get_cells(ADDBS(m.lcDir) + FORCEEXT(m.lcSheet,"xml"),@lcCur,m.cCurStr,m.lnColsNo,@laFields,m.lnStartRows,m.lcFileName,m.llCursor,m.llEmptyCells,m.cCurStyle,@laEmptyCells,@laDimRef,m.lcTableName)
	ENDIF

	cleanup(m.lcDir,m.llServer)
	SET TALK &lSetTalk
	SELECT (m.lnSelect)
	IF USED(m.cCurStr)
		USE IN (m.cCurStr)
	ENDIF
	IF USED(m.cCurStyle)
		USE IN (m.cCurStyle)
	ENDIF
	IF USED(m.lcCur)
		USE IN (m.lcCur)
	ENDIF
	RETURN m.lcDBF

EndFunc

*********************
* Extract xml files *
*********************
FUNCTION extract
	LPARAMETERS lcFileName,llServer
	LOCAL lcDir,lcZip,oShell,ofile,loErr as Exception,lcSetSaf,lni,lnFF,laDir[1],lnDir,lnDir0
	lcDir = ADDBS(SYS(2023)) + SYS(2015)
	lcZip = FORCEEXT(m.lcDir,'.zip')
	COPY FILE (m.lcFileName) TO (m.lcZip)
	MD (m.lcDir)
***************************
* Use Winrar
***************************
#IFDEF archiveWinRar
	ShellExecute(0,"open","WinRAR.exe","E " + m.lcZip + " xl\sharedStrings.xml " + m.lcDir,"",1)
	lnFF = FOPEN(ADDBS(m.lcDir) + "sharedStrings.xml")
	DO WHILE m.lnFF < 0
		sleep(50)
		lnFF = FOPEN(ADDBS(m.lcDir) + "sharedStrings.xml")
	ENDDO
	FCLOSE(m.lnFF)
	ShellExecute(0,"open","WinRAR.exe","E " + m.lcZip + " xl\workbook.xml " + m.lcDir,"",1)
	lnFF = FOPEN(ADDBS(m.lcDir) + "workbook.xml")
	DO WHILE m.lnFF < 0
		sleep(50)
		lnFF = FOPEN(ADDBS(m.lcDir) + "workbook.xml")
	ENDDO
	FCLOSE(m.lnFF)
	ShellExecute(0,"open","WinRAR.exe","E " + m.lcZip + " xl\styles.xml " + m.lcDir,"",1)
	lnFF = FOPEN(ADDBS(m.lcDir) + "styles.xml")
	DO WHILE m.lnFF < 0
		sleep(50)
		lnFF = FOPEN(ADDBS(m.lcDir) + "styles.xml")
	ENDDO
	FCLOSE(m.lnFF)
	ShellExecute(0,"open","WinRAR.exe","E " + m.lcZip + " xl\worksheets\sheet*.xml " + m.lcDir,"",1)
	lnDir0 = 0
	lnDir = ADIR(laDir,ADDBS(m.lcDir ) + "sheet*.xml")

	DO WHILE (m.lnDir <> m.lnDir0) OR (m.lnDir = 0)
		FOR lni = 1 TO m.lnDir
			lnFF = FOPEN(ADDBS(m.lcDir) + m.laDir[m.lni,1])
			DO WHILE m.lnFF < 0
				sleep(50)
				lnFF = FOPEN(ADDBS(m.lcDir) + m.laDir[m.lni,1])
			ENDDO
			FCLOSE(m.lnFF)
		NEXT
		lnDir0 = m.lnDir
		lnDir = ADIR(laDir,ADDBS(m.lcDir ) + "sheet*.xml")
	ENDDO
***************************
* Use Explorer
***************************
#ELSE
	oShell = CREATEOBJECT("shell.application")
	TRY
		FOR lni = 0 TO m.oShell.NameSpace(ADDBS(m.lcZip)+'xl').items.count - 1
			ofile = m.oShell.NameSpace(ADDBS(m.lcZip)+'xl').items.item(m.lni)
			IF INLIST(m.ofile.name,'sharedStrings.xml','workbook.xml','styles.xml')
				oShell.NameSpace( m.lcDir).copyhere( m.ofile)
				lnFF = FOPEN(ADDBS(m.lcDir) + m.ofile.name)
				DO WHILE m.lnFF < 0
					sleep(50)
					lnFF = FOPEN(ADDBS(m.lcDir) + m.ofile.name)
				ENDDO
				FCLOSE(m.lnFF)
			ENDIF
		ENDFOR
		IF m.llServer
			FOR lni = 0 TO m.oShell.NameSpace(ADDBS(m.lcZip)+'xl').items.count - 1
				ofile = m.oShell.NameSpace(ADDBS(m.lcZip)+'xl').items.item(m.lni)
				IF INLIST(m.ofile.name,'worksheets')
					oShell.NameSpace( m.lcDir).copyhere( m.ofile)
					sleep(500)
					EXIT
				ENDIF
			ENDFOR
		ELSE
			FOR lni = 0 TO m.oShell.NameSpace(ADDBS(m.lcZip)+'xl\worksheets').items.count - 1
				ofile = m.oShell.NameSpace(ADDBS(m.lcZip)+'xl\worksheets').items.item(m.lni)
				IF LOWER(LEFT(m.ofile.name,5)) == 'sheet'
					oShell.NameSpace( m.lcDir).copyhere( m.ofile)
					lnFF = FOPEN(ADDBS(m.lcDir) + m.ofile.name)
					DO WHILE m.lnFF < 0
						sleep(50)
						lnFF = FOPEN(ADDBS(m.lcDir) + m.ofile.name)
					ENDDO
					FCLOSE(m.lnFF)
				ENDIF
			ENDFOR
		ENDIF
		CATCH TO loErr
	ENDTRY
#ENDIF
RETURN lcDir
	
****************
* Read strings *
****************
FUNCTION get_strings
	LPARAMETERS lcStr
	LOCAL cCurStr,lnF,lnPosSiSeek,lcBuff,lnPosSi,lnPosSi2,lcMemo,lcReturn,lnTextPiece,lcTextPiece,lcVal
	STORE SYS(2015) TO lcReturn, cCurStr
	CREATE CURSOR (m.cCurStr) (cStr M)
	lnF = FOPEN(m.lcStr)
	IF m.lnF >= 0
		lnPosSiSeek = 0
		DO WHILE !FEOF(m.lnF)
			lcBuff = FREAD(m.lnF,8192)
			lnPosSi = AT('<si>',m.lcBuff)
			lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi + 3
			= FSEEK(m.lnF,m.lnPosSiSeek)
			lcBuff = FREAD(m.lnF,8192)
			lnPosSi2 = AT('</si>',m.lcBuff)
			lcMemo = ''
			DO WHILE !FEOF(m.lnF) AND m.lnPosSi2 = 0
				lcMemo = m.lcMemo + m.lcBuff
				lcBuff = FREAD(m.lnF,8192)
				lnPosSi2 = AT('</si>',m.lcMemo)
			ENDDO
			IF m.lnPosSi2 != 0
				lcMemo = m.lcMemo + LEFT(m.lcBuff,m.lnPosSi2 - 1)
				lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi2 + 4
				lnPosSi = FSEEK(m.lnF,m.lnPosSiSeek)
				lcVal = ""
				STORE 1 TO lnTextPiece
				lcTextPiece = STREXTRACT(m.lcMemo,'<t','</t>')
				DO WHILE !EMPTY(m.lcTextPiece)
					lcVal = m.lcVal + STREXTRACT(m.lcTextPiece,[>])
					lnTextPiece = m.lnTextPiece + 1
					lcTextPiece = STREXTRACT(m.lcMemo,'<t','</t>',m.lnTextPiece) 
				ENDDO
				INSERT INTO (m.cCurStr) (cStr) VALUES (htmspec(m.lcVal))
			ELSE
				lcMemo = m.lcMemo + m.lcBuff
				EXIT
			ENDIF
		ENDDO
	ELSE
		lcReturn = ''
		MESSAGEBOX(ERRMESS4 + ' sharedStrings.xml',16,'Error')
	ENDIF
	FCLOSE(m.lnF)
RETURN m.lcReturn

***************
* Read styles *
***************
FUNCTION get_styles
	LPARAMETERS lcStr
	LOCAL cCurStr,lcBuff,lcMemo,lcReturn,lcTextPiece,lnTextPiece,lcVal,llDate,lcMemo2,lcTextPiece2,lnTextPiece2,lcVal2,lcVal3
	STORE SYS(2015) TO lcReturn, cCurStyle
	CREATE CURSOR (m.cCurStyle) (iIndex I AUTOINC NEXTVALUE 0,iFmt I,lDate L)
	INDEX on iIndex TAG iIndex
	lcBuff = FILETOSTR(m.lcStr)
	lcMemo = STREXTRACT(m.lcBuff,'<cellXfs ','</cellXfs>')
	lcMemo2 = STREXTRACT(m.lcBuff,'<numFmts ','</numFmts>')
	lnTextPiece = 1
	lcTextPiece = STREXTRACT(m.lcMemo,'<xf ','<xf ')
	DO WHILE !EMPTY(m.lcTextPiece)
		lcVal = STREXTRACT(m.lcTextPiece,'numFmtId="','"')
		llDate = BETWEEN(VAL(m.lcVal),14,22) or BETWEEN(VAL(m.lcVal),45,47) or BETWEEN(VAL(m.lcVal),27,36) or BETWEEN(VAL(m.lcVal),50,58) or BETWEEN(VAL(m.lcVal),71,81);
			or (EMPTY(m.lcMemo2) and !BETWEEN(VAL(m.lcVal),0,13) and !BETWEEN(VAL(m.lcVal),37,44) and !INLIST(VAL(m.lcVal),48,59,60,61,62,67,68,69,70))
		IF !m.llDate &&AND VAL(lcVal) >= 164
			lnTextPiece2 = 1
			lcTextPiece2 = STREXTRACT(m.lcMemo2,'<numFmt ','/>')
			DO WHILE !EMPTY(m.lcTextPiece2)
				lcVal2 = STREXTRACT(m.lcTextPiece2,'numFmtId="','"')
				IF m.lcVal2 == m.lcVal
					lcVal3 = STREXTRACT(m.lcTextPiece2,'formatCode="','"')
					llDate = AT("0.",m.lcVal3) + AT(".0",m.lcVal3) + AT("0,",m.lcVal3) + AT(",0",m.lcVal3) + AT("#",m.lcVal3) = 0
					EXIT
				ENDIF
				lnTextPiece2 = m.lnTextPiece2 + 1
				lcTextPiece2 = STREXTRACT(m.lcMemo2,'<numFmt ','/>',m.lnTextPiece2)
			ENDDO
		ENDIF
			
		INSERT INTO (m.cCurStyle) (iFmt,lDate) VALUES (VAL(m.lcVal),m.llDate)
		lnTextPiece = m.lnTextPiece + 1
		lcTextPiece = STREXTRACT(m.lcMemo,'<xf ','<xf ',m.lnTextPiece)
		IF EMPTY(m.lcTextPiece)
			lcTextPiece = STREXTRACT(m.lcMemo,'<xf ','',m.lnTextPiece)
		ENDIF
	ENDDO
RETURN m.lcReturn

**********************************************
* Read first row and determine the data type *
**********************************************
FUNCTION gen_table
	LPARAMETERS lcStr,lnStartRows,lcSheet,lnField,laFieldGat,cCurStyle,llEmptyCells,laEmptyCells,lnHeader,cCurStr,llCursor,laDimRef
	LOCAL lcCell,lnCurRow,lnStartRows0,lnCurRow0,lcShCol,lnShCol,lnShField,lnCurCol,lcTable,lcWholeTable,lcWholeRow,llDate,llTime,llBool,llMemo,llNumber,lnStyle
	LOCAL lnCurRowF,lnCurRow0F,lnStartRows0F,lnFieldF,lcShCol,ldDat01,ldDat02,lnDat,lcVal,lnTim,lnName,lcName,lnLeftName,lcDimRef,lnDimRef,lcDimRef1
	ldDat01 = DATE(1900,3,1) - 61
	ldDat02 = DATE(1900,1,1) - 1

	lcTable = SYS(2015)
	lcWholeTable = FILETOSTR(m.lcStr)
	*****************
	STORE STREXTRACT(m.lcWholeTable,[<dimension ref="],["]) TO lcDimRef, lcDimRef1
	laDimRef = 0
	lnDimRef = AT(":", m.lcDimRef)
	IF m.lnDimRef > 0
		lcDimRef1 = LEFT(m.lcDimRef, m.lnDimRef - 1)
		laDimRef[1,1] = VAL(CHRTRAN(m.lcDimRef1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',''))
		lcDimRef1 = CHRTRAN(m.lcDimRef1,'0123456789','')
		IF LEN(m.lcDimRef1) = 1
			laDimRef[1,2] = ASC(m.lcDimRef1) - 64
		ELSE
			IF LEN(m.lcDimRef1) = 2
				laDimRef[1,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ELSE && LEN(m.lcDimRef1) = 3
				laDimRef[1,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(SUBSTR(m.lcDimRef1,1,1)) - 64) + 676 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ENDIF
		ENDIF
		lcDimRef1 = SUBSTR(m.lcDimRef, m.lnDimRef + 1)
		laDimRef[2,1] = VAL(CHRTRAN(m.lcDimRef1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',''))
		lcDimRef1 = CHRTRAN(m.lcDimRef1,'0123456789','')
		IF LEN(m.lcDimRef1) = 1
			laDimRef[2,2] = ASC(m.lcDimRef1) - 64
		ELSE
			IF LEN(m.lcDimRef1) = 2
				laDimRef[2,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ELSE && LEN(m.lcDimRef1) = 3
				laDimRef[2,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(SUBSTR(m.lcDimRef1,1,1)) - 64) + 676 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ENDIF
		ENDIF
	ELSE
		laDimRef[1,1] = VAL(CHRTRAN(m.lcDimRef1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',''))
		lcDimRef1 = CHRTRAN(m.lcDimRef1,'0123456789','')
		IF LEN(m.lcDimRef1) = 1
			laDimRef[1,2] = ASC(m.lcDimRef1) - 64
		ELSE
			IF LEN(m.lcDimRef1) = 2
				laDimRef[1,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ELSE && LEN(m.lcDimRef1) = 3
				laDimRef[1,2] = ASC(RIGHT(m.lcDimRef1,1)) - 64 + 26 * (ASC(SUBSTR(m.lcDimRef1,1,1)) - 64) + 676 * (ASC(LEFT(m.lcDimRef1,1)) - 64)
			ENDIF
		ENDIF
	ENDIF
	ACTIVATE SCREEN
	*******************
	lnCurRow = 1 &&m.lnStartRows
	lnCurRow0 = 1
	lnStartRows0 = m.lnStartRows
	lnFieldF = 0
	lnField = 1
	**************
	lcWholeRow = STREXTRACT(m.lcWholeTable,"<row ","</row>")
	IF EMPTY(m.lcWholeRow)
		MESSAGEBOX(ERRMESS1,16,ERRMESS0)
		RETURN ''
	ENDIF
	
	**************
	IF m.lnHeader > 0
		lnCurRowF = 1 &&m.lnStartRows
		lnCurRow0F = 1
		lnStartRows0F = m.lnHeader
*		lnFieldF = 1 
		lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
		DO WHILE !EMPTY(m.lcWholeRow) AND (lnCurRowF < m.lnStartRows0F OR EMPTY(m.lcCell) OR EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>])))
			lnCurRow0F = m.lnCurRow0F + 1
			IF !EMPTY(m.lcCell) AND !EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>]))
				lnCurRowF = m.lnCurRowF + 1
			ENDIF
			lcWholeRow = STREXTRACT(m.lcWholeTable,"<row ","</row>",m.lnCurRow0F)
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>])
		ENDDO
		IF EMPTY(m.lcWholeRow)
			MESSAGEBOX(ERRMESS1,16,ERRMESS0)
			RETURN ''
		ENDIF
		DO WHILE !EMPTY(m.lcCell)
			lcShCol = CHRTRAN(STREXTRACT(m.lcCell,'r="','"'),'0123456789','')
			IF LEN(m.lcShCol) = 1
				lnShCol = ASC(m.lcShCol) - 64 
			ELSE
				IF LEN(m.lcShCol) = 2
					lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(LEFT(m.lcShCol,1)) - 64)
				ELSE && LEN(m.lcShCol) = 3
					lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(SUBSTR(m.lcShCol,1,1)) - 64) + 676 * (ASC(LEFT(m.lcShCol,1)) - 64)
				ENDIF
			ENDIF
			lnShCol = m.lnShCol - laDimRef[1,2] + 1
			DIMENSION laFieldGat[m.lnShCol,18],laEmptyCells[m.lnShCol]
			FOR lnj = m.lnFieldF + 1 TO m.lnShCol
				STORE 0 TO laFieldGat[m.lnj,17],laFieldGat[m.lnj,18],laFieldGat[m.lnj,4]
				STORE .T. TO laFieldGat[m.lnj,5],laEmptyCells[m.lnj]
				STORE .F. TO laFieldGat[m.lnj,6],laFieldGat[m.lnj,5]
				STORE '' TO laFieldGat[m.lnj,7],laFieldGat[m.lnj,8],laFieldGat[m.lnj,9],laFieldGat[m.lnj,10],laFieldGat[m.lnj,11],laFieldGat[m.lnj,12],laFieldGat[m.lnj,13],laFieldGat[m.lnj,14],laFieldGat[m.lnj,15],laFieldGat[m.lnj,16]
				laFieldGat[m.lnj,2] = "M"
				laFieldGat[m.lnj,3] = 4
				IF m.lnj < m.lnShCol
					laFieldGat[m.lnj,1] = "MFIELD"+TRANSFORM(m.lnj)
				ELSE
					lcVal = STREXTRACT(m.lcCell,[<v>],[</v>])
					llBool = 't="b"' $ m.lcCell
					llMemo = 't="s"' $ m.lcCell
					llNumber = !m.llBool AND !m.llMemo AND not ('s="' $ m.lcCell)
					STORE .F. TO llDate, llTime
					IF !llBool AND !llMemo AND !llNumber
						lnStyle = VAL(STREXTRACT(m.lcCell,[s="],["]))
						IF SEEK(m.lnStyle,m.cCurStyle,"iIndex")
							llDate = &cCurStyle..lDate and VAL(STREXTRACT(m.lcCell,[<v>],[</v>])) = FLOOR(VAL(STREXTRACT(m.lcCell,[<v>],[</v>])))
							llTime = &cCurStyle..lDate and !m.llDate
							llNumber = !m.llDate and !m.llTime
						ENDIF
					ENDIF
					DO CASE
					CASE m.llNumber
						laFieldGat[m.lnShCol,1] = "_" + CHRTRAN(m.lcVal,'.,+-','')
					CASE m.llDate
						lnDat = VAL(m.lcVal)
						IF m.lnDat >= 61
							laFieldGat[m.lnShCol,1] = "_" + DTOS(m.ldDat01 + m.lnDat)
						ELSE
							laFieldGat[m.lnShCol,1] = "_" + DTOS(m.ldDat02 + m.lnDat)
						ENDIF
					CASE m.llTime
						lnTim = VAL(m.lcVal)
						lnDat = FLOOR(m.lnTim)
						laFieldGat[m.lnShCol,1] = "_" + TTOC(DTOT(m.ldDat01 + m.lnDat) + INT(86400.0 * (m.lnTim - m.lnDat)),1)
					CASE m.llBool
						laFieldGat[m.lnShCol,1] = IIF(m.lcVal == "1","TRUE","FALSE")
					OTHERWISE
						SELECT (m.cCurStr)
						TRY 
							IF [t="s"] $ m.lcCell
								GO VAL(m.lcVal) + 1 IN (m.cCurStr)
								laFieldGat[m.lnShCol,1] = cStr
							ELSE
								laFieldGat[m.lnShCol,1] = lcVal
							ENDIF
						CATCH TO loErr
							laFieldGat[m.lnShCol,1] = lcVal
						ENDTRY
						laFieldGat[m.lnShCol,1] = UPPER(ALLTRIM(laFieldGat[m.lnShCol,1]))
						laFieldGat[m.lnShCol,1] = CHRTRAN(laFieldGat[m.lnShCol,1],CHRTRAN(laFieldGat[m.lnShCol,1],"_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""),"")
						IF !ISALPHA(laFieldGat[m.lnShCol,1])
							laFieldGat[m.lnShCol,1] = "_" + laFieldGat[m.lnShCol,1]
						ENDIF
					ENDCASE
					laFieldGat[m.lnShCol,1] = LEFT(laFieldGat[m.lnShCol,1],IIF(m.llCursor,31,10)) && 31
					lnName = 0
					lcName = laFieldGat[m.lnShCol,1]
					DO WHILE BETWEEN(ASCAN(laFieldGat,m.lcName,1,-1,1,1+2+4+8), 1, m.lnShCol - 1)
						lnName = m.lnName + 1
						lcName = laFieldGat[m.lnShCol,1]
						lnLeftName = MIN(LEN(laFieldGat[m.lnShCol,1]) , IIF(m.llCursor,31,10) - LEN(TRANSFORM(m.lnName))) && 31
						lcName = LEFT(laFieldGat[m.lnShCol,1], m.lnLeftName) + TRANSFORM(m.lnName)
					ENDDO
					laFieldGat[m.lnShCol,1] = m.lcName
				ENDIF
			NEXT
			lnFieldF = m.lnShCol
			lnField = m.lnField + 1
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
		ENDDO
		lnField = m.lnField - 1
	ENDIF
	**************
	IF !m.llEmptyCells && simple case :  the sheet does not contain empty cells

*		lnField = 1 
		lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
		DO WHILE !EMPTY(m.lcWholeRow) AND (lnCurRow < m.lnStartRows0 OR EMPTY(m.lcCell) OR EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>])))
			lnCurRow0 = m.lnCurRow0 + 1
			IF !EMPTY(m.lcCell) AND !EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>]))
				lnCurRow = m.lnCurRow + 1
			ENDIF
			lcWholeRow = STREXTRACT(m.lcWholeTable,"<row ","</row>",m.lnCurRow0)
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>])
		ENDDO
		lnStartRows = lnCurRow0
		IF EMPTY(m.lcWholeRow)
			MESSAGEBOX(ERRMESS1,16,ERRMESS0)
			RETURN ''
		ENDIF
		DO WHILE !EMPTY(m.lcCell)
			IF m.lnFieldF < m.lnField
				DIMENSION laFieldGat[m.lnField,18],laEmptyCells[m.lnField]
				STORE 0 TO laFieldGat[m.lnField,17],laFieldGat[m.lnField,18],laFieldGat[m.lnField,4]
				STORE .T. TO laFieldGat[m.lnField,5],laEmptyCells[m.lnField]
				STORE .F. TO laFieldGat[m.lnField,6],laFieldGat[m.lnField,5]
				STORE '' TO laFieldGat[m.lnField,7],laFieldGat[m.lnField,8],laFieldGat[m.lnField,9],laFieldGat[m.lnField,10],laFieldGat[m.lnField,11],laFieldGat[m.lnField,12],laFieldGat[m.lnField,13],laFieldGat[m.lnField,14],laFieldGat[m.lnField,15],laFieldGat[m.lnField,16]
			ENDIF
			llBool = 't="b"' $ m.lcCell
			llMemo = 't="s"' $ m.lcCell
			llNumber = !m.llBool AND !m.llMemo AND not ('s="' $ m.lcCell)
			STORE .F. TO llDate, llTime
			IF !llBool AND !llMemo AND !llNumber
				lnStyle = VAL(STREXTRACT(m.lcCell,[s="],["]))
				IF SEEK(m.lnStyle,m.cCurStyle,"iIndex")
					llDate = &cCurStyle..lDate and VAL(STREXTRACT(m.lcCell,[<v>],[</v>])) = FLOOR(VAL(STREXTRACT(m.lcCell,[<v>],[</v>])))
					llTime = &cCurStyle..lDate and !m.llDate
					llNumber = !m.llDate and !m.llTime
				ENDIF
			ENDIF
			IF m.lnFieldF < m.lnField
				laFieldGat[m.lnField,1] = "MFIELD"+TRANSFORM(m.lnField)
			ENDIF
			laEmptyCells[m.lnField] = !m.llDate AND !m.llTime AND !m.llMemo AND !m.llBool AND !m.llNumber
			DO CASE
			CASE m.llNumber
				laFieldGat[m.lnField,2] = "B"
				laFieldGat[m.lnField,3] = 8
				laFieldGat[m.lnField,4] = 15
			CASE m.llDate
				laFieldGat[m.lnField,2] = "D"
				laFieldGat[m.lnField,3] = 8
			CASE m.llTime
				laFieldGat[m.lnField,2] = "T"
				laFieldGat[m.lnField,3] = 8
			CASE m.llBool
				laFieldGat[m.lnField,2] = "L"
				laFieldGat[m.lnField,3] = 1
			OTHERWISE
				laFieldGat[m.lnField,2] = "M"
				laFieldGat[m.lnField,3] = 4
			ENDCASE
			lnField = m.lnField + 1
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
		ENDDO
		lnField = m.lnField - 1
	ELSE && complicated :  check empty cells

		lnField = 1 
		lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
		IF AT([<c ],m.lcCell) > 0
			lcCell = LEFT(m.lcCell , AT([<c ],m.lcCell) - 1)
		ENDIF
		DO WHILE !EMPTY(m.lcWholeRow) AND (lnCurRow < m.lnStartRows0 OR EMPTY(m.lcCell) OR EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>])))
			lnCurRow0 = m.lnCurRow0 + 1
			IF !EMPTY(m.lcCell) AND !EMPTY(STREXTRACT(m.lcCell,[<v>],[</v>]))
				lnCurRow = m.lnCurRow + 1
			ENDIF
			lcWholeRow = STREXTRACT(m.lcWholeTable,"<row ","</row>",m.lnCurRow0)
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>])
			IF AT([<c ],m.lcCell) > 0
				lcCell = LEFT(m.lcCell , AT([<c ],m.lcCell) - 1)
			ENDIF
		ENDDO
		lnStartRows = lnCurRow0
		IF EMPTY(m.lcWholeRow)
			MESSAGEBOX(ERRMESS1,16,ERRMESS0)
			RETURN ''
		ENDIF
		lnShField = 0
		DO WHILE !EMPTY(m.lcCell)
			lnShCol = lnShField
			lcShCol = CHRTRAN(STREXTRACT(m.lcCell,'r="','"'),'0123456789','')
			DO CASE
			CASE LEN(m.lcShCol) = 1
				lnShCol = ASC(m.lcShCol) - 64
			CASE LEN(m.lcShCol) = 2
				lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(LEFT(m.lcShCol,1)) - 64)
			CASE LEN(m.lcShCol) = 3
				lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(SUBSTR(m.lcShCol,1,1)) - 64) + 676 * (ASC(LEFT(m.lcShCol,1)) - 64)
			ENDCASE
			lnShCol = m.lnShCol - laDimRef[1,2] + 1
		
			IF m.lnFieldF < m.lnShCol
				DIMENSION laFieldGat[m.lnShCol,18],laEmptyCells[m.lnShCol]
				FOR lnCurCol = MAX(m.lnShField,m.lnFieldF) + 1 TO m.lnShCol
					STORE 0 TO laFieldGat[m.lnCurCol,17],laFieldGat[m.lnCurCol,18],laFieldGat[m.lnCurCol,4]
					STORE .T. TO laFieldGat[m.lnCurCol,5],laEmptyCells[m.lnCurCol]
					STORE .F. TO laFieldGat[m.lnCurCol,6],laFieldGat[m.lnCurCol,5]
					STORE '' TO laFieldGat[m.lnCurCol,7],laFieldGat[m.lnCurCol,8],laFieldGat[m.lnCurCol,9],laFieldGat[m.lnCurCol,10],laFieldGat[m.lnCurCol,11],laFieldGat[m.lnCurCol,12],laFieldGat[m.lnCurCol,13],laFieldGat[m.lnCurCol,14],laFieldGat[m.lnCurCol,15],laFieldGat[m.lnCurCol,16]
					laFieldGat[m.lnCurCol,1] = "MFIELD"+TRANSFORM(m.lnCurCol)
				NEXT
				FOR lnCurCol = MAX(m.lnShField,m.lnFieldF) + 1 TO m.lnShCol - 1 && empty cells
					laFieldGat[m.lnCurCol,2] = "M"
					laFieldGat[m.lnCurCol,3] = 4
				NEXT
			ENDIF
			IF AT([<v>],m.lcCell) = 0 && empty cells
				laFieldGat[m.lnShCol,2] = "M"
				laFieldGat[m.lnShCol,3] = 4
			ELSE
				llBool = 't="b"' $ m.lcCell
				llMemo = 't="s"' $ m.lcCell
				llNumber = !llBool AND !llMemo AND not ('s="' $ m.lcCell)
				STORE .F. TO llDate, llTime
				IF !llBool AND !llMemo AND !llNumber
					lnStyle = VAL(STREXTRACT(m.lcCell,[s="],["]))
					IF SEEK(m.lnStyle,m.cCurStyle,"iIndex")
						llDate = &cCurStyle..lDate and VAL(STREXTRACT(m.lcCell,[<v>],[</v>])) = FLOOR(VAL(STREXTRACT(m.lcCell,[<v>],[</v>])))
						llTime = &cCurStyle..lDate and !llDate
						llNumber = !llDate and !llTime
					ENDIF
				ENDIF
*				laFieldGat[m.lnShCol,1] = "MFIELD"+TRANSFORM(m.lnShCol)
				laEmptyCells[m.lnShCol] = !m.llDate AND !m.llTime AND !m.llMemo AND !m.llBool AND !m.llNumber
				DO CASE
				CASE m.llNumber
					laFieldGat[m.lnShCol,2] = "B"
					laFieldGat[m.lnShCol,3] = 8
					laFieldGat[m.lnShCol,4] = 15
				CASE m.llDate
					laFieldGat[m.lnShCol,2] = "D"
					laFieldGat[m.lnShCol,3] = 8
				CASE m.llTime
					laFieldGat[m.lnShCol,2] = "T"
					laFieldGat[m.lnShCol,3] = 8
				CASE m.llBool
					laFieldGat[m.lnShCol,2] = "L"
					laFieldGat[m.lnShCol,3] = 1
				OTHERWISE
					laFieldGat[m.lnShCol,2] = "M"
					laFieldGat[m.lnShCol,3] = 4
				ENDCASE
			ENDIF
			lnField = m.lnField + 1
			lcCell = STREXTRACT(m.lcWholeRow,[<c ],[</c>],m.lnField)
			IF AT([<c ],m.lcCell) > 0
				lcCell = LEFT(m.lcCell , AT([<c ],m.lcCell) - 1)
			ENDIF
			lnShField = m.lnShCol
		ENDDO
		lnField = MAX(m.lnShCol,m.lnFieldF) &&m.lnField - 1
	ENDIF
	IF m.lnField > 254
		MESSAGEBOX(ERRMESS5,16,ERRMESS0)
		RETURN ''
	ELSE
		CREATE CURSOR (m.lcTable) FROM ARRAY laFieldGat
	ENDIF
RETURN m.lcTable

**************
* Read sheet *
**************
FUNCTION get_cells
	LPARAMETERS lcStr,cCurSheet,cCurStr,lnField,laField,lnStartRows,lcFileName,llCursor,llEmptyCells,cCurStyle,laEmptyCells,laDimRef,lcTable
	LOCAL lnField,ldDat01,ldDat02,lcSetDec,lnF,lnPosSiSeek,lcBuff,lnPosSi,lnPosSi2,lcMemo,laFieldGat[1],lni,lcCell,lcVal,lnDat,lnTim,lnCurRow,laFieldPrec[m.lnField,2],loErr as Exception,lcPoint
	LOCAL lcShCol,lnShCol,llDate,llTime,llBool,llMemo,llNumber,lnStyle,lcAlterCol,lnCurCell,lnj,llExtend,cCurSheet1,lcMySql,lcMySql0
	IF m.llCursor
		IF EMPTY(m.lcTable) OR m.lcTable == '?'
			lcTable = SYS(2015)
		ELSE
			lcTable = CHRTRAN(m.lcTable,CHRTRAN(m.lcTable,'_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXUZ',''),'')
			IF ISDIGIT(m.lcTable)
				lcTable = '_' + m.lcTable
			ENDIF
		ENDIF
	ELSE
		IF EMPTY(m.lcTable)
			lcTable = FORCEEXT(m.lcFileName,"DBF")
		ELSE
			IF m.lcTable == '?'
				lcTable = PUTFILE('',FORCEEXT(m.lcFileName,"DBF"),'DBF')
				IF EMPTY(m.lcTable)
					lcTable = FORCEEXT(m.lcFileName,"DBF")
				ELSE
					lcTable = FORCEEXT(m.lcTable,'DBF')
				ENDIF
			ELSE
				lcTable = FORCEEXT(m.lcTable,'DBF')
			ENDIF
		ENDIF
		lcTable = CHRTRAN(m.lcTable,[<>:"/\|?*],'')
	ENDIF
	lcTable = LEFT(m.lcTable,31)
	lnField = ALEN(laField,1)
	ldDat01 = DATE(1900,3,1) - 61
	ldDat02 = DATE(1900,1,1) - 1
	lcPoint = SET("Point")
	lcSetDec = SET("Decimals")
	laFieldPrec = 0
	SET DECIMALS TO 10
	lnF = FOPEN(m.lcStr)
	lnCurRow = 0
	IF m.lnF >= 0
		IF !llEmptyCells && simple :  table without empty celss
			lnPosSiSeek = 0
			DO WHILE !FEOF(m.lnF)
				lcBuff = FREAD(m.lnF,8192)
				lnPosSi = AT('<row r="',m.lcBuff)
				lcMemo = ''
				DO WHILE !FEOF(m.lnF) AND m.lnPosSi = 0
					lcMemo = m.lcMemo + m.lcBuff
					lcBuff = FREAD(m.lnF,8192)
					lnPosSi = AT('<row r="',m.lcMemo)
				ENDDO
				IF m.lnPosSi != 0
					lcMemo = m.lcMemo + LEFT(m.lcBuff,m.lnPosSi - 1)
					lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi + 7
					lnPosSi = FSEEK(m.lnF,m.lnPosSiSeek)
				ELSE
					EXIT
				ENDIF
				
				= FSEEK(m.lnF,m.lnPosSiSeek)
				lcBuff = FREAD(m.lnF,8192)
				lnPosSi2 = AT('</row>',m.lcBuff)
				lcMemo = ''
				DO WHILE !FEOF(m.lnF) AND m.lnPosSi2 = 0
					lcMemo = m.lcMemo + m.lcBuff
					lcBuff = FREAD(m.lnF,8192)
					lnPosSi2 = AT('</row>',m.lcMemo)
				ENDDO
				IF m.lnPosSi2 != 0
					lcMemo = m.lcMemo + LEFT(m.lcBuff,m.lnPosSi2 - 1)
					lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi2 + 5
					lnPosSi = FSEEK(m.lnF,m.lnPosSiSeek)
					lnCurRow = m.lnCurRow + 1
					IF m.lnStartRows > m.lnCurRow
						LOOP
					ENDIF
					SELECT (m.cCurSheet)
					APPEND BLANK
					SCATTER MEMO TO laFieldGat
					FOR lni = 1 TO lnField
						lcCell = STREXTRACT(m.lcMemo,[<c ],[</c>],m.lni)
						lcVal = STREXTRACT(m.lcCell,[<v>],[</v>])
						IF EMPTY(m.lcVal)
							LOOP
						ENDIF
						IF laField[m.lni,2] $ "CVM"
							SELECT (m.cCurStr)
							TRY 
								IF [t="s"] $ m.lcCell
									GO VAL(m.lcVal) + 1 IN (m.cCurStr)
									laFieldGat[m.lni] = cStr
								ELSE
									laFieldGat[m.lni] = lcVal
								ENDIF
							CATCH TO loErr
								laFieldGat[m.lni] = lcVal
							ENDTRY
							laFieldPrec[m.lni,1] = MAX(laFieldPrec[m.lni,1],LEN(laFieldGat[m.lni]))
							laFieldPrec[m.lni,2] = MAX(laFieldPrec[m.lni,2],OCCURS(CHR(13),laFieldGat[m.lni]))
						ELSE
							IF laField[m.lni,2] $ "NFBYI"
								laFieldGat[m.lni] = VAL(m.lcVal)
								laFieldPrec[m.lni,1] = MAX(laFieldPrec[m.lni,1],LEN(ALLTRIM(m.lcVal)))
								IF AT(m.lcPoint,ALLTRIM(m.lcVal)) > 0 
									laFieldPrec[m.lni,2] = MAX(laFieldPrec[m.lni,2],LEN(ALLTRIM(m.lcVal)) - AT(m.lcPoint,ALLTRIM(m.lcVal)))
								ENDIF
							ELSE
								IF laField[m.lni,2] $ "D"
									lnDat = VAL(m.lcVal)
									IF m.lnDat >= 61
										laFieldGat[m.lni] = m.ldDat01 + m.lnDat
									ELSE
										laFieldGat[m.lni] = m.ldDat02 + m.lnDat
									ENDIF
								ELSE
									IF laField[m.lni,2] $ "T"
										lnTim = VAL(m.lcVal)
										lnDat = FLOOR(m.lnTim)
										laFieldGat[m.lni] = DTOT(m.ldDat01 + m.lnDat) + INT(86400.0 * (m.lnTim - m.lnDat))
									ELSE
										IF laField[m.lni,2] $ "L"
											laFieldGat[m.lni] = m.lcVal == "1"
										ENDIF
									ENDIF
								ENDIF
							ENDIF
						ENDIF
					NEXT
					SELECT (m.cCurSheet)
					GATHER FROM laFieldGat MEMO
				ELSE
					lcMemo = m.lcMemo + m.lcBuff
					EXIT
				ENDIF
			ENDDO
		ELSE && complicated :  column check
			lnPosSiSeek = 0
			DO WHILE !FEOF(m.lnF)
				lcBuff = FREAD(m.lnF,8192)
				lnPosSi = AT('<row r="',m.lcBuff)
				lcMemo = ''
				DO WHILE !FEOF(m.lnF) AND m.lnPosSi = 0
					lcMemo = m.lcMemo + m.lcBuff
					lcBuff = FREAD(m.lnF,8192)
					lnPosSi = AT('<row r="',m.lcMemo)
				ENDDO
				IF m.lnPosSi != 0
					lcMemo = m.lcMemo + LEFT(m.lcBuff,m.lnPosSi - 1)
					lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi + 7
					lnPosSi = FSEEK(m.lnF,m.lnPosSiSeek)
				ELSE
					EXIT
				ENDIF
				
				= FSEEK(m.lnF,m.lnPosSiSeek)
				lcBuff = FREAD(m.lnF,8192)
				lnPosSi2 = AT('</row>',m.lcBuff)
				lcMemo = ''
				DO WHILE !FEOF(m.lnF) AND m.lnPosSi2 = 0
					lcMemo = m.lcMemo + m.lcBuff
					lcBuff = FREAD(m.lnF,8192)
					lnPosSi2 = AT('</row>',m.lcMemo)
				ENDDO
				IF m.lnPosSi2 != 0
					lcMemo = m.lcMemo + LEFT(m.lcBuff,m.lnPosSi2 - 1)
					lnPosSiSeek = m.lnPosSiSeek + m.lnPosSi2 + 5
					lnPosSi = FSEEK(m.lnF,m.lnPosSiSeek)
					lnCurRow = m.lnCurRow + 1
					IF m.lnStartRows > m.lnCurRow
						LOOP
					ENDIF
					SELECT (m.cCurSheet)
					APPEND BLANK
					SCATTER MEMO TO laFieldGat
					lnCurCell = 1
					lni = 1
					llExtend = .F.
					DO WHILE m.lni <= m.lnField OR m.llExtend
*					FOR lni=1 TO lnField
						llExtend = .F.
						lcCell = STREXTRACT(m.lcMemo,[<c ],[</c>],m.lnCurCell)
						IF AT([<c ],m.lcCell) > 0
							lcCell = LEFT(m.lcCell , AT([<c ],m.lcCell) - 1)
						ENDIF

						lcShCol = CHRTRAN(STREXTRACT(m.lcCell,'r="','"'),'0123456789','')
						IF LEN(m.lcShCol) = 1
							lnShCol = ASC(m.lcShCol) - 64
						ELSE
							IF LEN(m.lcShCol) = 2
								lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(LEFT(m.lcShCol,1)) - 64)
							ELSE && LEN(m.lcShCol) = 3
								lnShCol = ASC(RIGHT(m.lcShCol,1)) - 64 + 26 * (ASC(SUBSTR(m.lcShCol,1,1)) - 64) + 676 * (ASC(LEFT(m.lcShCol,1)) - 64)
							ENDIF
						ENDIF
						lnShCol = m.lnShCol - laDimRef[1,2] + 1
						
						IF m.lnShCol > m.lnField
							llExtend = .T.
							DIMENSION laField[m.lnShCol,ALEN(laField,2)],laEmptyCells[m.lnShCol],laFieldPrec[m.lnShCol,2],laFieldGat[m.lnShCol]
							lcMySql = ''
							FOR lnj = 1 TO m.lnField
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							
							FOR lnj = m.lnField + 1 TO m.lnShCol
								STORE 0 TO laField[m.lnj,17],laField[m.lnj,18],laField[m.lnj,4]
								STORE .T. TO laField[m.lnj,5],laEmptyCells[m.lnj]
								STORE .F. TO laField[m.lnj,6],laField[m.lnj,5]
								STORE '' TO laField[m.lnj,7],laField[m.lnj,8],laField[m.lnj,9],laField[m.lnj,10],laField[m.lnj,11],laField[m.lnj,12],laField[m.lnj,13],laField[m.lnj,14],laField[m.lnj,15],laField[m.lnj,16]
								laField[m.lnj,2] = "M"
								laField[m.lnj,3] = 4
								laEmptyCells[m.lnj] = .T.
								STORE 0 TO laFieldPrec[m.lnj,1],laFieldPrec[m.lnj,2]
								lcAlterCol = "MFIELD"+TRANSFORM(m.lnj)
								laField[m.lnj,1] = m.lcAlterCol
							NEXT
							lnField = m.lnShCol
							
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO BOTTOM IN (m.cCurSheet)
							
						ENDIF
						IF lni < m.lnShCol
							lni = m.lnShCol
						ENDIF

						lnCurCell = m.lnCurCell + 1

						lcVal = STREXTRACT(m.lcCell,[<v>],[</v>])
						IF EMPTY(m.lcVal)
							lni = m.lni + 1
							LOOP
						ELSE
							STORE .F. TO llBool,llMemo,llNumber,llDate,llTime
							llBool = 't="b"' $ m.lcCell
							llMemo = 't="s"' $ m.lcCell
							llNumber = !llBool AND !llMemo AND not ('s="' $ m.lcCell)
							STORE .F. TO llDate, llTime
							IF !llBool AND !llMemo AND !llNumber
								lnStyle = VAL(STREXTRACT(m.lcCell,[s="],["]))
								IF SEEK(m.lnStyle,m.cCurStyle,"iIndex")
									llDate = &cCurStyle..lDate and VAL(STREXTRACT(m.lcCell,[<v>],[</v>])) = FLOOR(VAL(STREXTRACT(m.lcCell,[<v>],[</v>])))
									llTime = &cCurStyle..lDate and !llDate
									llNumber = !llDate and !llTime
								ENDIF
							ENDIF
						ENDIF

						lcMySql0 = ''
						FOR lnj = 1 TO m.lnField
							lcMySql0 = m.lcMySql0 + laField[m.lnj,1] + ','
						NEXT
						lcMySql0 = RTRIM(m.lcMySql0,1,',')
						lcMySql = ''
						FOR lnj = 1 TO m.lni - 1
							lcMySql = m.lcMySql + laField[m.lnj,1] + ','
						NEXT
						lcAlterCol = laField[m.lni,1]
						IF laField[m.lni,2] == "D" AND m.llTime OR laField[m.lni,2] == "M" AND m.llTime AND m.laEmptyCells[m.lni]
							laField[m.lni,2] = "T"
							laEmptyCells[m.lni] = .F.

							lcMySql = m.lcMySql + "CAST(" + m.laField[m.lni,1] + " AS T) AS " + m.laField[m.lni,1] + ","
							FOR lnj = m.lni + 1 TO ALEN(laField,1)
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql0 + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO BOTTOM IN (m.cCurSheet) 
						ELSE
						IF laField[m.lni,2] == "M" AND m.llDate AND m.laEmptyCells[m.lni]
							laField[m.lni,2] = "D"
							laEmptyCells[m.lni] = .F.

							lcMySql = m.lcMySql + "CAST(" + m.laField[m.lni,1] + " AS D) AS " + m.laField[m.lni,1] + ","
							FOR lnj = m.lni + 1 TO ALEN(laField,1)
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql0 + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO BOTTOM IN (m.cCurSheet) 
						ELSE
						IF laField[m.lni,2] == "M" AND m.llBool AND m.laEmptyCells[m.lni]
							laField[m.lni,2] = "L"
							laEmptyCells[m.lni] = .F.

							lcMySql = m.lcMySql + "CAST(" + m.laField[m.lni,1] + " AS L) AS " + m.laField[m.lni,1] + ","
							FOR lnj = m.lni + 1 TO ALEN(laField,1)
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql0 + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO BOTTOM IN (m.cCurSheet) 
						ELSE
						IF laField[m.lni,2] == "M" AND m.llNumber AND m.laEmptyCells[m.lni]
							laField[m.lni,2] = "B"
							laField[m.lni,3] = 8
							laField[m.lni,4] = 15
							laEmptyCells[m.lni] = .F.

							lcMySql = m.lcMySql + "CAST(" + m.laField[m.lni,1] + " AS B(15)) AS " + m.laField[m.lni,1] + ","
							FOR lnj = m.lni + 1 TO ALEN(laField,1)
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql0 + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO BOTTOM IN (m.cCurSheet) 
						ELSE
						IF laField[m.lni,2] $ "BDT" AND m.llBool OR ;
							laField[m.lni,2] $ "BDTL" AND m.llMemo OR ;
							laField[m.lni,2] $ "DTL" AND m.llNumber OR ;
							laField[m.lni,2] $ "BL" AND m.llDate OR ;
							laField[m.lni,2] $ "BLD" AND m.llTime
							laField[m.lni,2] = "M"
							laField[m.lni,3] = 4
							laField[m.lni,4] = 0

							lcMySql = m.lcMySql + "CAST(" + m.laField[m.lni,1] + " AS M) AS " + m.laField[m.lni,1] + ","
							FOR lnj = m.lni + 1 TO ALEN(laField,1)
								lcMySql = m.lcMySql + laField[m.lnj,1] + ','
							NEXT
							lcMySql = RTRIM(m.lcMySql,1,',')
							cCurSheet1 = SYS(2015)
							CREATE CURSOR (m.cCurSheet1) FROM ARRAY laField
							lcMySql = "INSERT INTO " + m.cCurSheet1 + "(" + m.lcMySql0 + ") SELECT " + m.lcMySql + " FROM " + m.cCurSheet
							&lcMySql
							USE IN (m.cCurSheet)
							cCurSheet = m.cCurSheet1
							GO TOP IN (m.cCurSheet) 
							CALCULATE MAX(LEN(ALLTRIM(&lcAlterCol))) TO m.laFieldPrec[m.lni,1] IN (m.cCurSheet) 
							GO TOP IN (m.cCurSheet) 
							CALCULATE MAX(OCCURS(CHR(13),&lcAlterCol)) TO m.laFieldPrec[m.lni,2] IN (m.cCurSheet) 
							GO BOTTOM IN (m.cCurSheet) 
						ENDIF
						ENDIF
						ENDIF
						ENDIF
						ENDIF
						IF laField[m.lni,2] $ "CVM"
							IF m.llMemo
								SELECT (m.cCurStr)
								TRY 
									IF [t="s"] $ m.lcCell
										GO VAL(m.lcVal) + 1 IN (m.cCurStr)
										laFieldGat[m.lni] = cStr
									ELSE
										laFieldGat[m.lni] = m.lcVal
									ENDIF
								CATCH TO loErr
									laFieldGat[m.lni] = m.lcVal
								ENDTRY
							ELSE
								IF m.llNumber
									laFieldGat[m.lni] = m.lcVal
								ELSE
									IF m.llDate
										lnDat = VAL(m.lcVal)
										IF m.lnDat >= 61
											laFieldGat[m.lni] = TRANSFORM(m.ldDat01 + m.lnDat)
										ELSE
											laFieldGat[m.lni] = TRANSFORM(m.ldDat02 + m.lnDat)
										ENDIF
									ELSE
										IF m.llTime 
											lnTim = VAL(m.lcVal)
											lnDat = FLOOR(m.lnTim)
											laFieldGat[m.lni] = TRANSFORM(DTOT(m.ldDat01 + m.lnDat) + INT(86400.0 * (m.lnTim - m.lnDat)))
										ELSE && m.llBool
											laFieldGat[m.lni] = IIF(m.lcVal == "1",'.T.','.F.')
										ENDIF
									ENDIF
								ENDIF
							ENDIF
							laFieldPrec[m.lni,1] = MAX(laFieldPrec[m.lni,1],LEN(laFieldGat[m.lni]))
							laFieldPrec[m.lni,2] = MAX(laFieldPrec[m.lni,2],OCCURS(CHR(13),laFieldGat[m.lni]))
						ELSE
							IF laField[m.lni,2] $ "NFBYI"
								laFieldGat[m.lni] = VAL(m.lcVal)
								laFieldPrec[m.lni,1] = MAX(laFieldPrec[m.lni,1],LEN(ALLTRIM(m.lcVal)))
								IF AT(m.lcPoint,ALLTRIM(m.lcVal)) > 0 
									laFieldPrec[m.lni,2] = MAX(laFieldPrec[m.lni,2],LEN(ALLTRIM(m.lcVal)) - AT(m.lcPoint,ALLTRIM(m.lcVal)))
								ENDIF
							ELSE
								IF laField[m.lni,2] == "D"
									lnDat = VAL(m.lcVal)
									IF m.lnDat >= 61
										laFieldGat[m.lni] = m.ldDat01 + m.lnDat
									ELSE
										laFieldGat[m.lni] = m.ldDat02 + m.lnDat
									ENDIF
								ELSE
									IF laField[m.lni,2] == "T"
										lnTim = VAL(m.lcVal)
										lnDat = FLOOR(m.lnTim)
										laFieldGat[m.lni] = DTOT(m.ldDat01 + m.lnDat) + INT(86400.0 * (m.lnTim - m.lnDat))
									ELSE
										IF laField[m.lni,2] $ "L"
											laFieldGat[m.lni] = m.lcVal == "1"
										ENDIF
									ENDIF
								ENDIF
							ENDIF
						ENDIF
*					NEXT
						lni = m.lni + 1
					ENDDO
					SELECT (m.cCurSheet)
					GATHER FROM laFieldGat MEMO
				ELSE
					lcMemo = m.lcMemo + m.lcBuff
					EXIT
				ENDIF
			ENDDO
		ENDIF
	ELSE
		MESSAGEBOX(ERRMESS4,16,'Error')
	ENDIF
	FCLOSE(m.lnF)
	SET DECIMALS TO &lcSetDec 
	lcSql = "LPARAMETERS lcTable" + CHR(13) + "INSERT INTO (m.lcTable) SELECT "
	FOR lni = 1 TO lnField
		IF laField[m.lni,2] == "M" AND BETWEEN(laFieldPrec[m.lni,1],1,254) AND laFieldPrec[m.lni,2] = 0
			laField[m.lni,2] = "C"
			laField[m.lni,3] = laFieldPrec[m.lni,1]
			lcSql = m.lcSql + "LEFT(" + laField[m.lni,1] + "," + TRANSFORM(laFieldPrec[m.lni,1]) + ") AS " + laField[m.lni,1] + ","
		ELSE
			lcSql = m.lcSql + laField[m.lni,1] + ","
			IF laField[m.lni,2] == "B" AND BETWEEN(laFieldPrec[m.lni,1],1,20)
				IF laFieldPrec[m.lni,2] = 0 AND BETWEEN(laFieldPrec[m.lni,1],1,9)
					laField[m.lni,2] = "I"
					laField[m.lni,3] = 4
					laField[m.lni,4] = 0
				ELSE
					laField[m.lni,2] = "N"
					laField[m.lni,3] = laFieldPrec[m.lni,1]
					laField[m.lni,4] = laFieldPrec[m.lni,2]
				ENDIF
			ELSE
			ENDIF
		ENDIF
	NEXT
	IF m.llCursor
		*lcTable = SYS(2015) && CHRTRAN(JUSTSTEM(m.lcTable)," ","_")
		CREATE CURSOR (m.lcTable) FROM ARRAY laField 
		lcSql = LEFT(m.lcSql,LEN(m.lcSql) - 1) + " FROM " + m.cCurSheet 
		EXECSCRIPT(m.lcSql,m.lcTable)
	ELSE
		CREATE TABLE (m.lcTable) FREE FROM ARRAY laField
		lcSql = LEFT(m.lcSql,LEN(m.lcSql) - 1) + " FROM " + m.cCurSheet + CHR(13) + "RETURN ALIAS()"
		USE IN (EXECSCRIPT(m.lcSql,m.lcTable))
	ENDIF
	USE IN (m.cCurSheet)
RETURN m.lcTable

**********************
* Special characters *
**********************
FUNCTION htmspec
	LPARAMETERS cStr
	LOCAL lni,lcStrF,lcChar,lnChar
	lcStrF = m.cStr
	IF AT('&gt;',m.lcStrF)>0
		lcStrF = STRTRAN(m.lcStrF,'&gt;','>')
	ENDIF
	IF AT('&lt;',m.lcStrF)>0
		lcStrF = STRTRAN(m.lcStrF,'&lt;','<')
	ENDIF
	IF AT('&quot;',m.lcStrF)>0
		lcStrF = STRTRAN(m.lcStrF,'&quot;','"')
	ENDIF
	IF AT("&apos;",m.lcStrF)>0
		lcStrF = STRTRAN(m.lcStrF,'&apos;',"'")
	ENDIF

	IF AT([&#],m.lcStrF)>0
		FOR lnChar = 0 TO 255
			lcChar = [&#]+STR(m.lnChar,3)+[;]
			IF AT(m.lcChar,m.lcStrF)>0
				lcStrF = STRTRAN(m.lcStrF,m.lcChar,CHR(lnChar))
			ENDIF
		NEXT
	ENDIF
	IF AT([&#x],m.lcStrF)>0
		FOR lnChar = 0 TO 255
			lcChar = [&#x]+RIGHT(TRANSFORM(m.lnChar,"@0"),2)+[;]
			IF AT(m.lcChar,m.lcStrF)>0
				lcStrF = STRTRAN(m.lcStrF,m.lcChar,CHR(lnChar))
			ENDIF
		NEXT
	ENDIF
	IF AT('&amp;',m.lcStrF)>0
		lcStrF = STRTRAN(m.lcStrF,'&amp;',CHR(38))
	ENDIF

    * suggested by Koen Piller
	lcStrF = STRCONV(m.lcStrF,11)
	RETURN m.lcStrF
ENDFUNC

*****************
* Cleanup
******************
FUNCTION cleanup
	LPARAMETERS lcDir,llServer
	LOCAL lcZip,lcSetSaf,loErr as Exception
	lcZip = FORCEEXT(m.lcDir,'zip')
	lcSetSaf = SET("Safety")
	SET SAFETY OFF
	TRY 
		IF m.llServer
			ERASE (ADDBS(ADDBS(m.lcDir)+'worksheets\_rels')+'*.*')
			RD (ADDBS(m.lcDir)+'worksheets\_rels'))
			ERASE (ADDBS(ADDBS(m.lcDir)+'worksheets')+'*.*')
			RD (ADDBS(m.lcDir)+'worksheets'))
		ENDIF
		ERASE (ADDBS(m.lcDir)+'*.*')
		RD (m.lcDir)
	CATCH TO loErr
		THROW m.loErr
	ENDTRY

	ERASE (m.lcZip)
	SET SAFETY &lcSetSaf
RETURN .T.

*****************
* Read workbook *
*****************
FUNCTION get_sheet
LPARAMETERS lcStr,lcSheet
	LOCAL lnF,lcRealSheet,lcBuff,lcMemo,lni,lcRealSheet,lcCurSheet
	lnF = FOPEN(m.lcStr)
	lcRealSheet = ''
	IF m.lnF >= 0
		lcBuff = FREAD(m.lnf,8192)
		lcMemo = STREXTRACT(m.lcBuff,[<sheets>],[</sheets>])
		IF VARTYPE(m.lcSheet) == "N"
			IF BETWEEN(m.lcSheet,1,OCCURS([name="],m.lcMemo))
				lcRealSheet = 'sheet' + LTRIM(STR(m.lcSheet))
			ENDIF
		ELSE
			IF EMPTY(m.lcSheet)
				lcRealSheet = 'sheet1'
			ELSE
				FOR lni = 1 TO OCCURS([name="],m.lcMemo)
					lcCurSheet = STREXTRACT(m.lcMemo,[name="],["],m.lni)
					IF LOWER(ALLTRIM(m.lcCurSheet)) == LOWER(ALLTRIM(m.lcSheet))
						lcRealSheet = 'sheet' + TRANSFORM(m.lni)
						EXIT
					ENDIF
				NEXT
			ENDIF
		ENDIF
	ELSE
		MESSAGEBOX(ERRMESS4 + ' workbook.xml',16,'Error')
	ENDIF
	FCLOSE(m.lnF)
RETURN m.lcRealSheet
