/*###########################Tabelle löschen*/


--hier mit Transaction eine Tabelle löschen:
begin transaction Test

truncate table [dbo].[Statistik]-- opretaion
select * from [dbo].[Statistik]  -- Ergebnis anschauen
---------------------------------
commit tran Test -- zufrieden (nur das ausführen)

--rollback tran Test -- nicht zufrieden  (nur das ausführen)


/*###########################führe Prozedur aus*/
DECLARE @RC int
-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[Erstellung_Statistik_Aktuel_24.12.2019] 
GO

/*###########################öffne Statistik*/
SELECT *
  FROM [TestDBWaehrungen].[dbo].[Statistik]