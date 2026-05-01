USE [xxxx]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<xxxx>
-- Create date: <xxxx>
-- Description:	xxxxx
-- =============================================

ALTER PROCEDURE [XMLProcessing400] 	@ObjParent int, @TypeObjParent int, @stXML text, @IDoc int
AS
begin
set dateformat dmy

	DECLARE @AOLevel INT , @Guid_parent VARCHAR(255), @mode INT ,  @street VARCHAR(255),  @type VARCHAR(255), @mo INT, @id_terr INT, @DateTerr DATETIME, @city VARCHAR(50)
	
	select @AOLevel = cast(fnGetSubStringValueExtention(@StXML,'AOLevel','=','|','<') as int)
	select @Guid_parent = cast(fnGetSubStringValueExtention(@StXML,'Guid','=','|','<') as varchar(255))
	select @mode = cast(fnGetSubStringValueExtention(@StXML,'mode','=','|','<') as int)
	select @street = cast(fnGetSubStringValueExtention(@StXML,'street','=','|','<') as varchar(255))
	select @type = cast(fnGetSubStringValueExtention(@StXML,'TypeStreet','=','|','<') as varchar(255))
	select @mo = cast(fnGetSubStringValueExtention(@StXML,'mo','=','|','<') as int)
	select @id_terr = cast(fnGetSubStringValueExtention(@StXML,'idTypeTerr','=','|','<') as int)
	select @city = cast(fnGetSubStringValueExtention(@StXML,'city','=','|','<') as varchar(50))

	SELECT @AOLevel = CASE WHEN @AOLevel = 7 THEN 8 WHEN @AOLevel = 65 THEN 7 ELSE @AOLevel END
	
	IF @mode IN (1,2) --1-добавить, 2-редактировать
	BEGIN
		select @DateTerr = cast(fnGetSubStringValueExtention(@StXML,'DateTerr','=','|','<') as datetime)
			
		IF @AOLevel=0
			SELECT @AOLevel=oc.AOLEVEL 
			FROM objCity AS oc
			WHERE oc.FIASGuid=@Guid_parent AND oc.upd_lock=0
			
		IF @mo = -1 
			SELECT @mo=NULL
						
		IF @type = -1
			SELECT @type=NULL
				
		CREATE TABLE #adr (AOLevel INT, [guid] VARCHAR(50), [Name] VARCHAR(250),[Type] VARCHAR(10), idName INT, idType INT)
		
		INSERT INTO #adr(AOLevel)
		SELECT 2 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
		
		IF @AOLevel <> 8
			UPDATE #adr
			SET 
				[guid] = 'Отсутствует в ФИАС', [NAME] = @street, [TYPE] = (SELECT CONVERT(VARCHAR(10),dt.val_params) FROM Dictionary_table AS dt WHERE dt.IDAttr=1290 AND dt.IDRows=@Type)	
			WHERE AOLevel=8
			
		declare @lev int
		declare cur4 CURSOR LOCAL FOR
		SELECT AOLevel FROM #adr WHERE AOLevel <= @AOLevel ORDER BY AOLevel DESC
			
		open cur4
		fetch next from cur4 into @lev
		
		while @@FETCH_STATUS = 0 BEGIN
			
			UPDATE #adr 
			SET [guid] = ao.OBJECTGUID, [Name] = ao.NAME, [Type] = ao.TYPENAME
			FROM ADDR_OBJ AS ao
			INNER JOIN ADM_HIERARCHY AS ah ON ah.OBJECTID=ao.OBJECTID AND ah.ISACTIVE = 1
			INNER JOINADDR_OBJ AS ao2 ON ao2.OBJECTID=ah.PARENTOBJID AND ao2.ISACTUAL=1 AND ao2.ISACTIVE=1
			INNER JOIN #adr a ON a.AOLevel =ao.[level]
			WHERE ao.ISACTUAL=1 AND ao.ISACTIVE=1 AND ao.[level] =@lev AND ao.OBJECTGUID = @Guid_parent

			SELECT @Guid_parent = ISNULL(ao2.OBJECTGUID,@Guid_parent)
			FROM ADDR_OBJ AS ao
			INNER JOIN ADM_HIERARCHY AS ah ON ah.OBJECTID=ao.OBJECTID AND ah.ISACTIVE = 1
			INNER JOIN ADDR_OBJ AS ao2 ON ao2.OBJECTID=ah.PARENTOBJID AND ao2.ISACTUAL=1 AND ao2.ISACTIVE=1
			INNER JOIN #adr a ON a.AOLevel =ao.[level]
			WHERE ao.ISACTUAL=1 AND ao.ISACTIVE=1 AND ao.[level] =@lev AND ao.OBJECTGUID = @Guid_parent
		
		fetch next from cur4 into @lev
		END
		close cur4
		deallocate cur4			
		
			----------------------------------
			--проверка данных в справочниках--
			----------------------------------
		
			DECLARE @IDRows INT, @IDAttr INT
	
			--тип улицы
			SET @IDAttr = 1290
			SELECT @IDRows = MAX(dt.IDRows) FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr
	
			INSERT INTO Dictionary_table (IDAttr,IDRows,val_params,upd_date)
			SELECT DISTINCT @IDAttr, @IDRows+1, [Type], GETDATE()	
			FROM #adr ao
			WHERE AOLEVEL = 8 AND ao.[Type] IS NOT NULL
			AND NOT EXISTS (SELECT * FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr AND dt.val_params=ao.[Type])
			
			--тип планировочной структуры
			SET @IDAttr = 1282
			SELECT @IDRows = MAX(dt.IDRows) FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr

			INSERT INTO Dictionary_table (IDAttr,IDRows,val_params,upd_date)
			SELECT DISTINCT @IDAttr, @IDRows+1, [Type], GETDATE()	
			FROM #adr ao
			WHERE AOLEVEL = 7 AND ao.[Type] IS NOT NULL
			AND NOT EXISTS (SELECT * FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr AND dt.val_params=ao.[Type])

			--планировочная структура
			SET @IDAttr = 1281
			SELECT @IDRows = MAX(dt.IDRows) FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr	

			INSERT INTO Dictionary_table (IDAttr,IDRows,val_params,upd_date)
			SELECT DISTINCT @IDAttr, @IDRows+1, [Name], GETDATE()	
			FROM #adr ao
			WHERE AOLEVEL = 7 AND ao.[Name] IS NOT NULL
			AND NOT EXISTS (SELECT * FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr AND dt.val_params=ao.[Name])

			--тип населенного пункта
			SET @IDAttr = 47
			SELECT @IDRows = MAX(dt.IDRows) FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr
			
			INSERT INTO Dictionary_table (IDAttr,IDRows,val_params,upd_date)
			SELECT DISTINCT @IDAttr, @IDRows+1, [Type], GETDATE()	
			FROM #adr ao
			WHERE AOLEVEL = 6 AND ao.[Type] IS NOT NULL
			AND NOT EXISTS (SELECT * FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr AND dt.val_params=ao.[Type])			
	
			--населенный пункт
			SET @IDAttr = 1280
			SELECT @IDRows = MAX(dt.IDRows) FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr		

			INSERT INTO Dictionary_table (IDAttr,IDRows,val_params,upd_date)
			SELECT DISTINCT @IDAttr, @IDRows+1, [Name], GETDATE()	
			FROM #adr ao
			WHERE AOLEVEL = 6 AND ao.[Name] IS NOT NULL
			AND NOT EXISTS (SELECT * FROM Dictionary_table AS dt WHERE dt.IDAttr=@IDAttr AND dt.val_params=ao.[Name])		
		
			--город - район
			UPDATE ao SET ao.idName=oc.ID 
			FROM #adr ao
			INNER JOIN objCity AS oc ON oc.FIASGuid=ao.guid AND oc.upd_lock=0
			WHERE ao.AOLevel IN (2,5) AND ao.guid IS NOT NULL	
			
			--01/04/2022 Добавляем г.Заводоуковск
			UPDATE ao SET ao.idName=602
			FROM #adr ao
			WHERE ao.AOLevel IN (5) AND ao.guid = '10c58caf-f8b8-44b6-99b9-5cf25f681fcf'
			
			--населенный пункт
			UPDATE ao SET ao.idName=dt2.IDRows, ao.idType=dt1.IDRows 
			FROM #adr ao
			LEFT JOIN Dictionary_table AS dt1 ON dt1.IDAttr=47 AND CONVERT(VARCHAR(100), dt1.val_params) = ao.[Type]
			LEFT JOIN Dictionary_table AS dt2 ON dt2.IDAttr=1280 AND CONVERT(VARCHAR(100), dt2.val_params) = ao.[Name]
			WHERE ao.AOLevel IN (6) AND ao.guid IS NOT NULL	
			
			--Планировочная структура
			UPDATE ao SET ao.idName=dt2.IDRows, ao.idType=dt1.IDRows 
			FROM #adr ao
			LEFT JOIN Dictionary_table AS dt1 ON dt1.IDAttr=1282 AND CONVERT(VARCHAR(100), dt1.val_params) = ao.[Type]
			LEFT JOIN Dictionary_table AS dt2 ON dt2.IDAttr=1281 AND CONVERT(VARCHAR(100), dt2.val_params) = ao.[Name]
			WHERE ao.AOLevel IN (7) AND ao.guid IS NOT NULL	
			
			--Тип улицы
			UPDATE ao SET ao.idType=dt1.IDRows 
			FROM #adr ao
			LEFT JOIN Dictionary_table AS dt1 ON dt1.IDAttr=1290 AND CONVERT(VARCHAR(100), dt1.val_params) = ao.[Type]
			WHERE ao.AOLevel IN (8) AND ao.guid IS NOT NULL AND ao.[Type] IS NOT NULL
			
			
			--получим адрес из таблицы для возврата в программу
			DECLARE @stAddress VARCHAR(500)=''
		
			declare cur5 CURSOR LOCAL FOR
			SELECT AOLevel FROM #adr ORDER BY AOLevel DESC
			
			open cur5
			fetch next from cur5 into @lev
		
			while @@FETCH_STATUS = 0 BEGIN
				SELECT @stAddress = @stAddress + ISNULL([NAME]+' '+[TYPE]+', ','') 
				FROM #adr AS a
				WHERE a.AOLevel=@lev
		
		
			fetch next from cur5 into @lev
			END
			close cur5
			deallocate cur5	

			--01/04/2022 Подменяем г.Заводоуковск на населенный пункт
			IF EXISTS (SELECT * FROM #adr AS a WHERE AOLevel=5 AND idName = 602)
			BEGIN
				UPDATE #adr SET AOLevel = 6, idType = 0
				WHERE AOLevel=5 AND idName = 602
					
				UPDATE #adr SET
						        guid = 'd966f796-6fcb-4dfe-96f0-7e95fb098d25',
						        Name = 'Заводоуковский',
						        [Type] = 'р-н',
						        idName = 9,
						        idType = 6 
				WHERE AOLevel=2
			END 			
						
			--SELECT * FROM #adr
			IF @mode = 2 AND @ObjParent > 0
				BEGIN
					INSERT INTO objStreet_Shadow
					SELECT * 
					FROM objStreet AS os
					WHERE id = @ObjParent	
							
					UPDATE asup.dbo.objStreet
					SET  stName = (SELECT TOP 1 [Name] FROM #adr a WHERE a.AOLevel=8),
						 TypeStreet = (SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=8),
						 FIASGuid = (SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=8),
						 NasPunkt = (SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=6),
						 TypePlace = (SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=6),
						 PlaceFIASGuid = (SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=6),
						 PlanStruct = (SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=7),
						 TypePlanStruct = (SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=7),
						 FIASPlanStruct = (SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=7), 
						 City = @mo ,
						 [Date] = GETDATE(),
						 UserName = SUSER_NAME()
					WHERE id = @ObjParent	
					
					DECLARE @id_terr3 INT, @dateterr3 DATETIME
					
					SELECT TOP 1 @id_terr3 = CONVERT(INT,ISNULL([value],0)) , @dateterr3 = fnDayToDate(ISNULL(osp.e_period,0))
					FROM objStreet_Period AS osp 
					WHERE osp.Attr=1291 AND osp.upd_lock=0 AND fnDateToDay(GETDATE()) BETWEEN osp.b_period AND osp.e_period
					AND osp.Obj=@ObjParent
					
					INSERT INTO objStreet_Period_shadow
					SELECT *
					FROM objStreet_Period AS osp 
					WHERE osp.Attr=1291 AND osp.upd_lock=0 AND fnDateToDay(GETDATE()) BETWEEN osp.b_period AND osp.e_period
					AND osp.Obj=@ObjParent
					
					IF  @id_terr = 0
						BEGIN
							UPDATE osp
							SET 
								osp.e_period = fnDateToDay(@DateTerr)-1,
								osp.UserName = SUSER_NAME(),
								osp.[Date] = GETDATE()
							FROM objStreet_Period AS osp 
							WHERE osp.Attr=1291 AND osp.upd_lock=0 AND fnDateToDay(GETDATE()) BETWEEN osp.b_period AND osp.e_period
							AND osp.Obj=@ObjParent		
						END
					ELSE IF @id_terr = 1  AND @id_terr <> ISNULL(@id_terr3,0)--дата начала
						BEGIN
							UPDATE osp
							SET 
								osp.e_period = fnDateToDay(@DateTerr)-1,
								osp.UserName = SUSER_NAME(),
								osp.[Date] = GETDATE()
							FROM objStreet_Period AS osp 
							WHERE osp.Attr=1291 AND osp.upd_lock=0 AND dbo.fnDateToDay(GETDATE()) BETWEEN osp.b_period AND osp.e_period
							AND osp.Obj=@ObjParent	
							
							INSERT INTO objStreet_Period(Obj,Attr,b_period,e_period,UserName,[Date],upd_lock,[Value])
							VALUES
							(@ObjParent,1291,fnDateToDay(@DateTerr),1000000,SUSER_NAME(),GETDATE(),0,1)							
						END
					
					UPDATE os 
					SET os.FiasGuid = ISNULL(os.FIASPlanStruct,ISNULL(os.PlaceFIASGuid,oc.FIASGuid))
					FROM objStreet AS os
					INNER JOIN lnkCityStreet AS lcs ON lcs.ChildObj=os.ID AND lcs.upd_lock=0
					INNER JOIN objCity AS oc ON oc.ID=lcs.ParentObj AND oc.upd_lock=0
					WHERE os.ID=@ObjParent AND os.stName=''
									
					SELECT Res = 'OK', Street = '('+CONVERT(VARCHAR(50),@ObjParent)+') '+@stAddress
				END
			ELSE IF @mode = 1
				BEGIN
					DECLARE @id_street TABLE (id INT)
					
					DECLARE @i_city INT 
					SELECT @i_city = oc.ID FROM objCity AS oc
					WHERE oc.upd_lock = 0 AND oc.FIASGuid = @city 
										
					IF EXISTS (SELECT * FROM objStreet AS os 
								INNER JOIN lnkCityStreet AS lcs ON lcs.ChildObj=os.ID AND lcs.upd_lock=0
								INNER JOIN objCity AS oc ON oc.ID=lcs.ParentObj AND oc.upd_lock=0
					           WHERE ISNULL(stName,'') = ISNULL((SELECT TOP 1 [Name] FROM #adr a WHERE a.AOLevel=8),'')
								AND ISNULL(TypeStreet,0)  = ISNULL((SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=8),0)
								AND ISNULL(NasPunkt,0) = ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=6),0)
								AND ISNULL(TypePlace,0) = ISNULL((SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=6),0)
								AND ISNULL(PlanStruct,0) = ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=7),0)
								AND ISNULL(TypePlanStruct,0) = ISNULL((SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=7),0)
								AND oc.ID = ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=2),ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=5), ISNULL(@i_city,0)))
								AND os.upd_lock = 0
					)
						
					BEGIN
						declare @ss2 char(200)
							select @ss2=	'Улица, которую вы добавляете уже присутствует в базе данных. Добавление не возможно!!!'
							raiserror (@ss2,16,1)
							RETURN 
					END			
					
					IF ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=2),ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=5), @i_city)) IS NULL
					BEGIN
						declare @ss4 char(200)
							select @ss4=	'Не выбран район / город. Добавление не возможно'
							raiserror (@ss4,16,1)
							RETURN 0
					END							
													
					INSERT INTO objStreet
					(TypeObj,b_period,e_period,UserName,[Date],upd_lock,stName,TypePlace,City,NasPunkt,TypeStreet,KladrCode,FIASGuid,PlaceFIASGuid,PlanStruct,TypePlanStruct,FIASPlanStruct					)
					OUTPUT INSERTED.id INTO @id_street
					VALUES
					(1,0,1000000,SUSER_NAME(),GETDATE(),0,
						(SELECT TOP 1 [Name] FROM #adr a WHERE a.AOLevel=8),	-- Улица
						(SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=6),	-- Нас.пункт
						@mo,
						(SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=6),	-- Нас.пункт
						(SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=8),	-- Улица
						NULL,
						(SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=8),	-- Улица
						(SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=6),	-- Нас.пункт
						(SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=7),	-- План.структура
						(SELECT TOP 1 idType FROM #adr a WHERE a.AOLevel=7),	-- План.структура
						(SELECT TOP 1 [guid] FROM #adr a WHERE a.AOLevel=7)		-- План.структура
					)
									
					
					INSERT INTO lnkCityStreet
					(TypeLink,ParentObj,ChildObj,b_period,e_period,UserName,[Date],upd_lock	)
					VALUES
					(
						51,
						ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=2),ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=5), @i_city)),
						--ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=3),(SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=4)),
						(SELECT TOP 1 id FROM @id_street),
						0,	1000000, SUSER_NAME(),GETDATE(),0
					)	
					
					declare @city_right int, @street_right int
					select	@city_right = ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=2),ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=5), @i_city)),--ISNULL((SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=3),(SELECT TOP 1 idName FROM #adr a WHERE a.AOLevel=4)),
							@street_right = (SELECT TOP 1 id FROM @id_street)

					exec SetRightInherited 51,@city_right,@street_right
					
					IF @id_terr = 1
						INSERT INTO objStreet_Period(Obj,Attr,b_period,e_period,UserName,[Date],upd_lock,[Value])
						SELECT obj = id, attr = 1291, b_period = 0, e_period = 1000000, username = SUSER_NAME(), [DATE] = GETDATE(), upd_lock = 0, [VALUE] = 1 
						FROM @id_street
									
					SELECT Res = 'OK', Street = '('+CONVERT(VARCHAR(50),(SELECT TOP 1 id FROM @id_street))+') '+@stAddress
				END
			ELSE 
				BEGIN
					declare @ss char(200)
						select @ss=	'Ошибка БД'
						raiserror (@ss,16,1)
						RETURN 0
				END

	END
ELSE
BEGIN
	IF @ObjParent = 0 
	BEGIN
		IF @AOLevel = 0 -- Подгружаем справочник городов для выбора
		BEGIN
			SELECT * FROM (
				SELECT  inID		= 602,
						stName		= 'Заводоуковск г',
						inGuid		= '10c58caf-f8b8-44b6-99b9-5cf25f681fcf',
						inAOLEVEL	= 4  
				UNION ALL 
				SELECT 
						inID		= oc.ID,
						stName		= isnull(oc.DisplayName, '')+' ' + isnull(cast(val_params as varchar(255)), ''),
						inGuid		= oc.FIASGuid,
						inAOLEVEL	= oc.AOLEVEL  
				FROM objCity AS oc WITH (nolock)
				LEFT  JOIN  Dictionary_table WITH (nolock) ON  IDAttr = 25 and IDRows =oc.TypeCity
				WHERE oc.upd_lock=0 AND oc.id NOT IN (16, 39, 5)) t
			ORDER BY CASE WHEN inAOLEVEL = 4 THEN 0 ELSE 1 END, stName
			
			RETURN
		END
		IF @AOLevel = 1 -- Подгружаем справочник Муниципальных образований для выбора
		BEGIN
			SELECT 	
					inID	= ID,
					stName	= CONVERT(VARCHAR(250),DisplayName)
			FROM ObjCity
			WHERE upd_lock=0
			UNION ALL 
			SELECT 
					inID = IDRows + 1000,
					stName = CONVERT(VARCHAR(250),val_params)
			FROM dictionary_table
			WHERE idattr=1265
			
			RETURN
		END
		IF @AOLevel = 2 -- Подгружаем Address
		BEGIN
			SELECT 	stName = getAddressGAR(@Guid_parent)
			
			RETURN
		END
		IF @AOLevel = 3 -- Подгружаем TypeStreet
		BEGIN
			SELECT 
				inID	= d.IDRows, 
				stName	= CONVERT(VARCHAR(50), d.val_params) 
			FROM Dictionary AS d
			WHERE d.IDAttr = 1290
			
			RETURN
		END				
		IF @AOLevel in (6, 7, 8) -- Подгружаем справочник Населенных пунктов, Планировочной структуры или улицы для выбора
		BEGIN
			SELECT DISTINCT 
				inGuid = ao.OBJECTGUID, 
				stName = ao.NAME +' '+ ao.TYPENAME 
			FROM ADDR_OBJ AS ao
			INNER JOIN ADM_HIERARCHY AS ah ON ah.OBJECTID=ao.OBJECTID AND ah.ISACTIVE=1
			INNER JOIN ADDR_OBJ AS ao2 ON ao2.OBJECTID=ah.PARENTOBJID AND ao2.ISACTUAL=1 AND ao2.ISACTIVE=1
			WHERE ao.ISACTUAL=1 AND ao.ISACTIVE=1 AND ao.[LEVEL]=@AOLevel AND ao2.OBJECTGUID=@Guid_parent
			ORDER BY stName, ao.OBJECTGUID
			
			RETURN
		END
	END
	ELSE
		BEGIN
			IF @AOLevel = 0 -- Подгружаем данные из objStreet
				BEGIN
					DECLARE @id_terr2 INT, @dateterr2 DATETIME
					
					SELECT TOP 1 @id_terr2 = [value] , @dateterr2 = fnDayToDate(osp.e_period)
					FROM objStreet_Period AS osp 
					WHERE osp.Attr=1291 AND osp.upd_lock=0 AND dbo.fnDateToDay(GETDATE()) BETWEEN osp.b_period AND osp.e_period
					AND osp.Obj=@ObjParent
					
					--01/04/2022 Заводоуковск добавляем
					IF EXISTS (SELECT * FROM objStreet AS os WHERE os.upd_lock=0 AND os.ID = @ObjParent AND os.NasPunkt = 602)
						SELECT 
							inGuidCity = '10c58caf-f8b8-44b6-99b9-5cf25f681fcf',
							stNameCity = 'Заводоуковск г', 
							inGuidNasPunct = '',
							inGuidPlanStruct = ISNULL(os.FIASPlanStruct,''),
							inGuidStreet = ISNULL(os.FIASGuid,''),
							inIdMO = ISNULL(os.City,0),
							inIdTypeTerr = CASE WHEN @id_terr2 IS NOT NULL THEN 1 ELSE 0 END,
							inDateTerr = CASE WHEN @dateterr2 IS NULL THEN '01-01-1900 00:00:00' ELSE @dateterr2 END,
							inAddress = 
										/*город*/	
												CASE WHEN oc.aolevel=4 THEN 
													isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock) where IDAttr = 25 and IDRows =oc.TypeCity), '') 
													+' '+isnull(oc.DisplayName, '')
												ELSE 
													isnull(oc.DisplayName, '')+' '
													+isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock) where IDAttr = 25 and IDRows =oc.TypeCity), '')
												END 
										/*улица*/	+ case when isnull(oc.DisplayName,'')<>'' then ', ' else '' END

													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 47 and IDRows =os.TypePlace), '') 
													+ isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock)
														 where IDAttr = 1280 and IDRows =os.NasPunkt)+', ', '') 
				 
													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 1282 and IDRows =os.TypePlanStruct), '') 
													+ isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock)
														 where IDAttr = 1281 and IDRows =os.PlanStruct)+', ', '') 				 
				 
													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 1290 and IDRows=os.TypeStreet), '')
													+ isnull(os.stName, '')						
						
						FROM objStreet AS os
						INNER JOIN lnkCityStreet AS lcs ON lcs.upd_lock=0 AND lcs.ChildObj = os.ID
						INNER JOIN objCity AS oc ON oc.ID = lcs.ParentObj AND oc.upd_lock = 0
						LEFT  JOIN  Dictionary_table WITH (nolock) ON  IDAttr = 25 and IDRows =oc.TypeCity
						WHERE os.upd_lock = 0 AND os.ID = @ObjParent
					
					ELSE
					
						SELECT 
							inGuidCity = oc.FIASGuid,
							stNameCity = isnull(oc.DisplayName, '')+' ' + isnull(cast(val_params as varchar(255)), ''), 
							inGuidNasPunct = ISNULL(os.PlaceFIASGuid,''),
							inGuidPlanStruct = ISNULL(os.FIASPlanStruct,''),
							inGuidStreet = ISNULL(os.FIASGuid,''),
							inIdMO = ISNULL(os.City,0),
							inIdTypeTerr = CASE WHEN @id_terr2 IS NOT NULL THEN 1 ELSE 0 END,
							inDateTerr = CASE WHEN @dateterr2 IS NULL THEN '01-01-1900 00:00:00' ELSE @dateterr2 END,
							inAddress = 
										/*город*/	
												CASE WHEN oc.aolevel=4 THEN 
													isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock) where IDAttr = 25 and IDRows =oc.TypeCity), '') 
													+' '+isnull(oc.DisplayName, '')
												ELSE 
													isnull(oc.DisplayName, '')+' '
													+isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock) where IDAttr = 25 and IDRows =oc.TypeCity), '')
												END 
										/*улица*/	+ case when isnull(oc.DisplayName,'')<>'' then ', ' else '' END

													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 47 and IDRows =os.TypePlace), '') 
													+ isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock)
														 where IDAttr = 1280 and IDRows =os.NasPunkt)+', ', '') 
				 
													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 1282 and IDRows =os.TypePlanStruct), '') 
													+ isnull((select cast(val_params as varchar(255)) from Dictionary_table WITH (nolock)
														 where IDAttr = 1281 and IDRows =os.PlanStruct)+', ', '') 				 
				 
													+ isnull((select cast(val_params as varchar(255))+' ' from Dictionary_table WITH (nolock)
														 where IDAttr = 1290 and IDRows=os.TypeStreet), '')
													+ isnull(os.stName, '')						
						
						FROM objStreet AS os
						INNER JOIN lnkCityStreet AS lcs ON lcs.upd_lock=0 AND lcs.ChildObj = os.ID
						INNER JOIN objCity AS oc ON oc.ID = lcs.ParentObj AND oc.upd_lock = 0
						LEFT  JOIN  Dictionary_table WITH (nolock) ON  IDAttr = 25 and IDRows =oc.TypeCity
						WHERE os.upd_lock = 0 AND os.ID = @ObjParent
								
					RETURN
				END
			
		END
END
	
	
	
	
END

