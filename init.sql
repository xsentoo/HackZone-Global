
CREATE DATABASE IF NOT EXISTS TargetDB;
USE TargetDB;

-- Table Users vulnérable à l'injection SQL
CREATE TABLE IF NOT EXISTS Users (
                                     id INT AUTO_INCREMENT PRIMARY KEY,
                                     username VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,
    secret_data VARCHAR(100) -- Contient le Flag
    );

-- Insertion des données de la victime (sans chiffrage)
INSERT IGNORE INTO Users (username, password, secret_data) VALUES
('admin', 'admin123', 'FLAG{SQL_LEVEL_1_COMPLETED}'),
('client', '1234', 'Solde: 0€');


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
    userPWD VARCHAR(255) NOT NULL, -- Sera stocké en BCrypt
    level ENUM('deb','int','avan') DEFAULT 'deb',
    userBadge VARCHAR(255) DEFAULT 'Novice',
    point INT DEFAULT 0, -- Score total
    userDate DATE DEFAULT (curdate())
    );

-- Table 2 : Le Catalogue des Attaques (Challenges) - Structure Finale
CREATE TABLE IF NOT EXISTS Attacks (
                                       attId INT AUTO_INCREMENT PRIMARYINATION PRIMARY KEY,
                                       title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- Ex: SQL, XSS, BRUTEFORCE
    difficulty ENUM('deb','int','avan') NOT NULL,
    target_url VARCHAR(255), -- L'URL du challenge (ex: http://localhost:8081 ou /Challenge/SQL1)
    flag VARCHAR(255) NOT NULL, -- La réponse attendue
    points INT DEFAULT 10
    );

-- Table 3 : Les Validations (Anti-Triche & Historique)
CREATE TABLE IF NOT EXISTS Solves (
                                      solveId INT AUTO_INCREMENT PRIMARY KEY,
                                      userId INT NOT NULL,
                                      attId INT NOT NULL,
                                      solved_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- Anti-Triche : Empêche l'utilisateur de valider 2 fois le même challenge
                                      UNIQUE KEY unique_solve (userId, attId),

    -- Relations
    CONSTRAINT fk_user FOREIGN KEY (userId) REFERENCES UserHack(userId) ON DELETE CASCADE,
    CONSTRAINT fk_attack FOREIGN KEY (attId) REFERENCES Attacks(attId) ON DELETE CASCADE
    );

-- Insertion des Challenges (Le niveau 1 envoie vers TargetApp)
INSERT IGNORE INTO Attacks (title, description, category, difficulty, target_url, flag, points) VALUES
(
    'Injection SQL - Niveau 1',
    'Contournez le login administrateur de la banque cible pour exfiltrer le code secret.',
    'SQL',
    'deb',
    'http://localhost:8081', -- Lien vers la TargetApp
    'FLAG{SQL_LEVEL_1_COMPLETED}',
    50
),
(
    'Injection SQL - Niveau 2',
    'Attaquez la banque externe directement sur son interface de connexion (Union Based).',
    'SQL',
    'int',
    'http://localhost:8081',
    'FLAG{SQL_LEVEL_2_UNION}',
    100
);

-- ------------------------------------------------------------
-- PARTIE 3 : PERMISSIONS DOCKER
-- ------------------------------------------------------------
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;