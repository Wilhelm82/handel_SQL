
USE [TestDBWaehrungen]
GO
/****** Object:  StoredProcedure [dbo].[Erstellung_Statistik_Aktuel_l07.12.2019]    Script Date: 07.12.2019 14:21:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		WP
-- Create date: 
-- Description:	Erstellung Statistik
-- =============================================
ALTER PROCEDURE [dbo].[Erstellung_Statistik_Aktuel_24.12.2019] 

AS
BEGIN --Prozedur
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Waehrung varchar(10),@CandleType varchar(20),@CandleTypeID int, @sql nvarchar(1000), @dates datetime, @datesAlt datetime= null, @diffTage int, @weekDay int,
	@day int, @dayAlt int, @month int, @year int, @hour int, @minute int, @millisecond int, @StartLastWeek date, @EndLastWeek date, @StartCurWeek date, @EndCurWeek date, @Anzahl int, @WeekDayName varchar(50),
	@paramDef nvarchar(200), @Sollwert int, @Istwert int, @Abweichung int, @Show bit, @diffhour1 int, @diffminute int, @Gesamt int, @i int, @Kommentar nvarchar(4000), @WerteAusgrenzen bit, @WaehrungsID int

	Declare cur_waehrungenTables Cursor FOR
	
	select Waehrung,CandleType,CandleTypeID,WaehrungsID
	from [TESTdbVerwaltung].[dbo].tblWaehrungen 
	cross join [TESTdbVerwaltung].[dbo].CandleType
	where AktiveInMarket=1 
	--AND WaehrungsID=1 and CandleTypeID IN (1,2,3)
	AND WaehrungsID=2 and CandleTypeID =1
	order by Waehrung 

	OPEN cur_waehrungenTables

	Fetch NEXT FROM cur_waehrungenTables
	INTO @Waehrung,@CandleType,@CandleTypeID,@WaehrungsID

	--SET @paramDef=N'@day int OUTPUT, @month int OUTPUT, @year int OUTPUT'

	WHILE @@FETCH_STATUS=0
		BEGIN--Währungen
					
			/*============================================Check CandeleType=============================================*/
			IF (@CandleTypeID=1)
			BEGIN---- START ######### CandleTypeID 1 ----->Dayly
				
				/*CHECKEN DER DATENANKUFT VOM DATUM HER*/
				--SET @sql=N'SELECT @day=DATEPART(DAY,max([Time])), @month=DATEPART(MONTH,max([Time])), @year=DATEPART(YEAR,max([Time])) FROM '+@Waehrung+'_'+@CandleType
				--execute sp_executesql @sql ,@paramDef,@day=@day OUTPUT,@month=@month OUTPUT,@year=@year OUTPUT	
				
				--hier Funktion baue
				IF @WaehrungsID = 2
					SET @WerteAusgrenzen = 1
				Else
					SET @WerteAusgrenzen = 0
						
				--SET @sql=N'truncate table datesCheck insert into datesCheck select Datum from (select distinct(FORMAT([Time],''yyyy.MM.dd'')) Datum from '+@Waehrung+'_'+@CandleType+ ') as t order by Datum'
				SET @sql=N'truncate table datesCheck insert into datesCheck select Datum from (select distinct([Time]) Datum from '+@Waehrung+'_'+@CandleType+ ') as t order by Datum'
				execute sp_executesql @sql 

				Declare cur_datesCheck Cursor FOR
				select dates from datesCheck order by dates

				OPEN cur_datesCheck

				Fetch NEXT FROM cur_datesCheck
				INTO @dates

				WHILE @@FETCH_STATUS=0
				BEGIN--datesCheck
					
					IF @datesAlt is null --ERSTER WERT ####################################
					BEGIN-->erster Wert
						SET @datesAlt   = @dates
						SET @diffTage   = DATEDIFF(day,@datesAlt,@dates)
						--@weekDay ist eine Zahl 1 bis 7
						SET @weekDay = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 1
						SET @Istwert     = @diffTage				
						SET @Abweichung  = 	@Istwert -  @Sollwert
						SET @Show        = 0
						-- Istwert 3 und Sonntag und Abweichung 1 und Sonntag sollen nicht mit angedruckt werden. 
						IF (@Istwert = 3) OR (@Abweichung = 1) And (@WeekDay = 7)
							SET @Show = 1

						
						IF (@WerteAusgrenzen = 0)   --=========nimm Zwei Parameter ansonsten drei
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 1)
							Begin
								SET @Kommentar = 'Die Tagesdifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
											
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 1) --AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Tagesdifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
											
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))
										
							END
						END
					END	else -->erster Wert
					BEGIN--NÄCHSTER WERT ###################################################
						SET @diffTage = DATEDIFF(day,@datesAlt,@dates)
						--set datefirst 1;
						SET @weekDay = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 1
						SET @Istwert     = @diffTage
						SET @Abweichung  = @Istwert - @Sollwert 
						SET @Show        = 0
						IF (@Istwert = 3) OR (@Abweichung = 1) And (@WeekDay = 7)
							SET @Show = 1

						IF (@WerteAusgrenzen = 0)
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 1)
							Begin
								SET @Kommentar = 'Die Tagesdifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
											
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 1) --AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Tagesdifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
											
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))
										
							END
						END
						
						SET	@datesAlt=@dates
				
					END--> nächster Wert
					Fetch NEXT FROM cur_datesCheck
					INTO @dates
				END--datesCheck
			
			END---- ENDE ######### CandleTypeID 1 ----->Dayly
			
			/*============================================Check CandeleType=============================================*/
			Else IF (@CandleTypeID = 2)
			BEGIN---- START ######### CandleTypeID 2 -----> Hours_1
				
				SET @sql=N'truncate table datesCheck insert into datesCheck select Datum from (select distinct([Time]) Datum from '+@Waehrung+'_'+@CandleType+ ') as t order by Datum'
				execute sp_executesql @sql 

				Declare cur_datesCheck Cursor FOR
				select dates from datesCheck order by dates
	
				OPEN cur_datesCheck

				Fetch NEXT FROM cur_datesCheck
				INTO @dates

				WHILE @@FETCH_STATUS=0
				BEGIN--datesCheck
					
					IF @datesAlt is null --ERSTER WERT ################################
					BEGIN-->erster Wert
						SET @datesAlt  = @dates
						SET @diffTage  = DATEDIFF(day,@datesAlt,@dates)
						SET @diffhour1 = DATEDIFF(hour,@datesAlt,@dates)
						--@weekDay ist eine Zahl 1 bis 7
						SET @weekDay = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 24
						SET @Istwert     = @diffhour1			
						SET @Abweichung  = @Istwert - @Sollwert
						SET @Show        = 0
						IF (@Istwert = 72) OR (@Abweichung IN (25,26,27)) And (@WeekDay = 7)
							SET @Show = 1

						IF (@WerteAusgrenzen = 0)   --=========nimm Zwei Parameter ansonsten drei
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 24)
							Begin
								SET @Kommentar = 'Die Stundendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
							/*--------------schreibe in die Tabelle:-----------------*/				
							Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
							VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
				 
							--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' diffhour1:'+cast(@diffhour1 as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 24) AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Stundendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
							/*--------------schreibe in die Tabelle:-----------------*/				
							Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
							VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung, @Kommentar)
				 
							--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' diffhour1:'+cast(@diffhour1 as varchar(50))
										
							END
						END
					END	else -->erster Wert
					BEGIN --NÄCHSTER WERT ############################################
						SET @diffTage  = DATEDIFF(day,@datesAlt,@dates)
						SET @diffhour1 = DATEDIFF(hour,@datesAlt,@dates)
						--set datefirst 1;
						SET @weekDay = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 24
						SET @Istwert     = @diffhour1
						SET @Abweichung  = @Istwert - @Sollwert 
						SET @Show        = 0
						IF (@Istwert = 72) OR (@Abweichung IN (25,26,27)) And (@WeekDay = 7)
							SET @Show = 1

						IF (@WerteAusgrenzen = 0)
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 24)
							Begin
								SET @Kommentar = 'Die Stundendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert    ,@Istwert     ,@Abweichung  ,@Kommentar)
								--+' Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+'    Start Cur. Week:'+cast(@StartCurWeek as varchar(50))+'    End Cur. Week:'+cast(@EndCurWeek as varchar(50))
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' diffhour1:'+cast(@diffhour1 as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 24) AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Stundendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
							/*--------------schreibe in die Tabelle:-----------------*/				
							Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
							VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert    ,@Istwert     ,@Abweichung  ,@Kommentar)
							--+' Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+'    Start Cur. Week:'+cast(@StartCurWeek as varchar(50))+'    End Cur. Week:'+cast(@EndCurWeek as varchar(50))
							--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' diffhour1:'+cast(@diffhour1 as varchar(50))
										
							END
						END
						SET	@datesAlt=@dates
				
					END-->nächster Wert

					Fetch NEXT FROM cur_datesCheck
					INTO @dates
				END--datesCheck
			END-- Ende ######### CandleTypeID 2----->Hours_1
			
			/*============================================Check CandeleType=============================================*/	
			ELSE IF (@CandleTypeID = 3)
			BEGIN---- START ######### CandleTypeID 3 -----> Hours_4
				
				SET @sql=N'truncate table datesCheck insert into datesCheck select Datum from (select distinct([Time]) Datum from '+@Waehrung+'_'+@CandleType+ ') as t order by Datum'
				execute sp_executesql @sql 

				Declare cur_datesCheck Cursor FOR
				select dates from datesCheck order by dates

				OPEN cur_datesCheck

				Fetch NEXT FROM cur_datesCheck
				INTO @dates

				WHILE @@FETCH_STATUS=0
				BEGIN--datesCheck
					
					IF @datesAlt is null --ERSTER WERT ###################################
					BEGIN-->erster Wert
						--SET @i          = 1
						SET @datesAlt   = @dates
						SET @diffTage   = DATEDIFF(day,@datesAlt,@dates)
						SET @diffhour1  = DATEDIFF(hour,@datesAlt,@dates)
						SET @diffminute = DATEDIFF(mi,@datesAlt,@dates)
						--@weekDay ist eine Zahl 1 bis 7
						SET @weekDay    = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						--SET @dayAlt      = @day
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 1440
						SET @Istwert     = @diffminute
						/*
						IF @dayAlt = @day
						BEGIN
							SET @i = @i + 1
							SET @Gesamt = @i
						END
						*/				
						SET @Abweichung = 	@Istwert -  @Sollwert
						SET @Show = 0
						IF (@Istwert = 4320) OR (@Istwert = 2880) And (@WeekDay = 7)
							SET @Show = 1

						IF (@WerteAusgrenzen = 0)   --=========nimm Zwei Parameter ansonsten drei
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 1440)
							Begin
								SET @Kommentar = 'Die Minutendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/					
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung,  @Kommentar)
				 
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' @diffminute:'+cast(@diffminute as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 1440) AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Minutendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/					
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert     ,@Istwert    ,@Abweichung,  @Kommentar)
				 
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' @diffminute:'+cast(@diffminute as varchar(50))
										
							END
						END

					END	else -->erster Wert
					BEGIN --NÄCHSTER WERT ##############################################
						SET @diffTage    = DATEDIFF(day,@datesAlt,@dates)
						SET @diffhour1   = DATEDIFF(hour,@datesAlt,@dates)
						SET @diffminute  = DATEDIFF(mi,@datesAlt,@dates)
						--set datefirst 1;
						SET @weekDay     = DATEPART(weekday,@dates)
						EXEC SET_weekDayName @weekDay, @WeekDayName output
						SET @day         = DATEPART(day,@dates)
						SET @month       = DATEPART(month,@dates)
						SET @year        = DATEPART(year,@dates)
						SET @hour        = DATEPART(hh, @dates)
						SET @minute      = DATEPART(mi,@dates)
						SET @millisecond = DATEPART(ms,@dates)
						SET @Sollwert    = 1440
						/*
						IF @dayAlt = @day
						BEGIN
							SET @i = @i + 1
							SET @Gesamt = @i
						END Else
						Begin
							SET @i = 1
							SET @Gesamt = 1
						END
						*/
						SET @Istwert = @diffminute
						SET @Abweichung = 	@Istwert -  @Sollwert 
						SET @Show = 0
						IF (@Istwert = 4320) OR (@Istwert = 2880) And (@WeekDay = 7)
							SET @Show = 1

						/*IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
						--IF (@Abweichung != 0)
						Begin
							SET @Kommentar = 'Die Minutendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
							/*--------------schreibe in die Tabelle:-----------------*/				
							Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
							VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert    ,@Istwert     ,@Abweichung,  @Kommentar)
							--+' Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+'    Start Cur. Week:'+cast(@StartCurWeek as varchar(50))+'    End Cur. Week:'+cast(@EndCurWeek as varchar(50))
							--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' @diffminute:'+cast(@diffminute as varchar(50))+'Gesamt = '+cast(@Gesamt as varchar(50))
						END*/
						IF (@WerteAusgrenzen = 0)
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) 
							--IF (@Sollwert = 24)
							Begin
								SET @Kommentar = 'Die Minutendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert    ,@Istwert     ,@Abweichung,  @Kommentar)
								--+' Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+'    Start Cur. Week:'+cast(@StartCurWeek as varchar(50))+'    End Cur. Week:'+cast(@EndCurWeek as varchar(50))
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' @diffminute:'+cast(@diffminute as varchar(50))+'Gesamt = '+cast(@Gesamt as varchar(50))
										
							END
						END ELSE
						BEGIN
							IF (@Abweichung > 0) AND (@Show = 0) AND (@dates >= '2007-05-01 00:00:00.000')
							--IF (@Sollwert = 24) AND (@dates >= '2007-05-01 00:00:00.000')
							Begin
								SET @Kommentar = 'Die Minutendifferenz zum vorherigem Datensatz soll '+cast(@Sollwert as varchar(50)) +' ist aber '+cast(@Istwert as varchar(50))
								/*--------------schreibe in die Tabelle:-----------------*/				
								Insert Into Statistik ([Waehrung], [CandleTypeID], [Wochentag], [Day], [Month], [Year], [hour], [minute], [second],    [Soll_Kerzen], [Ist_Kerzen], [Abweichung], [Kommentar])
								VALUES	              (@Waehrung,  @CandleType,    @WeekDayName, @day, @month,  @year,  @hour,  @minute , @millisecond  ,@Sollwert    ,@Istwert     ,@Abweichung,  @Kommentar)
								--+' Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+'    Start Cur. Week:'+cast(@StartCurWeek as varchar(50))+'    End Cur. Week:'+cast(@EndCurWeek as varchar(50))
								--PRINT 'Waehrung: '+@Waehrung+'_'+@CandleType+ '   DiffTage:'+cast(@diffTage as varchar(50)) +'   WeekDay:'+cast(@weekDay as varchar(50))+' '+cast(@WeekDayName as varchar(50))+'  Day:'+cast(@day as varchar(50))+' Month:'+cast(@month as varchar(50))+' Year:'+cast(@year as varchar(50))+' @diffminute:'+cast(@diffminute as varchar(50))+'Gesamt = '+cast(@Gesamt as varchar(50))
										
							END
						END

						SET	@datesAlt=@dates
						--SET @dayAlt  = @day
				
					END-->nächster Wert

					Fetch NEXT FROM cur_datesCheck
					INTO @dates
				END--datesCheck
			END-- Ende ######### CandleTypeID 3-----> Hours_4
			
			/*============================================Check CandeleType=============================================*/
			/*
			IF (@CandleTypeID = 4)
			BEGIN
				
				/*#####Testen#############################------------------------------
							SET @day     =DATEPART(day,@dates)
							SET @month   =DATEPART(month,@dates)
							SET @year    =DATEPART(year,@dates)
							-- start of last week (begin: monday)
							SET @StartLastWeek =CAST(DATEADD(WEEK, -1 ,DATEADD(DAY, -DATEPART(WEEKDAY, @dates) + 1, @dates)) AS DATE)
							-- end of last week (begin: monday)
							SET @EndLastWeek   =CAST(DATEADD(WEEK, -1, DATEADD(DAY, -DATEPART(WEEKDAY, @dates) + 7, @dates)) AS DATE)
							-- start of current week (begin: monday)
							SET @StartCurWeek  =CAST(DATEADD(DAY, -DATEPART(WEEKDAY, @dates) + 1, @dates) AS DATE)
							-- end of current week (begins monday)
							SET @EndCurWeek    =CAST(DATEADD(DAY, -DATEPART(WEEKDAY, @dates) + 7, @dates) AS DATE)
				-----------------------------------*/						
			END

			
			*/
			
			CLOSE cur_datesCheck;  
			DEALLOCATE cur_datesCheck;


			Fetch NEXT FROM cur_waehrungenTables
			INTO @Waehrung,@CandleType,@CandleTypeID,@WaehrungsID
		END--Währungen

CLOSE cur_waehrungenTables;  
DEALLOCATE cur_waehrungenTables;  
END--Prozedur
