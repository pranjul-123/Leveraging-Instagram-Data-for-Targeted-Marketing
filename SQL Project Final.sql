-- Q_1
-- Comments
-- Select count(*) from comments                  -> 7488
-- Select count(user_id) from comments            -> 7488
-- Select count(photo_id) from comments           -> 7488 
-- Select count(created_at) from comments         -> 7488

-- Follows
-- Select count(*) from follows                   -> 7623
-- Select count( follower_id) from follows        -> 7623
-- Select count(followee_id) from follows         -> 7623
-- Select count(created_at) from follows          -> 7623

-- likes
-- Select count(*) from likes                     -> 8782
-- Select count(user_id) from likes               -> 8782
-- Select count(photo_id) from likes              -> 8782
-- Select count(created_at) from likes            -> 8782

-- photo_tags
-- Select count(*) from photo_tags                -> 501
-- Select count(photo_id) from photo_tags         -> 501
-- Select count(tag_id) from photo_tags           -> 501   

-- photos
-- Select count(*) from photos                    -> 257
-- Select count(id) from photos                   -> 257   
-- Select count(image_url) from photos            -> 257 
-- Select count(user_id) from photos              -> 257
-- Select count(created_dat) from photos          -> 257

-- tags
-- Select count(*) from tags                      -> 21
-- Select count(tag_name) from tags               -> 21
-- Select count(created_at) from tags             -> 21

-- users
-- Select count(*) from users                     -> 100
-- Select count(distinct username) from users     -> 100
-- Select count(created_at) from users            -> 100

-- Q-2
SELECT u.id AS user_id,  u.username,
    COALESCE(COUNT(DISTINCT p.id), 0) AS post_count,
    COALESCE(COUNT(DISTINCT l.photo_id), 0) AS like_count,
    COALESCE(COUNT(DISTINCT c.id), 0) AS comment_count
FROM  users u
LEFT JOIN photos p ON p.user_id = u.id
LEFT JOIN  likes l ON l.user_id = u.id
LEFT JOIN  comments c ON c.user_id = u.id
GROUP BY  u.id;


-- Q_3
SELECT 
    AVG(tag_count) AS avg_tags_per_post
FROM (
SELECT  photo_id,  COUNT(tag_id) AS tag_count
    FROM photo_tags
    GROUP BY photo_id
) AS tag_counts;


-- Q_4
SELECT u.user_id,
    (COALESCE(total_likes, 0) + COALESCE(total_comments, 0)) / COALESCE(total_posts, 1) AS engagement_rate,
    RANK() OVER (ORDER BY (COALESCE(total_likes, 0) + COALESCE(total_comments, 0)) / COALESCE(total_posts, 1) DESC) AS `rank`
FROM (
    SELECT p.user_id, COALESCE(SUM(likes_count), 0) AS total_likes, COALESCE(SUM(comments_count), 0) AS total_comments
    FROM photos p
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS likes_count FROM likes
        GROUP BY photo_id
    ) l ON p.id = l.photo_id
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS comments_count FROM comments
        GROUP BY photo_id
    ) c ON p.id = c.photo_id
    GROUP BY p.user_id
) AS u
JOIN (SELECT user_id, COUNT(*) AS total_posts
    FROM photos GROUP BY user_id
) AS p_count ON u.user_id = p_count.user_id
ORDER BY engagement_rate DESC limit 10;




-- Q_5
-- Users with the most followers
SELECT 
    followee_id AS user_id, COUNT(follower_id) AS followers_count
FROM  follows
GROUP BY followee_id
ORDER BY followers_count DESC
LIMIT 10;

-- Users with the most followings
SELECT 
    follower_id AS user_id, COUNT(followee_id) AS followings_count
FROM follows
GROUP BY  follower_id
ORDER BY followings_count DESC
LIMIT 1;

-- Q_6
SELECT 
    users.id AS user_id, users.username,
    ROUND((SUM(likes_count + comments_count) / COUNT(photos.id)) * 100,2) AS avg_engagement_rate
FROM users
JOIN photos ON photos.user_id = users.id
LEFT JOIN  (SELECT photo_id, COUNT(user_id) AS likes_count FROM likes GROUP BY photo_id) AS likes ON likes.photo_id = photos.id
LEFT JOIN  (SELECT photo_id, COUNT(user_id) AS comments_count FROM comments GROUP BY photo_id) AS comments ON comments.photo_id = photos.id
GROUP BY users.id
ORDER BY avg_engagement_rate DESC;

-- Q_7
SELECT 
    u.id AS user_id, 
    u.username 
FROM 
    users u
LEFT JOIN 
    likes l ON u.id = l.user_id
WHERE 
    l.user_id IS NULL;

-- Q_10
SELECT u.id AS user_id, u.username, 
       COUNT(DISTINCT l.photo_id) AS total_likes, 
       COUNT(DISTINCT c.id) AS total_comments, 
       COUNT(DISTINCT pt.tag_id) AS total_tags
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON u.id = c.user_id
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY u.id;

-- Q_11
WITH CTE AS (
SELECT u.id AS user_id, u.username, COALESCE(SUM(l.total_likes), 0) + COALESCE(SUM(c.total_comments), 0) AS total_engagement
FROM users u
LEFT JOIN ( SELECT user_id, COUNT(photo_id) AS total_likes FROM likes
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN ( SELECT user_id, COUNT(id) AS total_comments FROM comments
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) GROUP BY user_id
) c ON u.id = c.user_id
GROUP BY u.id
ORDER BY total_engagement DESC
)

SELECT * , dense_rank() OVER(ORDER BY total_engagement DESC) AS `RANK` FROM CTE


-- Q_12
WITH hashtag_avg_likes AS (
    SELECT pt.tag_id, t.tag_name, AVG(l.photo_id) AS avg_likes
    FROM photo_tags pt
    JOIN tags t ON pt.tag_id = t.id
    JOIN photos p ON pt.photo_id = p.id
    JOIN likes l ON p.id = l.photo_id
    GROUP BY pt.tag_id, t.tag_name
)
SELECT tag_name, avg_likes
FROM hashtag_avg_likes
ORDER BY avg_likes DESC
LIMIT 10;

-- Q_13

SELECT f1.follower_id, f1.followee_id
FROM follows f1
WHERE EXISTS (
    SELECT 1 
    FROM follows f2 
    WHERE f1.follower_id = f2.followee_id 
    AND f1.followee_id = f2.follower_id
);


-- SUBJECTIVE QUESTION Queries

-- Q_1
SELECT 
    u.id AS user_id, u.username,
    COALESCE(SUM(l.total_likes), 0) AS total_likes,
    COALESCE(SUM(c.total_comments), 0) AS total_comments,
    COALESCE(SUM(f.total_follows), 0) AS total_follows,
    (COALESCE(SUM(l.total_likes), 0) + COALESCE(SUM(c.total_comments), 0) + COALESCE(SUM(f.total_follows), 0)) AS total_engagement
FROM  users u
LEFT JOIN ( SELECT user_id, COUNT(*) AS total_likes
    FROM likes WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN ( SELECT user_id, COUNT(*) AS total_comments
    FROM comments WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) GROUP BY user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT follower_id AS user_id, COUNT(*) AS total_follows
    FROM follows WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) GROUP BY follower_id
) f ON u.id = f.user_id
GROUP BY u.id
ORDER BY total_engagement DESC;



-- Q_2
SELECT u.id, u.username
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
WHERE (p.created_dat IS NULL OR p.created_dat < NOW() - INTERVAL 30 DAY)
AND (l.created_at IS NULL OR l.created_at < NOW() - INTERVAL 30 DAY)
AND (c.created_at IS NULL OR c.created_at < NOW() - INTERVAL 30 DAY);

-- Q_3
Select tag_id, tag_name, count(tag_name) as count_tage, count(l.photo_id) as likes_photo, count(c.photo_id) as comments_photo from tags t
left join photo_tags  p on t.id = p.tag_id
left join likes l on l.photo_id = p.photo_id
left join comments c on c.photo_id = p.photo_id

group by tag_id, tag_name
order by count(tag_name) desc
limit 5

-- Q_4
SELECT 
    u.id AS user_id,
    u.username,
    HOUR(l.created_at) AS engagement_hour,
    COUNT(l.user_id) AS total_likes,
    COUNT(c.user_id) AS total_comments
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, HOUR(l.created_at)
ORDER BY total_likes DESC, total_comments DESC;

-- Q_5

with cte as (
SELECT p.user_id, COALESCE(SUM(likes_count), 0) AS total_likes, COALESCE(SUM(comments_count), 0) AS total_comments
FROM photos p
LEFT JOIN ( SELECT photo_id, COUNT(*) AS likes_count FROM likes GROUP BY photo_id
) l ON p.id = l.photo_id
LEFT JOIN ( SELECT  photo_id, COUNT(*) AS comments_count FROM comments GROUP BY photo_id
) c ON p.id = c.photo_id GROUP BY p.user_id order by total_likes desc, total_comments desc
),
cte2 as (
SELECT follower_id AS user_id, COUNT(followee_id) AS followings_count
FROM follows
GROUP BY  follower_id ORDER BY followings_count DESC
)
Select cte.user_id, u.username, total_likes, total_comments, followings_count from cte inner join cte2 on cte.user_id = cte2.user_id
inner join users u on u.id = cte.user_id
order by total_likes desc, total_comments desc, followings_count desc;


-- Q_6
WITH engagement AS (
    SELECT u.id AS user_id, u.username, COALESCE(SUM(l.likes_count), 0) AS total_likes, 
	COALESCE(SUM(c.comments_count), 0) AS total_comments, COUNT(p.id) AS total_posts,COUNT(DISTINCT f.follower_id) AS followers_count,
	COUNT(DISTINCT f.followee_id) AS followings_count
    FROM users u LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN (SELECT photo_id, COUNT(*) AS likes_count FROM likes GROUP BY photo_id) l ON p.id = l.photo_id
    LEFT JOIN (SELECT photo_id, COUNT(*) AS comments_count FROM comments GROUP BY photo_id) c ON p.id = c.photo_id
    LEFT JOIN follows f ON u.id = f.followee_id
    GROUP BY u.id
)
SELECT user_id, username,
    CASE 
        WHEN total_likes > 50 AND total_comments > 50 AND total_posts > 5 THEN 'Engaged User'
        WHEN followers_count > 100 THEN 'Influencer'
        WHEN total_likes > 50 AND total_posts < 5 THEN 'Content Consumer'
        WHEN total_likes = 0 AND total_comments = 0 AND total_posts = 0 THEN 'Inactive User'
        ELSE 'Topic-Specific Enthusiast'
    END AS user_segment
FROM engagement
ORDER BY user_segment;

-- Q_7
CREATE TABLE ad_campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_name VARCHAR(255),
    impressions INT,
    clicks INT,
    conversions INT,
    cost DECIMAL(10, 2),
    revenue DECIMAL(10, 2),
    start_date DATE,
    end_date DATE
);

-- Q_8
SELECT 
    u.id AS user_id,u.username,
    (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS total_followers,
    (SELECT COUNT(*) FROM photos WHERE user_id = u.id) AS total_photos_posted,
    COALESCE((
        SELECT AVG(like_count) FROM (
	SELECT COUNT(l.user_id) AS like_count FROM likes l
	JOIN photos p ON l.photo_id = p.id
    WHERE p.user_id = u.id GROUP BY p.id
        ) AS like_stats), 0) AS avg_likes_per_photo,
    COALESCE((
        SELECT AVG(comment_count) FROM (SELECT COUNT(c.id) AS comment_count FROM comments c
            JOIN photos p ON c.photo_id = p.id
WHERE p.user_id = u.id
            GROUP BY p.id
        ) AS comment_stats
    ), 0) AS avg_comments_per_photo,
    COALESCE((
        SELECT MAX(p.created_dat) FROM photos p WHERE p.user_id = u.id
    ), u.created_at) AS last_activity_date
    
FROM users u
HAVING total_followers > 50 AND total_photos_posted > 5 AND avg_likes_per_photo > 30       
ORDER BY avg_likes_per_photo DESC;    


-- Q_10
UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';

