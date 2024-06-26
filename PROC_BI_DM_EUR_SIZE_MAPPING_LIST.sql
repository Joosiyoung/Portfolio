  CREATE OR REPLACE EDITIONABLE PROCEDURE "BI_DWUSER"."PROC_BI_DM_EUR_SIZE_MAPPING_LIST" 
--(
--        PV_YYYYMM IN VARCHAR2 DEFAULT TO_CHAR(SYSDATE-1,'YYYYMM') 
--)
IS
/**************************************************************
 *  Created by: LOGOS DATA - SY Joo
 * 
 * 
 *	Date: 2023-12-06
 *	Desc.: Europe Size Mapping
***************************************************************/
-- PV_YYYYMM1        VARCHAR2(6) := NULL;
VN_CNT            NUMBER :=0;
BEGIN
PROC_SET_LOG( PV_PGM_NAME         => 'PROC_BI_DM_EUR_SIZE_MAPPING_LIST'
            , PD_DT               => SYSDATE
            , PN_RESULT_CNT       =>  NULL
            , PV_RESULT           =>  NULL
            , PV_STATUS           => 'START'
            , PV_ERR_CODE         =>  NULL
            , PV_ERR_MSG          =>  NULL
            , PV_REMARKS          =>  NULL
             ) ;
  DELETE FROM BI_DM_EUR_SIZE_MAPPING_LIST; --기존 마스터 TABLE 초기화
  INSERT INTO BI_DM_EUR_SIZE_MAPPING_LIST --마스터 TABLE 생성 (1:1 바로 붙는 SIZE부터 맵핑 후 맵핑 안된 SIZE는 우선순위 대로 처리)
    ( SEASON
    , LINE
    , SIZE2
    , ZSIZE
    , ZSPEED
    , XL
    , HAN_SIZE ) 
  WITH CV_EUROPOOL_SIZE AS ( --Size Code 통일화를 위해 Europool 데이터 전처리
    SELECT B.SEASON2 AS SEASON
         , B.LINE4 AS LINE
         , A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM||CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END||CASE WHEN A.REIN = '1' THEN ' XL' END  AS ZSIZE
         , CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END AS ZSPEED
         , CASE WHEN A.REIN = '1' THEN 'XL' END AS XL
	 , A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM AS SIZE2
      FROM BI_EUR_ETRMA_SMB A
      LEFT OUTER JOIN BI_EUR_SEGMENT_MST_TEMP B ON A.SEG4 = B.SEGMENT
     WHERE 1=1
       AND A.ZCODE = 'ZEU'
       AND LENGTH(LAND1) = 2
       AND A.SPEED IS NOT NULL
       AND A.ZLOAD IS NOT NULL
       AND A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM||CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END||CASE WHEN A.REIN = '1' THEN ' XL' END NOT LIKE '%NA%'
       AND A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM||CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END||CASE WHEN A.REIN = '1' THEN ' XL' END NOT LIKE '%R3%'
       AND B.LINE4 <> 'TBR'
     GROUP BY B.SEASON2
            , B.LINE4
            , CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END 
            , A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM||CASE WHEN B.LINE4 = 'LTR' THEN A.ZLOAD ELSE A.SPEED END||CASE WHEN A.REIN = '1' THEN ' XL' END
            , CASE WHEN A.REIN = '1' THEN 'XL' END
	    , A.WIDTH||'/'||A.RATIO||A.STRUCTURE||A.RIM
    )
  , CV_HAN_SIZE AS ( --Size Code 통일화를 위해 Hankook Tire 데이터 전처리
    SELECT DECODE(SEASON,'All Season','All Weather',SEASON) AS SEASON
         , CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END AS LINE 
	 , WIDTH||'/'||SERIES||'R'||INCH||
           CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
                	CASE WHEN INSTR(LI_SS,'/') = 0 THEN SUBSTR(LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(LI_SS,1,INSTR(LI_SS,'/')-1) END
                ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
                END||DECODE(XL,'XL',' '||XL) AS ZSIZE
	 , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
                	CASE WHEN INSTR(LI_SS,'/') = 0 THEN SUBSTR(LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(LI_SS,1,INSTR(LI_SS,'/')-1) END
                ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
                END AS ZSPEED
         , XL
	 , WIDTH||'/'||SERIES||'R'||INCH AS SIZE2
      FROM BI_EUR_LP 
      GROUP BY SEASON
             , CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END
	     , WIDTH||'/'||SERIES||'R'||INCH||
               CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
                    	CASE WHEN INSTR(LI_SS,'/') = 0 THEN SUBSTR(LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(LI_SS,1,INSTR(LI_SS,'/')-1) END
                    ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
                    END||DECODE(XL,'XL',' '||XL)
	     , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
                    	CASE WHEN INSTR(LI_SS,'/') = 0 THEN SUBSTR(LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(LI_SS,1,INSTR(LI_SS,'/')-1) END
                    ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
                    END
	     , XL
	     , WIDTH||'/'||SERIES||'R'||INCH
    ) -- 우선적으로 Europool 데이터와 Hankook Tire 데이터 간 Size Code 를 1:1 맵핑
    SELECT A.SEASON
         , A.LINE
	 , A.SIZE2
         , A.ZSIZE
         , A.ZSPEED
         , A.XL
         , B.ZSIZE AS HAN_SIZE
    FROM CV_EUROPOOL_SIZE A 
    LEFT OUTER JOIN CV_HAN_SIZE B ON A.ZSIZE = B.ZSIZE AND UPPER(A.SEASON) = UPPER(B.SEASON) AND UPPER(A.LINE) = UPPER(B.LINE)
   WHERE 1=1;

-- 1:1 맵핑 후 맵핑 안된 Code를 우선순위로 조건에 가장 가까운 Size 로 맵핑

  FOR C1 IN ( -- 1순위 LOOP ( XL 구분자가 같고, 속도가 같거나 높은 것 중 EUROPOOL SPEED GRADE와 가까운 SIZE)
    SELECT A.SEASON
	 , A.LINE
	 , A.SIZE2
	 , A.ZSPEED
	 , A.XL
	 , NVL(B.CODE_NM1,A.ZSPEED) AS SPEED_GRADE
      FROM BI_DM_EUR_SIZE_MAPPING_LIST A
      LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B ON A.ZSPEED = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
     WHERE 1=1
       AND A.HAN_SIZE IS NULL
       AND A.ZSPEED <> 'ERR'
    )
  LOOP
	UPDATE BI_DM_EUR_SIZE_MAPPING_LIST A
	   SET A.HAN_SIZE = (SELECT ZSIZE
	                       FROM ( SELECT A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
					     CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						  	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
					          ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1) --LTR은 LOAD INDEX로 SIZE 생성
					          END||DECODE(XL,'XL',' '||A.XL) AS ZSIZE
					   , ROW_NUMBER() OVER (
						  ORDER BY NVL(B.CODE_NM1
					  	             , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
							            	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
							            ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
								    END) ASC) AS SEQ
			                FROM BI_EUR_LP_HAN_RAW A
					LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B 
					  ON SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1) = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
                                         AND SUBSTR(UPPER(TRIM(SEGMENT)),1,1) <> 'L'
			               WHERE 1=1
			                 AND UPPER(DECODE(A.SEASON,'All Season','All Weather',A.SEASON)) = UPPER(C1.SEASON)
			                 AND UPPER(CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END) = (C1.LINE)
			                 AND NVL(A.XL,' ') = NVL(C1.XL,' ')
			                 AND TO_NUMBER(NVL(B.CODE_NM1
							 , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
								ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
								END)) >= TO_NUMBER(C1.SPEED_GRADE)
			                 AND A.WIDTH||'/'||A.SERIES||'R'||A.INCH = C1.SIZE2
                                       GROUP BY A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
						CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						     	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
						     ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
						     END||DECODE(A.XL,'XL',' '||A.XL)
		 			      , NVL(B.CODE_NM1,CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									       		CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
									       ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
									       END))
			      WHERE 1=1
				AND SEQ = '1')
	 WHERE 1=1
	   AND UPPER(A.SEASON) = UPPER(C1.SEASON)
	   AND UPPER(A.LINE) = (C1.LINE)
	   AND A.SIZE2 = C1.SIZE2
	   AND A.ZSPEED = C1.ZSPEED
	   AND NVL(A.XL,' ') = NVL(C1.XL,' '); 
  END LOOP;	

  FOR C1 IN ( -- 2순위 LOOP ( XL 구분자는 다른데, 속도가 같거나 높은 것 중 EUROPOOL SPEED GRADE와 가까운 SIZE)
    SELECT A.SEASON
	 , A.LINE
	 , A.SIZE2
	 , A.ZSPEED
	 , A.XL
	 , NVL(B.CODE_NM1,A.ZSPEED) AS SPEED_GRADE
      FROM BI_DM_EUR_SIZE_MAPPING_LIST A
      LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B ON A.ZSPEED = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
     WHERE 1=1
       AND A.HAN_SIZE IS NULL
       AND A.ZSPEED <> 'ERR'
    )
  LOOP
	UPDATE BI_DM_EUR_SIZE_MAPPING_LIST A
	   SET A.HAN_SIZE = (SELECT ZSIZE
	                       FROM ( SELECT A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
					     CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						  	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
					          ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1) --LTR은 LOAD INDEX로 SIZE 생성
					          END||DECODE(XL,'XL',' '||A.XL) AS ZSIZE
					   , ROW_NUMBER() OVER (
						  ORDER BY NVL(B.CODE_NM1
					  	             , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
							            	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
							            ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
								    END) ASC) AS SEQ
			                FROM BI_EUR_LP_HAN_RAW A
					LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B 
					  ON SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1) = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
                                         AND SUBSTR(UPPER(TRIM(SEGMENT)),1,1) <> 'L'
			               WHERE 1=1
			                 AND UPPER(DECODE(A.SEASON,'All Season','All Weather',A.SEASON)) = UPPER(C1.SEASON)
			                 AND UPPER(CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END) = (C1.LINE)
			                 AND NVL(A.XL,' ') <> NVL(C1.XL,' ')
			                 AND TO_NUMBER(NVL(B.CODE_NM1
							 , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
								ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
								END)) >= TO_NUMBER(C1.SPEED_GRADE)
			                 AND A.WIDTH||'/'||A.SERIES||'R'||A.INCH = C1.SIZE2
                                       GROUP BY A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
						CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						     	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
						     ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
						     END||DECODE(A.XL,'XL',' '||A.XL)
		 			      , NVL(B.CODE_NM1,CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									       		CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
									       ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
									       END))
			      WHERE 1=1
				AND SEQ = '1')
	 WHERE 1=1
	   AND UPPER(A.SEASON) = UPPER(C1.SEASON)
	   AND UPPER(A.LINE) = (C1.LINE)
	   AND A.SIZE2 = C1.SIZE2
	   AND A.ZSPEED = C1.ZSPEED
	   AND NVL(A.XL,' ') = NVL(C1.XL,' '); 
  END LOOP;	

  FOR C1 IN ( -- 3순위 LOOP ( XL 구분자는 같고, 속도가 낮은 것 중 EUROPOOL SPEED GRADE와 가까운 SIZE)
    SELECT A.SEASON
	 , A.LINE
	 , A.SIZE2
	 , A.ZSPEED
	 , A.XL
	 , NVL(B.CODE_NM1,A.ZSPEED) AS SPEED_GRADE
      FROM BI_DM_EUR_SIZE_MAPPING_LIST A
      LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B ON A.ZSPEED = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
     WHERE 1=1
       AND A.HAN_SIZE IS NULL
       AND A.ZSPEED <> 'ERR'
    )
  LOOP
	UPDATE BI_DM_EUR_SIZE_MAPPING_LIST A
	   SET A.HAN_SIZE = (SELECT ZSIZE
	                       FROM ( SELECT A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
					     CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						  	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
					          ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1) --LTR은 LOAD INDEX로 SIZE 생성
					          END||DECODE(XL,'XL',' '||A.XL) AS ZSIZE
					   , ROW_NUMBER() OVER (
						  ORDER BY NVL(B.CODE_NM1
					  	             , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
							            	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
							            ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
								    END) ASC) AS SEQ
			                FROM BI_EUR_LP_HAN_RAW A
					LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B 
					  ON SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1) = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
                                         AND SUBSTR(UPPER(TRIM(SEGMENT)),1,1) <> 'L'
			               WHERE 1=1
			                 AND UPPER(DECODE(A.SEASON,'All Season','All Weather',A.SEASON)) = UPPER(C1.SEASON)
			                 AND UPPER(CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END) = (C1.LINE)
			                 AND NVL(A.XL,' ') = NVL(C1.XL,' ')
			                 AND TO_NUMBER(NVL(B.CODE_NM1
							 , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
								ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
								END)) < TO_NUMBER(C1.SPEED_GRADE)
			                 AND A.WIDTH||'/'||A.SERIES||'R'||A.INCH = C1.SIZE2
                                       GROUP BY A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
						CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						     	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
						     ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
						     END||DECODE(A.XL,'XL',' '||A.XL)
		 			      , NVL(B.CODE_NM1,CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									       		CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
									       ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
									       END))
			      WHERE 1=1
				AND SEQ = '1')
	 WHERE 1=1
	   AND UPPER(A.SEASON) = UPPER(C1.SEASON)
	   AND UPPER(A.LINE) = (C1.LINE)
	   AND A.SIZE2 = C1.SIZE2
	   AND A.ZSPEED = C1.ZSPEED
	   AND NVL(A.XL,' ') = NVL(C1.XL,' '); 
  END LOOP;	

  FOR C1 IN ( -- 4순위 LOOP ( XL 구분자도 다르고, 속도가 낮은 것 중 EUROPOOL SPEED GRADE와 가까운 SIZE)
    SELECT A.SEASON
	 , A.LINE
	 , A.SIZE2
	 , A.ZSPEED
	 , A.XL
	 , NVL(B.CODE_NM1,A.ZSPEED) AS SPEED_GRADE
      FROM BI_DM_EUR_SIZE_MAPPING_LIST A
      LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B ON A.ZSPEED = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
     WHERE 1=1
       AND A.HAN_SIZE IS NULL
       AND A.ZSPEED <> 'ERR'
    )
  LOOP
	UPDATE BI_DM_EUR_SIZE_MAPPING_LIST A
	   SET A.HAN_SIZE = (SELECT ZSIZE
	                       FROM ( SELECT A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
					     CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						  	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
					          ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1) --LTR은 LOAD INDEX로 SIZE 생성
					          END||DECODE(XL,'XL',' '||A.XL) AS ZSIZE
					   , ROW_NUMBER() OVER (
						  ORDER BY NVL(B.CODE_NM1
					  	             , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
							            	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
							            ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1)
								    END) ASC) AS SEQ
			                FROM BI_EUR_LP_HAN_RAW A
					LEFT OUTER JOIN BI_GERPUSER.BI_DM_COMMON_CODE B 
					  ON SUBSTR(SUBSTR(REPLACE(REPLACE(LI_SS,'(',''),')',''),-1,1),-1,1) = B.CODE1 AND B.GROUP_CD = 'EUROPOOL_SPEED_GRADE'
                                         AND SUBSTR(UPPER(TRIM(SEGMENT)),1,1) <> 'L'
			               WHERE 1=1
			                 AND UPPER(DECODE(A.SEASON,'All Season','All Weather',A.SEASON)) = UPPER(C1.SEASON)
			                 AND UPPER(CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END) = (C1.LINE)
			                 AND NVL(A.XL,' ') <> NVL(C1.XL,' ')
			                 AND TO_NUMBER(NVL(B.CODE_NM1
							 , CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
								ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
								END)) < TO_NUMBER(C1.SPEED_GRADE)
			                 AND A.WIDTH||'/'||A.SERIES||'R'||A.INCH = C1.SIZE2
                                       GROUP BY A.WIDTH||'/'||A.SERIES||'R'||A.INCH||
						CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
						     	CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
						     ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
						     END||DECODE(A.XL,'XL',' '||A.XL)
		 			      , NVL(B.CODE_NM1,CASE WHEN (CASE WHEN SUBSTR(UPPER(TRIM(A.SEGMENT)),1,1) = 'L' THEN 'LTR' ELSE 'PCR' END ) = 'LTR' THEN 
									       		CASE WHEN INSTR(A.LI_SS,'/') = 0 THEN SUBSTR(A.LI_SS,1,LENGTH(A.LI_SS)-1) ELSE SUBSTR(A.LI_SS,1,INSTR(A.LI_SS,'/')-1) END
									       ELSE SUBSTR(SUBSTR(REPLACE(REPLACE(A.LI_SS,'(',''),')',''),-1,1),-1,1)
									       END))
			      WHERE 1=1
				AND SEQ = '1')
	 WHERE 1=1
	   AND UPPER(A.SEASON) = UPPER(C1.SEASON)
	   AND UPPER(A.LINE) = (C1.LINE)
	   AND A.SIZE2 = C1.SIZE2
	   AND A.ZSPEED = C1.ZSPEED
	   AND NVL(A.XL,' ') = NVL(C1.XL,' '); 
  END LOOP;	

COMMIT;

PROC_SET_LOG( PV_PGM_NAME         => 'PROC_BI_DM_EUR_SIZE_MAPPING_LIST'
            , PD_DT               => SYSDATE
            , PN_RESULT_CNT       =>  VN_CNT
            , PV_RESULT           => 'SUCCESS'
            , PV_STATUS           => 'END'
            , PV_ERR_CODE         =>  NULL
            , PV_ERR_MSG          =>  NULL
            , PV_REMARKS          =>  NULL
             ) ;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
    RAISE_APPLICATION_ERROR(-20200, SQLERRM) ;
END;
