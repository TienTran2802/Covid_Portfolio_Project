--as continents are listed in column location, remove locations that are continents (asia, africa, etc.), income classes(low,medium,high), world in column location


--Display the percent of total deaths and total cases in locations including letters 'ia'
SELECT location, population, date, total_deaths, total_cases, (total_deaths/total_cases)*100 as Death_Percentage
FROM Covid_Portfolio..CovidDeaths
WHERE location like '%ia'
and continent is not null
ORDER BY 5 desc


--Convert empty spaces into null values
UPDATE Covid_Portfolio..CovidDeaths
SET continent=NULL
WHERE continent=''
--Convert total_deaths from nvarchar to int
SELECT location, population, MAX(CAST(total_deaths as int)) as Death_num
FROM Covid_Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 3 desc


--Display new cases per day and new deaths per day
SELECT date, SUM(new_cases) as Case_num_per_day, SUM(CAST(new_deaths as int)) as Death_num_per_day
FROM Covid_Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2 desc


-- Display the highest case number and infection rate for each location
With Infection (Location, Population, Highest_Infection_num, Infection_rate)
as 
(
SELECT location, population, MAX(total_cases) as Highest_Infection_Num, MAX((total_cases/population))*100 as Infection_rate
FROM Covid_Portfolio..CovidDeaths
--In the SQL GROUP BY clause, we can use a column in the select statement if it is used in Group by clause as well. 
WHERE continent is not null
GROUP BY location, population
)
SELECT *,
CASE
	WHEN Infection_rate < 20 THEN 'LOW'
	WHEN Infection_rate < 30 THEN 'MED'
	WHEN Infection_rate > 30 THEN 'HIGH'
END AS Infection_rate_cat
FROM Infection


----Convert empty spaces into null values
UPDATE Covid_Portfolio..CovidVaccinations
SET new_vaccinations=NULL
WHERE new_vaccinations=''
-- Display cumulative vaccinations of each location and the percent between cumulative vaccination and population
With POPVAC (Continent, Location, Date, Population, New_vaccinations, Cumulative_vaccinations)
as
(
SELECT De.continent, De.location, De.date, De.population, Va.new_vaccinations, 
SUM(CAST(Va.new_vaccinations as float)) OVER (Partition by Va.location ORDER BY Va.location, Va.date) AS Cumulative_Vaccinations
FROM Covid_Portfolio..CovidDeaths De
JOIN Covid_Portfolio..CovidVaccinations Va
	ON De.location=Va.location
	and De.date=Va.date
WHERE De.continent is not null
)
SELECT *, (Cumulative_vaccinations/Population)*100 as Vac_percent
FROM POPVAC


-- Display TEMPT TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Cumulative_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT De.continent, De.location, De.date, De.population, Va.new_vaccinations, 
SUM(CAST(Va.new_vaccinations as float)) OVER (Partition by Va.location ORDER BY Va.location, Va.date) AS Cumulative_Vaccinations
FROM Covid_Portfolio..CovidDeaths De
JOIN Covid_Portfolio..CovidVaccinations Va
	ON De.location=Va.location
	and De.date=Va.date
WHERE De.continent is not null

SELECT *, (Cumulative_vaccinations/Population)*100 as Vac_percent
FROM #PercentPopulationVaccinated

--Create View to store data for later visualizations
USE Covid_Portfolio
GO
Create View PercentPopulationVaccinated as
SELECT De.continent, De.location, De.date, De.population, Va.new_vaccinations, 
SUM(CAST(Va.new_vaccinations as float)) OVER (Partition by Va.location ORDER BY Va.location, Va.date) AS Cumulative_Vaccinations
FROM Covid_Portfolio..CovidDeaths De
JOIN Covid_Portfolio..CovidVaccinations Va
	ON De.location=Va.location
	and De.date=Va.date
WHERE De.continent is not null

