DECLARE @guid TABLE (objectguid UNIQUEIDENTIFIER)
CREATE TABLE #house (id INT)

INSERT INTO @guid
SELECT DISTINCT ao.OBJECTGUID
FROM journal_upd_addr_obj AS jnao
INNER JOIN HOUSES AS ao ON ao.ID=jnao.id_obj
WHERE jnao.upd_table='house' AND jnao.[STATUS] IS NULL

INSERT INTO #house
SELECT id
FROM objHouse AS oh
WHERE oh.upd_lock=0 AND oh.VidObj=1
AND oh.TypeHouse IN (1, 2, 3, 4,8,12)

CREATE INDEX idx ON #house (id)
CREATE TABLE #house_guid(id INT, guid UNIQUEIDENTIFIER)

INSERT INTO #house_guid
SELECT oh.ID,
TRY_CAST(isnull(isnull(ISNULL(CASE WHEN TRY_CAST(os.FIASGuid AS uniqueidentifier) IS NULL AND isnull(os.stName,'') = '' THEN NULL ELSE TRY_CAST(os.FIASGuid AS uniqueidentifier) END,
			CASE WHEN TRY_CAST(os.FIASPlanStruct AS uniqueidentifier) IS NULL AND os.PlanStruct IS NULL THEN NULL ELSE TRY_CAST(os.FIASPlanStruct AS uniqueidentifier) END),
				CASE WHEN TRY_CAST(os.PlaceFIASGuid AS uniqueidentifier) IS NULL AND os.NasPunkt IS NULL THEN NULL ELSE TRY_CAST(os.PlaceFIASGuid AS uniqueidentifier) END),
					CASE WHEN TRY_CAST(oc.FIASGuid AS uniqueidentifier) IS NULL THEN NULL ELSE TRY_CAST(oc.FIASGuid AS uniqueidentifier) END) AS uniqueidentifier) 
FROM objHouse AS oh WITH (NOLOCK)
INNER JOIN lnkStreetHouse AS lsh WITH (NOLOCK) ON lsh.ChildObj=oh.ID AND lsh.upd_lock=0
INNER JOIN objStreet AS os WITH (NOLOCK) ON os.ID=lsh.ParentObj AND os.upd_lock=0
INNER JOIN lnkCityStreet AS lcs WITH (NOLOCK) ON os.ID=lcs.ChildObj AND lcs.upd_lock=0
INNER JOIN objCity AS oc WITH(NOLOCK) ON oc.ID=lcs.ParentObj AND oc.upd_lock=0
WHERE oh.upd_lock=0 AND asup.dbo.fnDateToDay(GETDATE()) BETWEEN oh.b_period AND oh.e_period
AND  TRY_CAST(isnull(isnull(ISNULL(CASE WHEN TRY_CAST(os.FIASGuid AS uniqueidentifier) IS NULL AND isnull(os.stName,'') = '' THEN NULL ELSE TRY_CAST(os.FIASGuid AS uniqueidentifier) END,
			CASE WHEN TRY_CAST(os.FIASPlanStruct AS uniqueidentifier) IS NULL AND os.PlanStruct IS NULL THEN NULL ELSE TRY_CAST(os.FIASPlanStruct AS uniqueidentifier) END),
				CASE WHEN TRY_CAST(os.PlaceFIASGuid AS uniqueidentifier) IS NULL AND os.NasPunkt IS NULL THEN NULL ELSE TRY_CAST(os.PlaceFIASGuid AS uniqueidentifier) END),
					CASE WHEN TRY_CAST(oc.FIASGuid AS uniqueidentifier) IS NULL THEN NULL ELSE TRY_CAST(oc.FIASGuid AS uniqueidentifier) END) AS uniqueidentifier) IS NOT NULL
AND exists (SELECT id FROM #house AS h WHERE h.id=oh.ID)

CREATE INDEX idx ON #house_guid (id, guid)
ALTER TABLE #house_guid ADD fias UNIQUEIDENTIFIER

UPDATE #house_guid
SET fias = GetGuidGarHouse_new(ID, guid)

INSERT INTO objHouse_Shadow 
SELECT oh.*
FROM objHouse AS oh WITH (NOLOCK)
INNER JOIN  #house_guid AS h on h.id=oh.ID
WHERE ISNULL(oh.FIASGuid,'')<> ISNULL(convert(varchar(50),h.fias),'')

insert into GuidWithoutGarHouse 
SELECT oh.id, oh.FIASGuid, ahb.[Address], GETDATE(), NULL, NULL, convert(varchar(500), dt.val_params)                                                          
FROM objHouse AS oh WITH (NOLOCK)
INNER JOIN  #house_guid AS h on h.id=oh.ID
INNER JOIN Address_house_bondar AS ahb ON ahb.i_House=oh.ID
LEFT JOIN  Dictionary_table AS dt on dt.IDAttr=983 AND dt.IDRows= oh.TypeHouse
WHERE ISNULL(oh.FIASGuid,'')<> ISNULL(convert(varchar(50),h.fias),'')
AND h.fias IS NULL
AND NOT EXISTS (SELECT * FROM GuidWithoutGarHouse  t WHERE t.i_house = oh.id)

UPDATE oh 
SET  
	oh.FIASGuid= h.fias,
	[Date] = GETDATE(), UserName = 'update_GAR'
FROM objHouse AS oh WITH (NOLOCK)
INNER JOIN  #house_guid AS h on h.id=oh.ID
WHERE ISNULL(oh.FIASGuid,'')<> ISNULL(convert(varchar(50),h.fias),'')

UPDATE jnao
SET 
	[STATUS] = 1,
	date_state = GETDATE()
FROM journal_upd_addr_obj AS jnao
INNER JOIN HOUSES AS ao ON ao.ID=jnao.id_obj
WHERE jnao.upd_table='house' AND jnao.[STATUS] IS NULL
AND ao.OBJECTGUID IN (SELECT objectguid FROM @guid)
