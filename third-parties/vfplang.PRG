* SOURCE: https://blogs.msdn.microsoft.com/calvin_hsia/2005/08/19/foxpro-language-into-a-table/
* 
* CHANGES:
*	- Try with ole automation.
*   - Generated files destination changed.

CREATE CURSOR lang (word c(30), stuff c(20))

FOR nType=1 to 4

      n=ALANGUAGE(aa,nType)

      FOR i = 1  to n

            INSERT INTO lang VALUES (aa[i],"")

            IF nType= 3 AND aa[i] != "Ole" && baseclasses, but not olecontrol, oleboundcontrol

                  obj=CREATEOBJECT(aa[i])

                  nProps=AMEMBERS(arrMem,obj,1)

                  FOR j = 1 TO nProps

                        INSERT INTO lang VALUES (aa[i]+":"+arrMem[j,1],arrMem[j,2])

                  ENDFOR

            ENDIF

      ENDFOR

ENDFOR

GO TOP

 

BROWSE LAST NOWAIT

LIST off to vfplang.txt

CURSORTOXML(0,FullPath("") + "vfplang.xml",1,512)

 

LOCAL oIe as internetexplorer.application

Try
	oIe=NEWOBJECT("internetexplorer.application")

	oIe.Visible=1

	oie.Navigate(FullPath("") + "vfplang.xml")
Catch
	*--
EndTry


MODIFY COMMAND vfplang.txt nowait
