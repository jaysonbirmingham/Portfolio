--SELECT *
--FROM PortfolioProject1..CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject1..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs. total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject1..CovidDeaths
WHERE COALESCE(total_cases, total_deaths) IS NOT NULL
	AND location LIKE '%states%'
ORDER BY 1,2

-- Looking at total cases vs. population

SELECT location, date, population, total_cases, (total_cases/population)*100 as population_percentage
FROM PortfolioProject1..CovidDeaths
WHERE COALESCE(total_cases, population) IS NOT NULL
	AND location LIKE '%states%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared with population

SELECT location, population, MAX(total_cases) AS max_cases, MAX((total_cases/population)) * 100 AS percent_infected
FROM PortfolioProject1..CovidDeaths
WHERE population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Looking at countries with highest death rate compared with population

SELECT location, population, MAX(total_deaths) AS max_deaths, MAX((total_deaths/population))*100 AS percent_death
FROM PortfolioProject1..CovidDeaths
WHERE population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;

-- EXPLORING DATA BY CONTINENT

SELECT continent, cd.continent_population, cd.continent_deaths, cd.continent_deaths/cd.continent_population * 100 AS percent_death
FROM (SELECT DISTINCT continent,
		SUM(MAX(population)) 
			OVER (PARTITION BY continent ORDER BY continent) AS continent_population,
		SUM(MAX(CAST(total_deaths AS INT))) 
			OVER (PARTITION BY continent ORDER BY continent) AS continent_deaths
	FROM PortfolioProject1..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location) AS cd
ORDER BY 4 DESC;


-- Global Calculations

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS death_percentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL;

-- Vaccinations: TOTAL POPULATION VS. VACCINATION

WITH popvac AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_sum
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND COALESCE(dea.population, vac.new_vaccinations) IS NOT NULL
	AND dea.population IS NOT NULL
)
SELECT *, rolling_vaccine_sum/population * 100 AS vaccination_percent
FROM popvac
WHERE location LIKE '%states%'
ORDER BY 2,3;


-- TEMP TABLE

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccine_sum numeric
)
INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_sum
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND COALESCE(dea.population, vac.new_vaccinations) IS NOT NULL
	AND dea.population IS NOT NULL

SELECT *, rolling_vaccine_sum/population * 100 AS vaccination_percent
FROM #percent_population_vaccinated
WHERE location LIKE '%states%'
ORDER BY 2,3;

-- Creating view for later data visualizations

CREATE VIEW subqueryvaccination AS
WITH popvac AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_sum
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND COALESCE(dea.population, vac.new_vaccinations) IS NOT NULL
	AND dea.population IS NOT NULL
)
SELECT *, rolling_vaccine_sum/population * 100 AS vaccination_percent
FROM popvac
WHERE location LIKE '%states%'
