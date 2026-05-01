USE [XXX]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<xxxxxxxxxxxx>
-- Create date: <xxxxxxxxxxxxxxx>
-- Description:	<xxxxxxxxxxxxxxxxxxxxxxxxx>
-- =============================================
CREATE PROCEDURE [update_street_child] @guid UNIQUEIDENTIFIER
AS
BEGIN
	SET NOCOUNT ON;


	-- Для объектов по которым не изменялся ParentGUIID
	IF EXISTS (SELECT * FROM tmp_upd_street WHERE PARENTGUID IS NULL AND guid=@guid)
	BEGIN
	
		DECLARE @Version INT	
	
		declare crDate cursor for
		SELECT DISTINCT version_file
		FROM tmp_upd_street WHERE PARENTGUID IS NULL AND guid=@guid
		ORDER BY version_file
		
		open crDate

		fetch next from crDate into @Version

		WHILE @@FETCH_STATUS=0
		BEGIN
			---ЛОГИ-----
			INSERT INTO street_upd_gar_log(remark,i_street,curr_street_name,curr_street_type,new_name,new_type,new_level,date_upd)
			SELECT 
				remark				= 'Изменяется улица',
				i_street			= os.id, 
				curr_street_name	= stName,	
				curr_street_type	= fnGetDictValueForAttr(1290, os.TypeStreet,0),
				new_name			= t.[NAME], 
				new_type			= t.typeNAME, 
				new_level			= t.[LEVEL], 
				date_upd			= GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL  AND guid=@guid AND t.level_prev = 8
				AND version_file = @Version
				
				
			--Если изменилась улица
			INSERT INTO objStreet_Shadow
			SELECT os.*
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL  AND guid=@guid AND t.level_prev = 8
				AND version_file = @Version

			UPDATE os 
			SET 
				os.stName = ISNULL(t.[NAME], os.stName), 
				os.TypeStreet = ISNULL(dt.IDRows, os.TypeStreet), 
				UserName = 'GAR_UPDATE', 
				os.[Date] = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			LEFT JOIN Dictionary_table AS dt ON dt.IDAttr=1290 AND CONVERT(VARCHAR(10),dt.val_params)=t.typeName
			WHERE t.PARENTGUID IS NULL  AND guid=@guid AND t.level_prev = 8
				AND version_file = @Version
		
			UPDATE n
			SET 
				[status] = 10, 
				date_state = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN [journal_upd_addr_obj] n ON n.upd_table='street' AND n.[STATUS] IS NULL AND n.version_file=@Version AND n.OBJECTID=t.OBJECTID
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL  AND guid=@guid AND t.level_prev = 8
				AND n.version_file = @Version				
					
			--=======================================		
			--Если изменилась планировочная структура
				
			---ЛОГИ-----
			INSERT INTO street_upd_gar_log(remark,	i_street, curr_planstruct_name,	curr_planstruct_type, curr_naspunct_name, curr_naspunct_type, new_name, new_type, new_level, date_upd)
			SELECT 
				CASE WHEN t.[LEVEL] = 6 THEN 'Изменяется план.структура на нас.пункт' ELSE 'Изменяется планировочная структура' END,
				os.id, 
				fnGetDictValueForAttr(1281, os.PlanStruct,0) AS PlanStruct,
				fnGetDictValueForAttr(1282, os.TypePlanStruct,0) AS TypePlanStruct,
				fnGetDictValueForAttr(1280, os.NasPunkt,0) AS NasPunkt,
				fnGetDictValueForAttr(47, os.TypePlace,0) AS TypePlace,
				new_name			= t.[NAME], 
				new_type			= t.typeNAME, 
				new_level			= t.[LEVEL], 
				date_upd			= GETDATE()		
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASPlanStruct=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL  AND guid=@guid AND t.level_prev = 7
				AND version_file = @Version			
			
			INSERT INTO objStreet_Shadow
			SELECT os.*			
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASPlanStruct=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 7
				AND version_file = @Version		
	
			UPDATE os 
			SET 
				os.PlanStruct = CASE WHEN t.[LEVEL] = 6 THEN NULL ELSE ISNULL(dt1.IDRows, os.PlanStruct) END, 			
				os.TypePlanStruct = CASE WHEN t.[LEVEL] = 6 THEN NULL ELSE ISNULL(dt.IDRows, os.TypePlanStruct) END, 
				os.FIASPlanStruct = CASE WHEN t.[LEVEL] = 6 THEN NULL ELSE os.FIASPlanStruct END,
				os.NasPunkt = ISNULL(dt61.IDRows, os.NasPunkt), 			
				os.TypePlace = ISNULL(dt6.IDRows, os.TypePlace), 
				os.PlaceFIASGuid = CASE WHEN t.[LEVEL] = 6 THEN t.OBJECTGUID ELSE os.PlaceFIASGuid END,
				UserName = 'GAR_UPDATE', 
				os.[Date] = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.FIASPlanStruct=t.ObjectGuid AND os.upd_lock=0
			LEFT JOIN Dictionary_table AS dt1 ON dt1.IDAttr=1281 AND CONVERT(VARCHAR(100),dt1.val_params)=t.[NAME] AND ISNULL(t.[LEVEL], t.level_prev) = 7
			LEFT JOIN Dictionary_table AS dt ON dt.IDAttr=1282 AND CONVERT(VARCHAR(10),dt.val_params)=t.typeNAME AND ISNULL(t.[LEVEL], t.level_prev) = 7
			LEFT JOIN Dictionary_table AS dt61 ON dt61.IDAttr=1280 AND CONVERT(VARCHAR(100),dt61.val_params)=t.[NAME] AND ISNULL(t.[LEVEL], t.level_prev) = 6
			LEFT JOIN Dictionary_table AS dt6 ON dt6.IDAttr=47 AND CONVERT(VARCHAR(10),dt6.val_params)=t.typeNAME AND ISNULL(t.[LEVEL], t.level_prev) = 6
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 7
				AND version_file = @Version	
			
			UPDATE n
			SET 
				[status] = 10, 
				date_state = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN [journal_upd_addr_obj] n ON n.upd_table='street' AND n.[STATUS] IS NULL AND n.version_file=@Version AND n.OBJECTID=t.OBJECTID
			INNER JOIN objStreet AS os ON os.FIASPlanStruct=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 7
				AND n.version_file = @Version		
													
			--Если изменился населенный пункт
			---ЛОГИ-----
			INSERT INTO street_upd_gar_log(remark,	i_street, curr_planstruct_name,	curr_planstruct_type, curr_naspunct_name, curr_naspunct_type, new_name, new_type, new_level, date_upd)
			SELECT 
				CASE WHEN t.[LEVEL] = 7 THEN 'Изменяется нас.пункт на план.структуру' ELSE 'Изменяется нас.пункт' END,
				os.id, 
				fnGetDictValueForAttr(1281, os.PlanStruct,0) AS PlanStruct,
				fnGetDictValueForAttr(1282, os.TypePlanStruct,0) AS TypePlanStruct,
				fnGetDictValueForAttr(1280, os.NasPunkt,0) AS NasPunkt,
				fnGetDictValueForAttr(47, os.TypePlace,0) AS TypePlace,
				new_name			= t.[NAME], 
				new_type			= t.typeNAME, 
				new_level			= t.[LEVEL], 
				date_upd			= GETDATE()	
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.PlaceFIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 6
				AND version_file = @Version					
			
			INSERT INTO objStreet_Shadow
			SELECT os.*					
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.PlaceFIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 6
				AND version_file = @Version												

			UPDATE os 
			SET 
				os.PlanStruct = ISNULL(dt1.IDRows, os.PlanStruct), 			
				os.TypePlanStruct = ISNULL(dt.IDRows, os.TypePlanStruct), 
				os.FIASPlanStruct = CASE WHEN t.[LEVEL] = 7 THEN t.OBJECTGUID ELSE os.FIASPlanStruct END,
				os.NasPunkt =  CASE WHEN t.[LEVEL] = 7 THEN NULL ELSE ISNULL(dt61.IDRows, os.NasPunkt) END, 					
				os.TypePlace = CASE WHEN t.[LEVEL] = 7 THEN NULL ELSE ISNULL(dt6.IDRows, os.TypePlace) END, 
				os.PlaceFIASGuid = CASE WHEN t.[LEVEL] = 7 THEN NULL ELSE os.PlaceFIASGuid END,
				UserName = 'GAR_UPDATE', 
				os.[Date] = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN objStreet AS os ON os.PlaceFIASGuid=t.ObjectGuid AND os.upd_lock=0
			LEFT JOIN Dictionary_table AS dt1 ON dt1.IDAttr=1281 AND CONVERT(VARCHAR(100),dt1.val_params)=t.[NAME] AND ISNULL(t.[LEVEL], t.level_prev) = 7
			LEFT JOIN Dictionary_table AS dt ON dt.IDAttr=1282 AND CONVERT(VARCHAR(10),dt.val_params)=t.typeNAME AND ISNULL(t.[LEVEL], t.level_prev) = 7
			LEFT JOIN Dictionary_table AS dt61 ON dt61.IDAttr=1280 AND CONVERT(VARCHAR(100),dt61.val_params)=t.[NAME] AND ISNULL(t.[LEVEL], t.level_prev) = 6
			LEFT JOIN Dictionary_table AS dt6 ON dt6.IDAttr=47 AND CONVERT(VARCHAR(10),dt6.val_params)=t.typeNAME AND ISNULL(t.[LEVEL], t.level_prev) = 6
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 6
				AND version_file = @Version	
									
			UPDATE n
			SET 
				[status] = 10, 
				date_state = GETDATE()			
			FROM tmp_upd_street AS t
			INNER JOIN [journal_upd_addr_obj] n ON n.upd_table='street' AND n.[STATUS] IS NULL AND n.version_file=@Version AND n.OBJECTID=t.OBJECTID
			INNER JOIN objStreet AS os ON os.PlaceFIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND t.level_prev = 6
				AND n.version_file = @Version																	
											
			DELETE t FROM tmp_upd_street AS t
			WHERE t.PARENTGUID IS NULL AND guid=@guid AND version_file = @Version
																	
			fetch next from crDate into @Version
		END

		close crDate
		deallocate crDate	
	
	
	END -- Для объектов по которым не изменялся ParentGUIID



	-- Для объектов по которым изменялся ParentGUIID одного уровня
	IF EXISTS (SELECT * FROM tmp_upd_street WHERE PARENTGUID IS NOT NULL AND guid=@guid)
	BEGIN
	
		DECLARE @Version2 INT	
	
		declare crDate2 cursor for
		SELECT DISTINCT version_file
		FROM tmp_upd_street WHERE PARENTGUID IS NOT NULL AND guid=@guid
		ORDER BY version_file
		
		open crDate2

		fetch next from crDate2 into @Version2

		WHILE @@FETCH_STATUS=0
		BEGIN
			---ЛОГИ-----
			INSERT INTO street_upd_gar_log(remark,i_street,curr_street_name,curr_street_type, curr_planstruct_name,	curr_planstruct_type, curr_naspunct_name, curr_naspunct_type,
			new_name,new_type,new_level,date_upd)
			SELECT 
				remark				= 'Изменяется Родительский объект',
				i_street			= os.id, 
				curr_street_name	= stName,	
				curr_street_type	= fnGetDictValueForAttr(1290, os.TypeStreet,0),
				fnGetDictValueForAttr(1281, os.PlanStruct,0) AS PlanStruct,
				fnGetDictValueForAttr(1282, os.TypePlanStruct,0) AS TypePlanStruct,
				fnGetDictValueForAttr(1280, os.NasPunkt,0) AS NasPunkt,
				fnGetDictValueForAttr(47, os.TypePlace,0) AS TypePlace,
				new_name			= t2.[NAME], 
				new_type			= t2.typeNAME, 
				new_level			= t2.level_prev, 
				date_upd			= GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN tmp_upd_street AS t2 ON t2.parentguid=t.parentguid AND t2.OBJECTGUID=t2.parentguid
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NOT NULL  AND t.OBJECTGUID <> t.parentguid AND t.guid=@guid AND t.level_prev = 8
			AND ((t2.level_prev = 7 AND os.PlanStruct IS NOT NULL) OR (t2.level_prev = 6 AND os.NasPunkt IS NOT NULL AND os.PlanStruct IS NULL))
				AND t.version_file = @Version2
				
				
			--Если изменилась улица
			INSERT INTO objStreet_Shadow
			SELECT os.*
			FROM tmp_upd_street AS t
			INNER JOIN tmp_upd_street AS t2 ON t2.parentguid=t.parentguid AND t2.OBJECTGUID=t2.parentguid
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NOT NULL AND t.OBJECTGUID <> t.parentguid  AND t.guid=@guid AND t.level_prev = 8
			AND ((t2.level_prev = 7 AND os.PlanStruct IS NOT NULL) OR (t2.level_prev = 6 AND os.NasPunkt IS NOT NULL AND os.PlanStruct IS NULL))
				AND t.version_file = @Version2

			UPDATE os 
			SET 
				stName		= ISNULL(t.[NAME], os.stName), 
				TypeStreet	= ISNULL(dt.IDRows, os.TypeStreet), 
				PlanStruct	= CASE WHEN t2.level_prev = 7 THEN dt71.IDRows ELSE NULL END, 			
				TypePlanStruct = CASE WHEN t2.level_prev = 7 THEN dt7.IDRows ELSE NULL END,  
				FIASPlanStruct = CASE WHEN t2.level_prev = 7 THEN t2.OBJECTGUID ELSE NULL END, 
				NasPunkt		= CASE WHEN t2.level_prev = 6 THEN dt71.IDRows ELSE NULL END, 			
				TypePlace	= CASE WHEN t2.level_prev = 6 THEN dt7.IDRows ELSE NULL END, 
				PlaceFIASGuid = CASE WHEN t2.level_prev = 6 THEN t2.OBJECTGUID ELSE NULL END,
				UserName = 'GAR_UPDATE', 
				[Date] = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN tmp_upd_street AS t2 ON t2.parentguid=t.parentguid AND t2.OBJECTGUID=t2.parentguid
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			LEFT JOIN Dictionary_table AS dt ON dt.IDAttr=1290 AND CONVERT(VARCHAR(10),dt.val_params)=t.typeName
			
			LEFT JOIN Dictionary_table AS dt71 ON dt71.IDAttr=CASE WHEN t2.level_prev = 7 THEN 1281 WHEN  t2.level_prev =6 THEN 1280 ELSE NULL  END 
																		AND CONVERT(VARCHAR(100),dt71.val_params)=t2.[NAME]
			LEFT JOIN Dictionary_table AS dt7  ON  dt7.IDAttr=CASE WHEN t2.level_prev = 7 THEN 1282 WHEN  t2.level_prev =6 THEN 47 ELSE NULL  END  
																		AND CONVERT(VARCHAR(10),dt7.val_params)=t2.typeNAME		
			WHERE t.PARENTGUID IS NOT NULL  AND t.OBJECTGUID <> t.parentguid AND t.guid=@guid AND t.level_prev = 8
			AND ((t2.level_prev = 7 AND os.PlanStruct IS NOT NULL) OR (t2.level_prev = 6 AND os.NasPunkt IS NOT NULL AND os.PlanStruct IS NULL))
			AND t.version_file = @Version2
		
			UPDATE n
			SET 
				[status] = 10, 
				date_state = GETDATE()
			FROM tmp_upd_street AS t
			INNER JOIN [journal_upd_addr_obj] n ON n.upd_table='street' AND n.[STATUS] IS NULL AND n.version_file=@Version2 AND n.OBJECTID=t.OBJECTID
			INNER JOIN tmp_upd_street AS t2 ON t2.parentguid=t.parentguid AND t2.OBJECTGUID=t2.parentguid
			INNER JOIN objStreet AS os ON os.FIASGuid=t.ObjectGuid AND os.upd_lock=0
			WHERE t.PARENTGUID IS NOT NULL  AND t.OBJECTGUID <> t.parentguid AND t.guid=@guid AND t.level_prev = 8
			AND ((t2.level_prev = 7 AND os.PlanStruct IS NOT NULL) OR (t2.level_prev = 6 AND os.NasPunkt IS NOT NULL AND os.PlanStruct IS NULL))
				AND t.version_file = @Version2		
																
											
			DELETE t FROM tmp_upd_street AS t
			WHERE t.PARENTGUID IS NOT NULL AND guid=@guid AND version_file = @Version2
																	
			fetch next from crDate2 into @Version2
		END

		close crDate2
		deallocate crDate2	
	
	
	END -- Для объектов по которым изменялся ParentGUIID одного уровня
END

GO


