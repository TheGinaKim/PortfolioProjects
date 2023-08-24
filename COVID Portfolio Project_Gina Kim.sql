
/* COVID DEATHS EXPLORATION- PORTFOLIO PROJECT- GK
DATA SET found on https://ourworldindata.org/covid-deaths
*/

SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

--SELECT * 
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4;

--SELECT Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2;

--Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (try_convert(float,(total_deaths))* 100 / try_convert(float,(total_cases))) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2;


--Looking at Total Cases vs Total Deaths in the United States
--Shows the likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (try_convert(float,(total_deaths))* 100 / try_convert(float,(total_cases))) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%' AND continent is not null
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (try_convert(float,(total_cases))* 100 / population) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1,2;


--Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (try_convert(float, (MAX(total_cases)))* 100 / population) AS HighestPercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestPercentPopulationInfected DESC;


-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY HighestDeathCount DESC;


-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC;

--SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount
--FROM PortfolioProject.dbo.CovidDeaths
----WHERE location like '%states%'
--WHERE continent is null
--GROUP BY location
--ORDER BY HighestDeathCount DESC;


-- GLOBAL NUMBERS
SELECT /*date,*/ SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100) AS GlobalDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
/*GROUP BY date*/
ORDER BY 1,2;

--SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) * 100 / SUM(new_cases)) AS GlobalDeathPercentage
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE continent is not null
--GROUP BY date
--ORDER BY 1,2;



-- JOINING Covid.Vaccinations TABLE TO Covid.Deaths TABLE
SELECT * 
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;


--ROLLING COUNT OF vac.new_vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location)
--FROM PortfolioProject.dbo.CovidDeaths dea
--JOIN PortfolioProject.dbo.CovidVaccinations vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3;


--Going back and looking at Total Population vs Vaccinations...
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- USING CTE TO CREATE A TEMP TABLE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;


-- TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;



-- Creating View to Store Data for Later Visualizations

USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
;

SELECT *
FROM PercentPopulationVaccinated;