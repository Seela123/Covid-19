--1.How many lines does the dataset have?

SELECT COUNT(*) FROM covid_deaths

SELECT COUNT(*) FROM covid_deaths

--2.Exploring some important columns of the dataset covid.deaths.csv

SELECT continent,location,total_cases,new_cases,total_deaths FROM covid_deaths

SELECT continent,location,new_tests,total_tests,people_fully_vaccinated,population_density
FROM covid_vaccination

--3.Checking for duplicate values

SELECT location,date,COUNT(*)
FROM covid_deaths
GROUP BY location,date
HAVING COUNT(*) > 1

--4.Checking the quantity of continents and countries

SELECT continent,count(continent) AS TOTAL_CONTINENT
FROM covid_deaths
GROUP BY continent

SELECT location,COUNT(location) as TOTAL_LOCATION 
FROM covid_deaths
GROUP BY location

--5.Average number of deaths by day (Continents and Countries)

SELECT CAST(avg(total_deaths) AS INT) AS deaths,continent,date
FROM covid_deaths
GROUP BY CAST(total_deaths AS INT),continent,date

SELECT AVG(total_deaths)AS count_deaths,location,date
FROM covid_deaths
GROUP BY location,date

--6.Average of cases divided by the number of population of each country (TOP 10)

SELECT TOP 10 CAST(location AS nvarchar(50)) as continent,AVG(CAST(total_cases AS float))/avg(population)*100 AS divided_contry
FROM covid_deaths
GROUP BY location
ORDER BY  divided_contry DESC

--7.Considering the highest value of total cases, which countries have the highest rate of infection in relation to population?

SELECT location, MAX(total_cases) AS total_cases,population, (round(max(total_cases)/max(population),4))*100 as PERCENT_TOTAL
FROM covid_deaths
WHERE location <> 'world' 
AND location <> 'asia' 
AND location <> 'Europe' AND location <> 'north america'
AND location <> 'united states'
AND location <> 'south america'
AND location <> 'european union'
GROUP BY population, location,(population/total_cases)*100
ORDER BY total_cases DESC;

--8.Countries with the highest number of deaths

SELECT location,COUNT(total_deaths) AS total_deaths
FROM covid_deaths
WHERE location <> 'world' 
AND location <> 'asia' 
AND location <> 'Europe' AND location <> 'north america'
AND location <> 'united states'
AND location <> 'south america'
AND location <> 'european union'
GROUP BY location
ORDER BY total_deaths DESC

--9.Continents with the highest number of deaths

SELECT continent,COUNT(total_deaths) AS total_deaths 
FROM covid_deaths
GROUP BY continent
ORDER BY total_deaths DESC

--10.Number of new vaccinated and rolling average of new vaccinated over time by country on the European continent

SELECT continent, new_tests, AVG(new_vaccinations_smoothed) AS new_vaccinations_smoothed
FROM covid_vaccination
WHERE continent = 'europe' 
AND new_vaccinations_smoothed IS NOT NULL
GROUP BY new_tests,continent


--11.-- JOINING THE TWO TABLES TOGETHER FOR VIEWING

SELECT covid_deaths.location,population,total_cases,total_vaccinations,new_tests FROM covid_deaths
FULL JOIN covid_vaccination
ON total_deaths = total_cases
WHERE total_vaccinations IS NOT NULL
AND new_tests IS NOT NULL

CREATE VIEW VI_COVID19 AS (
SELECT covid_deaths.location,population,total_cases,total_vaccinations,new_tests FROM covid_deaths
FULL JOIN covid_vaccination
ON total_deaths = total_cases
WHERE total_vaccinations IS NOT NULL
AND new_tests IS NOT NULL)

SELECT * FROM VI_COVID19

--12. LOOKING AT THE TOTAL POPULATION VS VACCINATIONS
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT COUNT(covid_deaths.location),covid_deaths.location, population,total_vaccinations,ROUND((total_vaccinations/population*100),2) AS TOTAL_PERCENT FROM covid_deaths
FULL JOIN covid_vaccination
ON total_deaths = total_cases
WHERE total_vaccinations IS NOT NULL
AND population IS NOT NULL
GROUP BY population,total_vaccinations,ROUND((total_vaccinations/population*100),2),covid_deaths.location 


--13. Getting the percentage of RollingPeopleVaccinated for each location

-- Using CTE to perform Calculation on Partition By in previous query


DROP TABLE #POPVAC


WITH popvsvac  AS (
    SELECT 
        cd.location,cd.continent,population,cd.date,new_vaccinations,
        SUM(cv.total_tests) OVER (PARTITION BY cd.population) AS RollingPeopleVaccinated
    FROM 
        covid_deaths cd
    JOIN 
        covid_vaccination cv ON cd.continent = cv.continent
)


CREATE TABLE #POPVAC (
    location VARCHAR(100),
    continent VARCHAR(100),
    population FLOAT,
    date DATE,
    new_vaccinations FLOAT,
    RollingPeopleVaccinated FLOAT
	);

DROP TABLE  #POPVAC
INSERT INTO #POPVAC 
    SELECT TOP 200 
        cd.location,cd.continent,population,cd.date,new_vaccinations,
        SUM(cv.total_tests) OVER (PARTITION BY cd.population) AS RollingPeopleVaccinated
    FROM 
        covid_deaths cd
    JOIN 
        covid_vaccination cv ON cd.continent = cv.continent

SELECT top 200 *,(population/RollingPeopleVaccinated)*100 AS TOTAL_PERCENT FROM popvsvac
WHERE population IS NOT NULL
AND new_vaccinations IS NOT NULL

SELECT * FROM #POPVAC