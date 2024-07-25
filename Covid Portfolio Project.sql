--SQL Portfolio Project

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4; --Remember this means column number, which is the same as mentioning column name

SELECT *
FROM CovidVaccinations
ORDER BY 3,4;


-- Get familiar with the data B

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

--ALTER COLUMNS DATA TYPES

ALTER TABLE CovidDeaths
ALTER COLUMN hosp_patients_per_million INT;

--Total Cases vs Total Deaths

SELECT location, date, total_cases , total_deaths AS int, (total_deaths/total_cases) * 100 AS Death_Percentage
FROM CovidDeaths
WHERE location LIKE '%South Africa%'
ORDER BY 1,2 DESC;


--Total cases vs total population
--Shows what percentage of population got Covid

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS Percentageinfectionrate
FROM CovidDeaths
--WHERE location LIKE '%South Africa%'
ORDER BY 1,2 DESC;



--Which countries have the highest infection rate per population

SELECT location, population, MAX (total_cases) AS HighestInfectionCount,
MAX ((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location LIKE 'South Africa'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--Which CONTINENT has the highest infection rate per population

SELECT continent, population, MAX (total_cases) AS HighestInfectionCount,
MAX ((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location LIKE 'South Africa'
GROUP BY continent, population
ORDER BY PercentPopulationInfected DESC;

--How many people died from Covid, highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


--How many people died from Covid, highest death count per population per CONTINENT

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Break things down by continent

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
--WHERE continent LIKE 'Africa'
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-- Global Numbers

SELECT date, SUM(new_cases), SUM(CAST(new_deaths AS INT)), (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
AND new_deaths IS NOT NULL
AND new_cases IS NOT NULL
GROUP BY date
ORDER BY 1, 2 DESC;
 
 --
 SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100 AS DeathPercentage
 FROM CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1,2;


--JOIN  the 2 tables 

SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

--total population vs vaccinations (remember u have to specify where u're getting the col from if it exists in both tables)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- PARTION BY
--Did a rolling count (it adds up every entry (row) of vaccinations and gives you the total) of 
--breaking it up by location, everytime it gets to a new location it needs to start over
--Order by date so that it uses that to separate the result out
--Used the convert function here, works the same as the cast function

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated / population) --You'll get an error cos u can't use an alias to do a calc, rather use a cte or temptable
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


--Use a CTE to get a total percentage population that are vaccinated 
--The num of columns in ur cte has to be same as the ones in your select statement
--

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
--,(RollingPeopleVaccinated / population) --You'll get an error cos u can't use an alias to do a calc, rather use a cte or temptable
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3; -- can't include this
)
SELECT *, (RollingPeopleVaccinated/population) * 100
FROM PopVsVac;

--You can also use a temptable instead of a CTE

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations int,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --Changed into to bigint
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;


--CREATE MULTIPLE VIEWS 

--Create View to store data for later visualizations in Tableau later or PowerBI

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

--You could run this script or go to the view in object explorer & select top1000 rows
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [continent]
      ,[location]
      ,[date]
      ,[population]
      ,[new_vaccinations]
      ,[RollinPeopleVaccinated]
  FROM [PortfolioProject].[dbo].[PercentPopulationVaccinated]

--View for total deaths in each country

CREATE VIEW TotalDeathPerCountry AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE location IS NOT NULL
--WHERE continent LIKE 'Africa'
GROUP BY location
--ORDER BY TotalDeathCount DESC;

-- 
SELECT * 
FROM TotalDeathPerCountry;

--View for showing 

CREATE VIEW PercentPopulationDeaths AS
SELECT dea.continent, dea.location, dea.date, dea.population, dea.total_deaths,
SUM (dea.total_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleDied
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollinPeopleDied/population) * 100
FROM PercentPopulationDeaths;
