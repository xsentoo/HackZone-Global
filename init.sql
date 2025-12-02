-- ------------------------------------------------------------
-- PARTIE 1 : TARGET APP (La Victime - Port 8081)
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TargetDB;
USE TargetDB;

-- Table Users vulnerable a l'injection SQL
CREATE TABLE IF NOT EXISTS Users (
                                     id INT AUTO_INCREMENT PRIMARY KEY,
                                     username VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,
    secret_data VARCHAR(100) -- Contient le Flag
    );

-- Insertion des donnees de la victime
INSERT IGNORE INTO Users (username, password, secret_data) VALUES
('admin', 'admin123', 'FLAG{SQL_LEVEL_1_COMPLETED}'),
('client', '1234', 'Solde: 0 EUR');

-- --- AJOUT POUR LE NIVEAU 2 (SQL UNION) ---

-- 1. Une table normale (Les Produits) - SANS ACCENTS
CREATE TABLE IF NOT EXISTS Products (
                                        id INT AUTO_INCREMENT PRIMARY KEY,
                                        name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
    );

INSERT IGNORE INTO Products (name, category, price) VALUES
('T-Shirt HackZone', 'Vetements', 25.00),
('Hoodie Noir', 'Vetements', 45.00),
('Mug Developpeur', 'Accessoires', 12.50),
('Cle USB 64Go', 'Electronique', 15.00);

-- 2. Une table secrete (Le but du hack)
CREATE TABLE IF NOT EXISTS SecretConfig (
                                            id INT AUTO_INCREMENT PRIMARY KEY,
                                            config_name VARCHAR(50),
    config_value VARCHAR(100)
    );

INSERT IGNORE INTO SecretConfig (config_name, config_value) VALUES
('admin_email', 'admin@bankofhack.com'),
('FLAG_LEVEL_2', 'FLAG{UNION_SELECT_IS_POWERFUL}');


-- ------------------------------------------------------------
-- PARTIE 2 : HACKZONE (Le QG - Port 8080)
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS HackZone;
USE HackZone;

-- Table 1 : Les Utilisateurs (Hackers)
CREATE TABLE IF NOT EXISTS UserHack (
                                        userId INT AUTO_INCREMENT PRIMARY KEY,
                                        userName VARCHAR(255) NOT NULL,
    userMail VARCHAR(255) NOT NULL UNIQUE,
    userPWD VARCHAR(255) NOT NULL,
    level ENUM('deb','int','avan') DEFAULT 'deb',
    userBadge VARCHAR(255) DEFAULT 'Novice',
    point INT DEFAULT 0,
    userDate DATE DEFAULT (curdate())
    );

-- Table 2 : Le Catalogue des Attaques (Challenges)
-- CORRECTION : "PRIMARYINATION" supprime, URLs mises a jour
CREATE TABLE IF NOT EXISTS Attacks (
                                       attId INT AUTO_INCREMENT PRIMARY KEY,
                                       title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    difficulty ENUM('deb','int','avan') NOT NULL,
    target_url VARCHAR(255),
    flag VARCHAR(255) NOT NULL,
    points INT DEFAULT 10
    );

-- Table 3 : Les Validations (Anti-Triche & Historique)
CREATE TABLE IF NOT EXISTS Solves (
                                      solveId INT AUTO_INCREMENT PRIMARY KEY,
                                      userId INT NOT NULL,
                                      attId INT NOT NULL,
                                      solved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                      UNIQUE KEY unique_solve (userId, attId),
    CONSTRAINT fk_user FOREIGN KEY (userId) REFERENCES UserHack(userId) ON DELETE CASCADE,
    CONSTRAINT fk_attack FOREIGN KEY (attId) REFERENCES Attacks(attId) ON DELETE CASCADE
    );

-- Insertion des Challenges (Sans accents et avec les bons ports 8081)
INSERT IGNORE INTO Attacks (title, description, category, difficulty, target_url, flag, points) VALUES
(
    'Injection SQL - Niveau 1',
    'Contournez le login administrateur de la banque cible pour exfiltrer le code secret.',
    'SQL',
    'deb',
    'http://localhost:8081/',
    'FLAG{SQL_LEVEL_1_COMPLETED}',
    50
),
(
    'Injection SQL - Niveau 2',
    'La boutique filtre mal les categories. Utilisez UNION SELECT pour voler les donnees de la table SecretConfig.',
    'SQL',
    'int',
    'http://localhost:8081/shop',
    'FLAG{UNION_SELECT_IS_POWERFUL}',
    100
);

-- ------------------------------------------------------------
-- PARTIE 3 : PERMISSIONS DOCKER
-- ------------------------------------------------------------
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;