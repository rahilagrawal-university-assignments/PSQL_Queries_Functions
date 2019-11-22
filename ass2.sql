-- COMP3311 19T3 Assignment 2
-- Written by Rahil Agrawal - z5165505

-- Q1 Which movies are more than 6 hours long? 

create or replace view Q1(title)
as
select main_title from titles where format = 'movie' and runtime > 360 order by main_title
;


-- Q2 What different formats are there in Titles, and how many of each?

create or replace view Q2(format, ntitles)
as
select format, count(format) from titles group by format order by format
;


-- Q3 What are the top 10 movies that received more than 1000 votes?

create or replace view Q3(title, rating, nvotes)
as
select main_title, rating, nvotes from titles where format = 'movie' and nvotes > 1000 order by rating desc, main_title asc limit 10
;


-- Q4 What are the top-rating TV series and how many episodes did each have?

create or replace view Q4(title, nepisodes)
as
select t.main_title, count(t.main_title) from titles as t inner join episodes e on e.parent_id = t.id where format like 'tv%Series' and rating = (select max(rating) from titles where format like 'tv%Series') group by t.main_title order by t.main_title
;


-- Q5 Which movie was released in the most languages?
create or replace view movieLangs(movie, lang) as select title_id, language from aliases where language is not null group by title_id, language;
create or replace view movieLangCounts(movie, nlangs) as select movie, count(movie) from movieLangs group by movie;
create or replace view Q5(title, nlanguages)
as select main_title, nlangs from titles inner join movieLangCounts on id = movie where nlangs = (select max(nlangs) from movieLangCounts)
;


-- Q6 Which actor has the highest average rating in movies that they're known for?
create or replace view actorHits(actor, avg_rating, hits) as select k.name_id, avg(t.rating), count(k.name_id) from known_for as k inner join titles as t on t.id = k.title_id inner join worked_as as w on k.name_id = w.name_id where t.format = 'movie' and t.rating is not null and w.work_role = 'actor' group by k.name_id;
create or replace view hitActors(actor) as select actor from actorhits where hits >= 2 and avg_rating = (select max(avg_rating) from actorHits where hits>= 2);
create or replace view Q6(name)
as select name from names inner join hitActors on id = actor
;

-- Q7 For each movie with more than 3 genres, show the movie title and a comma-separated list of the genres

create or replace view genreLists(title, genres, totalGenres) as select main_title, STRING_AGG(tg.genre, ',' order by tg.genre) genres, count(t.id) genreCount from titles t inner join title_genres tg on t.id = tg.title_id where t.format = 'movie' group by t.id;
create or replace view Q7(title,genres)
as
select title, genres from genreLists where totalGenres > 3
;

-- Q8 Get the names of all people who had both actor and crew roles on the same movie

create or replace view Q8(name)
as
select n.name from names n inner join actor_roles a on n.id = a.name_id inner join crew_roles c on a.name_id = c.name_id and a.title_id = c.title_id inner join titles t on a.title_id = t.id where t.format = 'movie' group by n.name order by n.name
;

-- Q9 Who was the youngest person to have an acting role in a movie, and how old were they when the movie started?

create or replace view ages(name, age) as select n.name, (t.start_year - n.birth_year) age from actor_roles ac inner join names n on ac.name_id = n.id inner join titles t on t.id = ac.title_id where t.format = 'movie'; 
create or replace view Q9(name,age)
as
select * from ages where age = (select min(age) from ages)
;

-- Q10 Write a PLpgSQL function that, given part of a title, shows the full title and the total size of the cast and crew

create or replace view moviePeople(id, title, people) as 
select t.id, t.main_title, c.name_id from titles t 
inner join crew_roles c on c.title_id = t.id
union
select t.id, t.main_title, a.name_id actor from titles t
inner join actor_roles a on a.title_id = t.id 
union
select t.id, t.main_title, p.name_id principal from titles t 
inner join principals p on p.title_id = t.id ;
                                             
create or replace function
	Q10(partial_title text) returns setof text
as $$
DECLARE
  mName text;
  people integer;
  titleId integer;
  search integer;
BEGIN
for titleId, mName, people in select id, title, count(title) from moviePeople
where title ilike '%' || partial_title || '%'
group by id, title
loop
  return next mName || ' has ' || people || ' cast and crew';
end loop;
IF mName is null THEN
return next 'No matching titles';
END IF;
return;
END;
$$ language plpgsql;
