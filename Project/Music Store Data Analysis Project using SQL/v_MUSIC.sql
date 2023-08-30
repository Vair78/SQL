select * from album
#Q 1 :  Who is the Senior Most Employee based on Job Title ?

select * from employee
ORDER BY levels desc
LIMIT 1

# Q 2 : Which countries have the most invoices ?
select * from invoice ;
select count(*) as c, billing_country from invoice
group by billing_country
order by c desc;


# Q3: What are top 3 Values of total invoice?

select total from invoice
order by total desc
limit 3

#Q4 : which city has the best customers ?  we would like to throw a promotional Music Festival in the city we made the most money. 
#Wrtie a query that returns one city that has the highest sum of Invoice totals. Return both the City name and sum of all invoice totals.

select * from invoice ;

select sum(total) as invoice_total, billing_city from invoice
group by billing_city
order by invoice_total desc

#Q5 : who is best customers  ? The customer who has spent the most money will be declared the best customer. 
#Write a query that shows the person who has spent the most money?

select * from customer 


select customer.customer_id, customer.first_name, customer.last_name, SUM(total)as total
from customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total DESC
LIMIT 3


- Set 2 Mode Moderate 
# Q6. Write query to return the email, first name, last name, & Genre of all Rock Music Listeners.
-Return your list ordered alphabetically by email starting with A.

select distinct email, first_name,last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name Like 'Rock'
	
)
ORDER BY email ;


# Q7. Let’s invite the artists who have written the most ROCK music in our dataset. 
-Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id)AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
Limit 10 ;



select * from track

# Q8. Return all the track names that have a song length longer than the average song length. 
- Return the Name and Milliseconds for each Track. Order by the song length with the longest songs listed first.

select * from track

SELECT name,milliseconds FROM track
WHERE milliseconds >(
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)

ORDER BY milliseconds DESC;



# Qustion set 3 Advance 
#Q9. Find how much amount spent by each customer on artists? 
# Write a query to return customer name, artist name and total spent.

- customer from customer table
- artist  from artist table
-Total Spent from invoice table ( unit price * Quantity)
- CT (Comman Table for temp to run multiple table)

WITH best_selling_artist AS(
	SELECT artist.artist_id AS artist_id, artist.name As artist_name,
	SUM(invoice_line.unit_price *invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)


SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price * il.quantity)AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER by 5 DESC ;



# Q10. We want to find out the most popular music Genre for each country. 
#We determine the most popular genre as the genre with the highest amount of purchases. 
#Write a query that returns each country along with the top genre. 
#For Countries where the maximum number of purchases is shared return all genres.
# ANS: 
- Coutnry from Invoice table
-Genre from Genre table


WITH popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country,genre.name, genre.genre_id,
	ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT (invoice_line.quantity)DESC) AS RowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP By 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <=1


# Now same output using Recursive Mean 2nd query output is depend on 1st Query.
#Example 2 : 

WITH RECURSIVE 
      Sales_per_country AS (
	  SELECT COUNT(*) AS  purchases_per_genre, customer.country, genre.name, genre.genre_id
	  FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	  ),
	  max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number,country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2	 )
		
	SELECT sales_per_country,* 
	FROM sales_per_country
	JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
	WHERE  sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number



#Q11.Write a query that determine the customer that has spent them ost on music for each country.
#Write a query that returns the country along with the TOP customer and how much they spent. 
#For countries where the TOP amount SPENT is shared, provide ALL customers who spent this amount.

WITH RECURSIVE
	customer_with_country AS (
	SELECT customer.customer_id, first_name,last_name,billing_country, sum(total) AS total_spending
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 2,3 DESC),
	
	country_max_spending AS(
	SELECT billing_country, MAX(total_spending) AS max_spending
	FROM customer_with_country
	GROUP BY billing_country)
	
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name,cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1 ;

# Example 2 ( Using CT )

WITH customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name,billing_country, SUM(total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC,5 DESC)
SELECT  * FROM customer_with_country WHERE RowNO <= 1	


