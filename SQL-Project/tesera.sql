/* tesera.ru - сайт о настольных играх и немного соцсеть. Пользователи добавляют странички игр, где можно почитать
 * описание игры, отзывы, посмотреть видео, скачать правила. Также есть страницы магазинов, коммьюнити, события,
 * связанные с играми, публикуются статьи, обзоры, новости. Напрямую через сайт купить ничего нельзя, но можно 
 * узнать информацию о ценах, а также есть раздел "барахолка", где игроки размещают информацию о продаже/ покупке,
 * а далее договариваются через личные сообщения. 
 * При регистрации пользователь выбирает тип аккаунта: пользователь, магазин, сообщество (клуб) или событие. Для этого
 * у меня есть общая таблица accounts и 4 типа профилей. В конце работы добавлена транзакция, чтобы id из общей таблицы
 * подгружались в соответствующие таблицы профилей.  */

DROP DATABASE IF EXISTS tesera;
CREATE DATABASE tesera;
USE tesera;

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id SERIAL,
    account_type ENUM ('user', 'shop', 'club', 'event'),
    login VARCHAR(100) UNIQUE NOT NULL, 
    password_hash VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    last_online DATETIME DEFAULT NOW(),
    is_deleted BIT(1) DEFAULT 0,
    
    INDEX login_idx (login) -- поиск по нику пользователя, названия магазина и т.п.
);

DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
    id SERIAL,
    city_name VARCHAR(100) UNIQUE NOT NULL,
    
    INDEX city (city_name)
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type ENUM ('photo', 'video', 'document'),
    from_account_id BIGINT UNSIGNED NOT NULL,
  	description VARCHAR(300),
    filename VARCHAR(255),  	
    `size` INT,
	`path` VARCHAR(200),
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (from_account_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS shops_profiles; -- это информационные страницы (без покупок). 
CREATE TABLE shops_profiles (
    account_id BIGINT UNSIGNED NOT NULL UNIQUE,
    photo_id BIGINT UNSIGNED DEFAULT NULL,
    shop_city_id BIGINT UNSIGNED, -- В идеале нужна отдельная таблица shop_cities, т.к. отделения могут быть в разных городах
    website VARCHAR(100),
    club_id BIGINT UNSIGNED, -- Магазин может быть связан с клубом
    info TEXT,
    
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (shop_city_id) REFERENCES cities(id),
    FOREIGN KEY (photo_id) REFERENCES media(id),
    FOREIGN KEY (club_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS users_profiles;
CREATE TABLE users_profiles (
    account_id BIGINT UNSIGNED NOT NULL UNIQUE, 
    user_real_name VARCHAR(50),
    photo_id BIGINT UNSIGNED DEFAULT NULL,
    user_city_id BIGINT UNSIGNED,
    gender CHAR(1),
    birthday DATE,
    info TEXT,
    rating INT UNSIGNED Comment 'Рейтинг пользователя, зависит от его действий на сайте, добавления контента и т.п.',
    status ENUM ('registered', 'approved', 'editor', 'admin') Comment '4 разновидности прав пользователя',
    
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (user_city_id) REFERENCES cities(id),
    FOREIGN KEY (photo_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS clubs_profiles;
CREATE TABLE clubs_profiles (
    account_id BIGINT UNSIGNED NOT NULL UNIQUE, 
    admin_id BIGINT UNSIGNED,
    shop_id BIGINT UNSIGNED,
    photo_id BIGINT UNSIGNED DEFAULT NULL,
    website VARCHAR(100),
    club_city_id BIGINT UNSIGNED,
    info TEXT,
    
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (club_city_id) REFERENCES cities(id),
    FOREIGN KEY (photo_id) REFERENCES media(id),
    FOREIGN KEY (admin_id) REFERENCES accounts(id),
    FOREIGN KEY (shop_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS events;
CREATE TABLE events (
    account_id BIGINT UNSIGNED NOT NULL UNIQUE, 
    photo_id BIGINT UNSIGNED DEFAULT NULL,
    event_city_id BIGINT UNSIGNED,
    website VARCHAR(100),
    event_time DATETIME DEFAULT NULL,
    info TEXT,
    
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (event_city_id) REFERENCES cities(id),
    FOREIGN KEY (photo_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS games;
CREATE TABLE games (
	id SERIAL,
	from_user_id BIGINT UNSIGNED NOT NULL Comment 'ID пользователя, добавившего карточку игры',
    main_name VARCHAR(100) UNIQUE NOT NULL Comment 'Официальное название, по которому производится поиск',
    sub_name  VARCHAR(300) DEFAULT NULL Comment 'Альтернативные переводы названия, год издания',
    min_number_of_players TINYINT, 
    max_number_of_players TINYINT,
    from_age TINYINT,
    preparation_time TINYINT Comment 'в минутах',
    min_play_time SMALLINT,
    max_play_time SMALLINT,
    author VARCHAR(100),
    designer VARCHAR(100), -- В идеале нужны отдельные таблицы для авторов, дизайнеров и издателей. 
    publisher VARCHAR(100),
    components TEXT Comment 'Комплектация игры, размер и вес коробки и т.п.',
    description TEXT,
    languages VARCHAR(255) Comment 'Список языков, на которых издана игра',
    photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    
    INDEX game_name (main_name),
    INDEX sub_name (sub_name),
    
    FOREIGN KEY (from_user_id) REFERENCES accounts(id),
    FOREIGN KEY (photo_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS categories;
CREATE TABLE categories ( -- категории игр: варгеймы, карточные, логические, семейные, приключения и т.д
	id SERIAL,
	name VARCHAR(100),
	
	INDEX category_idx (name)    
);

DROP TABLE IF EXISTS games_categories;
CREATE TABLE games_categories (
    game_id BIGINT UNSIGNED NOT NULL,
	category_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (game_id, category_id),
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

DROP TABLE IF EXISTS users_clubs;
CREATE TABLE users_clubs (
    user_id BIGINT UNSIGNED NOT NULL,
	club_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, club_id),
    FOREIGN KEY (user_id) REFERENCES accounts(id),
    FOREIGN KEY (club_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS users_events;
CREATE TABLE users_events (
    user_id BIGINT UNSIGNED NOT NULL,
	event_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, event_id),
    FOREIGN KEY (user_id) REFERENCES accounts(id),
    FOREIGN KEY (event_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS user_games;
CREATE TABLE user_games (
    user_id BIGINT UNSIGNED NOT NULL,
	game_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, game_id),
    FOREIGN KEY (user_id) REFERENCES accounts(id),
    FOREIGN KEY (game_id) REFERENCES games(id)
);

DROP TABLE IF EXISTS user_sells; -- пользователи, которые продают игры
CREATE TABLE user_sells (
    user_id BIGINT UNSIGNED NOT NULL,
	game_id BIGINT UNSIGNED NOT NULL,
	price INT, -- не нашла ни одной цены с копейками, поэтому выбран int
	`condition` ENUM ('new', 'secondhand') DEFAULT NULL,
	comment VARCHAR(300),
	created_at DATETIME DEFAULT NOW(),
    is_deleted BIT(1),
	  
	PRIMARY KEY (user_id, game_id),
    FOREIGN KEY (user_id) REFERENCES accounts(id),
    FOREIGN KEY (game_id) REFERENCES games(id)
);

DROP TABLE IF EXISTS user_buys; -- пользователи, которые покупают игры
CREATE TABLE user_buys (
    user_id BIGINT UNSIGNED NOT NULL,
	game_id BIGINT UNSIGNED NOT NULL,
	`condition` ENUM ('new', 'secondhand', 'any'),
	comment VARCHAR(300),
	created_at DATETIME DEFAULT NOW(),
    is_deleted BIT(1),
	  
	PRIMARY KEY (user_id, game_id),
    FOREIGN KEY (user_id) REFERENCES accounts(id),
    FOREIGN KEY (game_id) REFERENCES games(id)
);

DROP TABLE IF EXISTS account_media;
CREATE TABLE account_media (
    account_id BIGINT UNSIGNED NOT NULL,
	media_id BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (account_id, media_id),
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS game_media;
CREATE TABLE game_media (
    game_id BIGINT UNSIGNED NOT NULL,
	media_id BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (game_id, media_id),
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL,
	from_id BIGINT UNSIGNED NOT NULL,
    to_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(),
    is_deleted BIT(1) DEFAULT 0,

    FOREIGN KEY (from_id) REFERENCES accounts(id),
    FOREIGN KEY (to_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'unfriended', 'declined'),
	requested_at DATETIME DEFAULT NOW(),
	confirmed_at DATETIME ON UPDATE NOW(),
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES accounts(id),
    FOREIGN KEY (target_user_id) REFERENCES accounts(id)
);
ALTER TABLE friend_requests
ADD CHECK(initiator_user_id <> target_user_id);

DROP TABLE IF EXISTS games_shops; -- магазины, где продается игра 
CREATE TABLE games_shops (
    id Serial,
    game_id BIGINT UNSIGNED NOT NULL,
	shop_id BIGINT UNSIGNED, -- или ссылка на аккаунт магазина на tesera, или ссылка на сайт магазина
	shop_link VARCHAR(100),
	price INT, -- т.к. все цены на сайте целочисленные
	  
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (shop_id) REFERENCES accounts(id)
);

DROP TABLE IF EXISTS articles; -- статьи, новости, проекты - можно сделать отдельные таблицы, но они однотипные
CREATE TABLE articles (
    id SERIAL,
    article_name VARCHAR(255) UNIQUE NOT NULL,
    article_photo_id BIGINT UNSIGNED DEFAULT NULL,
    article_date DATETIME DEFAULT NOW(),
    author_id BIGINT UNSIGNED NOT NULL,
    related_links TEXT,
    description TEXT,
    is_deleted BIT(1) DEFAULT 0,
    
    INDEX article_idx (article_name),
    FOREIGN KEY (article_photo_id) REFERENCES media(id),
    FOREIGN KEY (author_id) REFERENCES accounts(id)   
);

DROP TABLE IF EXISTS articles_media; -- к статье может быть прикреплено несколько медиафайлов (помимо основной фотографии)
CREATE TABLE articles_media(
    article_id BIGINT UNSIGNED NOT NULL,
	media_id BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (article_id, media_id),
    FOREIGN KEY (article_id) REFERENCES articles(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS awards; -- награды
CREATE TABLE awards (
    id Serial,
    award_name VARCHAR(300) UNIQUE NOT NULL,
    info TEXT,
    city_id BIGINT UNSIGNED,
    website VARCHAR(100),
    
    INDEX awards (award_name),
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

DROP TABLE IF EXISTS awards_games; -- награды, которые получила игра
CREATE TABLE awards_games (
    award_id BIGINT UNSIGNED NOT NULL,
    game_id BIGINT UNSIGNED NOT NULL,
    `year` INT(4),
    status ENUM ('лауреат', 'номинант'),
    
    FOREIGN KEY (award_id) REFERENCES awards(id),
    FOREIGN KEY (game_id) REFERENCES games(id)
);

DROP TABLE IF EXISTS comments;
CREATE TABLE comments (
    id SERIAL,
    game_id BIGINT UNSIGNED,
    article_id BIGINT UNSIGNED,
    account_id BIGINT UNSIGNED,
    media_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    body TEXT,

    FOREIGN KEY (article_id) REFERENCES articles(id),
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (media_id) REFERENCES media(id),
    FOREIGN KEY (user_id) REFERENCES accounts(id)
);
ALTER TABLE comments
ADD CHECK(article_id IS NOT NULL or account_id IS NOT NULL or game_id IS NOT NULL or media_id IS NOT NULL);

-- проверим, что у нас точно указан пост (страница), к которому оставлен комментарий 
DELIMITER //
DROP TRIGGER IF EXISTS insert_comments//
CREATE TRIGGER insert_comments BEFORE INSERT ON comments
FOR EACH ROW
BEGIN
  IF NEW.article_id IS NULL AND NEW.account_id IS NULL AND NEW.game_id IS NULL AND NEW.media_id IS NULL THEN
  SIGNAL SQLSTATE '23000' SET MESSAGE_TEXT = 'Subject ID is not identified';
 END IF;
END//
DROP TRIGGER IF EXISTS update_comments//
CREATE TRIGGER update_comments BEFORE UPDATE ON comments
FOR EACH ROW
BEGIN
  IF NEW.article_id IS NULL AND NEW.account_id IS NULL AND NEW.game_id IS NULL AND NEW.media_id IS NULL THEN
  SIGNAL SQLSTATE '23000' SET MESSAGE_TEXT = 'Subject ID is not identified';
 END IF;
END//
DELIMITER ;

DROP TABLE IF EXISTS games_scores; 
-- оценка игры пользователями. Оцениваются 4 параметра: геймплей, глубина, оригинальность, реализация
CREATE TABLE games_scores (
    id SERIAL,
    game_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    gameplay TINYINT UNSIGNED DEFAULT NULL, -- 10-балльная шкала, целочисленная оценка
    versatility TINYINT UNSIGNED DEFAULT NULL,
    originality TINYINT UNSIGNED DEFAULT NULL,
    representation TINYINT UNSIGNED DEFAULT NULL,
    total_score DECIMAL(3,2), -- итоговая оценка, рассчитывается автоматически с помощью триггера
    
    PRIMARY KEY (game_id, user_id),
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (user_id) REFERENCES accounts(id)
);
-- Итоговую оценку посчитаем автоматически и сразу увеличим рейтинг пользователя, оценившего игру, на 3 балла
DELIMITER //
DROP TRIGGER IF EXISTS total_game_score_insert//
CREATE TRIGGER total_game_score_insert BEFORE INSERT ON games_scores
FOR EACH ROW
BEGIN
SET NEW.total_score = (NEW.gameplay + NEW.versatility + NEW.originality + NEW.representation) / 4;
UPDATE users_profiles SET rating = rating + 3 WHERE account_id = NEW.user_id;
END//
DROP TRIGGER IF EXISTS total_game_score_update//
CREATE TRIGGER total_game_score_update BEFORE UPDATE ON games_scores
FOR EACH ROW
BEGIN
  SET NEW.total_score = (NEW.gameplay + NEW.versatility + NEW.originality + NEW.representation) / 4;
  UPDATE users_profiles SET rating = rating + 3 WHERE account_id = NEW.user_id;
END//
DELIMITER ;

DROP TABLE IF EXISTS other_scores; 
-- оценка статьи, новости, магазина - 10-балльная шкала, целочисленная оценка
CREATE TABLE other_scores (
    id SERIAL,
    subject_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    score TINYINT DEFAULT NULL,
    
    FOREIGN KEY (subject_id) REFERENCES accounts(id),
    FOREIGN KEY (subject_id) REFERENCES articles(id),
    FOREIGN KEY (user_id) REFERENCES accounts(id)
);
    
INSERT INTO `cities` (`city_name`) VALUES
    ('Alisonfort'),
    ('Brycentown'),
    ('Geovannyborough'),
    ('Labadieberg'),
    ('Lake Carloborough'),
    ('Lake Scot'),
    ('New Alessandratown'),
    ('New Ellie'),
    ('North Berta'),
    ('Parisianstad'),
    ('Port Rosamond'),
    ('Rubyhaven'),
    ('Sammyside'),
    ('South Andreanneburgh'),
    ('South Russell'),
    ('Unaview'),
    ('West Bella'),
    ('West Jean'),
    ('West Phoebe'),
    ('Williamsonburgh');

INSERT INTO `accounts` VALUES ('1','event','rerum','f4cca50a91cab1d49605fdf8ad7f251a7acead24','kulas.thalia@example.net','2015-01-08 05:34:05','2019-10-04 21:58:58',0),
('2','user','dolorem','5cfc9b48cbfa8d9116de184632f7eb3687f43563','kenyatta.price@example.com','1992-10-23 19:47:52','2019-11-29 15:42:30',0),
('3','club','ratione','55d547568b59dc167553b9b2e727a20870d4d48c','roy.spinka@example.com','2011-11-09 04:51:11','2019-12-26 10:21:00',0),
('4','user','cumquetum','b5f2ef42c4335555d6254f8d9ea65f5b70866340','towne.bessie@example.org','1982-02-28 12:06:33','2020-08-18 00:29:40',0),
('5','user','fuga','c4e0b62e8537e7a57e83a5881153e7da7075a6e6','gayle.white@example.com','2019-04-13 13:29:06','2019-09-09 23:33:15',0),
('6','user','volup','9dd8d7fcbd51d61f9a9da64a4e5cbf9403947d15','bstanton@example.org','1971-03-10 11:12:32','2019-11-07 14:18:58',0),
('7','club','ipsam','be3f8d64dcf10eb9fabe762983810724d402673a','bernhard.sammy@example.org','2008-10-14 18:32:18','2020-05-17 17:23:14',0),
('8','shop','ips','e93d100b1048b705c4d675538e2e9ccaedf4f82e','edare@example.com','2015-06-05 17:02:07','2019-09-15 04:51:09',0),
('9','event','molestiae','b7ebc090f30cb6d436eca91504741f3d5ac8ebbb','kiarra23@example.com','1970-08-14 16:44:26','2020-07-25 09:08:01',0),
('10','club','amet','3da6da7aab8aa1302b4423c5b0e86caf61c019c4','zboncak.darius@example.com','1971-10-19 06:57:51','2020-06-13 20:11:43',0),
('11','user','labor','3ae8932385cf037fe3ced8ae52b0c12ec6b5ce32','winona78@example.org','2001-11-20 07:10:04','2020-04-17 15:49:15',0),
('12','club','numquam','2ee3b9ebed42c153570f4928f5eb5ed2fb63c047','allen35@example.org','2014-02-02 03:57:58','2019-10-30 07:34:29',0),
('13','shop','veritatis','11f14aebdef226c475f7d9f8e441b2ef5c66f667','aufderhar.jazmin@example.org','1973-11-16 20:06:01','2020-04-19 01:26:14',0),
('14','event','necessitatibus','8be156083fa9efa591c38c5ae8c6fd77da194ea2','ruth35@example.net','1999-08-27 02:58:35','2020-08-14 11:14:25',0),
('15','user','qui','146dbab88ab1750d1856b40c4753a14694fbe7bf','frice@example.com','1974-06-19 18:30:09','2020-02-06 05:57:34',0),
('16','user','quod','85229d5bb8dec19904b1d48d296b5391abcdd5f0','kuhic.buster@example.com','2009-05-28 02:22:32','2020-03-30 22:22:57',1),
('17','user','porro','e427752e1ff755cd938ef47f158683678dd80368','reinger.verlie@example.org','1984-07-13 18:57:11','2020-04-29 02:51:02', 1),
('18','user','voluptat','4cc96adf7eef5d158e9f46d0b694d3926c2c6fe9','melba.wyman@example.org','1990-03-18 23:02:40','2019-09-01 21:33:14',0),
('19','user','laboriosam','fb3d7165e397c2cd147c8064c9a207369ce49b9d','cole.annamae@example.org','1983-01-23 01:37:35','2020-07-16 18:19:42',0),
('20','user','corporis','38370f5c91984a027ff4150ba0c9851d42e4dcfd','gspencer@example.org','1974-01-30 13:22:42','2019-10-06 11:20:05',0),
('21','shop','dolor','72311e30aa22c8892f936041eb147da7cdd6f19f','ho\'keefe@example.org','2003-08-15 10:25:18','2020-06-27 14:55:05',0),
('22','club','cum','b91eabea9b8b315e4abce969075b4b6cb6655b45','lawson.marks@example.org','1975-05-02 11:36:08','2019-12-01 02:48:40',0),
('23','event','eveniet','5d59b7a532a63d9333ffb90d90e6ca20c0c2b786','sarah35@example.net','1984-03-26 21:49:40','2020-02-22 10:11:42',0),
('24','event','unde','3b750b49d5b2d92b961b6e9aefb7026437092cf0','solon.schowalter@example.net','2006-12-28 01:10:25','2020-07-16 01:49:48',0),
('25','shop','excepturi','5e05598ac4aee13e2873eeef35abec318d49a051','cblick@example.com','2015-03-14 18:42:03','2019-12-21 18:17:20',0),
('26','club','ut','cd618695f39d8b30542415947521ffeaeb93219f','bessie22@example.org','1991-03-28 19:50:21','2019-12-15 20:50:03',0),
('27','user','voluptatem','60aabca848392e5285b12a696836b7d8e7283cd6','kchristiansen@example.net','1991-01-05 23:08:50','2020-04-02 18:58:44',0),
('28','user','blanditiis','4068aedca40f92cddd7a3457e66be873c7c576e7','ramon72@example.net','2016-11-20 12:37:38','2020-02-08 00:10:36',0),
('29','user','deleniti','fc8e3e59fe463c2bf3a34e9fb53af0f51a9d6a68','schmeler.megane@example.org','2008-07-25 23:14:05','2019-09-05 17:35:16',0),
('30','user','ducimus','5106603be0234432dbee2909a45e4474f26baaa0','mtremblay@example.net','1991-09-04 14:20:02','2019-09-28 05:26:43',0),
('31','user','cumque','ee0a3a98965c95f31aec9e0a840d1ac9dac09b40','ona.mosciski@example.org','1996-01-03 00:55:32','2019-12-22 21:27:04',0),
('32','user','omnia','5bf01bcca5a87c91f0805b903a6b79df77c237cc','lysanne76@example.org','1973-02-13 16:58:39','2020-01-08 06:00:27',0),
('33','user','quialem','d729e52b0ddd20c7c0714679127e64bc17cd9055','runolfsdottir.mariana@example.com','2014-01-24 16:36:41','2019-11-09 02:41:03',0),
('34','user','suntat','0731d7a1895b27dcb16fb353789c057fd5b04e50','moore.jacinthe@example.org','1994-05-15 19:11:33','2019-12-07 13:03:51',0),
('35','user','illo','726f32ad0681aa6460effee8f6b721dab98d09e1','fannie.rodriguez@example.com','1970-01-24 23:57:19','2020-02-03 11:51:33',0),
('36','user','quia','3206427c34a3a4ad54e48ed64241ff90ebb640de','opal.vandervort@example.net','2010-12-03 02:00:33','2020-05-30 14:58:07',0),
('37','user','nihil','9c069a9eb646dfd0b082ee86b3e0f99cdf633991','ohammes@example.org','1993-05-11 23:55:37','2019-11-19 20:46:48',0),
('38','club','quo','dbae645540c22e0500c5c2b3f273d7a2664a662b','romaguera.stephany@example.org','1992-07-12 22:58:30','2020-03-10 08:44:05',0),
('39','user','commodi','a975d52f8533151898db1043832e0f6f2515b1c1','jannie.davis@example.com','2011-02-22 22:23:30','2019-11-25 16:03:16',0),
('40','event','quasi','52104801197c0d004d73703892f007072055e71b','iliana91@example.com','2012-10-29 04:50:21','2019-10-18 14:11:53',1),
('41','shop','sed','aba7fd3b228089df27730626d24ed3e46239c0da','kaitlyn.botsford@example.org','1997-12-06 10:03:32','2020-08-23 18:25:23',0),
('42','club','et','845c75637a84ef6831f50a8d8cc1b80980dc7c72','ubins@example.com','1972-02-10 01:06:38','2020-01-08 07:59:10',0),
('43','user','omnis','c106d450ea7bf36ad9f6946e00da8512b5fe47ba','michelle.turner@example.org','1989-04-07 15:19:28','2020-01-27 15:28:01',0),
('44','user','quitum','a1f13babfe6585425a75a52f435a0e596e7d12d2','erogahn@example.net','2006-10-19 18:26:49','2019-12-15 10:02:38',0),
('45','user','dolore','f65aceddabc3a781bb88d2d3745932b331ae5ee8','pasquale48@example.org','1985-09-28 11:45:34','2020-03-30 06:07:07',0),
('46','user','sunt','db30da300b61f12aa186778a4e55ea6d8846b131','godfrey04@example.com','1998-06-23 17:09:34','2019-12-31 00:00:22',0),
('47','user','veniam','454ae17e08800c421b86df6dd0c0845604fd53b2','maeve59@example.com','1983-08-10 17:29:45','2020-04-12 23:15:17',1),
('48','user','pov','d83636a25a227b31f9b7bdb0f6b222d32a24300b','ewald11@example.net','2013-10-03 18:39:00','2019-10-04 06:56:40',0),
('49','user','dignissimos','369acc1d947be08e0d68cfb9ee727f33e4f231da','juwan16@example.net','2009-10-10 06:49:47','2020-07-26 14:12:03',0),
('50','event','uptatum','5d14cbb6c1f939ed6fe8df25d44673d78284dda6','green.vita@example.net','2014-06-21 12:22:25','2019-11-24 21:30:20',0); 


INSERT INTO `media` VALUES ('1','photo','6','Perferendis id quasi iste.','in','3','/srv/web/../file.jpg','2018-11-24 05:40:31','2019-09-28 11:44:26'),
('2','video','4','Voluptatem ut voluptas dolores ut recusandae.','fuga','572','/srv/web/../file.jpg','2020-01-20 19:08:22','2020-05-02 06:11:22'),
('3','document','4','Sint error et ut architecto nobis.','labore','4204','/srv/web/../file.jpg','2011-12-30 00:01:19','2020-05-21 18:30:28'),
('4','video','6','A blanditiis iste vero similique dolorem impedit.','a','238','/srv/web/../file.jpg','2015-04-02 02:33:49','2019-11-05 12:02:42'),
('5','photo','7','Soluta nihil delectus sit.','id','841','/srv/web/../file.jpg','2014-03-31 18:49:50','2020-03-04 08:11:00'),
('6','photo','2','Aut et cupiditate id amet saepe enim architecto.','sit','449','/srv/web/../file.jpg','2013-04-25 05:49:53','2019-11-20 13:38:10'),
('7','photo','6','Quidem velit est quis cumque recusandae et accusamus.','et','77','/srv/web/../file.jpg','2018-11-18 13:23:16','2020-06-30 11:26:50'),
('8','document','7','Doloremque architecto debitis et omnis id modi est.','dolorem','10','/srv/web/../file.jpg','2014-09-17 16:09:19','2019-10-03 15:49:00'),
('9','photo','6','Nemo voluptatem ut repellendus aut maiores ratione eos qui.','ea','18','/srv/web/../file.jpg','2014-01-24 07:40:00','2019-12-11 17:33:31'),
('10','document','6','Explicabo et consequuntur est.','natus','50','/srv/web/../file.jpg','2015-01-04 04:19:13','2019-10-26 02:25:20'),
('11','photo','15','Incidunt veniam eum et et maiores qui quisquam.','at','2724','/srv/web/../file.jpg','2018-04-20 00:13:07','2020-03-06 06:54:43'),
('12','photo','2','Molestiae totam aliquid velit soluta ipsam reiciendis.','qui','4935','/srv/web/../file.jpg','2014-03-07 12:22:38','2020-06-15 05:14:42'),
('13','photo','4','Repudiandae porro illum aperiam voluptatibus aut non autem.','sint','7805','/srv/web/../file.jpg','2012-10-16 21:10:25','2020-07-03 19:49:36'),
('14','document','9','Repudiandae magni officiis qui tenetur quibusdam rem.','unde','402','/srv/web/../file.jpg','2013-08-29 22:14:53','2019-09-23 16:08:41'),
('15','document','5','Dicta nisi et corrupti.','aperiam','208','/srv/web/../file.jpg','2018-08-30 06:13:34','2020-08-13 15:27:17'),
('16','video','5','Animi inventore ut ducimus voluptatem delectus cupiditate veniam.','maiores','1612','/srv/web/../file.jpg','2018-03-31 02:20:04','2019-10-27 18:52:33'),
('17','document','5','Delectus fuga eligendi nulla nobis nisi quae.','ea','910','/srv/web/../file.jpg','2014-02-26 11:59:15','2019-10-20 11:16:34'),
('18','document','1','Ipsam ratione molestiae earum consequatur sint et et.','aut','747','/srv/web/../file.jpg','2012-01-05 06:18:29','2020-07-09 18:59:10'),
('19','photo','1','Recusandae est excepturi mollitia rem.','error','442','/srv/web/../file.jpg','2012-08-29 04:51:05','2020-06-09 05:23:20'),
('20','video','9','Aut dolorem accusantium ut fuga consequatur sit.','qui','5864','/srv/web/../file.jpg','2012-07-22 10:42:18','2019-09-04 19:29:46'),
('21','photo','2','Recusandae est excepturi mollitia rem.','','442','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('22','photo','4','Recusandae est excepturi mollitia rem.','tenetur','42','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('23','photo','5','Recusandae est excepturi mollitia rem.','sint','35','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('24','photo','6','Recusandae est excepturi mollitia rem.','quae','84','/srv/web/../file.jpg','2018-08-29 04:51:05','2020-06-09 05:23:20'),
('25','photo','11','Recusandae est excepturi mollitia rem.','nisi','48','/srv/web/../file.jpg','2017-08-29 04:51:05','2020-06-09 05:23:20'),
('26','photo','15','Recusandae est excepturi mollitia rem.','aut','29','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('27','photo','16','Recusandae est excepturi mollitia rem.','natus','84','/srv/web/../file.jpg','2082-08-29 04:51:05','2020-06-09 05:23:20'),
('28','photo','32','Recusandae est excepturi mollitia rem.','et','442','/srv/web/../file.jpg','2020-01-29 04:51:05','2020-06-09 05:23:20'),
('29','photo','33','Recusandae est excepturi mollitia rem.','dolorem','442','/srv/web/../file.jpg','2020-03-29 04:51:05','2020-06-09 05:23:20'),
('30','photo','34','Recusandae est excepturi mollitia rem.','modi','442','/srv/web/../file.jpg','2018-08-29 04:51:05','2020-06-09 05:23:20'),
('31','photo','35','Recusandae est excepturi mollitia rem.','enim','442','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('32','photo','36','Recusandae est excepturi mollitia rem.','sit','442','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('33','photo','37','Recusandae est excepturi mollitia rem.','soluta','442','/srv/web/../file.jpg','2020-02-04 04:51:05','2020-06-09 05:23:20'),
('34','photo','39','Recusandae est excepturi mollitia rem.','veniam','442','/srv/web/../file.jpg','2019-08-29 04:51:05','2020-06-09 05:23:20'),
('35','photo','49','Recusandae est excepturi mollitia rem.','qui','442','/srv/web/../file.jpg','2019-08-06 04:51:05','2020-06-09 05:23:20'),
('36','photo','9','Tempora sapiente ea nam dolorem eum nesciunt.','a','207838','/srv/web/../file.jpg','2020-07-04 23:52:00', '2020-06-09 05:23:20'),
('37','photo','3','Omnis cupiditate ratione sit aut suscipit itaque.','optio','61','/srv/web/../file.jpg','2019-09-04 09:41:25', '2020-06-09 05:23:20'),
('38','photo','3','Laborum vel ab provident. Culpa doloremque nulla vero ducimus','rerum','558','/srv/web/../file.jpg','2020-06-18 19:39:05', '2020-06-09 05:23:20'),
('39','photo','9','Iste id officia neque velit eaque. Quisquam unde repudiandae','dolorum','929','/srv/web/../f.jpg','2020-03-19 20:29:40', '2020-06-09 05:23:20'),
('40','photo','8','Fuga soluta doloremque maxime sed porro ut.','minus','513','/srv/web/../file.jpg','2019-11-09 21:04:12', '2020-06-09 05:23:20'),
('41','photo','4','Nam tempora pariatur consectetur libero magni excepturi voluptatem quas.','earum','939','/srv/web/../file.jpg','2020-01-20 12:13:23', '2020-06-09 05:23:20'),
('42','photo','6','Accusantium vero adipisci veniam molestias.','quasi','236','/srv/web/../file.jpg','2019-11-24 10:44:08', '2020-06-09 05:23:20'),
('43','photo','9','Sint aliquam sequi veritatis minima quod illum enim','deserunt','61','/srv/web/../file.jpg','2019-10-14 17:38:29', '2020-06-09 05:23:20'),
('44','photo','8','Ea cupiditate et cupiditate in quos. Non rerum.','et','61','/srv/web/../file.jpg','2020-02-24 04:32:25', '2020-06-09 05:23:20'),
('45','photo','7','Eum ex aliquid ut consequatur nulla. Reic','doloremque','79','/srv/web/../file.jpg','2020-04-29 14:12:24', '2020-06-09 05:23:20'),
('46','photo','6','Qui ducimus qui nobis aut veniam blanditiis consequatur','maiores','4','/srv/web/../file.jpg','2020-05-14 16:45:25', '2020-06-09 05:23:20'),
('47','photo','8','Sint vero magnam.','rem','600','/srv/web/../file.jpg','2020-08-16 22:40:56', '2020-06-09 05:23:20'),
('48','photo','9','Animi enim Tempora dolores aut corrupti aut','voluptas','621','/srv/web/../file.jpg','2020-04-06 07:46:25', '2020-08-23 15:23:20'),
('49','photo','9','Deserunt consectetur aut commodi minus','dolore','929','/srv/web/../file.jpg','2020-04-08 11:06:41', '2020-08-23 15:23:20'),
('50','photo','9','Voluptate dolorum non eos non nesciunt reprehenderit.','iusto','8363','/srv/web/../file.jpg','2019-11-27 11:42:57', '2020-08-23 15:23:20'),
('51','photo','8','Facere necessitatibus nesciunt maxime consectetur fuga ad','excepturi','840','/srv/web/../file.jpg','2020-04-01 18:15:06', '2020-08-23 15:23:20'),
('52','photo','5','Eligendi minus eligendi ipsum dolor.','iste','9817','/srv/web/../file.jpg','2020-07-04 19:40:55', '2020-08-23 15:23:20'),
('53','photo','6','Sit ut molestiae sit aut.','eius','89','/srv/web/../file.jpg','2019-10-25 16:58:13', '2020-08-23 15:23:20'),
('54','photo','5','Molestiae nulla quibusdam non magni qui maiores.','facere','47','/srv/web/../file.jpg','2020-06-10 09:55:18', '2020-08-14 15:22:20'),
('55','photo','6','Quaerat aliquid alias fugiat cum repudiandae.','at','14','/srv/web/../file.jpg','2020-05-23 18:06:46', '2020-07-11 23:23:20'),
('56','photo','4','Nemo amet et quasi in','voluptatem','89','/srv/web/../file.jpg','2020-05-14 13:52:40', '2020-07-17 15:23:20'),
('57','photo','9','Blanditiis possimus sint libero.','recusandae','71','/srv/web/../file.jpg','2019-11-07 11:05:14', '2020-02-23 11:23:20'),
('58','photo','4','Nostrum nihil quisquam cumque consequatur aut consequatur.','ut','130','/srv/web/../file.jpg','2020-03-23 12:58:55', '2020-05-11 12:15:20'),
('59','photo','3','Id nihil aut sed delectus ut omnis in.','nisi','613','/srv/web/../file.jpg','2020-02-14 02:04:09', '2020-03-14 12:11:20'),
('60','photo','8','Culpa sit et ut id. Sequi velit magnam voluptatem adipisci rem ipsam.','nulla','2804','/srv/web/../file.jpg','2020-02-24 01:40:39', '2020-08-01 14:12:15');

INSERT INTO `users_profiles` VALUES ('2','Pedro','21','6','m','1980-09-06','Consequatur quae repellendus odio quo aliquam ut repellendus.','1308431','admin'),
('4','Lilian','22','2','f','1972-06-25','Cupiditate aut consequatur necessitatibus qui. Temporibus quidem voluptates quam sequi necessitatibus optio.','50','registered'),
('5','Maddison','23','7','f','1990-01-24','Fuga illo deleniti nobis omnis fuga est minus architecto. Ea reprehenderit aliquid autem exercitationem aut tenetur enim. Atque enim saepe voluptas a aperiam sit rem architecto.','24621','admin'),
('6','Keon','24','3','m','1981-03-19','Nulla consequuntur ex sed non soluta. Voluptatem pariatur est voluptatem eum aperiam. Pariatur sed omnis sed repellat tempora. Quo quibusdam voluptatem delectus error nihil ab repudiandae.','21990','editor'),
('11','Santiago','25','1','m','1997-01-22','Et vero recusandae occaecati accusamus. Voluptatem animi voluptas dignissimos aut dolor pariatur. Mollitia est iste vero. Et quis ut unde earum eum iusto. Esse aut id adipisci et minus cupiditate esse.','55','registered'),
('15','Barney','26','2','m','1996-12-27','Delectus similique voluptate sint ut enim. Vitae saepe nemo accusantium nobis sed. Eligendi officia inventore et. Suscipit dolores et laborum voluptatibus excepturi veritatis nobis assumenda.','4854374','editor'),
('16','Norris','27','2','m','1989-11-13','Iusto minus quasi eum nihil expedita blanditiis. Blanditiis quasi ipsum omnis voluptatem.','491','registered'),
('17','Delfina',NULL,'8','f','1973-03-23','Officiis quos neque voluptatibus nam itaque. Similique voluptas repellendus vel voluptatem qui.','615','registered'),
('18','Willy',NULL,'2','m','2000-09-30','Quia ducimus aperiam non ut doloribus autem. Expedita sint minus soluta. Consequatur voluptatem ea deleniti et. Amet commodi harum cumque impedit consequatur velit ea occaecati.','361','registered'), 
('19','Norma',NULL,'2','f','2017-02-09','Et ex quia labore aut voluptatem aut molestias pariatur.','3053085','admin'),
('20','Santa',NULL,'1','f','2001-07-25','Hic alias consequatur iusto pariatur et aut consequuntur harum.','90809','approved'),
('27','Cielo',NULL,'2','m','2010-09-01','Rerum quidem hic amet cumque aperiam.','27816','registered'),
('28','Francisca',NULL,'7','f','2019-01-07','Quasi inventore nesciunt quasi dolores qui.','188958','editor'),
('29','Clarissa',NULL,'3','f','2012-01-23','Sit ad vel harum molestiae non.','52','registered'),
('30','Keith',NULL,'5','f','2012-12-17','At ea neque laborum ad.','90','registered'),
('31','Rafael',NULL,'1','m','2006-08-16','Rerum aspernatur eos ipsum voluptates.','7956','approved'),
('32','Kamille','28','8','f','1997-08-28','Temporibus qui reiciendis quae nostrum possimus blanditiis consequatur.','893105','editor'),
('33','Katheryn','29','9','f','1976-07-16','Enim a autem voluptatibus id vitae modi.','4714','approved'),
('34','Johnny','30','7','m','1974-03-29','Qui dolores tenetur tenetur omnis eum.','473','registered'),
('35','Madeline','31','5','f','1972-07-12','Et et facere aliquam minima.','66','registered'),
('36','Nya','32','3','f','1972-08-06','Officiis repellat veniam deserunt voluptates quia tempora qui.','136653','approved'),
('37','Morton','33','1','m','1997-09-22','Quia et amet suscipit.','77','registered'),
('39','Esta','34','4','f','2013-01-18','Aut ab ab ratione nemo illum quo.','83498','registered'),
('43','Troy',NULL,'7','m','1988-08-11','Magnam occaecati inventore repudiandae earum veritatis omnis voluptas.','879','registered'),
('44','Marjory',NULL,'5','f','1981-06-21','Dolor magnam magnam quae sapiente fugit.','100','registered'),
('45','Jaren',NULL,'4','m','2008-01-23','Dolor veniam impedit eveniet rerum sequi.','89665','approved'),
('46','Drake',NULL,'1','m','1970-11-07','Quo aut est maxime blanditiis.','1023','registered'),
('47','Clay',NULL,'8','m','1989-02-19','Qui voluptatem a aliquid sint.','596','registered'),
('48','Cortez',NULL,'4','m','1976-01-23','Dicta dolorem ratione earum voluptatem sunt vel suscipit.','3979','registered'),
('49','Vallie','35','9','m','1970-07-05','Quaerat sit ad facere eius velit laborum cum.','346171','registered');

INSERT INTO `shops_profiles` VALUES ('8','9','14','http://www.hahn.org/','3','Repellat quia est et aliquam.'),
('13','7','19','http://www.feilmacejkovic.com/','7','Hic ipsum quis ut voluptatem hic saepe consequatur.'),
('21','1','5','http://rau.com/','10','Vero deleniti enim ipsa aut omnis inventore.'),
('25','5','6','http://www.grant.com/','12','Dolores molestias numquam culpa aut.'),
('41','6','18','http://www.cassinhansen.com/',NULL,'Adipisci et maxime voluptates molestiae.');

INSERT INTO `clubs_profiles` VALUES ('3','31','8','11','http://hartmannstreich.com/','3','Officiis doloremque perferendis ex quaerat nemo pariatur.'),
('7','32','13','12','http://www.shanahan.com/','9','Dolor facilis qui eveniet architecto est doloremque reprehenderit.'),
('10','39','21','13','http://wolf.com/','5','Dolores eos magnam qui.'),
('12','45','25','19','http://kunze.biz/','5','Similique eum ad harum id eveniet.'),
('22','46',NULL,NULL,'http://anderson.com/','3','Aut laborum vero sed illum doloribus asperiores maiores.'),
('26','49',NULL,NULL,'http://www.schoen.org/','5','Incidunt incidunt sunt sint labore.'),
('38','6',NULL,NULL,'http://heathcote.com/','7','Quia vitae in sunt est dolorem.'),
('42','5',NULL,NULL,'http://www.bruenolson.net/','1','Quos illo iure praesentium qui sit.');

INSERT INTO `events` VALUES ('1',NULL,'2','http://stantonschmitt.org/','2020-07-18 13:02:29','Exercitationem nesciunt veniam perspiciatis molestiae officia non veritatis.'),
('9',NULL,'2','http://raulind.net/','2020-06-23 07:18:39','Odio et nisi numquam totam sed.'),
('14','1','10','http://leuschkedicki.info/','2020-05-09 16:03:30','Maxime ex corporis velit modi.'),
('23','6','4','http://www.greenkunde.com/','2020-03-09 15:49:10','Rerum placeat magnam optio voluptatum officia perspiciatis nulla vitae.'),
('24','5','16','http://watersschoen.org/','2019-12-21 06:10:13','Id cupiditate et voluptatum quidem ut natus minima et.'),
('40',NULL,'9','http://wardkris.com/','2020-03-23 12:38:03','Voluptate eum quis omnis molestias quo consequatur.'),
('50',NULL,'7','http://johnstonlarson.org/','2020-02-22 20:43:53','Porro voluptatem eos recusandae totam magni omnis maxime.');

INSERT INTO `games` (id, from_user_id, main_name, sub_name, min_number_of_players, max_number_of_players, from_age, preparation_time, min_play_time, max_play_time, author, designer, publisher, components, description, languages, photo_id) VALUES ('1','2','Renner Inc','Molestiae quidem, est quaerat at doloribus, minus fugiat.','1','3','8','15','30','60','Vella Grimes','Sienna Beatty Sr.','Jessie Jast','Enim quo qui deleniti neque suscipit porro rerum. Aut assumenda ea voluptate rerum quo incidunt reiciendis. Dolorem qui nihil numquam voluptates omnis assumenda illum.','Asperiores adipisci molestias quas et. Provident blanditiis aut adipisci incidunt amet. Ex repellendus et aliquam sed accusantium.','Repellat labore possimus id veniam sed voluptatem. Molestias sint dolor numquam quam quae aut reiciendis. Quidem id qui nihil veritatis quaerat.','36'),
('2','6','Dare Group','Minus quidem a doloribus nemo.','2','8','12','30','45','60','Viva Schimmel','Valentin Rutherford','Elnora Stokes','Aut quam eos placeat. Qui accusantium ut quis. Voluptatem quia qui dolorem illo.m.','Sint consectetur et laudantium perspiciatis facere culpa. Quis aperiam enim dolores voluptas labore et. Quo facere doloribus consequatur adipisci et. Earum ut dolor pariatur in necessitatibus.','Sapiente temporibus qui quasi. Dolore porro molestiae aut soluta. Molestiae accusamus sint vitae. Voluptatem consequuntur et nisi officia nemo nostrum.','37'),
('3','8','Kiehn-Muller','Ea et asperiores, doloremque, amet fugit, rerum ullam.','1','4','12','30','120','120','Sarina Fisher','Deontae Deckow','Darius Bradtke II','Necessitatibus ipsum perspiciatis quas maxime. Hic eos autem eius rerum. Tempore voluptatem ratione incidunt provident ratione.','Assumenda ut recusandae tenetur odit. Et quam aperiam et laboriosam voluptatem consequatur amet.','Ullam molestias sequi maiores dicta sit. Suscipit at animi et eum laboriosam maiores esse. Consequatur incidunt aut eligendi magni consequatur.','38'),
('4','2','Fadel-Buckridge','Non neque voluptas facilis','2','6','10','20','20','60','Dejuan Veum','Drake Marks','Connie Gleichner','Iusto eligendi doloremque maxime et aspernatur odio nostrum.','Ipsa iusto qui nostrum corporis. Sequi perferendis repudiandae modi et ut excepturi. Possimus enim vel optio. Quia et et repellendus repudiandae occaecati possimus est', 'Et nisi maiores doloribus porro alias.','39'),
('5','6','Hodkiewicz, Ward and Macejkovic','Hic odio et aliquid aut','2','10','6','15','15','30','Amira Hoeger','Mr. Domingo O\'Kon','Mose Nitzsche','Earum tenetur quae molestias commodi.Quis provident nesciunt natus molestiae ut omnis perspiciatis cupiditate.','Ratione suscipit atque quia voluptatem voluptatem.','Sunt sapiente ipsum iste rem. Eum quasi culpa atque iure aut unde. Doloremque rerum ut maiores. Libero nihil veritatis rerum non nihil.','40'),
('6','7','Thompson-Hintz',NULL,'1','3','12','60','60','120','Arianna Purdy MD','Miss Helga Powlowski Sr.','Deja Koepp II','Voluptas recusandae aut aut quidem. Esse debitis rerum possimus ducimus veniam.','Omnis dolores velit neque.','Reprehenderit sed voluptates architecto tempora voluptatem. Deserunt quas aliquid sit numquam.','41'),
('7','2','Paucek LLC','Asperiores est maxime at qui voluptatem est nihil.','1','5','8','10','20','30','Peggie Stiedemann','Adrien Johnson','Miss Florine Nienow','Nisi neque fugiat quis est magni','Modi velit in sit incidunt.Eveniet aut perferendis sequi repellat eaque commodi optio.','Eos est enim doloribus maiores totam sit.','42'),
('8','12','Hettinger and Sons','Quia et recusandae, omnis laborum est ea.','4','8','5','15','60','60','Duncan Jakubowski','Ms. Stella Streich','Reese Crona','Nihil odit voluptatibus culpa aut. Et quae corrupti cum commodi voluptatibus provident odio. Qui et quis adipisci illum eligendi sunt.','Quasi sapiente minima ab eos molestiae laboriosam optio','aque doloremque sint temporibus voluptatem optio velit.','43'),
('9','6','Klein PLC','Aliquam aliquam laboriosam dolorum nostrum.','1','4','12','20','120','130','Deborah Strosin','Francesca Wisoky','Rhiannon Jacobson','Quasi distinctio distinctio soluta ut. Voluptas id quas consequatur. Veritatis eum rerum reiciendis qui repellat. In magni adipisci ut libero.','Corrupti','Dolor incidunt quos atque voluptatem','44'),
('10','13','Bednar-Dickens','Tempora et sed omnis alias in.','1','4','6','10','15','30','Elisha Corwin','Floyd Rowe','Prof. Yolanda Hilll','Est possimus laboriosam necessitatibus eos est quam ut deserunt. Sed quo in aut voluptatem. Et voluptatum fugiat sapiente voluptatem atque placeat tempore.','Reprehenderit','Qui nobis consequatur expedita. Et qui accusantium aspernatur voluptate sint.','45'),
('11','2','Rohan and Sons','Aperiam numquam fugit porro eum minus aliquam quia.','2','4','10','15','30','60','Drew Murphy','Dr. Tony Bechtelar Sr.','Laurel Monahan','Impedit neque quis voluptatem dolor rerum. Ut facilis ut nihil architecto sit voluptas. Possimus sunt omnis saepe qui facilis.','Fuga conseqrepellendus eos.','Numquam impedit blanditiis in quisquam et quia. Debitis magni illo officiis','46'),
('12','9','Jacobson-Bergstrom','Debitis inventore magnam eaque delectus est voluptas odit.','1','5','14','15','120','120','Miss Maymie Kuhn','Ms. Ludie Hand V','Kaitlyn Fadel','Rerum numquam vel et qui ut eaque sint minus. Est consequuntur molestiae ut rerum ad.','Rerum et id nam est explicabo est. Sit voluptatibus','Aliquam consequatur illum est alias cupiditate dolor tenetur','47'),
('13','4','Spencer, Littel and VonRueden','Velit totam dolores ipsum numquam sit','2','2','10','10','40','60','Petra Streich','Stanton Christiansen MD','Green Rippin','Aut necessitatibus ad laudantium veniam quia recusandae ut. Dolores suscipit at nihil dolorem. Iste impedit et aut ducimus saepe.','Quia quas autem cumque. Minus soluta ut commodi saepe adipisci. Vel excepturi ea atque reprehenderit dolor. Ratione sit aut tempore qui dolorem sint cumque.','Velit id dolore sit perspiciatis mollitia eos iusto. Eligendi quis dignissimos exercitationem nisi.','48'),
('14','5','Wiza LLC','Iure quisquam non autem dolor voluptatum harum','2','4','6','10','20','30','Dr. Pauline Gislason Sr.','Alvena Schroeder','Dr. Peyton Littel V','Ut ipsam omnis est sed id quas modi. Doloribus dolores id libero itaque. Rem ea dolores rem.','Quis sit quibusdam et fuga. Voluptas omnis accusamus consequatur blanditiis autem non sapiente. Excepturi qui modi quia occaecati esse.','Modi qui earum consequuntur aut voluptas. Iure provident et labore veniam omnis. Non hic porro magnam ratione impedit.','49'),
('15','2','Heller, Boehm and Bradtke','asperiores dolorum rerum.','1','4','12','20','30','60','Stanford Moen MD','Sven Purdy','Barrett Schaefer','Pariatur tempora ipsum hic aut quia qui. Reiciendis aut molestiae est in veritatis. Iure laboriosam placeat est sint ut.','Rerum qui quia minus optio. Amet adipisci quia et necessitatibus modi quaerat adipisci. Error consequatur officia et veniam cum.','Perferendis veniam perspiciatis consequatur officiis est. Rerum deleniti labore et nemo. Quae expedita officia similique expedita temporibus nihil. Sed quisquam corrupti impedit unde.','50'),
('16','3','Bosco, Bosco and Dach','Dolor omnis facilis dolorem dolor quis magnam quis','1','4','14','25','60','80','Miss Frederique Rempel','Cindy Hintz','Scotty Cartwright V','Aut omnis ea porro sint dolores. Magnam nihil ullam adipisci repellendus provident odit iste maxime. Mollitia et aliquam eaque labore laborum.','Sunt deleniti est voluptas rem voluptatem iusto. Sint ut minima eum a optio. Asperiores perspiciatis quis voluptatem inventore in ab. Id sapiente ex dolorum omnis natus.','Sit et fugit doloremque sint est nemo et accusantium. Repudiandae aut odio perferendis error rerum voluptatibus corrupti.','51'),
('17','5','Hessel, Rau and Ferry','Dolore voluptatibus quia voluptas voluptas .','2','2','14','10','20','30','Furman Hirthe','Damian Hodkiewicz','Matteo O\'Kon','Ea nulla voluptatem incidunt quasi quidem explicabo. Laudantium amet aut quia tempore praesentium fugit eos. Modi sequi harum blanditiis perferendis aut. Voluptatum ad officia voluptas eum.','Reiciendis qui ut accusamus rerum. Ullam vel numquam et autem unde fuga. Nulla voluptatem est quibusdam. Aut tempora minima suscipit dicta inventore.','Est est est non libero commodi natus. Nostrum eligendi autem voluptas dolorem optio. Id facilis fugit iure. Earum suscipit nesciunt harum ut ipsa quidem consequatur.','52'),
('18','15','Ratke Inc','Rerum libero ut inventore ea id vitae eius.','1','4','14','30','60','120','Cesar Hegmann PhD','Enrique Deckow','D\'angelo Langosh','Recusandae inventore omnis error perspiciatis dicta quidem. Et perspiciatis iste soluta placeat necessitatibus nemo. Eos sed illo minima sed et est eligendi. Itaque cupiditate qui deleniti.','Laborum suscipit corporis omnis sunt doloribus assumenda ut. Sint necessitatibus deleniti fuga expedita facere porro non doloribus. Consequatur soluta inventore atque nobis molestiae.','Odit velit et doloremque omnis molestiae temporibus.chitecto dignissimos a sunt. Neque amet placeat qui natus.','53'),
('19','16','Barrows Inc','In odit officiis exercitationem sit saepe','1','3','14','20','120','120','Lilliana Schroeder','Tyrel Blick I','Vidal Mohr','Nulla sit facere quaerat sapiente. Ut id qui sed illo autem ut vitae. Id eius facere rerum consequatur dolorem aliquam veritatis.','Ut veritatis voluptatem earum sunt qui tempore. Vel iure at architecto omnis. Corporis minima animi ad voluptatem error voluptatem. Fuga impedit ipsum cumque quo tempora omnis.','Aut deleniti veritatis explicabo reiciendis. Numquam et animi et neque totam qui. Consequuntur non necessitatibus nostrum praesentium mollitia doloremque.','54'),
('20','8','Amore Group','Esse beatae dolores sunt nobis veritatis illo exercitationem explicabo','1','4','6','10','15','30','Omari Christiansen','Monte West Sr.','Ruth Jacobson','Voluptas possimus porro architecto iste. Qui quia magnam et. Magnam quam numquam a molestias atque autem provident et.','Velit omnis vero aut aliquid rerum quisquam. Eius odio in maiores quo illo et aspernatur.','Est quidem minima qui ea laboriosam. Nulla quasi harum adipisci hic ea sint. Dolores iste cumque doloribus consequuntur nihil.','55'),
('21','5','Goldner PLC','Id aliquid rem officiis libero quia','2','5','8','5','20','60','Nathen Corwin II','Ms. Vivienne Beahan','Annamarie Franecki','Aut cum adipisci pariatur sint et fugiat. Tempora magnam sunt consectetur a vel eaque facere. Ut molestias omnis explicabo porro. Ullam quibusdam alias quam quisquam praesentium molestias quasi.','Et ducimus numquam dignissimos id et debitis ut. Laudantium necessitatibus est iure consequatur. Id voluptas ea dolorem rerum officia. Quos dolorum ea quis necessitatibus sunt et. Perferendis provident vel voluptatem quasi aspernatur.','Quidem et quis quasi dolor in quod rem quam.','56'),
('22','7','Thompson and Sons','Temporibus dolores iusto voluptatem nobis.','2','4','14','15','40','60','Mathias Paucek','Loren Volkman','Genevieve Kautzer','Dolorem asperiores voluptas et totam. Eius sed alias non quisquam totam. Omnis ad minus non. Ut natus ex tempore.','Aliquam beatae sit cum consequatur. Sint voluptas sit ducimus. Quia quod assumenda et soluta nihil.','Odit quod excepturi dicta eos veniam eligendi dolorum. Suscipit architecto dignissimos aperiam reprehenderit dolorum ut est. Deserunt non vel repudiandae consequatur.','57'),
('23','9','Kuhlman, Abbott and Terry','Aut natus reiciendis laudantium mollitia. ','1','4','14','40','120','150','Jamil Stokes','Dr. Isaias Collins Jr.','Dr. Tara Windler','Ratione debitis error ipsam harum. Voluptatum qui maxime voluptatem consequuntur sunt. Repudiandae esse voluptatem et dolorem. Fugit velit blanditiis tempora aperiam.','Eveniet rem quidem dolor nam ut harum cupiditate. Modi commodi non sint minima nihil sint asperiores. Porro ad mollitia perferendis quam sed.','Vitae qui fugit sed temporibus rerum asperiores nesciunt. Ut magni accusantium velit quod et necessitatibus. Rerum cum velit impedit et sed mollitia.','58'),
('24','4','Streich, Prohaska and Berge','Sint est aut unde voluptas necessitatibus a','2','6','10','5','15','30','Reanna Bradtke','Miss Estelle Emard','Camryn Hegmann','Perferendis hic officiis molestiae quaerat recusandae quis doloribus aut. Corrupti a laborum voluptatem. Sunt nemo aut ut voluptatem aut animi.','Ex sapiente voluptas est fugiat neque unde dolores. Earum dicta assumenda ut enim dicta. Aut nisi nulla odio neque. Est cumque rem facilis distinctio eos sed temporibus.','Expedita accusantium et perspiciatis ipsa esse. Officia alias nobis totam voluptas facilis laborum','59'),
('25','17','Tremblay, O\'Conner and Gutkowski','Et rerum voluptatem dolor modi accusantium.','1','4','14','10','20','30','Ana Beier','Rubie Keebler II','Monty Davis','Repudiandae adipisci omnis pariatur nulla iste. Voluptatem expedita dolorum nulla repellendus enim est officia. Odit delectus dolorem eligendi voluptatum culpa. Earum aut id magni beatae enim.','Quaerat a vel dignissimos recusandae nobis fugit in suscipit. Distinctio occaecati quis ut porro. Necessitatibus quis unde architecto maiores esse nihil consequuntur. Voluptate quasi quibusdam et.','Aut laborum nostrum et dolorem.','60'),
('26','2','Stamm Ltd','Ratione accusantium quia pariatur consequatur officiis illo aut.','2','6','8','15','20','40','Reuben Hartmann','Miss Bethel Corwin IV','Emie Rogahn','Esse reprehenderit ullam fugiat quia. Harum quisquam aliquam eligendi asperiores ratione. Ut occaecati enim ut deserunt quis.','Sint voluptatem nobis aut voluptatem. Est eaque id sit delectus mollitia sequi ducimus. Ipsa dolores fugit ut inventore blanditiis.','Cum error eveniet commodi sequi. Facere perspiciatis sapiente omnis assumenda. Eum iste pariatur dolorem.',NULL),
('27','2','Gulgowski, Gaylord and Hahn','Facere facilis nihil provident et ratione reprehenderit.','2','4','6','10','30','60','Ewell Upton','Antonetta West','Ms. Jaclyn Tromp','Architecto amet velit saepe quisquam optio animi. Molestias non dignissimos ducimus qui ipsa. Suscipit enim rerum hic in quo et. Doloremque sint dicta inventore.','Ad qui at quod quidem. Tenetur necessitatibus numquam ut expedita. Praesentium blanditiis rem et aperiam et eos qui.','Sint officiis beatae sit adipisci dolor qui. Sed optio dicta odit et laborum sint ex',NULL),
('28','5','O\'Keefe, Wintheiser and Bartoletti','Excepturi dolore delectus qui est cupiditate laboriosam eum rerum. Corporis nihil aut delectus illum.','2','4','14','60','120','150','Jerome Jast','Prof. Emmie Bernier Sr.','Kelsi Eichmann','Temporibus nam alias harum quae in hic. Distinctio fugit libero qui saepe expedita dignissimos ducimus. Tempora itaque sequi sint. Numquam quia voluptatibus quod et illo.','Libero magnam delectus iste non. Sed voluptatem enim voluptatem iusto. Necessitatibus amet et necessitatibus hic.','Aperiam eaque eum totam quisquam aut nostrum','58'),
('29','18','Davis, Morissette and Kohler','Et autem modi sed qui.','1','4','8','15','50','60','Eloise Schultz','Brannon Mayer','Dr. Isom Hand DVM','Quaerat nam vel aliquid et laboriosam maiores. Atque esse in aut consequuntur voluptatibus consequuntur. Numquam et dicta odit reprehenderit pariatur.','Architecto dolores aliquam vitae eaque ab quia totam. Aperiam dolores doloremque deleniti magnam suscipit ratione possimus. Aspernatur incidunt aliquid qui ut. Consequatur praesentium quidem sit.','Sit exercitationem sint et voluptates harum','46'),
('30','2','Hilll and Sons','Et aut necessitatibus et voluptate. Odio est dolores minima in ut. Enim ducimus sapiente magnam unde odit sit laborum. Tempore aut quibusdam voluptatem.','0','127','3','127','7','127','Ms. Lia Streich','Ike Watsica','Ms. Cydney Treutel DDS','Et et occaecati aut occaecati voluptatem. Facere et maxime non doloremque quisquam sit occaecati. Tempora ea debitis et. Reprehenderit est in qui quo debitis ut nostrum.','Vitae dolor in non. Ut aliquid officiis est perferendis magnam ipsam. Et voluptatem vel atque soluta.', 'atem voluptate eos sint. Quis est et sint dolores','44'),
('31','8','Zboncak-Schneider','Temporibus dolorem saepe et quibusdam','2','6','12','30','60','80','Dr. Sarina Dickens III','Dr. Ada Frami','Aaliyah Block','Cumque et voluptate quia aut fugiat eveniet. Maxime sed reiciendis autem quas vitae eligendi ut. Dolor est cupiditate dolore ratione animi.','Quis et perferendis libero fuga quibusdam qui ullam quia. Et quidem nulla provident eos harum cumque velit. Nihil quisquam non est. Voluptas vitae non ut voluptas ipsam qui sed.','Quia ut quas velit. Eveniet voluptates commodi eligendi in quam..','38'),
('32','4','McDermott Group','Sed qua','2','4','4','10','15','20','Dr. Odie Abernathy DDS','Maverick Connelly','Lindsay Ledner DVM','Nam esse cupiditate repellat nobis est. Quod tenetur hic dolorem eligendi. Esse quia dolorem doloribus ut libero qui quos.','Ipsam beatae qui itaque error necessitatibus iusto suscipit omnis. Hic consequatur doloribus neque doloribus quia culpa.','Delectus ipsam et neque quia autem nostrum sint. Eius amet pariatur ut consectetur. Velit cupiditate sint molestiae repellat deleniti ullam. Minima dolorum asperiores voluptatem veniam ab.','39'),
('33','8','Schaefer and Sons','Esse excepturi unde numquam.','2','4','10','10','20','40','Etha Mills','Fanny Flatley','Oran Becker','Occaecati eos quis est sit ratione. Soluta eius minima illo et. Ad iure occaecati rerum veniam sit non illo. Quidem qui adipisci ipsa nisi.','Ad provident harum illo modi ipsam sit distinctio soluta. Facilis accusamus quo quia harum minus ea aliquid. Iusto deserunt possimus aut ea facilis sint.','Adipisci quisquam est voluptatum aut est. Et tenetur ullam non doloribus rerum totam dicta in. Veniam temporibus repellat dolorem quas quia.','36'),
('34','5','Orn PLC','Provident numquam vitae autem et ea officiis.','2','5','6','15','20','30','Alexandro Frami','Sandra Bogisich','Ena Hackett','Est quos dicta eum voluptatem. Exercitationem dolorem tempore autem est ducimus id. Itaque repellat praesentium dolorem in nostrum.','Voluptate illum molestiae omnis ea id recusandae est. Minima eos culpa officia velit. Ut cupiditate voluptatem qui ea enim aut commodi. Eum commodi et recusandae consectetur aut cumque.','Non laboriosam beatae delectus vel. Et consequatur deserunt sapiente ut. Ex nesciunt placeat delectus. Sunt mollitia est est molestiae.','40'),
('35','7','Weimann, Kub and Runte','Dolorem officiis quo consequatur qui.','3','8','10','15','30','127','Karianne Berge','Antonia Kunde','Tia Weber','At quia ipsa nam cumque voluptatem ex. Assumenda earum omnis non sapiente quo recusandae. Sed cum id iste doloribus. Eos consectetur est laboriosam perspiciatis sint sed et.','Quidem doloribus quidem reiciendis eum vel. Harum officiis placeat itaque excepturi temporibus dolores sequi. Praesentium quis sed voluptas ut velit. Commodi rerum sunt at ut autem consequatur.','Occaecati et voluptas at quo autem rerum aspernatur.','41'),
('36','7','Okuneva, Grant and Borer','Inventore atque magnam incidunt quis eligendi.','2','4','10','20','45','60','Angus Gerhold','Mr. Denis Leffler MD','Mrs. Kaitlyn Romaguera','Suscipit cum earum quod magnam nisi. Eius voluptatum aut vitae iure magnam quo. Placeat molestias eum commodi hic.','Ut accusantium praesentium culpa nobis tempore. Eveniet molestiae mollitia ut adipisci consequuntur doloribus.','Qui sint voluptas velit soluta illo et. Consequatur voluptatem ex iusto quo velit. Ea officiis vel in ab provident.','42'),
('37','7','Hayes Ltd','Suscipit eos deserunt atque iusto','1','4','14','30','60','120','Prof. Mathilde Nienow I','Trenton Champlin','Dr. Cecilia Gulgowski','Illum perspiciatis doloremque velit vitae. Rerum a et quas amet. Itaque consequatur ut voluptatem sint ducimus est dicta. Et adipisci ullam occaecati in omnis qui.','Expedita odio reiciendis cum et dolore. Asperiores vitae veritatis illo non et optio. Eius aut aliquid quia eveniet ipsam iure minus.','Ad natus non repellendus in sed. Pariatur sit asperiores consectetur aliquid est labore modi. Harum tempore nemo accusamus explicabo excepturi.','43'),
('38','6','Bogisich-Grady','Error amet commodi aut unde','1','6','8','15','25','30','Marcellus Wiza DVM','Kraig Weber','Gaston Bosco','Eos inventore ut veniam nobis fugit sit. Odit aut qui optio nihil nostrum neque est. Incidunt voluptates at dolorem distinctio.','Voluptas dolor libero est quis officiis veniam. Quod sunt consequatur sit quaerat nesciunt. Esse quis exercitationem ut qui et exercitationem veritatis. Et alias quia maiores eius.','Qui dolorem vero molestias quisquam sit eaque. Est qui earum quia vitae optio error minima veniam.','45'),
('39','6','Stamm-Rogahn','Aperiam sapiente laboriosam ','3','10','6','5','15','25','Mr. Nelson Nader III','Halie Aufderhar DDS','Miss Mona Dietrich V','Laborum iure architecto ut iste aut aut. Quam non eum cum. Ab iure culpa dicta quam libero deserunt velit. Quia ut ut sit voluptas nisi dolor.','Architecto nihil et qui quos rem. Quia consequatur inventore atque minus nesciunt officia nobis. Autem tempora accusantium animi. Est velit odio cum amet sequi occaecati illo saepe.','Accusantium ex aliquam est repudiandae','47'),
('40','8','Prohaska-Johnston','Nulla unde voluptatibus.','2','4','8','15','20','45','Toby Schmitt','Dr. Hilda Flatley','Michel Kreiger V','Dolores officia eos qui facilis eum mollitia possimus. Dolores autem voluptas suscipit dignissimos eum culpa et.','Non animi eos laborum placeat sed. Fugit enim esse qui labore. Corporis minima excepturi ab qui. Impedit alias earum dignissimos esse et vero.','Quam minima sint vel fugiat quam accusamus harum. Magnam voluptatem provident aliquid ut sint. Sequi animi et totam sint.','49'),
('41','7','Fisher, Raynor and Rath','Et architecto tempora omnis enim fugiat sed sapiente.','2','2','14','45','120','150','Gerda Gorczany','Grayson Stiedemann','Teresa Nader','Voluptas harum saepe impedit eveniet distinctio assumenda. Excepturi id velit aperiam ut occaecati laudantium. Deserunt ipsa odio ipsa labore. Fuga nulla sit incidunt qui dolorem.','Ex qui at dicta voluptas vero cumque facere. Ut ullam laboriosam voluptates consectetur. Delectus error vero placeat velit dolor cupiditate rerum. Nihil ullam.','Et unde voluptas voluptatem voluptatem','50'),
('42','9','Gutmann Group','Minus ut delectus est est quisquam ab aut.','2','4','12','20','40','60','Mr. Garett Koch','Adele Pfannerstill MD','Lindsay Kunde','Commodi sapiente iure aliquid commodi ad veniam. Ad eius et ex sapiente mollitia. Vel cum incidunt vel quibusdam qui earum expedita.','Temporibus praesentium unde eum illum aut non optio distinctio. Doloribus possimus veniam est aliquid. Aspernatur placeat doloremque ut. Cupiditate est laborum recusandae minus fugiat.','Non laboriosam voluptas ut tenetur. Tempo ea quo culpa aut.',NULL),
('43','7','Bahringer-Kuhic','Qui voluptate repudiandae velit.','1','4','14','15','60','60','Rashawn Grant DVM','Marcella Reilly MD','Stefanie Heathcote','Nobis voluptas esse quia vel. Reiciendis commodi eos enim rem repudiandae possimus. Quia ut molestias sequi voluptas aut exercitationem.','Voluptas ut asperiores saepe minima. Voluptas illum magni sed cum iusto velit. Ut placeat repellendus quas fuga quia. Ad voluptate unde sint assumenda vitae.','Unde non molestiae iste ut. Consequatur expedita incidunt rerum officia fugit temporibus molestiae. Sint cum qui et mollitia.',NULL),
('44','6','Graham, Jakubowski and Lesch','Possimus aspernatur dolorum','1','4','10','15','30','40','Prof. Doyle Watsica','Mr. Caleb Zieme','Prof. Marjolaine Stamm','Culpa esse quis atque qui rerum omnis. Molestiae et amet vel laudantium et. Dolorem aut esse impedit velit. Quos temporibus sed magni.','Repudiandae quas libero est cupiditate saepe nostrum et. Nulla sed repellat sit autem. Quas ut voluptatibus delectus totam. Aut molestiae sed et officia.','Quo accusantium suscipit neque quis. Aliquid vitae neque qui soluta',NULL),
('45','19','Nicolas-Crist','At quasi quo rerum architecto eos voluptate. Neque nostrum optio ut optio.','1','4','12','15','30','60','Wilfrid Batz','Rodger Windler V','Esperanza Rath','Pariatur qui nam nisi est a. Quas incidunt atque maxime quos et reiciendis. Aut laudantium ducimus qui accusamus itaque.','Quia itaque saepe aut. Atque repellat nemo maiores sit ut. Aut quo voluptas cumque unde pariatur. Nam animi nisi iure.','Ea iste aut ut nemo. Tempore ipsam iste iure dolores velit. Officia optio consectetur numquam non itaque rerum et impedit.','51'),
('46','6','Kuphal PLC','A nisi nemo et voluptatum dolor.','2','4','6','15','20','40','Anastasia Cummings','Anderson Crooks','Louie Mayert','Qui ad id et harum et. Harum nostrum provident sit. Enim odit dignissimos perspiciatis consectetur nihil fugiat temporibus vel. Quam illum ea non unde reprehenderit tempora et rem.','Atque eum voluptas rerum architecto consectetur molestiae voluptas exercitationem. Dolorem esse voluptate fugit a dolor magnam quis. Ut dolorem in et impedit. Nulla magni asperiores in labore architecto aliquam.','Dolores et ut eum illum unde dolorum ad. Maiores sit sint nobis ab dicta.','52'),
('47','20','Krajcik-Hansen','Corporis et adipisci rem quibusdam earum tenetur dolorem.','1','4','14','20','30','60','Dr. Breanne Reilly','Leonor Berge','Estelle Gottlieb DDS','Inventore esse sed rerum amet debitis. Quis assumenda a sit facilis assumenda. Dolorem fugiat hic sed pariatur maiores et et.','Culpa assumenda reiciendis labore perferendis vero. A eligendi doloribus tempore sit. Odit est fugiat aliquam inventore tempora eum.','Dolor consectetur earum in quia ipsa. Hic aut vel molestiae quasi. Laborum vel quis recusandae eos expedita voluptas error error.','53'),
('48','5','Dickinson LLC','Nemo hic blanditiis magni sed debitis','2','4','14','30','60','90','Prof. Lelah Larkin Sr.','Dr. Nannie Doyle PhD','Armani Leuschke','Aperiam et sint sed nesciunt. Odit ut ea at modi alias. Quasi voluptatem ea quae distinctio.','Sed vel magnam unde eos repellendus. Accusamus neque voluptates quia.','Corporis dolorem illum tenetur id est. Nulla maxime architecto autem odio fuga a illo. Et deleniti et voluptatem repellendus incidunt illum.','54'),
('49','5','Jaskolski, Heaney and Bernhard','Veritatis architecto impedit dolor quos odit est. Ipsam est distinctio explicabo aspernatur ipsa officiis velit.','1','3','12','20','45','60','Mr. Zackery Murray I','Mrs. Tiffany Nicolas PhD','Kara Bogan','In qui neque qui officia provident laborum quis. Sed voluptas voluptatem necessitatibus est dolor officia iste. Maxime quam repudiandae ex est exercitationem voluptatem.','Maiores corrupti animi natus recusandae esse velit et. Tempore ad eos facere.','Sed ipsa quasi omnis aut fugiat est quos ut.',NULL),
('50','20','Bernhard LLC','Placeat reiciendis laborum voluptatem voluptas. Qui placeat dolorum mollitia aperiam. Vero autem dolorem voluptatem qui amet.','127','2','6','8','45','60','Leif Kunde','Nya Kilback','Larry Runte','Autem nisi dolores voluptatem consequatur sint natus. Sed et et sequi sunt qui earum. Inventore animi vero officia ut et assumenda explicabo. Rem aut quis quaerat.','Non ex veritatis sed fugiat non. Rerum suscipit nulla neque maiores quaerat accusantium eum ab.','Voluptate error consectetur quis',NULL); 

INSERT INTO `categories` (`name`) VALUES ('wargames'),
('cards'),
('history'),
('classics'),
('family'),
('company'),
('logic'),
('economics');

INSERT into games_categories VALUES ('5','3'),
('9','3'),
('6','1'),
('7','8'),
('2','8'),
('27','2'),
('18','8'),
('5','8'),
('3','6'),
('6','3'),
('28','8'),
('35','3'),
('15','8'),
('3','3'),
('8','1'),
('6','8'),
('22','1'),
('7','4'),
('10','1'),
('7','2'),
('8','5'),
('4','2'),
('9','6'),
('9','1'),
('1','8'),
('2','3'),
('2','4'),
('8','8');


INSERT INTO users_clubs VALUES
   ('2', '3'),
   ('2', '7'),
   ('2', '10'),
   ('2', '12'),
   ('4', '22'),
   ('4', '7'),
   ('4', '26'),
   ('5', '38'),
   ('5', '10'),
   ('6', '42'),
   ('6', '3'),
   ('11', '3'),
   ('15', '12'),
   ('15', '22'),
   ('17', '38'),
   ('17', '12'),
   ('17', '26'),
   ('19', '42'),
   ('20', '3'),
   ('20', '7');

INSERT INTO users_events VALUES
   ('2', '1'),
   ('2', '9'),
   ('2', '14'),
   ('2', '24'),
   ('4', '23'),
   ('4', '40'),
   ('4', '50'),
   ('5', '9'),
   ('5', '1'),
   ('6', '40'),
   ('6', '14'),
   ('29', '1'),
   ('15', '24'),
   ('30', '23'),
   ('17', '40'),
   ('17', '50'),
   ('33', '1'),
   ('19', '1'),
   ('20', '14'),
   ('20', '23');
  
  INSERT INTO user_games VALUES
   ('2', '1'),
   ('2', '9'),
   ('2', '14'),
   ('2', '24'),
   ('2', '30'),
   ('2', '34'),
   ('2', '41'),
   ('2', '50'),
   ('2', '15'),
   ('4', '23'),
   ('4', '40'),
   ('4', '50'),
   ('5', '9'),
   ('5', '1'),
   ('5', '14'),
   ('5', '30'),
   ('5', '32'),
   ('5', '11'),
   ('5', '2'),
   ('6', '40'),
   ('6', '14'),
   ('29', '1'),
   ('15', '24'),
   ('30', '23'),
   ('17', '40'),
   ('17', '50'),
   ('33', '1'),
   ('19', '1'),
   ('20', '14'),
   ('20', '23'),
   ('27', '8'),
   ('28', '1'),
   ('28', '6'),
   ('28', '7'),
   ('28', '9'),
   ('28', '19'),
   ('29', '22'),
   ('30', '5'),
   ('30', '6'),
   ('30', '10'),
   ('31', '1'),
   ('32', '9'),
   ('32', '14'),
   ('32', '24'),
   ('33', '11'),
   ('33', '15'),
   ('33', '16'),
   ('33', '34'),
   ('34', '36'),
   ('35', '48');

INSERT INTO `user_sells` VALUES ('2','7','5','new','Et quaerat possimus quos.','2020-08-26 17:29:20',0),
('2','4','4978','secondhand','Veniam qui asperiores commodi et velit porro.','2020-08-19 13:09:55',0),
('28','6','2700','secondhand','Reprehenderit voluptatem doloremque et omnis exercitationem voluptatem natus assumenda.','2020-08-29 13:09:38',0),
('29','7','4680','secondhand','Aut autem suscipit asperiores perspiciatis et ex.','2020-08-25 12:18:39',0),
('29','3','3500','new','Explicabo et quia dolor nesciunt debitis quis quia.','2020-08-20 18:38:22',0),
('29','2','7094','secondhand','Voluptatibus reiciendis voluptatibus aspernatur quidem alias rerum.','2020-08-04 04:43:01',1),
('30','40','2000','new','Placeat aut commodi reprehenderit eius minima dicta asperiores beatae.','2020-08-13 11:37:41',0),
('30','4','7982','secondhand','Quis vel optio ad et aspernatur.','2020-08-26 01:55:50',0),
('6','5','5021','secondhand','Est officia amet laborum veritatis nemo.','2020-08-26 00:25:30',0),
('11','1','2443','secondhand','Quam totam ullam adipisci doloremque aut quas.','2020-08-25 17:17:55',0),
('11','6','3373','secondhand','Sed id placeat culpa qui impedit sint sit animi.','2020-08-06 07:45:48',0),
('11','10','1159','new','Et esse ut quod dolorem nisi quia.','2020-08-26 06:10:17',0),
('15','2','4841','secondhand','Cum est ea hic voluptate quis sunt quia.','2020-08-21 19:43:12',0),
('15','9','7639','new','Maxime eos enim rerum aspernatur rerum recusandae ut.','2020-08-04 22:59:08',1),
('16','3','4259','secondhand','Maxime occaecati perspiciatis sunt corrupti molestiae voluptas.','2020-08-29 22:57:07',1),
('16','7','4687','new','Eligendi qui ea ea voluptatem.','2020-08-28 23:01:32',1),
('16','9','2500','new','Et consequatur illo voluptatem nulla fuga unde necessitatibus.','2020-08-10 22:06:40',0),
('17','7','5649','secondhand','Omnis aliquid id omnis architecto fugit.','2020-08-18 18:12:47',0),
('18','7','6286','secondhand','Optio delectus assumenda molestias ab voluptates sapiente.','2020-08-23 01:54:08',0),
('18','6','2629','new','Dolor est tempora cum consequatur nam error.','2020-08-28 13:31:36',0),
('19','8','3000','secondhand','Occaecati et ut adipisci maiores vel aut soluta.','2020-08-22 20:21:55',0),
('20','5','4161','new','Corporis modi mollitia neque quia eos vel.','2020-08-24 09:12:55',1),
('20','7','1900','new','Quis excepturi reprehenderit tempore nemo at et minima.','2020-08-04 13:38:46',0),
('20','30','1911','secondhand','Non ipsum quia labore rerum vero quia facilis.','2020-08-21 22:18:13',0),
('20','3','2199','new','Eius laudantium voluptatem alias rerum perferendis temporibus reprehenderit molestias.','2020-08-28 01:25:27',0),
('27','20','3254','new','Ex expedita possimus in nemo sed et dolores.','2020-08-20 16:22:00',0),
('27','4','8890','new','Natus quia et illum cupiditate.','2020-08-25 11:14:37',0),
('27','39','3000','new','Harum omnis et ipsum nam voluptates at facilis.','2020-08-31 19:40:50',0),
('28','22','2000','new','Sapiente est voluptatum consectetur veritatis.','2020-08-20 20:33:37',0),
('28','35','3236','secondhand','Tenetur fuga unde est alias.','2020-08-15 02:49:11',0); 

INSERT INTO `user_buys` VALUES ('4','39','any','Minus accusamus eligendi odio pariatur praesentium necessitatibus.','2020-08-31 18:37:27',0),
('4','43','new','Alias repudiandae qui voluptas magni cumque iusto facilis.','2020-08-20 09:04:05',0),
('5','11','secondhand','Ea quis cumque laborum mollitia pariatur aspernatur quod amet.','2020-08-23 23:06:49',0),
('6','25','any','Omnis est quidem cum qui et.','2020-08-08 23:25:18',0),
('11','41','secondhand','In reprehenderit et dignissimos aliquid officiis in.','2020-08-19 01:32:06',0),
('11','7','any','Inventore aut corrupti quidem dolor.','2020-08-02 18:41:34',1),
('15','5','new','Molestiae ut harum vel nostrum.','2020-08-08 23:45:24',0),
('16','10','new','Aut nam qui ipsum nihil aut.','2020-08-14 21:42:13',0),
('16','7','any','Asperiores dignissimos quos facilis aut ut animi architecto.','2020-08-26 17:25:32',0),
('16','2','secondhand','Qui deserunt corrupti aut velit quia debitis.','2020-09-01 17:37:31',0),
('17','6','new','Harum aut reiciendis eos exercitationem quidem.','2020-08-17 02:47:00',0),
('18','18','any','Deserunt dolor debitis omnis ut iste optio eum.','2020-08-29 17:40:30',0),
('19','39','new','Id et rem numquam nulla dolores.','2020-08-16 03:05:56',0),
('20','26','secondhand','Aliquam eaque laborum accusamus sint id hic esse.','2020-09-02 00:53:02',1),
('20','7','new','Quo alias rem quis et asperiores earum rerum.','2020-08-22 12:43:58',0),
('20','9','any','Nihil eum voluptatem facilis voluptas.','2020-08-11 04:10:45',0),
('20','8','new','Itaque a repellat et asperiores velit et.','2020-08-27 05:47:08',0),
('27','6','new','Ut qui delectus quo tenetur in.','2020-08-16 21:36:26',1),
('27','32','any','Sint corrupti quis architecto quia omnis.','2020-08-09 20:39:05',0),
('28','19','new','Aut expedita molestiae incidunt ea est vitae voluptate.','2020-08-07 21:28:55',0),
('29','14','any','Ipsa quos doloribus occaecati itaque earum dolorem tempora.','2020-08-10 18:06:02',0),
('30','27','secondhand','Consequatur aut illo qui iusto nesciunt eaque et.','2020-09-01 07:45:36',0),
('30','9','any','Et non vero consequatur ducimus quasi sint dolor.','2020-08-21 14:29:34',1),
('30','8','secondhand','Ipsum maiores ut temporibus possimus et.','2020-08-26 00:40:08',0),
('31','47','any','Quia vitae non aut qui.','2020-09-02 13:41:05',0),
('31','40','any','Mollitia et rerum ab aspernatur amet et sed labore.','2020-08-15 06:38:35',0),
('32','5','new','Dolorum animi molestiae sed corporis ut excepturi natus quam.','2020-08-28 17:03:27',0),
('33','24','secondhand','Quia omnis ut impedit qui ut.','2020-08-17 16:55:49',0),
('34','17','new','Qui ea natus atque et qui aliquid.','2020-08-19 13:50:16',0),
('35','47','secondhand','Rerum velit dignissimos consectetur asperiores magnam.','2020-08-19 05:05:37',0); 

INSERT INTO `game_media` VALUES ('2','5'),
('6','27'),
('7','8'),
('1','15'),
('20','2'),
('9','6'),
('9','8'),
('15','19'),
('38','38'),
('48','26'),
('26','18'),
('2','1'),
('23','13'),
('19','39'),
('16','9'),
('44','22'),
('44','15'),
('39','17'),
('21','25'),
('13','5'); 

INSERT INTO `account_media` VALUES ('4','7'),
('8','8'),
('2','4'),
('3','17'),
('17','25'),
('28','1'),
('7','5'),
('7','3'),
('18','15'),
('12','6'),
('43','11'),
('25','22'),
('1','31'),
('20','9'),
('5','18'),
('14','32'),
('37','2'),
('15','24'),
('31','19'),
('31','33'); 

INSERT INTO `friend_requests` VALUES ('4','5','unfriended','2019-11-20 18:33:24','2020-08-22 05:52:04'),
('5','2','requested','2020-01-29 23:36:34','2020-08-05 18:57:27'),
('1','6','unfriended','2020-01-20 04:47:02','2020-08-04 12:26:47'),
('1','11','declined','2020-03-24 04:54:06','2020-08-05 01:35:38'),
('15','5','approved','2020-05-24 19:14:10','2020-09-02 01:49:46'),
('2','4','approved','2019-10-27 12:05:42','2020-08-08 01:24:18'),
('6','4','requested','2019-12-26 06:44:09','2020-08-28 22:50:30'),
('11','3','unfriended','2019-09-12 04:36:16','2020-08-05 21:15:16'),
('15','1','approved','2020-08-27 16:44:23','2020-08-15 09:11:49'),
('6','17','approved','2019-11-22 16:35:00','2020-08-20 04:51:18'),
('17','18','approved','2020-01-31 01:23:48','2020-08-13 23:12:03'),
('19','8','declined','2019-12-08 07:06:45','2020-08-25 13:05:55'),
('20','1','unfriended','2019-11-22 15:56:33','2020-08-29 15:57:29'),
('27','20','unfriended','2019-10-12 15:52:51','2020-08-04 02:34:39'),
('18','11','approved','2020-03-23 16:47:44','2020-08-12 03:40:06'),
('27','9','declined','2020-05-20 22:12:04','2020-08-11 00:17:41'),
('2','28','declined','2020-03-07 11:47:16','2020-08-05 04:48:23'),
('1','28','requested','2020-05-22 21:35:09','2020-08-13 17:39:07'),
('29','5','requested','2020-05-21 23:31:55','2020-08-04 11:12:13'),
('4','29','declined','2020-01-18 09:35:27','2020-08-22 12:18:49'),
('9','30','unfriended','2020-01-15 09:28:21','2020-08-30 14:43:50'),
('8','31','approved','2020-07-03 00:25:18','2020-08-15 22:23:18'),
('2','31','requested','2020-08-19 07:15:01','2020-08-20 17:00:37'),
('31','7','requested','2020-03-09 22:16:25','2020-08-03 17:42:14'),
('32','3','declined','2019-12-29 19:31:01','2020-09-02 06:13:38'),
('6','32','unfriended','2020-02-24 09:30:42','2020-08-16 01:17:01'),
('7','33','approved','2020-06-23 20:10:12','2020-08-03 11:18:13'),
('9','33','requested','2020-06-27 23:45:37','2020-08-16 00:04:36'),
('33','3','declined','2020-05-06 21:15:40','2020-08-06 12:11:25'),
('27','34','unfriended','2019-12-12 03:47:25','2020-08-08 12:40:57'); 

INSERT INTO `messages` VALUES ('1','6','5','Saepe voluptas ipsam corporis id at hic rerum.','2020-03-10 13:06:15',0),
('2','3','1','Est eius dicta nemo provident.','2020-03-21 10:18:25',0),
('3','8','5','Non illum sunt at odit similique.','2020-04-23 22:45:53',0),
('4','1','5','Dolore non iusto odit error quae nihil.','2020-07-22 09:36:36',0),
('5','8','1','Tempore consequuntur sequi cumque consequatur et a.','2020-06-17 04:04:02',0),
('6','1','1','Corporis ut quia ad.','2019-11-19 09:03:04',0),
('7','6','6','Qui ut voluptatem perferendis debitis autem harum.','2019-09-20 13:30:19',1),
('8','1','8','Est iusto odio eius omnis.','2020-08-06 11:47:26',0),
('9','1','1','Fuga maiores aliquid reiciendis sequi.','2020-06-02 23:30:35',0),
('10','4','9','Eum autem repellendus accusamus itaque.','2020-06-09 05:43:43',0),
('11','9','5','Doloribus iusto cumque ratione qui quos molestias.','2020-05-26 01:05:26',0),
('12','1','6','Ex porro cum sunt et suscipit ut vero.','2020-09-02 08:14:08',1),
('13','5','7','Voluptas harum temporibus corrupti maiores.','2020-05-14 00:16:53',0),
('14','6','3','Sint magnam molestiae veritatis animi quidem sed repellendus.','2019-10-07 13:46:01',0),
('15','6','9','Eos et voluptatem numquam autem magni esse voluptatem.','2020-07-31 12:49:29',1),
('16','9','5','Consequuntur exercitationem architecto quasi tempora asperiores iste.','2020-08-19 05:54:55',0),
('17','4','4','Sit eligendi voluptas rem vel velit ea.','2019-12-09 00:43:02',0),
('18','3','6','Est voluptas neque iusto non corrupti.','2020-01-02 14:55:26',0),
('19','4','6','Unde accusantium aperiam nihil laborum odio aut quod.','2020-05-04 01:34:38',0),
('20','2','3','Itaque inventore sed adipisci rerum est illo saepe.','2019-10-23 02:17:45',0),
('21','5','7','Est itaque cum alias delectus ab tenetur.','2020-03-25 21:14:04',0),
('22','5','1','Repellat rerum et et dolorem consequatur dolores sequi.','2020-02-02 14:45:16',1),
('23','1','7','Cum omnis sed sed ipsam.','2020-01-08 13:28:42',0),
('24','4','6','Doloremque ut dolorem autem quo.','2020-07-10 10:31:41',0),
('25','8','5','Animi placeat beatae aut dolorem.','2020-04-13 07:21:36',1),
('26','3','6','Quisquam ratione facilis neque distinctio atque consequatur qui.','2020-02-04 04:41:52',0),
('27','7','1','In rerum rem veritatis nihil harum quis nesciunt.','2020-03-23 01:27:56',0),
('28','5','9','Ex dolor esse impedit voluptatem culpa non.','2020-08-18 19:34:16',0),
('29','7','5','Est occaecati et eveniet quaerat occaecati.','2020-03-19 02:29:18',0),
('30','1','2','Facilis numquam aut qui quos excepturi reiciendis.','2019-10-24 04:58:24',0),
('31','2','9','Est provident mollitia ut.','2020-07-02 04:25:43',1),
('32','6','2','Inventore ratione reprehenderit ut provident aliquam velit.','2020-01-07 04:35:40',0),
('33','3','8','Aut error placeat dolor est sit rerum officiis.','2019-12-20 04:23:55',0),
('34','2','7','Officia fugit ea sequi blanditiis earum facere.','2020-02-02 15:53:04',0),
('35','1','5','Consequatur doloremque nihil ad sunt ex placeat quam.','2020-05-05 19:44:42',0),
('36','5','1','Iure velit voluptatum non libero.','2020-03-25 01:32:18',1),
('37','3','2','Consequatur et ullam qui aut laborum rem.','2020-02-06 21:44:35',0),
('38','7','4','Ipsam et eos sed et laudantium nam eius.','2019-12-10 21:38:44',0),
('39','1','1','Ut voluptas voluptas maiores et nihil consequuntur quos.','2020-03-29 15:44:59',0),
('40','3','8','Incidunt nihil itaque voluptatem libero necessitatibus assumenda.','2020-05-23 07:46:25',0); 

INSERT INTO `articles` VALUES ('1','eos','21','2020-05-13 03:17:32','6','http://smith.com/','Et vel ducimus voluptatibus distinctio vero. Veritatis temporibus est quas quia quae distinctio maxime.',0),
('2','dignissimos','60','2019-09-21 18:31:42','3','http://www.lehnerlarkin.info/','Aut qui iure eum error doloribus voluptates sapiente. Deserunt et fugiat laudantium modi. Corporis totam ut veritatis ut neque. Praesentium dolores debitis quibusdam eum molestiae.',0),
('3','tempora','32','2020-06-12 00:34:28','6','http://www.oconnerdenesik.com/','Necessitatibus ad ratione in repellat quia. Perspiciatis voluptatum consequatur ipsam eos natus. Qui ullam vero error rerum necessitatibus ut eveniet. Odio ab nihil praesentium qui.',0),
('4','optio','27','2019-12-19 21:52:35','7','http://swaniawskikuhlman.com/','Cum quae et nemo velit vel aut sed. Dolore nam excepturi reiciendis cum unde. Quaerat deserunt aperiam ullam quo minima laboriosam neque. Repellendus harum quos perferendis at adipisci molestiae.',0),
('5','et','49','2020-01-12 01:52:49','8','http://homenick.biz/','Praesentium sunt sit quae vitae est est accusantium autem. Facilis voluptatum voluptatem sed sit ipsa voluptas. Laboriosam ut modi deserunt aut a deleniti quos. Quo rerum numquam alias culpa autem odio repellendus.',0),
('6','consequatur','38','2019-11-22 17:25:10','6','http://www.pagac.com/','Nemo sit ipsam esse labore eum. Sunt a et suscipit asperiores est. Cum ut vel dignissimos aut consequuntur harum. Quisquam magni culpa velit nisi voluptates.',0),
('7','porro','29','2019-10-23 04:09:03','2','http://schaden.com/','Sunt ut voluptatum consequatur quam. Debitis delectus similique qui recusandae quidem adipisci consequuntur. Amet non fugiat dignissimos ipsam consequatur aspernatur fugit.',1),
('8','sed','43','2020-06-11 10:17:11','2','http://www.russelhahn.com/','Ut eligendi ea magni voluptas enim eos. Fugiat deserunt autem cupiditate eos. Nobis ad eaque dolorum accusantium magni tenetur.',0),
('9','corporis','37','2019-11-01 14:49:30','4','http://www.flatleydamore.com/','Rerum deserunt voluptas blanditiis est doloremque possimus accusamus quidem. Consectetur dolorem maxime assumenda aliquid. Repudiandae ut officia aut.',0),
('10','qui','27','2020-02-16 22:29:42','8','http://www.funk.org/','Nihil possimus earum soluta et. Ut voluptatem optio incidunt ut. Officiis temporibus ad et ratione quia suscipit.',0),
('11','molestias','49','2019-11-08 09:55:09','5','http://www.jakubowski.org/','Dolorem blanditiis sequi eveniet quos distinctio nesciunt accusamus. Consequatur voluptatem nesciunt id aut aperiam quam. Aliquam vero fugiat doloremque. Qui facere fugit nulla.',0),
('12','excepturi','58','2019-11-13 16:02:23','6','http://www.kuhnbins.com/','Velit rerum rerum corrupti possimus est non. Ut ut facilis odit iste eum rem ipsa nihil. Illo aut inventore velit qui autem voluptatibus aut omnis. Esse consequatur enim laboriosam deleniti dolorum.',0),
('13','aut','23','2020-06-29 12:53:35','8','http://www.auer.com/','Occaecati voluptatum sit et enim nihil voluptates et. Sed non molestiae minima eligendi. Quis earum quibusdam eligendi quia reprehenderit commodi molestiae. Numquam ut quidem reiciendis in. In quas natus rerum.',0),
('14','ea','28','2020-06-10 16:23:31','9','http://howe.info/','Aut ipsum voluptatibus quia modi. Quia laudantium magnam quia cumque et dicta in. Est officiis aliquid eveniet amet ut inventore.',0),
('15','dolores','59','2020-08-14 00:10:31','1','http://www.durganprosacco.com/','Consequatur in qui minus. Non facere cum corrupti occaecati adipisci. Aut maxime et nihil odio officiis fugit cum inventore.',0),
('16','iusto','25','2020-06-06 04:23:59','1','http://www.grimes.biz/','Aperiam assumenda placeat laborum aliquam tempora. Sint modi dignissimos officia sed deserunt ut.',1),
('17','id','46','2020-01-09 01:32:31','4','http://www.ortiz.net/','Perferendis iure sed distinctio qui aut. Nobis laborum sunt vel. Beatae ipsum molestiae omnis. Harum similique rem totam beatae quasi consequatur rerum.',0),
('18','facilis','29','2020-04-02 01:14:02','2','http://www.kessler.com/','Qui repellat repellat accusamus porro veniam nemo. Rerum qui mollitia ut earum nemo in. Cumque est voluptates cumque unde facere nemo. Quasi quae rerum aut id odio quia.',0),
('19','deserunt','23','2020-03-26 08:51:36','1','http://brakus.com/','Cum aliquam eveniet alias ut dolore totam occaecati. In omnis molestiae ipsum molestias. Sit ullam molestiae ut maxime id nihil.',0),
('20','eum','39','2020-04-12 00:35:29','9','http://www.okon.org/','Harum maiores ea vel nesciunt officia. Ut velit temporibus quasi fuga voluptatum adipisci et. Et dolor et inventore. Ipsam animi aut accusantium qui et omnis quisquam.',0),
('21','dolor','45','2020-02-13 12:14:13','6','http://www.conroy.org/','Molestias quia commodi sint itaque neque. Similique inventore quia commodi id recusandae quis magnam porro. Vero adipisci qui in pariatur.',0),
('22','rerum','51','2020-07-19 16:07:23','4','http://www.gusikowski.com/','Aut aut quasi quaerat sint laudantium. Eaque facilis qui totam officiis.',0),
('23','sint','37','2019-10-15 03:30:16','3','http://fadel.info/','Possimus dolorem quis officiis nostrum eveniet odio excepturi. Est quis est accusantium aut. Aperiam veniam accusantium quae qui eum et ut.',0),
('24','quasi','29','2020-07-18 10:22:29','7','http://www.volkmanreilly.com/','Est ut nam eos a sit sit minus. Illum commodi dolor iure et ipsam consequatur. Suscipit sed nostrum maxime occaecati ab assumenda commodi. Qui laborum quod dolores maiores consequatur.',1),
('25','voluptatem','49','2020-01-26 08:32:30','2','http://faykoch.com/','Est voluptatem qui dolore distinctio adipisci repellat. Et et odio culpa. Quos sint est omnis et.',0),
('26','harum','33','2020-07-08 15:27:22','9','http://www.jakubowskischneider.org/','Et sed dolorem voluptatum eos quos voluptates. Et dolores quisquam provident ducimus necessitatibus est. Eaque iure unde aliquam a. Nihil illo est eos quaerat omnis.',0),
('27','veniam','37','2019-11-21 04:19:07','8','http://www.breitenberg.com/','Sed tenetur rerum aut vitae necessitatibus optio consequatur. Est sed aliquam mollitia non quisquam aspernatur velit. Possimus tempore animi expedita ipsam placeat debitis porro eum.',0),
('28','quas','56','2019-10-19 01:16:19','6','http://www.mccullough.com/','Corporis consectetur ex pariatur sequi laudantium. Eaque unde ut autem quod ut minima. Id repellendus non voluptatem omnis voluptatem quasi rerum.',0),
('29','mollitia','42','2019-12-19 10:56:16','9','http://www.mullerheidenreich.com/','Non ea consequatur earum. Soluta beatae ab quis corrupti aut velit. Natus nihil possimus laborum nihil earum rerum.',0),
('30','ipsum','41','2019-12-25 12:44:48','7','http://lehnerflatley.com/','Incidunt accusamus nemo ab ipsa atque suscipit amet. Libero et perspiciatis magni autem consequatur corporis possimus. Voluptatem odit animi natus aliquid. Natus et fugiat dolor quia.',1); 

INSERT INTO `articles_media` VALUES ('7','5'),
('1','4'),
('1','8'),
('4','18'),
('2','28'),
('9','13'),
('3','8'),
('15','34'),
('14','45'),
('27','20'),
('30','6'),
('11','23'),
('15','3'),
('8','8'),
('22','19'),
('28','6'),
('18','12'),
('25','27'),
('2','47'),
('10','14'),
('17','5'),
('16','3'),
('29','16'),
('21','4'),
('24','11'),
('28','22'),
('17','37'),
('5','14'),
('7','34'),
('24','8'); 

INSERT INTO `games_shops` VALUES ('1','3','8','http://www.raynor.org/','5573'),
('2','25','8','http://www.casper.net/','4970'),
('3','21','13','http://www.oconner.com/','3730'),
('4','2','25','http://powlowski.com/','1490'),
('5','8','41','http://schinner.org/','1406'),
('6','6',NULL,'http://www.gulgowski.net/','2000'),
('7','9',NULL,'http://lemkerunolfsson.biz/','1832'),
('8','4',NULL,'http://erdman.com/','5800'),
('9','9','21','http://www.barton.info/','4647'),
('10','6',NULL,'http://jacobson.com/','4900'),
('11','3',NULL,'http://www.harvey.com/','1000'),
('12','3','21','http://riceyundt.com/','5521'),
('13','3','8','http://www.haag.com/','1602'),
('14','6',NULL,'http://rowemonahan.com/','2400'),
('15','6',NULL,'http://balistreribode.com/','2022'),
('16','9',NULL,'http://www.bashirian.biz/','2100'),
('17','9',NULL,'http://powlowski.com/','3000'),
('18','8','8','http://www.harvey.com/','1114'),
('19','3','13','http://rodriguez.com/','2800'),
('20','4','25','http://www.wilkinsonvon.biz/','4124'),
('21','8','41','http://www.harberkunde.biz/','1171'),
('22','7','21','http://www.armstrongcarroll.com/','1430'),
('23','8','8','http://heaneyjerde.com/','6475'),
('24','5','13','http://www.johns.com/','2100'),
('25','8','21','http://rowemedhurst.com/','2500'),
('26','7','41','http://crist.com/','1875'),
('27','1','25','http://www.shanahan.com/','2134'),
('28','7',NULL,'http://www.dach.net/','5905'),
('29','5','8','http://www.bayerbogan.biz/','1600'),
('30','5',NULL,'http://medhurst.org/','4235'); 


INSERT INTO `awards` VALUES ('1','autem','Cupiditate omnis voluptatem qui odio fugit quis harum. Aspernatur autem illum illo autem et voluptates voluptas. Sint et ipsam omnis dolore. Dolore doloremque cum sapiente rerum eaque accusamus. Asperiores est corporis repudiandae quo accusantium id.','5','http://koepp.com/'),
('2','molestias','Nihil aliquid iusto aut accusamus provident. Unde qui commodi ullam voluptas nihil illum non dicta. Ut deserunt eligendi nesciunt asperiores.','6','http://www.cummingslynch.com/'),
('3','accusamus','Dolore exercitationem vel quod nostrum reprehenderit. Est tempora numquam distinctio dolorem sint fugiat illo pariatur. Suscipit magni explicabo qui ut unde odit.','16','http://bartell.net/'),
('4','iusto','Officia porro quo ex. Dolor neque omnis illum illum quidem. Doloremque minus maiores aut. Id aut sunt non quis.','6','http://shields.com/'),
('5','fuga','Inventore accusantium hic porro voluptatem sint. Mollitia tempora eius cumque iste cum. Molestiae nobis ratione et. Optio dolor et optio assumenda.','3','http://www.uptonbosco.info/'),
('6','et','Quae minima natus voluptate cum. Ipsum eum rerum sit. Assumenda ea id molestiae hic omnis quia similique. Omnis deserunt odit mollitia quo.','1','http://mclaughlin.biz/'),
('7','adipisci','Et optio reprehenderit dolore. Et rerum et omnis aut sit dignissimos. Ad commodi est numquam vel.','8','http://glover.info/'),
('8','rerum','In quisquam non rerum sunt. Aut numquam nulla dolorum perferendis. Adipisci sunt ut corporis non aut. Voluptatem vero sunt fuga repellat et ut.','8','http://www.thompson.com/'),
('9','dolorem','Nobis quaerat dolor quas qui. Illum eaque voluptatum ratione nobis qui. Cupiditate distinctio eum quis pariatur.','8','http://lockman.com/'),
('10','nam','Provident et similique et quis exercitationem. Vero dolor id assumenda ex perferendis. Deserunt amet consequatur enim ea qui eos. Et magnam et rerum delectus praesentium facere.','3','http://www.heaney.org/'),
('11','quam','Fuga voluptate placeat ipsa. Voluptas laboriosam modi quos molestiae a iure quae. Nostrum quia et sunt odit.','5','http://www.koelpin.org/'),
('12','veniam','Atque sint eos eos. Rerum quis pariatur doloribus et. Quos ipsam magnam cumque nihil aut dolorem. Ullam maiores est eveniet quia dolore.','7','http://www.kertzmann.biz/'),
('13','qui','Molestiae dignissimos quidem accusamus placeat est animi. Earum pariatur ut tenetur labore non omnis aut.','4','http://www.huelsraynor.biz/'),
('14','animi','Repellendus eos corporis aperiam vitae et beatae. Et ex perspiciatis occaecati sapiente dolorem. Ut corrupti aut delectus et dicta quia.','7','http://www.denesikwhite.com/'),
('15','odio','Eius sunt temporibus quis ut placeat consectetur. Architecto autem et ab libero inventore qui laudantium cupiditate. Culpa amet quisquam repellat ipsam quas dolorum.','6','http://hermiston.org/'),
('16','excepturi','Quibusdam maxime quis ex ea doloremque maiores. Voluptatem eius sunt velit nulla. Iure sit vitae animi autem odit.','8','http://bogisichbrakus.com/'),
('17','provident','Voluptatem cum vel odit animi rerum et quo. Maxime autem aut ullam quo ea. Numquam perferendis ea omnis blanditiis laborum atque. Ea ad atque ducimus incidunt eum.','17','http://www.johnsonskiles.org/'),
('18','pariatur','Odit in sit amet nulla aut. Ipsam odit at eos soluta reiciendis est. Animi dolorum ex aut.','9','http://www.hackett.com/'),
('19','esse','Officiis molestias et impedit laborum iste. Sint est ea unde ea consequatur quasi. Doloribus harum repellat mollitia voluptatem. Ipsam velit impedit et id.','3','http://www.heaney.com/'),
('20','eos','Animi et molestiae at perspiciatis culpa vel. Ab doloremque dolore rerum id ipsa temporibus dolorum. Qui eveniet consequatur ullam.','9','http://wildermanwaters.com/'),
('21','fugiat','Perferendis qui illo amet eveniet debitis aut. Asperiores maxime quasi temporibus vel autem laboriosam. Omnis quas sed harum molestias. Nisi qui quibusdam beatae delectus ut sunt culpa.','5','http://www.johnsonkonopelski.biz/'),
('22','soluta','Illo natus vitae sequi sunt labore temporibus aperiam. Illum aut laudantium aut autem quam rerum et. Sunt sit iusto quisquam nihil. Ipsam nulla ut velit facere mollitia.','5','http://harvey.com/'),
('23','quas','Nihil maiores suscipit temporibus ipsa animi dolores. Tempore sunt rem ut temporibus ut modi. Aut unde excepturi voluptas eos aspernatur deleniti voluptate.','3','http://www.rodriguez.com/'),
('24','tenetur','Et et odit aut perferendis magni. Velit necessitatibus ducimus sequi quia autem eum. Consequatur mollitia ullam voluptatem omnis fugiat qui dolorem. Rerum quaerat fuga aliquid quos molestiae sed voluptas. Sunt et dolorum similique doloremque.','1','http://christiansenfadel.com/'),
('25','non','Quod quia et nisi quia harum. Et at aut quod possimus reprehenderit qui. In assumenda quis asperiores sed non maiores porro.','8','http://www.mantebogan.com/'),
('26','itaque','Tenetur soluta quae reiciendis libero quasi ut quis possimus. Sapiente nemo architecto molestias et pariatur. Consectetur inventore libero quia occaecati laborum provident.','7','http://www.spencerrobel.biz/'),
('27','tempore','Ea odit maxime repudiandae delectus. Et facere fuga sint non. Architecto blanditiis aut reiciendis non. Esse possimus sed dolore.','7','http://kosswintheiser.com/'),
('28','nostrum','Deserunt quidem ad magni voluptas nihil. Voluptas qui distinctio sit doloremque voluptas quia qui. Eligendi quia cumque accusamus.','6','http://www.zemlakhartmann.com/'),
('29','quibusdam','Minus modi blanditiis reiciendis illo sit quibusdam asperiores. Amet repellat commodi qui consectetur quis perferendis impedit. Blanditiis consequatur suscipit cum porro consequatur non. Eos exercitationem et eaque totam. Rerum voluptatem natus omnis nesciunt quo.','10','http://www.wolff.com/'),
('30','culpa','Dignissimos molestias impedit ut debitis sed dolores quo. Ad ipsam sit qui. Est cum cupiditate ad et optio delectus omnis.','3','http://schroeder.org/'); 

INSERT INTO `awards_games` VALUES ('4','8','2010','лауреат'),
('9','9','1992','лауреат'),
('5','4','2002','лауреат'),
('3','6','2000','номинант'),
('2','14','1992','номинант'),
('7','28','2016','лауреат'),
('15','8','1987','лауреат'),
('12','7','1981','номинант'),
('25','18','1987','номинант'),
('30','13','1978','номинант'),
('14','22','1977','номинант'),
('11','9','1977','лауреат'),
('29','19','1972','номинант'),
('19','13','1971','номинант'),
('22','26','1970','номинант'),
('1','17','2020','номинант'),
('12','6','2008','номинант'),
('8','10','2016','лауреат'),
('3','30','1976','номинант'),
('23','27','1973','номинант'),
('29','12','2014','номинант'),
('26','7','1995','лауреат'),
('1','17','1971','лауреат'),
('17','11','1988','лауреат'),
('10','19','1983','номинант'),
('6','2','1975','лауреат'),
('25','4','1981','номинант'),
('3','1','2006','номинант'),
('15','1','1993','лауреат'),
('14','5','1971','лауреат'),
('3','7','2004','номинант'),
('28','7','2009','номинант'),
('13','6','1977','номинант'),
('6','6','1995','номинант'),
('1','17','1998','лауреат'),
('7','5','2012','номинант'),
('29','6','2005','номинант'),
('8','2','2007','лауреат'),
('12','18','2018','номинант'),
('5','27','1978','номинант'); 


INSERT INTO `comments` VALUES ('1','4',NULL,NULL,NULL,'2','2020-05-25 19:30:44','Illo quisquam qui ut aliquam qui sed.'),
('2',NULL,'18',NULL,NULL,'24','2020-07-19 20:52:51','Sunt a expedita aliquid quis sed ut fugit.'),
('3','19',NULL,NULL,NULL,'12','2020-07-14 17:57:32','Cupiditate incidunt dolor exercitationem est qui.'),
('4',NULL,NULL,NULL,'45','2','2019-11-24 04:03:31','Reiciendis sapiente quibusdam eius unde voluptates odit.'),
('5',NULL,'30',NULL,NULL,'7','2019-09-07 12:28:58','Omnis et nobis repellendus facere.'),
('6',NULL,'21',NULL,NULL,'2','2020-06-29 16:54:07','Eos et sint accusantium consequuntur aliquid quo harum.'),
('7',NULL,NULL,'1',NULL,'50','2019-11-04 08:03:04','Ut quia et dolores est nihil consequatur dignissimos excepturi.'),
('8','41',NULL,NULL,NULL,'38','2020-08-12 02:21:12','Aut et et aliquam consectetur in dolores quis.'),
('9',NULL,NULL,NULL,'7','26','2020-02-29 08:29:21','Accusantium necessitatibus voluptatum ipsum eius assumenda.'),
('10',NULL,'7',NULL,NULL,'11','2020-07-28 03:10:54','In quia porro necessitatibus quia.'),
('11',NULL,NULL,'14',NULL,'2','2019-09-12 14:23:47','Velit qui et et nisi tempore similique.'),
('12',NULL,'11',NULL,NULL,'11','2020-07-31 15:09:26','Est est repellat cum vel enim amet ea.'),
('13','32',NULL,NULL,NULL,'34','2019-11-07 16:25:09','Sit libero et nobis repellendus voluptatibus.'),
('14',NULL,NULL,NULL,'40','43','2020-01-07 04:31:52','Repellat aliquam et est.'),
('15',NULL,NULL,'50',NULL,'43','2020-06-27 08:23:52','Sit aut architecto accusantium dolorem.'),
('16',NULL,'13',NULL,NULL,'45','2019-10-31 08:32:17','Consequatur sed reprehenderit quia maiores voluptatem neque quam.'),
('17',NULL,NULL,NULL,'59','23','2020-04-11 05:22:37','Ut quos qui culpa reprehenderit.'),
('18',NULL,NULL,'48',NULL,'22','2020-01-09 19:00:06','Perspiciatis unde laborum consequatur rerum magni porro nisi.'),
('19','17',NULL,NULL,NULL,'26','2020-08-14 11:24:46','Nemo saepe ex tenetur.'),
('20',NULL,'10',NULL,NULL,'48','2020-02-29 19:33:26','Similique quia eum veniam quia.'),
('21','45',NULL,NULL,NULL,'4','2020-05-30 21:06:37','Laboriosam dolorum quia quia dolore eveniet omnis.'),
('22',NULL,NULL,NULL,'34','24','2020-05-06 09:11:54','Voluptatem animi recusandae temporibus ex beatae.'),
('23',NULL,NULL,NULL,'26','29','2020-09-01 16:18:59','Suscipit tempora voluptatem consectetur quo labore laudantium laudantium.'),
('24','33','13','10','26','13','2020-02-15 13:13:27','Illum non qui dignissimos sunt repudiandae.'),
('25',NULL,'8',NULL,NULL,'9','2020-04-07 06:02:54','Assumenda eius nesciunt repudiandae.'),
('26','42',NULL,NULL,NULL,'12','2020-05-18 20:56:39','Non quae temporibus quo id ea libero quos eaque.'),
('27',NULL,NULL,NULL,'2','48','2019-12-03 04:14:52','Nihil necessitatibus et perspiciatis quaerat laudantium saepe ex.'),
('28',NULL,NULL,'41',NULL,'50','2020-07-23 21:50:08','Accusamus dolorem iure quibusdam quia voluptatem ut.'),
('29','27',NULL,NULL,NULL,'10','2020-02-28 05:00:37','Est minus debitis magnam.'),
('30',NULL,'24',NULL,NULL,'10','2020-03-10 12:36:05','Fugit non quia ea quis non eum.'),
('31',NULL,NULL,NULL,'17','13','2019-10-26 03:11:08','Rerum et quam voluptatibus dignissimos est qui.'),
('32',NULL,'17',NULL,NULL,'14','2020-04-25 22:41:01','Ut ratione fuga reprehenderit iste iste.'),
('33','25',NULL,NULL,NULL,'6','2020-08-03 20:11:59','Blanditiis soluta quidem cum dicta.'),
('34',NULL,NULL,'21',NULL,'47','2020-01-16 15:06:25','Voluptatem nihil ut nam consequatur quis ut.'),
('35',NULL,NULL,NULL,'45','41','2020-02-18 21:36:29','Expedita molestias molestias ab sit id non aspernatur.'),
('36',NULL,'6',NULL,NULL,'50','2019-11-18 20:07:39','Quas eveniet commodi vitae illum in aut architecto consectetur.'),
('37','16',NULL,NULL,NULL,'25','2020-04-30 17:18:35','Facere reprehenderit soluta occaecati quod unde non aut.'),
('38',NULL,NULL,'8',NULL,'36','2020-03-27 12:28:41','Ut est illo voluptatem optio.'),
('39','11',NULL,NULL,NULL,'22','2019-10-27 16:00:48','Eum est aperiam repellendus voluptas ut molestiae.'),
('40',NULL,NULL,NULL,'45','10','2020-06-05 16:24:24','Ratione unde temporibus doloribus tempora expedita.'),
('41',NULL,'23',NULL,NULL,'26','2020-02-24 21:08:03','Voluptatem quo exercitationem ullam sed qui.'),
('42',NULL,NULL,NULL,'57','48','2020-02-15 05:37:50','Exercitationem ad quia voluptatem dolore.'),
('43','6',NULL,NULL,NULL,'34','2020-04-08 04:29:36','Quia et exercitationem blanditiis explicabo quia magnam aut.'),
('44',NULL,NULL,NULL,'50','22','2020-08-04 02:03:16','Reiciendis praesentium deleniti illum occaecati totam aperiam.'),
('45',NULL,NULL,'25',NULL,'11','2020-02-27 16:13:24','Illum facere delectus eos occaecati maxime.'),
('46',NULL,'20',NULL,NULL,'22','2019-10-28 03:37:26','Amet delectus expedita et eos.'),
('47',NULL,NULL,NULL,'16','34','2020-01-23 09:43:37','Repellendus dolor consequatur ut.'),
('48','50',NULL,NULL,NULL,'37','2020-02-03 16:16:47','Voluptatum architecto cum dolorem occaecati occaecati et cupiditate.'),
('49',NULL,'11',NULL,NULL,'19','2020-08-11 22:05:39','Hic reprehenderit atque expedita et repudiandae modi.'),
('50','48',NULL,NULL,NULL,'35','2020-08-19 02:47:05','Est non voluptatem voluptatem hic.'); 

INSERT INTO `games_scores` (id, game_id, user_id, created_at, gameplay, versatility, originality, representation) VALUES ('1','44','7','2013-09-09 14:20:48','5','5','5','6'),
('2','3','2','2016-10-27 07:44:49','5','10','6','5'),
('3','3','7','2017-09-03 07:51:04','6','6','6','6'),
('4','35','2','2012-06-26 00:23:12','9','10','5','1'),
('5','38','7','2017-01-26 22:18:03','9','2','9','9'),
('6','31','1','2015-11-20 07:46:32','5','10','6','4'),
('7','1','42','2013-08-28 14:43:09','7','6','3','7'),
('8','2','2','2012-10-30 07:36:18','3','3','4','10'),
('9','2','7','2017-04-02 09:55:33','4','8','5','5'),
('10','22','23','2011-04-30 00:39:51','7','8','1','3'),
('11','18','28','2020-02-13 21:26:58','7','5','2','7'),
('12','18','2','2015-07-07 10:34:36','2','8','10','4'),
('13','29','8','2013-07-17 19:18:02','8','5','4','7'),
('14','16','2','2012-09-25 02:37:54','2','4','4','3'),
('15','48','47','2020-01-03 15:13:13','4','8','9','2'),
('16','2','31','2017-05-20 16:22:53','10','4','10','7'),
('17','16','28','2011-08-07 03:13:08','8','1','9','8'),
('18','8','38','2016-07-08 09:58:04','2','4','2','10'),
('19','43','38','2010-09-18 12:01:13','10','2','1','2'),
('20','48','2','2015-09-09 15:02:43','9','4','3','9'),
('21','19','2','2015-03-25 21:59:52','4','9','1','8'),
('22','35','16','2011-01-16 02:27:52','6','2','10','8'),
('23','19','5','2012-10-23 05:14:18','5','6','2','9'),
('24','48','5','2014-09-12 14:49:16','6','7','6','6'),
('25','48','7','2015-09-12 16:23:09','6','6','7','7'),
('26','42','32','2015-04-28 23:02:47','6','6','6','9'),
('27','26','28','2013-02-28 23:25:52','6','2','9','4'),
('28','18','35','2018-04-12 19:34:44','6','6','6','6'),
('29','5','36','2018-06-26 18:56:29','6','8','2','10'),
('30','27','22','2014-07-24 10:43:45','4','2','2','2'),
('31','44','2','2016-08-01 16:03:52','5','5','6','6'),
('32','44','5','2012-07-25 22:02:26','5','5','6','5'),
('33','48','50','2017-12-08 14:29:07','6','2','7','9'),
('34','6','32','2011-12-16 17:53:41','6','10','4','1'),
('35','2','10','2013-12-31 13:49:37','4','8','9','8'),
('36','5','5','2017-12-10 15:22:58','10','2','1','4'),
('37','21','11','2018-05-30 08:45:26','1','1','2','6'),
('38','1','2','2020-03-20 16:07:02','6','6','2','9'),
('39','34','10','2012-09-22 23:13:05','1','1','1','4'),
('40','39','34','2017-02-21 15:43:07','8','10','10','3'),
('41','1','8','2010-09-18 21:30:50','10','9','7','4'),
('42','43','13','2019-06-19 11:43:24','4','1','2','2'),
('43','3','48','2020-07-31 16:53:01','7','5','7','2'),
('44','2','18','2011-07-07 12:16:56','5','5','5','5'),
('45','39','48','2020-03-06 03:48:51','4','4','8','6'),
('46','29','13','2011-09-13 08:24:07','5','3','6','8'),
('47','10','18','2018-08-23 04:35:23','1','6','4','9'),
('48','17','41','2018-10-18 18:32:28','1','7','2','5'),
('49','2','38','2020-04-17 17:13:25','9','10','6','8'),
('50','11','37','2019-04-07 22:59:07','7','4','5','4'),
('51','24','15','2010-11-23 14:08:35','6','8','9','2'),
('52','21','19','2016-02-11 13:06:02','8','7','6','1'),
('53','38','22','2019-07-17 23:52:06','4','8','7','3'),
('54','40','10','2011-06-05 01:16:02','7','3','9','6'),
('55','27','38','2018-08-20 19:54:16','2','6','6','10'),
('56','20','5','2013-04-11 01:10:00','1','4','9','8'),
('57','2','35','2013-04-17 14:51:34','6','2','3','5'),
('58','14','42','2013-12-24 02:42:59','4','3','9','1'),
('59','14','7','2017-11-03 08:21:59','2','4','8','7'),
('60','11','23','2018-02-17 11:29:52','3','3','9','5'),
('61','49','7','2020-04-24 13:20:58','3','5','2','5'),
('62','45','37','2015-01-24 11:55:07','1','1','10','4'),
('63','49','12','2017-03-13 23:06:39','7','4','3','8'),
('64','27','7','2019-04-07 21:21:10','5','9','6','8'),
('65','36','26','2012-06-19 10:48:43','10','4','5','2'),
('66','47','39','2015-12-22 13:16:25','4','7','5','6'),
('67','30','2','2015-04-12 06:39:58','2','5','8','5'),
('68','10','30','2015-04-14 10:39:26','10','3','4','6'),
('69','48','30','2019-01-10 03:08:54','3','7','1','8'),
('70','25','50','2011-10-16 01:57:15','8','9','2','5'); 

-- Характерные выборки

/*  Поиск игр по определенным критериям. 
Попробуем найти игры в категории "варгеймы", в названии которых (официальном или неофициальном) содержится "sons",
и отсортировать по рейтингу игры. Игры оценивают пользователи. Для начала создадим представление, в котором подсчитан
общий рейтинг игры с учетом всех оценок пользователей. */

CREATE OR REPLACE VIEW game_rating AS
SELECT game_id, SUM(total_score) / COUNT(game_id) AS rating from games_scores
GROUP BY game_id;

-- Поиск.
SELECT g.main_name, g.sub_name, m.filename AS 'photo',g.description, CONCAT(g.min_number_of_players, '-', g.max_number_of_players, ' players') AS 'players',
  CONCAT('from ', g.from_age, ' years old') AS 'age', gr.rating
FROM games g
JOIN categories c ON c.name = 'wargames' AND g.main_name LIKE '%sons%' or g.sub_name LIKE '%sons%'
JOIN games_categories gc ON g.id = gc.game_id AND gc.category_id = c.id
JOIN media m ON g.photo_id = m.id
JOIN game_rating gr ON g.id = gr.game_id
ORDER by rating DESC;

/* Барахолка. Купить на сайте ничего нельзя, но можно написать в личку продавцу. 
У барахолки 2 отдельных раздела: продажи и покупки. Сделаю для них 2 отдельных представления
 */
CREATE OR REPLACE VIEW secondhand_sales AS
SELECT a.login AS 'seller', m1.filename AS "user's photo", c.city_name, g.main_name AS 'game', m2.filename AS 'game_photo', us.price, us.`condition`, us.comment, us.created_at
from user_sells us 
JOIN accounts a ON us.user_id = a.id and a.is_deleted = 0 and us.is_deleted = 0 
JOIN users_profiles up ON us.user_id = up.account_id
JOIN cities c ON c.id = up.user_city_id
JOIN games g ON g.id = us.game_id
JOIN media m1 ON m1.id = up.photo_id
JOIN media m2 ON m2.id = g.photo_id
Order By created_at DESC;

CREATE OR REPLACE VIEW secondhand_purchases AS
SELECT a.login AS 'buyer', m1.filename AS "user's photo", c.city_name, g.main_name AS 'game', m2.filename AS 'game_photo', ub.`condition`, ub.comment, ub.created_at
from user_buys ub
JOIN accounts a ON ub.user_id = a.id and a.is_deleted = 0 and ub.is_deleted = 0
JOIN users_profiles up ON ub.user_id = up.account_id
JOIN cities c ON c.id = up.user_city_id
JOIN games g ON g.id = ub.game_id
JOIN media m1 ON m1.id = up.photo_id
JOIN media m2 ON m2.id = g.photo_id
Order By created_at DESC;

SELECT * FROM secondhand_sales;
SELECT * FROM secondhand_purchases;


/* Комментарии. Можно прокомментировать статью, новость, игру, магазин, событие - почти любую страницу. 
 * На странице каждого пользователя отображаются все его недавние комментарии. Создадим процедуру, принимающую ID 
 * пользователя и отображающую его 5 последних комментариев */
DELIMITER //
DROP PROCEDURE IF EXISTS user_comments//
CREATE PROCEDURE user_comments (IN num BIGINT UNSIGNED)
BEGIN
SELECT a.login,  CONCAT ('commented game') AS `text`, g.main_name, c.created_at
FROM accounts a
JOIN comments c ON a.id = num and a.id = c.user_id and c.game_id IS NOT NULL
JOIN games as g ON g.id = c.game_id
UNION
SELECT a.login, CONCAT ('commented article'), art.article_name, c.created_at
FROM accounts a 
JOIN comments c ON a.id = c.user_id and c.article_id IS NOT NULL and a.id = num
JOIN articles art ON c.article_id = art.id
UNION
SELECT a.login, CONCAT( 'commented ', a.account_type), ac.login, c.created_at
FROM accounts a
JOIN comments c ON a.id = c.user_id and c.account_id IS NOT NULL and a.id = num
JOIN accounts ac ON c.account_id = ac.id
UNION
SELECT a.login, CONCAT( 'commented ',m.media_type), m.filename, c.created_at
FROM accounts a
JOIN comments c ON a.id = c.user_id and c.media_id IS NOT NULL and a.id = num
JOIN media m ON c.media_id = m.id
ORDER By created_at DESC
LIMIT 5;
END//
DELIMITER ;

CALL user_comments(2);

/* Схожие пользователи. На сайте tesera коэффициент схожести определяется по совпадению оценок игр: если 
разница в оценках игры пользователями меньше 0.5 балла, к коэффициенту добавляется 1. Если разница больше 5, то 
вычитается 1. Информация о схожих пользователях выводится в виде "всего игр оценено, коэффициент схожести оценок". */
DROP PROCEDURE IF EXISTS users_match;
DELIMITER //
CREATE PROCEDURE users_match (in num BIGINT UNSIGNED)
BEGIN
SELECT a.login AS 'user', gs3.rated_games, 
ROUND(SUM(CASE WHEN (ABS(gs1.total_score - gs2.total_score)) > 5 THEN '-1' WHEN (ABS(gs1.total_score - gs2.total_score)) < 0.5
THEN '1' END), 0) AS 'match_index'
FROM games_scores gs1
JOIN games_scores gs2 ON gs1.game_id = gs2.game_id and gs1.user_id = num and gs2.user_id != num
JOIN accounts a ON a.id = gs2.user_id and a.is_deleted = 0
JOIN (SELECT user_id, COUNT(total_score) AS 'rated_games' from games_scores GROUP BY user_id) gs3
  ON gs2.user_id  = gs3.user_id
GROUP BY gs2.user_id
ORDER by match_index DESC
LIMIT 5;
END//
DELIMITER ;
CALL users_match(2);

/* Добавление аккаунта.
 При добавлении аккаунта его ID подгружается в таблицу или профилей пользователей, или магазинов, 
 или клубов, или событий cоответственно.  Если это пользователь, ему добавляется стартовый рейтинг 50 баллов. 
 А остальную информацию в профиль пользователь уже внесет позже, когда захочет.
 */
DROP PROCEDURE IF EXISTS new_account;
DELIMITER //
CREATE PROCEDURE new_account (account_type varchar(100), login varchar(100), password_hash varchar(100), email varchar(50), 
  OUT tran_result varchar(200))
BEGIN
    DECLARE `_rollback` BOOL DEFAULT 0;
   	DECLARE code varchar(100);
   	DECLARE error_string varchar(100);
   DECLARE last_user_id int;

   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
   begin
    	SET `_rollback` = 1;
	GET stacked DIAGNOSTICS CONDITION 1
          code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
    	set tran_result := concat('Error occured. Code: ', code, '. Text: ', error_string);
    end;
   	        
    START TRANSACTION;
		INSERT INTO accounts (account_type, login, password_hash, email)
		  VALUES (account_type, login, password_hash, email);
	    IF (SELECT account_type FROM accounts WHERE id = last_insert_id()) = 'user' THEN
	         INSERT INTO users_profiles (account_id, rating, status )
		     VALUES (last_insert_id(), '50', 'registered');
		ELSEIF (SELECT account_type FROM accounts WHERE id = last_insert_id()) = 'shop' THEN
		    INSERT INTO shops_profiles (account_id) VALUES (last_insert_id());
		ELSEIF (SELECT account_type FROM accounts WHERE id = last_insert_id()) = 'club' THEN
		    INSERT INTO clubs_profiles (account_id) VALUES (last_insert_id());    
		ELSEIF (SELECT account_type FROM accounts WHERE id = last_insert_id()) = 'event' THEN
		    INSERT INTO events (account_id) VALUES (last_insert_id());     	
	    END IF; 
	  IF `_rollback` THEN
	       ROLLBACK;
	    ELSE
		set tran_result := 'ok';
	       COMMIT;
	    END IF;
END//

DELIMITER ;

call new_account('user','user18','pass1', 'email8@example.com', @tran_result);
-- select @tran_result;

/* Также рейтинг пользователя увеличивается за определенные действия. Например, оценивание игры — 3 балла 
 (реализовано выше, сразу после создания таблицы games_scores вместе с подсчетом рейтинга игры)
 * Еще рассмотрю добавление 5 баллов (не чаще раза в день) за посещение сайта */

ALTER TABLE users_profiles
ADD rating_update DATETIME;
UPDATE users_profiles SET rating_update = NOW() - INTERVAL 1 DAY;

-- когда пользователь заходит на сайт, проверяем, получал ли он уже сегодня 5 баллов, и обновляем значение last-online
DROP PROCEDURE IF EXISTS new_online;
DELIMITER //
CREATE PROCEDURE new_online (num BIGINT UNSIGNED)
BEGIN
SET @x = NOW() - INTERVAL 1 DAY;
SET @y = (SELECT rating_update FROM users_profiles WHERE account_id = num);
IF @x >= @y and (SELECT account_type from accounts WHERE id = num) = 'user' THEN 
  UPDATE users_profiles SET rating = rating + 5, rating_update = NOW() WHERE account_id = num;
END IF; 
UPDATE accounts SET last_online = NOW() WHERE id = num; 
END//
DELIMITER ;

call new_online(4);
-- SELECT * from users_profiles WHERE account_id = 4;


-- Функция: подсчет пользователей, посетивших сайт
DROP FUNCTION IF EXISTS users_per_time;
DELIMITER //
CREATE FUNCTION users_per_time (from_day DATETIME, to_day DATETIME)
RETURNS INT READS SQL DATA
BEGIN
 RETURN (SELECT COUNT(id) FROM accounts WHERE DATE(last_online) BETWEEN(from_day) AND (to_day));
END//
DELIMITER ;

SELECT users_per_time(DATE(NOW()), DATE(NOW())) AS 'today'; -- сколько пользователей посетило сайт сегодня
SELECT users_per_time(DATE(NOW() - INTERVAL 1 MONTH), DATE(NOW())) AS 'this month'; -- сколько пользователей посетило сайт в этом месяце
SELECT users_per_time('1990-01-01', DATE(NOW() - INTERVAL 1 YEAR)) AS 'not this year'; -- не посещали уже год

