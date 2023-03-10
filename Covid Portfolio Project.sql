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
-- Commented out the aggregate function. Error encountered Msg 8134, Level 16, State 1, Line 90. Divide by zero error encountered.


SELECT date, SUM(new_cases), SUM(new_deaths) --,(SUM(new_deaths) / SUM(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
AND new_deaths IS NOT NULL
AND new_cases IS NOT NULL
GROUP BY date
ORDER BY 1, 2 DESC;

--SELECT *
FROM CovidVaccinations;

--JOIN  the 2 tables 

SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Did a rolling count (it adds up every entry (row) of vaccinations and gives you the total) of 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
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
SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
--,(RollingPeopleVaccinated / population) --You'll get an error cos u can't use an alias to do a calc, rather use a cte or temptable
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;
)
SELECT *, (RollingPeopleVaccinated/population) * 100
FROM PopVsVac;

--You can also use a temptable instead of a CTE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
--,(RollingPeopleVaccinated / population) --You'll get an error cos u can't use an alias to do a calc, rather use a cte or temptable
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/population) * 100
FROM #PercentPopulationVaccinated;

--CREATE MULTIPLE VIEWS

--Create View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollinPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

--View for total deaths in each country

CREATE VIEW TotalDeathPerCountry AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE location IS NOT NULL
--WHERE continent LIKE 'Africa'
GROUP BY location
--ORDER BY TotalDeathCount DESC;

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