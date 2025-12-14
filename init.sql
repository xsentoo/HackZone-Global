-- ------------------------------------------------------------
-- PARTIE 1 : TARGET APP (La Victime - Port 8081)
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TargetDB;
USE TargetDB;
SET NAMES 'utf8mb4';

-- Table Users (Modifiée pour le CSRF)
CREATE TABLE IF NOT EXISTS Users (
                                     id INT AUTO_INCREMENT PRIMARY KEY,
                                     username VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,
    email VARCHAR(100) DEFAULT 'admin@target.com', -- Colonne ajoutée pour le CSRF
    secret_data VARCHAR(100)
    );

INSERT IGNORE INTO Users (username, password, email, secret_data) VALUES
('admin', 'admin123', 'admin@target.com', 'FLAG{SQL_LEVEL_1_COMPLETED}'),
('client', '1234', 'client@target.com', 'Solde: 0 EUR');

-- Table Produits (SQLi Nv 2)
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

-- Table Config Secrete
CREATE TABLE IF NOT EXISTS SecretConfig (
                                            id INT AUTO_INCREMENT PRIMARY KEY,
                                            config_name VARCHAR(50),
    config_value VARCHAR(100)
    );

INSERT IGNORE INTO SecretConfig (config_name, config_value) VALUES
('admin_email', 'admin@bankofhack.com'),
('FLAG_LEVEL_2', 'FLAG{UNION_SELECT_IS_POWERFUL}');

-- Table Commentaires (XSS)
CREATE TABLE IF NOT EXISTS Comments (
                                        id INT AUTO_INCREMENT PRIMARY KEY,
                                        content TEXT,
                                        session_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );


-- ------------------------------------------------------------
-- PARTIE 2 : HACKZONE (Le QG - Port 8080)
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS HackZone CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE HackZone;
SET NAMES 'utf8mb4';

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

CREATE TABLE IF NOT EXISTS Solves (
                                      solveId INT AUTO_INCREMENT PRIMARY KEY,
                                      userId INT NOT NULL,
                                      attId INT NOT NULL,
                                      solved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                                      UNIQUE KEY unique_solve (userId, attId),
    CONSTRAINT fk_user FOREIGN KEY (userId) REFERENCES UserHack(userId) ON DELETE CASCADE,
    CONSTRAINT fk_attack FOREIGN KEY (attId) REFERENCES Attacks(attId) ON DELETE CASCADE
    );

-- Nettoyage pour éviter les doublons ID
DELETE FROM Solves WHERE solveId > 0;
ALTER TABLE Solves AUTO_INCREMENT = 1;

DELETE FROM Attacks WHERE attId > 0;
ALTER TABLE Attacks AUTO_INCREMENT = 1;

SET @WARNING_MSG = ' ATTENTION : L''utilisation illégale de ces techniques est punie par la loi.';

-- INSERTION DES CHALLENGES
INSERT IGNORE INTO Attacks (title, description, category, difficulty, target_url, flag, points) VALUES
-- SQL
('Injection SQL - Niveau 1 (Login Bypass)', 'Contournez l''authentification. Hint: Utiliser OR', 'SQL', 'deb', 'http://localhost:8081/login', 'FLAG{SQL_LEVEL_1_COMPLETED}', 50),
('Injection SQL - Niveau 2 (Union Select)', 'Volez les données de la table SecretConfig via la boutique.', 'SQL', 'int', 'http://localhost:8081/shop', 'FLAG{UNION_SELECT_IS_POWERFUL}', 100),
-- XSS
('XSS - Niveau 1 (Stored XSS)', 'Volez le cookie de session via le Livre d''Or.', 'XSS', 'int', 'http://localhost:8081/guestbook', 'FLAG{XSS_MASTER_ALERT}', 150),
-- CSRF (NOUVEAU)
('CSRF - Niveau 1 (Profile Update)', 'Forcez l''administrateur à changer son email en "hacker@csrf.com". Créez un formulaire HTML piégé qui cible la page de profil.', 'CSRF', 'int', 'http://localhost:8081/profile', 'FLAG{CSRF_ATTACK_SUCCESS}', 200),
-- OSINT
('OSINT - Niveau 1 (Google Dorking)', CONCAT('Trouvez le backup SQL. site:cible.com filetype:sql', @WARNING_MSG), 'OSINT', 'deb', 'https://www.google.com', 'HACKZONE{g00gl3_d0rk1ng_b4s1c}', 100),
('OSINT - Niveau 2 (Email Hunter)', CONCAT('Trouvez l''email du CEO de TechSecure Corp.', @WARNING_MSG), 'OSINT', 'deb', 'https://www.linkedin.com', 'HACKZONE{c3o@t3chsecur3.com}', 150),
('OSINT - Niveau 3 (Subdomain Discovery)', CONCAT('Trouvez 3 sous-domaines cachés de target-company.com.', @WARNING_MSG), 'OSINT', 'int', 'https://crt.sh', 'HACKZONE{admin.target-company.com}', 200),
('OSINT - Niveau 4 (Shodan Master)', CONCAT('Trouvez des caméras IP non sécurisées à Paris.', @WARNING_MSG), 'OSINT', 'int', 'https://www.shodan.io', 'HACKZONE{sh0d4n_1s_p0w3rful}', 250),
('OSINT - Niveau 5 (The Full Recon)', CONCAT('Reconnaissance complète de mega-corp.com.', @WARNING_MSG), 'OSINT', 'avan', 'https://builtwith.com', 'HACKZONE{full_r3c0n_m4st3r_2024}', 300),
-- BRUTE FORCE
('Brute Force - Niveau 1 (Weak Password)', CONCAT('Compte admin avec mot de passe faible.', @WARNING_MSG), 'BRUTE_FORCE', 'deb', 'http://localhost:8081/login', 'HACKZONE{adm1n_p4ssw0rd_w34k}', 100),
('Brute Force - Niveau 2 (Hash Cracker)', CONCAT('Crackez ce hash MD5 : 098f6bcd4621d373cade4e832627b4f6.', @WARNING_MSG), 'BRUTE_FORCE', 'deb', 'https://crackstation.net', 'HACKZONE{h4sh_cr4ck3d_md5}', 150),
('Brute Force - Niveau 3 (SSH)', CONCAT('Attaquez le SSH sur le port 2222. User: root. Password: root.', @WARNING_MSG), 'BRUTE_FORCE', 'int', 'http://localhost:8081/ssh-challenge', 'HACKZONE{ssh_brut3f0rc3_succ3ss}', 200),
('Brute Force - Niveau 4 (ZIP Password)', CONCAT('Crackez le ZIP protégé.', @WARNING_MSG), 'BRUTE_FORCE', 'int', 'http://localhost:8081/download/secret_docs.zip', 'HACKZONE{z1p_p4ssw0rd_r3c0v3r3d}', 250),
('Brute Force - Niveau 5 (Rainbow Table)', CONCAT('Utilisez des rainbow tables.', @WARNING_MSG), 'BRUTE_FORCE', 'avan', 'https://crackstation.net', 'HACKZONE{r41nb0w_t4bl3_4tt4ck}', 300),
-- NETWORK
('Analyse Réseau - Niveau 1 (Packet Sniffer)', CONCAT('Trouvez le mot de passe HTTP en clair.', @WARNING_MSG), 'NETWORK_ANALYSIS', 'deb', 'http://localhost:8081/download/traffic.pcap', 'HACKZONE{p4ck3t_sn1ff3d_http}', 100),
('Analyse Réseau - Niveau 2 (FTP Credentials)', CONCAT('Trouvez les identifiants FTP.', @WARNING_MSG), 'NETWORK_ANALYSIS', 'deb', 'http://localhost:8081/download/ftp_capture.pcap', 'HACKZONE{ftp_us3r:ftp_p4ss}', 150),
('Analyse Réseau - Niveau 3 (ARP Spoofing)', CONCAT('Détectez le spoofing ARP.', @WARNING_MSG), 'NETWORK_ANALYSIS', 'int', 'http://localhost:8081/download/arp_attack.pcap', 'HACKZONE{4rp_sp00f1ng_d3t3ct3d}', 200),
('Analyse Réseau - Niveau 4 (DNS Tunneling)', CONCAT('Décodez l''exfiltration DNS.', @WARNING_MSG), 'NETWORK_ANALYSIS', 'int', 'http://localhost:8081/download/dns_exfil.pcap', 'HACKZONE{dns_tunn3l1ng_3xf1l}', 250),
('Analyse Réseau - Niveau 5 (SSL/TLS Decryption)', CONCAT('Déchiffrez le trafic HTTPS avec la clé.', @WARNING_MSG), 'NETWORK_ANALYSIS', 'avan', 'http://localhost:8081/download/encrypted_traffic.pcap', 'HACKZONE{ssl_d3crypt3d_m4st3r}', 300);

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;