/* As continent names are listed in both column continent & location, remove continents (asia, africa, etc.) in column location where 
values in column continent are null, as well as uncomparable values such as income classes (low, medium, high), world, international. */


-- 1)
--Display the percent of total deaths and total cases 
USE Covid_Portfolio
GO
DROP TABLE IF EXISTS Overall_statistics
CREATE TABLE Overall_statistics
(
Total_cases numeric, 
Total_death numeric, 
Death_percentage float
) 

INSERT INTO Overall_statistics
--Column new_cases & new_deaths represent new cases & new deaths per day
SELECT SUM(CAST(new_cases as float)) as Total_cases, SUM(CAST(new_deaths as float)) as Total_deaths, 
SUM(CAST(new_deaths as float))/SUM(new_cases) as Death_rate
FROM Covid_Portfolio..CovidDeaths
WHERE continent is not null



-- 2)
--Convert empty spaces into null values
UPDATE Covid_Portfolio..CovidDeaths
SET continent=NULL
WHERE continent=''

--Display the number of deaths for each continent
USE Covid_Portfolio
GO
DROP TABLE IF EXISTS Total_death_count
CREATE TABLE Total_death_count
(
location nvarchar(255),
population nvarchar(255),
Death_count numeric
)

INSERT INTO Total_death_count
--Column total_deaths represents total deaths per day
SELECT location, population, MAX(CAST(total_deaths as int)) as Death_count
FROM Covid_Portfolio..CovidDeaths
WHERE continent is null
and location not in ('Upper middle income','High income','Lower middle income','Low income','World','European Union','International')
GROUP BY location, population
ORDER BY 3 desc



--3)
--Display new cases per day and new deaths per day
USE Covid_Portfolio
GO
DROP TABLE IF EXISTS New_cases_deaths
CREATE TABLE New_cases_deaths
(
Date datetime,
New_cases numeric,
New_deaths numeric,
Cumulative_cases numeric,
Cumulative_deaths numeric
);

WITH CTE_cases_deaths (date, new_cases, new_deaths)
AS
(
SELECT date, SUM(new_cases) as newcases, SUM(CAST(new_deaths as float)) as newdeaths
FROM Covid_Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY date
)

INSERT INTO New_cases_deaths
SELECT *, 
SUM(new_cases) OVER (ORDER BY date) as Cumulative_cases,
SUM(CAST(new_deaths as float)) OVER (ORDER BY date) as Cumulative_deaths
FROM CTE_cases_deaths



--4)
-- Display the highest case number and infection rate for each location
USE Covid_Portfolio
GO
DROP TABLE IF EXISTS Infection_table
CREATE TABLE Infection_table
(
Location nvarchar(255), 
Highest_Infection_Num float,
Infection_rate float,
Infection_rate_cat nvarchar(255)
);

WITH Infection (Location, Highest_Infection_num, Infection_rate)
AS 
(
SELECT location, MAX(total_cases) as Highest_Infection_Num, MAX((total_cases/population))*100 as Infection_rate
FROM Covid_Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY location
)

-- Display infection levels based on infection rates 
INSERT INTO Infection_table
Select *,
CASE
	WHEN Infection_rate < 20 THEN 'LOW'
	WHEN Infection_rate < 30 THEN 'MED'
	WHEN Infection_rate > 30 THEN 'HIGH'
END AS Infection_rate_cat
FROM Infection



--5)
-- Display cumulative vaccinations of each location and the percent of cumulative vaccinations
UPDATE Covid_Portfolio..CovidVaccinations
SET new_vaccinations=NULL
WHERE new_vaccinations=''

USE Covid_Portfolio
GO
DROP TABLE IF EXISTS Percent_Population_Vaccinated
Create Table Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations float,
Cumulative_vaccinations numeric,
Cumulative_vaccination_percent float
);

WITH Vaccination_table (Continent, Location, Date, Population, New_vaccinations, Cumulative_vaccinations)
AS
(
SELECT De.continent, De.location, De.date, De.population, Va.new_vaccinations, 
SUM(CAST(Va.new_vaccinations as float)) OVER (PARTITION BY Va.location ORDER BY Va.location, Va.date) AS Cumulative_vaccinations
FROM Covid_Portfolio..CovidDeaths De
JOIN Covid_Portfolio..CovidVaccinations Va
	ON De.location=Va.location
	and De.date=Va.date
WHERE De.continent is not null
)

INSERT INTO Percent_Population_Vaccinated
SELECT *, ROUND((Cumulative_vaccinations/Population)*100, 2) as Cumulative_vaccination_percent
FROM Vaccination_table
        


