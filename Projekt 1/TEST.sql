[dbo].[Erstellung_Statistik_Aktuel_24.12.2019]

SELECT *
  FROM [TestDBWaehrungen].[dbo].[Statistik]

--hier mit Transaction eine Tabelle löschen:
begin transaction Test

truncate table [dbo].[Statistik]-- opretaion
select * from [dbo].[Statistik]  -- Ergebnis anschauen
---------------------------------
commit tran Test -- zufrieden (nur das ausführen)

rollback tran Test -- nicht zufrieden  (nur das ausführen)

--test

--Zeige mir genau diese Zeile mit Time=:
SELECT *
FROM [TestDBWaehrungen].[dbo].[AUDCAD_Hours_1]
Where [Time] = '19980709 00:00:00' 

