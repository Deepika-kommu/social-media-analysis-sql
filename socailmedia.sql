
USE ig_clone;
-- ============================================================================
-- Social media SQL PROJECT
-- Submitted By: DEEPIKA KOMMU
-- ============================================================================

-- ============================================================================
-- OBJECTIVE QUESTIONS
-- ============================================================================

-- ============================================================================
-- Objective Question 1
-- Are there any tables with duplicate or missing null values? If so, how would you handle them?
-- ============================================================================

-- NULL values in users

SELECT
    COUNT(*) AS total_rows,
    SUM(id IS NULL) AS null_id,
    SUM(username IS NULL) AS null_username,
    SUM(created_at IS NULL) AS null_created_at
FROM users;
-- NULL values in photos

SELECT
    COUNT(*) AS total_rows,
    SUM(id IS NULL) AS null_id,
    SUM(image_url IS NULL) AS null_image_url,
    SUM(user_id IS NULL) AS null_user_id,
    SUM(created_dat IS NULL) AS null_created_dat
FROM photos;

-- NULL values in comments

SELECT
    COUNT(*) AS total_rows,
    SUM(id IS NULL) AS null_id,
    SUM(comment_text IS NULL) AS null_comment_text,
    SUM(user_id IS NULL) AS null_user_id,
    SUM(photo_id IS NULL) AS null_photo_id,
    SUM(created_at IS NULL) AS null_created_at
FROM comments;

-- NULL values in likes

SELECT
    COUNT(*) AS total_rows,
    SUM(user_id IS NULL) AS null_user_id,
    SUM(photo_id IS NULL) AS null_photo_id,
    SUM(created_at IS NULL) AS null_created_at
FROM likes;

-- NULL values in follows

SELECT
    COUNT(*) AS total_rows,
    SUM(follower_id IS NULL) AS null_follower_id,
    SUM(followee_id IS NULL) AS null_followee_id,
    SUM(created_at IS NULL) AS null_created_at
FROM follows;

-- NULL values in tags

SELECT
    COUNT(*) AS total_rows,
    SUM(id IS NULL) AS null_id,
    SUM(tag_name IS NULL) AS null_tag_name,
    SUM(created_at IS NULL) AS null_created_at
FROM tags;

-- NULL values in photo_tags

SELECT
    COUNT(*) AS total_rows,
    SUM(photo_id IS NULL) AS null_photo_id,
    SUM(tag_id IS NULL) AS null_tag_id
FROM photo_tags;

-- Duplicate values in users

SELECT
    username,
    COUNT(*) AS duplicate_count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- Duplicate values in photos

SELECT
    id,
    COUNT(*) AS duplicate_count
FROM photos
GROUP BY id
HAVING COUNT(*) > 1;

-- Duplicate values in comments 

SELECT
    id,
    COUNT(*) AS duplicate_count
FROM comments
GROUP BY id
HAVING COUNT(*) > 1;

-- Duplicate values in likes

SELECT
    user_id,
    photo_id,
    COUNT(*) AS duplicate_count
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- Duplicate values in follows 

SELECT
    follower_id,
    followee_id,
    COUNT(*) AS duplicate_count
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

-- Duplicate values in photo-tags

SELECT
    photo_id,
    tag_id,
    COUNT(*) AS duplicate_count
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1;

-- ============================================================================
-- Objective Question 2
-- What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?
-- ============================================================================

WITH user_activity AS
(
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT p.id) AS posts,
        COUNT(DISTINCT l.photo_id) AS likes_given,
        COUNT(DISTINCT c.id) AS comments_made
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON u.id = l.user_id
    LEFT JOIN comments c
        ON u.id = c.user_id
    GROUP BY u.id, u.username
),
activity_levels AS
(
    SELECT
        id,
        username,
        posts,
        likes_given,
        comments_made,
        posts + likes_given + comments_made AS activity_score
    FROM user_activity
)
SELECT
    CASE
        WHEN activity_score = 0 THEN 'Inactive'
        WHEN activity_score <= 20 THEN 'Low Activity'
        WHEN activity_score <= 50 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS activity_level,
    COUNT(*) AS number_of_users
FROM activity_levels
GROUP BY
    CASE
        WHEN activity_score = 0 THEN 'Inactive'
        WHEN activity_score <= 20 THEN 'Low Activity'
        WHEN activity_score <= 50 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END
ORDER BY number_of_users DESC;

-- ============================================================================
-- Objective Question 3
-- Calculate the average number of tags per post (photo_tags and photos tables)
-- ============================================================================
SELECT
    ROUND(
        COUNT(pt.tag_id) / COUNT(DISTINCT p.id),
        2
    ) AS average_tags_per_post
FROM photos p
LEFT JOIN photo_tags pt
    ON p.id = pt.photo_id;

-- ============================================================================
-- Objective Question 4
-- Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
-- ============================================================================

WITH user_likes AS
(
    SELECT
        p.user_id,
        COUNT(*) AS likes_received
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
user_comments AS
(
    SELECT
        p.user_id,
        COUNT(*) AS comments_received
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
),
user_engagement AS
(
    SELECT
        u.id,
        u.username,
        COALESCE(ul.likes_received, 0) AS likes_received,
        COALESCE(uc.comments_received, 0) AS comments_received,
        COALESCE(ul.likes_received, 0)
            + COALESCE(uc.comments_received, 0) AS total_engagement
    FROM users u
    LEFT JOIN user_likes ul
        ON u.id = ul.user_id
    LEFT JOIN user_comments uc
        ON u.id = uc.user_id
),
ranked_users AS
(
    SELECT
        *,
        RANK() OVER (
            ORDER BY total_engagement DESC
        ) AS engagement_rank
    FROM user_engagement
)
SELECT *
FROM ranked_users
WHERE engagement_rank <= 10
ORDER BY engagement_rank;

-- ============================================================================
-- Objective Question 5
-- Which users have the highest number of followers and followings?
-- ============================================================================

WITH user_followers AS
(
    SELECT
        u.id,
        u.username,
        COUNT(f.follower_id) AS followers
    FROM users u
    LEFT JOIN follows f
        ON u.id = f.followee_id
    GROUP BY u.id, u.username
),
user_followings AS
(
    SELECT
        u.id,
        COUNT(f.followee_id) AS followings
    FROM users u
    LEFT JOIN follows f
        ON u.id = f.follower_id
    GROUP BY u.id
)
SELECT
    uf.id,
    uf.username,
    uf.followers,
    ufg.followings,
    RANK() OVER (ORDER BY uf.followers DESC) AS follower_rank,
    RANK() OVER (ORDER BY ufg.followings DESC) AS following_rank
FROM user_followers uf
JOIN user_followings ufg
    ON uf.id = ufg.id
ORDER BY follower_rank;
-- ============================================================================
-- Objective Question 6
-- Calculate the average engagement rate (likes, comments) per post for each user.
-- ============================================================================

WITH user_posts AS
(
    SELECT
        u.id,
        u.username,
        COUNT(p.id) AS total_posts
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    GROUP BY u.id, u.username
),
user_likes AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
user_comments AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    up.id,
    up.username,
    up.total_posts,
    COALESCE(ul.total_likes, 0) AS total_likes,
    COALESCE(uc.total_comments, 0) AS total_comments,

    COALESCE(ul.total_likes, 0)
    + COALESCE(uc.total_comments, 0) AS total_engagement,
    ROUND(
    (
        COALESCE(ul.total_likes, 0)
        + COALESCE(uc.total_comments, 0)
    ) / NULLIF(up.total_posts, 0),
    2
) AS average_engagement_per_post
FROM user_posts up
LEFT JOIN user_likes ul
    ON up.id = ul.user_id
LEFT JOIN user_comments uc
    ON up.id = uc.user_id
ORDER BY average_engagement_per_post DESC;
-- ============================================================================
-- Objective Question 7
-- Get the list of users who have never liked any post (users and likes tables)
-- ============================================================================

SELECT
    u.id,
    u.username
FROM users u
LEFT JOIN likes l
    ON u.id = l.user_id
WHERE l.user_id IS NULL
ORDER BY u.id;

-- ============================================================================
-- Objective Question 8
-- How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
-- ============================================================================

SELECT
    t.id AS tag_id,
    t.tag_name,
    COUNT(pt.photo_id) AS post_count
FROM tags t
JOIN photo_tags pt
    ON t.id = pt.tag_id
GROUP BY t.id, t.tag_name
ORDER BY post_count DESC;


-- Hashtags with highest likes
SELECT
    t.id AS tag_id,
    t.tag_name,
    COUNT(DISTINCT pt.photo_id) AS post_count,
    COUNT(l.photo_id) AS total_likes
FROM tags t
JOIN photo_tags pt
    ON t.id = pt.tag_id
JOIN photos p
    ON pt.photo_id = p.id
LEFT JOIN likes l
    ON p.id = l.photo_id
GROUP BY t.id, t.tag_name
ORDER BY total_likes DESC;


-- Hashtags with highest overall engagement
SELECT
    t.id AS tag_id,
    t.tag_name,
    COUNT(DISTINCT pt.photo_id) AS post_count,
    COUNT(DISTINCT l.user_id, l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT l.user_id, l.photo_id)
        + COUNT(DISTINCT c.id) AS total_engagement
FROM tags t
JOIN photo_tags pt
    ON t.id = pt.tag_id
JOIN photos p
    ON pt.photo_id = p.id
LEFT JOIN likes l
    ON p.id = l.photo_id
LEFT JOIN comments c
    ON p.id = c.photo_id
GROUP BY t.id, t.tag_name
ORDER BY total_engagement DESC;

-- ============================================================================
-- Objective Question 9
-- Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this
-- ============================================================================

WITH user_activity AS
(
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT p.id) AS photo_posts,
        COUNT(DISTINCT l.photo_id) AS likes_given,
        COUNT(DISTINCT c.id) AS comments_made
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON u.id = l.user_id
    LEFT JOIN comments c
        ON u.id = c.user_id
    GROUP BY u.id, u.username
)

SELECT
    CASE
        WHEN photo_posts + likes_given + comments_made = 0
            THEN 'Inactive'
        WHEN photo_posts + likes_given + comments_made <= 20
            THEN 'Low Activity'
        WHEN photo_posts + likes_given + comments_made <= 50
            THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS activity_level,

    COUNT(*) AS number_of_users,
    SUM(photo_posts) AS total_photo_posts,
    ROUND(AVG(photo_posts), 2) AS average_photo_posts_per_user

FROM user_activity

GROUP BY
    CASE
        WHEN photo_posts + likes_given + comments_made = 0
            THEN 'Inactive'
        WHEN photo_posts + likes_given + comments_made <= 20
            THEN 'Low Activity'
        WHEN photo_posts + likes_given + comments_made <= 50
            THEN 'Moderate Activity'
        ELSE 'High Activity'
    END

ORDER BY average_photo_posts_per_user DESC;

-- ============================================================================
-- Objective Question 10
-- Calculate the total number of likes, comments, and photo tags for each user.
-- ============================================================================

WITH user_likes AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

user_comments AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

user_tags AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_photo_tags
    FROM photos p
    JOIN photo_tags pt
        ON p.id = pt.photo_id
    GROUP BY p.user_id
)

SELECT
    u.id,
    u.username,
    COALESCE(ul.total_likes, 0) AS total_likes,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(ut.total_photo_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN user_likes ul
    ON u.id = ul.user_id
LEFT JOIN user_comments uc
    ON u.id = uc.user_id
LEFT JOIN user_tags ut
    ON u.id = ut.user_id
ORDER BY u.id;

-- ============================================================================
-- Objective Question 11
-- Rank users based on their total engagement (likes, comments, shares) over a month.
-- ============================================================================

WITH monthly_likes AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    WHERE l.created_at >= (
        SELECT DATE_FORMAT(MAX(created_at), '%Y-%m-01')
        FROM likes
    )
    AND l.created_at < (
        SELECT DATE_ADD(
            DATE_FORMAT(MAX(created_at), '%Y-%m-01'),
            INTERVAL 1 MONTH
        )
        FROM likes
    )
    GROUP BY p.user_id
),

monthly_comments AS
(
    SELECT
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    WHERE c.created_at >= (
        SELECT DATE_FORMAT(MAX(created_at), '%Y-%m-01')
        FROM comments
    )
    AND c.created_at < (
        SELECT DATE_ADD(
            DATE_FORMAT(MAX(created_at), '%Y-%m-01'),
            INTERVAL 1 MONTH
        )
        FROM comments
    )
    GROUP BY p.user_id
),

monthly_engagement AS
(
    SELECT
        u.id,
        u.username,
        COALESCE(ml.total_likes, 0) AS total_likes,
        COALESCE(mc.total_comments, 0) AS total_comments,
        COALESCE(ml.total_likes, 0)
        + COALESCE(mc.total_comments, 0) AS total_engagement
    FROM users u
    LEFT JOIN monthly_likes ml
        ON u.id = ml.user_id
    LEFT JOIN monthly_comments mc
        ON u.id = mc.user_id
)
SELECT
    id,
    username,
    total_likes,
    total_comments,
    total_engagement,
    RANK() OVER (
        ORDER BY total_engagement DESC
    ) AS engagement_rank
FROM monthly_engagement
ORDER BY engagement_rank;

-- ============================================================================
-- Objective Question 12
-- Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.
-- ============================================================================

WITH hashtag_likes AS
(
    SELECT
        t.id AS tag_id,
        t.tag_name,
        p.id AS photo_id,
        COUNT(l.photo_id) AS likes_per_post
    FROM tags t
    JOIN photo_tags pt
        ON t.id = pt.tag_id
    JOIN photos p
        ON pt.photo_id = p.id
    LEFT JOIN likes l
        ON p.id = l.photo_id
    GROUP BY
        t.id,
        t.tag_name,
        p.id
),
hashtag_average AS
(
    SELECT
        tag_id,
        tag_name,
        ROUND(AVG(likes_per_post), 2) AS average_likes
    FROM hashtag_likes
    GROUP BY
        tag_id,
        tag_name
)
SELECT
    tag_id,
    tag_name,
    average_likes
FROM hashtag_average
WHERE average_likes = (
    SELECT MAX(average_likes)
    FROM hashtag_average
)
ORDER BY tag_id;

-- ============================================================================
-- Objective Question 13
-- Retrieve the users who have started following someone after being followed by that person
-- ============================================================================

SELECT
    f1.follower_id AS user_id,
    u1.username,
    f1.followee_id AS followed_user_id,
    u2.username AS followed_username,
    f2.created_at AS first_followed_at,
    f1.created_at AS reciprocal_followed_at
FROM follows f1
JOIN follows f2
    ON f1.follower_id = f2.followee_id
    AND f1.followee_id = f2.follower_id
JOIN users u1
    ON f1.follower_id = u1.id
JOIN users u2
    ON f1.followee_id = u2.id
WHERE f1.created_at > f2.created_at
ORDER BY f1.created_at;

-- ============================================================================
-- SUBJECTIVE QUESTIONS
-- ============================================================================

-- ============================================================================
-- Subjective Question 1
-- Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
-- ============================================================================

-- =====================================================
-- SUBJECTIVE QUESTION 1
-- IDENTIFY LOYAL / VALUABLE USERS
-- =====================================================

WITH user_posts AS
(
    SELECT
        user_id,
        COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),
user_likes_received AS
(
    SELECT
        p.user_id,
        COUNT(*) AS likes_received
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
user_comments_received AS
(
    SELECT
        p.user_id,
        COUNT(*) AS comments_received
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
),
user_likes_given AS
(
    SELECT
        user_id,
        COUNT(*) AS likes_given
    FROM likes
    GROUP BY user_id
),
user_comments_given AS
(
    SELECT
        user_id,
        COUNT(*) AS comments_given
    FROM comments
    GROUP BY user_id
)
SELECT
    u.id,
    u.username,

    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(ulr.likes_received, 0) AS likes_received,
    COALESCE(ucr.comments_received, 0) AS comments_received,
    COALESCE(ulg.likes_given, 0) AS likes_given,
    COALESCE(ucg.comments_given, 0) AS comments_given,
    COALESCE(up.total_posts, 0)
    + COALESCE(ulr.likes_received, 0)
    + COALESCE(ucr.comments_received, 0)
    + COALESCE(ulg.likes_given, 0)
    + COALESCE(ucg.comments_given, 0) AS engagement_score
FROM users u
LEFT JOIN user_posts up
    ON u.id = up.user_id
LEFT JOIN user_likes_received ulr
    ON u.id = ulr.user_id
LEFT JOIN user_comments_received ucr
    ON u.id = ucr.user_id
LEFT JOIN user_likes_given ulg
    ON u.id = ulg.user_id
LEFT JOIN user_comments_given ucg
    ON u.id = ucg.user_id
ORDER BY engagement_score DESC;

-- ============================================================================
-- Subjective Question 2
-- For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
-- ============================================================================

SELECT
    u.id,
    u.username
FROM users u
LEFT JOIN photos p
    ON u.id = p.user_id
LEFT JOIN likes l
    ON u.id = l.user_id
LEFT JOIN comments c
    ON u.id = c.user_id
WHERE p.id IS NULL
  AND l.user_id IS NULL
  AND c.user_id IS NULL
ORDER BY u.id;

-- ============================================================================
-- Subjective Question 3
-- Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?
-- ============================================================================

WITH hashtag_engagement AS
(
    SELECT
        t.id AS tag_id,
        t.tag_name,
        COUNT(l.photo_id) AS total_likes,
        COUNT(DISTINCT p.id) AS total_posts,
        ROUND(
            COUNT(l.photo_id) / COUNT(DISTINCT p.id),
            2
        ) AS average_likes
    FROM tags t
    JOIN photo_tags pt
        ON t.id = pt.tag_id
    JOIN photos p
        ON pt.photo_id = p.id
    LEFT JOIN likes l
        ON p.id = l.photo_id
    GROUP BY
        t.id,
        t.tag_name
)
SELECT
    tag_id,
    tag_name,
    total_posts,
    total_likes,
    average_likes
FROM hashtag_engagement
ORDER BY average_likes DESC;

-- ============================================================================
-- Subjective Question 4
-- Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
-- ============================================================================

SELECT
    HOUR(p.created_dat) AS posting_hour,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    ROUND(
        (
            COUNT(DISTINCT l.photo_id)
            + COUNT(DISTINCT c.id)
        ) / COUNT(DISTINCT p.id),
        2
    ) AS average_engagement_per_post
FROM photos p
LEFT JOIN likes l
    ON p.id = l.photo_id
LEFT JOIN comments c
    ON p.id = c.photo_id
GROUP BY HOUR(p.created_dat)
ORDER BY average_engagement_per_post DESC;

-- ============================================================================
-- Subjective Question 5
-- Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
-- ============================================================================

WITH follower_count AS
(
    SELECT
        followee_id AS user_id,
        COUNT(*) AS followers
    FROM follows
    GROUP BY followee_id
),
user_engagement AS
(
    SELECT
        p.user_id,
        COUNT(DISTINCT l.photo_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments,
        COUNT(DISTINCT p.id) AS total_posts
    FROM photos p
    LEFT JOIN likes l
        ON p.id = l.photo_id
    LEFT JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    u.id,
    u.username,
    COALESCE(fc.followers, 0) AS followers,
    COALESCE(ue.total_posts, 0) AS total_posts,
    COALESCE(ue.total_likes, 0) AS total_likes,
    COALESCE(ue.total_comments, 0) AS total_comments,
    ROUND(
        (
            COALESCE(ue.total_likes, 0)
            + COALESCE(ue.total_comments, 0)
        ) / NULLIF(COALESCE(ue.total_posts, 0), 0),
        2
    ) AS average_engagement_per_post
FROM users u
LEFT JOIN follower_count fc
    ON u.id = fc.user_id
LEFT JOIN user_engagement ue
    ON u.id = ue.user_id
WHERE COALESCE(fc.followers, 0) > 0
  AND COALESCE(ue.total_posts, 0) > 0
ORDER BY
    followers DESC,
    average_engagement_per_post DESC;

-- ============================================================================
-- Subjective Question 6
-- Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
-- ============================================================================

WITH user_activity AS
(
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.photo_id) AS likes_given,
        COUNT(DISTINCT c.id) AS comments_given
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON u.id = l.user_id
    LEFT JOIN comments c
        ON u.id = c.user_id
    GROUP BY
        u.id,
        u.username
)
SELECT
    id,
    username,
    total_posts,
    likes_given,
    comments_given,
    CASE
        WHEN total_posts + likes_given + comments_given = 0
            THEN 'Inactive User'
        WHEN total_posts >= 5
             AND likes_given + comments_given >= 100
            THEN 'Content Creator'
        WHEN total_posts = 0
             AND likes_given + comments_given > 0
            THEN 'Active Engager'
        WHEN total_posts + likes_given + comments_given > 100
            THEN 'Highly Active User'
        WHEN total_posts + likes_given + comments_given BETWEEN 20 AND 100
            THEN 'Moderately Active User'
        ELSE 'Low Activity User'
    END AS user_segment
FROM user_activity
ORDER BY
    total_posts + likes_given + comments_given DESC;

-- ============================================================================
-- Subjective Question 7
-- If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?
-- ============================================================================

SELECT
    campaign_id,
    campaign_name,
    impressions,
    clicks,
    conversions,
    cost,

    ROUND(
        clicks * 100.0 / NULLIF(impressions, 0),
        2
    ) AS ctr,

    ROUND(
        conversions * 100.0 / NULLIF(clicks, 0),
        2
    ) AS conversion_rate,
    ROUND(
        cost / NULLIF(clicks, 0),
        2
    ) AS cost_per_click,
    ROUND(
        cost / NULLIF(conversions, 0),
        2
    ) AS cost_per_conversion
FROM ad_campaigns
ORDER BY conversion_rate DESC;

-- ============================================================================
-- Subjective Question 8
-- How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?.
-- ============================================================================
WITH user_activity AS
(
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.photo_id) AS likes_received,
        COUNT(DISTINCT c.id) AS comments_received
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON p.id = l.photo_id
    LEFT JOIN comments c
        ON p.id = c.photo_id
    GROUP BY
        u.id,
        u.username
)
SELECT
    id,
    username,
    total_posts,
    likes_received,
    comments_received,
    (
        total_posts
        + likes_received
        + comments_received
    ) AS engagement_score
FROM user_activity
WHERE total_posts > 0
ORDER BY engagement_score DESC;

-- ============================================================================
-- Subjective Question 9
-- How would you approach this problem, if the objective and subjective questions weren't given?
-- ============================================================================



-- ============================================================================
-- Subjective Question 10
-- Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?
-- ============================================================================

UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';
