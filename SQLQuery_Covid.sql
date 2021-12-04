-- Exploring the CovidDeaths and CovidVaccinations Tables

SELECT *
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM Portfolio..CovidVaccinations
WHERE continent IS NOT NULL
AND new_vaccinations IS NOT NULL
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Looking at Total Cases VS. Total Deaths
-- Shows likelihood of dying if you contract covid in the United States over time

SELECT 
	location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM 
	Portfolio..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at Total Cases VS. Population
-- Shows the percentage of population contract covid over time

SELECT location, date, population, total_cases, (total_cases/population)*100 AS CovidPersentage
FROM Portfolio..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2


-- Looking at Countries with Highest Infeftion Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM Portfolio..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Let's Break Things Down By Continent - Showing Continents with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global Numbers

SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths as INT)) AS Total_Deaths, SUM(Cast(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2


-- Looking at Total Population VS. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
-- AND dea.location like '%States%'
ORDER BY 2,3

-- USE CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	AND dea.date = vac.date
where dea.continent IS NOT NULL 
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Data datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
	dea.Date) AS RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	AND dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated
WHERE New_vaccinations IS NOT NULL

-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
