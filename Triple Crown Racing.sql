CREATE DATABASE TripleCrown;
GO

Use TripleCrown;
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Races]') AND type in (N'U'))
DROP TABLE [dbo].Races
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TrackConditions]') AND type in (N'U'))
DROP TABLE [dbo].TrackConditions
GO

CREATE TABLE Races (
    final_place INT,
    PP VARCHAR(10),
    Horse VARCHAR(50),
    Jockey VARCHAR(50),
    Trainer VARCHAR(50),
    Odds FLOAT NULL,  -- Allow NULL values
    Win FLOAT,
    Place FLOAT,
    Show FLOAT,
    year INT,
    race VARCHAR(50)
);

BULK INSERT Races
FROM 'C:\Users\Ihard\Downloads\archive (10)\TripleCrownRaces_2005-2019.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);


CREATE TABLE TrackConditions (
year INT,
high_temp FLOAT,
low_temp FLOAT,
precipitation_24hrs FLOAT,
weather VARCHAR(50),
track_condition VARCHAR(50),
attendance INT,
race VARCHAR(50)
);

BULK INSERT TrackConditions
FROM 'C:\Users\Ihard\Downloads\archive (10)\TrackConditions.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

-- Horse that have won
SELECT Horse, year, race
FROM Races
WHERE final_place = 1
ORDER BY year, race;

-- Horse that won 2 races or more in same year
SELECT Horse, year, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY Horse, year
HAVING COUNT(*) >= 2
ORDER BY WINS DESC;

-- Horses, jockey, trainer that have won the triple crown
SELECT Horse, Jockey, Trainer, year
FROM Races
WHERE final_place = 1 
GROUP BY Horse, Jockey, Trainer, year
HAVING COUNT(*) = 3;

-- list top 5 trainers with most wins
SELECT TOP 5 Trainer, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY trainer
ORDER BY Wins DESC;

-- list of top 10 jockies with most wins
SELECT TOP 10 Jockey, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY jockey
ORDER BY Wins DESC;


-- races on wet vs dry track
SELECT Year, Race,CASE 
WHEN track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END AS Track_Status
FROM TrackConditions
ORDER BY year, race;

-- how many races were done on wet vs dry tracks 
SELECT CASE 
WHEN track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END AS Track_Status, COUNT(*) AS Total_Races
FROM TrackConditions
GROUP BY CASE 
WHEN track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END;

-- track condition for each race and how many were wet vs dry (list of each race + total # on wet, # on dry...)
SELECT Race, CASE 
WHEN track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END AS Track_Status,COUNT(*) AS Total_Races
FROM TrackConditions
GROUP BY race, CASE 
WHEN track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END
ORDER BY race;

-- track condition / if wet or dry when triple crown happened
SELECT T.Year, T.Race, T.Track_Condition, CASE 
WHEN T.track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END AS Track_Status
FROM TrackConditions T JOIN (SELECT year 
							 FROM Races 
							 WHERE final_place = 1 
							 GROUP BY Horse, year
							 HAVING COUNT(*) = 3) AS TripleCrownYears ON T.year = TripleCrownYears.year
ORDER BY T.year, CASE 
WHEN T.race = 'Kentucky Derby' THEN 1 
WHEN T.race = 'Preakness Stakes' THEN 2 
WHEN T.race = 'Belmont Stakes' THEN 3 END;

-- how many of the races were on wet vs dry tracks when triple crown happened
SELECT CASE 
WHEN T.track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END AS Track_Status, COUNT(*) AS Total_Races
FROM TrackConditions T JOIN (SELECT year 
							 FROM Races 
							 WHERE final_place = 1 
							 GROUP BY Horse, year HAVING COUNT(*) = 3) AS TripleCrownYears ON T.year = TripleCrownYears.year
GROUP BY CASE 
WHEN T.track_condition IN ('Sloppy', 'Muddy') THEN 'Wet Track' ELSE 'Dry Track' END;

-- attendance over the years
SELECT year, AVG(attendance) AS Avg_Attendance
FROM TrackConditions
GROUP BY year;

-- Average odd of winning
SELECT AVG(Odds) AS Avg_Winning_Odds
FROM Races
WHERE final_place = 1;

-- How many horses ran in each race
SELECT Year, Race, COUNT(*) AS Total_Horses
FROM Races
GROUP BY year, race
ORDER BY year, CASE 
WHEN race = 'Kentucky Derby' THEN 1
WHEN race = 'Preakness Stakes' THEN 2
WHEN race = 'Belmont Stakes' THEN 3
ELSE 4 END;

-- Number of wins per poll position and their odds
SELECT PP, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY PP
ORDER BY TRY_CAST(PP AS INT);

-- Horses with best odds
SELECT Horse, Race, year, Odds, Jockey, Trainer
FROM Races
WHERE Odds IS NOT NULL
ORDER BY Odds ASC;

-- Horse with highest odd by race and where they placed
SELECT R.Horse, R.Race, R.year, R.Odds, R.final_place, R.Jockey, R.Trainer
FROM Races R
JOIN (
    SELECT race, year, MIN(Odds) AS MinOdds
    FROM Races
    WHERE Odds IS NOT NULL
    GROUP BY race, year
) AS Fav
  ON R.race = Fav.race AND R.year = Fav.year AND R.Odds = Fav.MinOdds
ORDER BY R.year, 
         CASE 
             WHEN R.race = 'Kentucky Derby' THEN 1
             WHEN R.race = 'Preakness Stakes' THEN 2
             WHEN R.race = 'Belmont Stakes' THEN 3
             ELSE 4
         END;

-- Top 5 favoured horses per race
SELECT *
FROM (
    SELECT 
        Horse,
        race,
        year,
        Odds,
        Jockey,
        Trainer,
        ROW_NUMBER() OVER (PARTITION BY race, year ORDER BY Odds ASC) AS Rank
    FROM Races
    WHERE Odds IS NOT NULL
) AS RankedHorses
WHERE Rank <= 3
ORDER BY year, race, Rank;

-- each horse that won, the race, year and pp
SELECT Horse, Race, year, PP
FROM Races
WHERE final_place = 1
ORDER BY year, 
         CASE 
             WHEN race = 'Kentucky Derby' THEN 1
             WHEN race = 'Preakness Stakes' THEN 2
             WHEN race = 'Belmont Stakes' THEN 3
             ELSE 4
         END;

-- top 10 trainers with most wins
SELECT TOP 10 Trainer, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY Trainer
ORDER BY Wins DESC;

-- top 10 jockies with most wins
SELECT TOP 10 Jockey, COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY Jockey
ORDER BY Wins DESC;

-- top 10 most wins for jockey / trainer combination
SELECT TOP 10 
    Jockey, 
    Trainer, 
    COUNT(*) AS Wins
FROM Races
WHERE final_place = 1
GROUP BY Jockey, Trainer

ORDER BY Wins DESC;
