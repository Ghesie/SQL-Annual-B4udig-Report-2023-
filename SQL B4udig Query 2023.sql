Select *
From b4udigData2023..New_B4udig_Nikko

Select *
From b4udigData2023..New_B4udig_Ghesie

Select *
From b4udigData2023..New_B4udig_Russel

Select *
From b4udigData2023..New_B4udig_David


-- TOTAL B4UDIG OUTPUT (Union 4 tables)

Select Ghes.Name, Ghes.SiteName, Ghes.Status, Ghes.JO, Ghes.Date, Ghes.Location
From b4udigData2023..New_B4udig_Ghesie as Ghes
Where Name Is Not Null

UNION ALL

Select Nik.Name, Nik.SiteName, Nik.Status, Nik.JO, Nik.Date, Nik.Location
From b4udigData2023..New_B4udig_Nikko as Nik
Where Name Is Not Null

UNION ALL

Select Rus.Name, Rus.SiteName, Rus.Status, Rus.JO, Rus.Date, Rus.Location
From b4udigData2023..New_B4udig_Russel as Rus
Where Name Is Not Null

UNION ALL

Select Dav.Name, Dav.SiteName, Dav.Status, Dav.JO, Dav.Date, Dav.Location
From b4udigData2023..New_B4udig_David as Dav
Where Name Is Not Null

ORDER BY Date



-- Create Temp Table for TOTAL B4UDIG OUTPUT

DROP TABLE IF EXISTS #Temp_TotalB4udigOutput

Create Table #Temp_TotalB4udigOutput
(
Name nvarchar(255),
SiteName nvarchar(255),
Status nvarchar(255),
JO float,
Date datetime,
Location nvarchar(255)
)

Insert Into #Temp_TotalB4udigOutput
Select Ghes.Name, Ghes.SiteName, Ghes.Status, Ghes.JO, Ghes.Date, Ghes.Location
From b4udigData2023..New_B4udig_Ghesie as Ghes
Where Name Is Not Null

UNION ALL

Select Nik.Name, Nik.SiteName, Nik.Status, Nik.JO, Nik.Date, Nik.Location
From b4udigData2023..New_B4udig_Nikko as Nik
Where Name Is Not Null

UNION ALL

Select Rus.Name, Rus.SiteName, Rus.Status, Rus.JO, Rus.Date, Rus.Location
From b4udigData2023..New_B4udig_Russel as Rus
Where Name Is Not Null

UNION ALL

Select Dav.Name, Dav.SiteName, Dav.Status, Dav.JO, Dav.Date, Dav.Location
From b4udigData2023..New_B4udig_David as Dav
Where Name Is Not Null

ORDER BY Date


Select *
From #Temp_TotalB4udigOutput

Select Name as Team_Member, Count(JO) as B4udig_Request, Date
From #Temp_TotalB4udigOutput
Group By Name, Date

--1: Total B4udig Request Per Person on year 2023 (DONE)

Select Name as Team_Member, DATEPART(Year, Date) as Year, COUNT(JO) as Total_Output
From #Temp_TotalB4udigOutput
GROUP BY Name, DATEPART(Year, Date)


--2: Showing the monthly b4udig request of each member

--2.1: Creating a Temp table of monthly b4udig request for future reference (Step 1)
DROP TABLE IF EXISTS #Temp_TrialTable

Create Table #Temp_TrialTable
(
Name nvarchar(255),
Month nvarchar(255),
Monthly_B4udig_Request int
)

Insert into #Temp_TrialTable
Select Name, DATENAME(Month, Date) as Month, COUNT(JO) as Monthly_B4udig_Request
From #Temp_TotalB4udigOutput

Group By Name, DATENAME(Month, Date)
Order By Name, DATENAME(Month, Date)


Select *
From #Temp_TrialTable
Order By Name

--2.2: Showing Monthly B4udig Request per member (FINAL)
Select *
From 
 (
   Select Name as TeamMember, Month, Monthly_B4udig_Request
   From #Temp_TrialTable
 ) as SourceTable PIVOT(AVG(Monthly_B4udig_Request) For Month in (January,February,March,April,May,June,July,August,September,October,November,December)) as PivotTable;



--3: Showing the average monthly b4udig request of each team member

Select Name as Team_Member, AVG(Monthly_B4udig_Request) as Average_Monthly_B4udig_Request
From #Temp_TrialTable
Group by Name



--4: Average B4uig Request of each team member daily
With CTE_Requests as
(
Select Name as TeamMember,Date, Count(JO) AS Request
From #Temp_TotalB4udigOutput
Group by Name, Date
)

Select TeamMember, AVG(Request) AS Daily_Average
From CTE_Requests
Group by TeamMember

--5: Total B4udig Reuest of the Team on year 2023

Select DATEPART(Year, Date) as Year, Count(JO) as Total_B4udig_Request
FRom #Temp_TotalB4udigOutput
Group by DATEPART(Year, Date)

--6: Completion rate of B4udig Request Per Person

	--6.1: Create TempTable for b4udig request with complete plans

DROP TABLE IF EXISTS #Temp_Completed
Create Table #Temp_Completed
(
Team_Member nvarchar(255),
Request_With_Complete_Plans int,
)

Insert into #Temp_Completed
select Name as Team_Member, Count(Status) as Request_With_Complete_Plans
FROM #Temp_TotalB4udigOutput
WHERE Status='Completed'
GROUP by Name

	--6.2: Create TempTable for b4udig request with pending plans

DROP TABLE IF EXISTS #Temp_Pending
Create Table #Temp_Pending
(
Team_Member nvarchar(255),
Request_With_Pending_Plans int,
)
Insert Into #Temp_Pending
Select Name as Team_Member, Count(Status) as Request_With_Pending_Plans
FROM #Temp_TotalB4udigOutput
WHERE Status='Pending'
GROUP by Name

	--6.3: Create TempTable for total b4udig requests

DROP TABLE IF EXISTS #Temp_Total_Output
Create Table #Temp_Total_Output
(
Team_Member nvarchar(255),
Total_B4udig_Request int
)

Insert Into #Temp_Total_Output
Select Name as Team_Member, COUNT(JO) as Total_B4udig_Request
From #Temp_TotalB4udigOutput
GROUP BY Name, DATEPART(Year, Date)

	--6.4: Use CTE to Join the 3 tables to compute the completion rate of each members (FINAL OUTPUT)

With CTE_CompletionRate as 
(
Select #Temp_Completed.Team_Member, Request_With_Complete_Plans, Request_With_Pending_Plans, Total_B4udig_Request
From #Temp_Completed
JOIN #Temp_Pending on #Temp_Completed.Team_Member = #Temp_Pending.Team_Member
JOIN #Temp_Total_Output on #Temp_Completed.Team_Member = #Temp_Total_Output.Team_Member
)

Select *, CAST(Request_With_Complete_Plans AS DECIMAL) / (SUM(CAST(Request_With_Complete_Plans AS DECIMAL) + CAST(Request_With_Pending_Plans AS DECIMAL)))*100 as Completion_Rate
From CTE_CompletionRate
Group By Team_Member, Request_With_Complete_Plans, Request_With_Pending_Plans, Total_B4udig_Request


-- Completion Rate of B4udig Request of the Team
