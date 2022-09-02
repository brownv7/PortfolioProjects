SELECT *
FROM CovidDeaths
WHERE continent is not null
order by 3,4
--Can change all below to location to continent
--SELECT *
--FROM CovidVaccinations
--order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
order by 1,2

--#Looking at Total Cases vs. Total Deaths
--#Shows liklihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths

--Looking at Total Cases vs, Population
--Shows what persentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location like '%states%'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	   MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
--WHERE location like '%states%'
GROUP BY location
ORDER BY TotalDeathCount desc


--Breakdown by Continent

--SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
--FROM CovidDeaths
--WHERE continent is null
----WHERE location like '%states%'
--GROUP BY location
--ORDER BY TotalDeathCount desc

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
--WHERE location like '%states%'
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global Numbers

SELECT date, SUM(new_cases) as totl_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100
		AS DeathPercentage--total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT  SUM(new_cases) as totl_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100
		AS DeathPercentage--total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(cast(vac.new_vaccinations as int)) --SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location,
		dea.date) AS RollingPeopleVacccinated 
		,--(RollingPeopleVacccinated/population)*100--cannot use newly created column in equation must use CTE or Temp Table. 
		--See Below
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3--cannot be used in CTE

--USE CTE

WITH POPvsVAC (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
--column names must be the same
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(cast(vac.new_vaccinations as int)) --SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location,
		dea.date) AS RollingPeopleVaccinated 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM POPvsVAC

--TEMP TABLE

DROP TABLE IF exists  #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(cast(vac.new_vaccinations as int)) --SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location,
		dea.date) AS RollingPeopleVaccinated 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visulizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(cast(vac.new_vaccinations as int)) --SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location,
		dea.date) AS RollingPeopleVaccinated 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated
