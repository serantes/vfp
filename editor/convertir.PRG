tamano = 200 &&Set('Memowidth') - 20

temp = _cliptext
out = ''
Do while not Empty(temp)
out = out + "lcHTML = lcHMTL + '" + Left(temp, tamano) + "'" + Chr(13) + Chr(10)
temp = Substr(temp, tamano + 1)
EndDo

*_cliptext = out
