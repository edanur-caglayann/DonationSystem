CREATE TABLE Badge (
    Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    Amount BIGINT NOT NULL
);

CREATE TABLE Company (
    Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX)
);

CREATE TABLE Campain (
    Id INT PRIMARY KEY IDENTITY,
    BadgeId INT NOT NULL FOREIGN KEY REFERENCES Badge(Id),
    CompanyId INT NOT NULL FOREIGN KEY REFERENCES Company(Id),
    EndDate DATETIME NOT NULL
);

CREATE TABLE CompanyAccount (
    Id INT PRIMARY KEY IDENTITY,
    CompanyId INT NOT NULL FOREIGN KEY REFERENCES Company(Id),
    TotalDonationAmount BIGINT NOT NULL
);

CREATE TABLE PaymentType (
    Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX)
);

CREATE TABLE [User] (
    Id INT PRIMARY KEY IDENTITY(1,1),
    CompanyId INT NOT NULL,
    BadgeId INT NULL,
    UserName NVARCHAR(255) NOT NULL,
    UserSurename NVARCHAR(255) NOT NULL,
    CONSTRAINT FK_User_Badge FOREIGN KEY (BadgeId) REFERENCES Badge(Id)
);


CREATE TABLE Donation (
    Id INT PRIMARY KEY IDENTITY,
    CompanyId INT NOT NULL FOREIGN KEY REFERENCES Company(Id),
    UserId INT NOT NULL FOREIGN KEY REFERENCES [User](Id),
    PaymentTypeId INT NOT NULL FOREIGN KEY REFERENCES PaymentType(Id),
    Amount BIGINT NOT NULL
);

CREATE TABLE FeedBack (
    Id INT PRIMARY KEY IDENTITY,
    DonationId INT NOT NULL FOREIGN KEY REFERENCES Donation(Id),
    UserId INT NOT NULL FOREIGN KEY REFERENCES [User](Id),
    Message NVARCHAR(MAX),
    Date DATETIME NOT NULL
);



-- 2. Ornek Insert Scriptleri
INSERT INTO Badge (Name, Description, Amount) VALUES ('Gold Badge', 'Top level badge', 1000);
INSERT INTO Company (Name, Description) VALUES ('TechCorp', 'A leading technology company');
INSERT INTO Campain (BadgeId, CompanyId, EndDate) VALUES (1, 1, '2025-12-31');
INSERT INTO CompanyAccount (CompanyId, TotalDonationAmount) VALUES (1, 50000);
INSERT INTO PaymentType (Name, Description) VALUES ('Credit Card', 'Standard credit card payment');
INSERT INTO [User] (CompanyId, BadgeId, UserName, UserSurename) VALUES (1, 1, 'John', 'Doe');
INSERT INTO [User] (CompanyId, BadgeId, UserName, UserSurename) VALUES(1, null, 'Eda','Caglayan');
INSERT INTO Donation (CompanyId, UserId, PaymentTypeId, Amount) VALUES (1, 1, 1, 1000);
INSERT INTO FeedBack (DonationId, UserId, Message, Date) VALUES (1, 1, 'Great initiative!', GETDATE());

SELECT * FROM Badge;
SELECT * FROM Company;
SELECT * FROM Campain;
SELECT * FROM CompanyAccount;
SELECT * FROM PaymentType;
SELECT * FROM [User];
SELECT * FROM Donation;
SELECT * FROM FeedBack;


-- 3. Ornek Update Scriptleri
UPDATE Badge SET Description = 'Updated description for Gold Badge' WHERE Id = 1;
UPDATE Company SET Description = 'Updated company description' WHERE Id = 1;
UPDATE Campain SET EndDate = '2026-01-01' WHERE Id = 1;
UPDATE CompanyAccount SET TotalDonationAmount = 60000 WHERE Id = 1;
UPDATE PaymentType SET Description = 'Updated payment type description' WHERE Id = 1;
UPDATE [User] SET UserName = 'Jane' WHERE Id = 1;
UPDATE Donation SET Amount = 1200 WHERE Id = 1;
UPDATE FeedBack SET Message = 'Updated feedback message' WHERE Id = 1;


-- 5. Ornek Delete Scriptleri
DELETE FROM FeedBack WHERE Id = 1;
DELETE FROM Donation WHERE Id = 1;
DELETE FROM [User] WHERE Id = 1;
DELETE FROM PaymentType WHERE Id = 1;
DELETE FROM CompanyAccount WHERE Id = 1;
DELETE FROM Campain WHERE Id = 1;
DELETE FROM Company WHERE Id = 1;
DELETE FROM Badge WHERE Id = 1;


-- Sakli Yordam: Toplam Bagis Miktarini Guncelle
CREATE PROCEDURE UpdateTotalDonationAmount
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE CompanyAccount
    SET TotalDonationAmount = (
        SELECT SUM(Amount) FROM Donation WHERE CompanyId = @CompanyId
    )
    WHERE CompanyId = @CompanyId;
END;

-- Tetikleyici: Bagis Eklendikten Sonra Toplam Bagis Miktarini Guncelle
CREATE TRIGGER AfterInsertDonation
ON Donation
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CompanyId INT;
    SELECT @CompanyId = CompanyId FROM inserted;
    EXEC UpdateTotalDonationAmount @CompanyId;
END;


--Sakli Yordam: Toplam bagıs 10k dan fazla olursa kullanıcıya badge ata
CREATE PROCEDURE ProToplamOnBinBadgeAtama
    @UserId INT,
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalDonationAmount BIGINT;
    DECLARE @FirstBadgeId INT;
    DECLARE @FirstCampainId INT;

    -- Şirket ve kullanıcı toplam bağış miktarını hesapla
    SELECT @TotalDonationAmount = SUM(Amount)
    FROM Donation
    WHERE CompanyId = @CompanyId AND UserId = @UserId;

    -- Eğer toplam bağış miktarı 10,000 TL'den fazlaysa işlem yap
    IF @TotalDonationAmount > 10000
    BEGIN
		IF NOT EXISTS (SELECT 1 FROM [User] WHERE Id = @UserId AND BadgeId IS NOT NULL)
		BEGIN
	    -- Şirketin ilk kampanyasının ilk badge'ini bul
        SELECT TOP 1 @FirstCampainId = Id FROM Campain WHERE CompanyId = @CompanyId ORDER BY Id;
        SELECT TOP 1 @FirstBadgeId = BadgeId FROM Campain WHERE Id = @FirstCampainId;

        -- Kullanıcıya badge atanmasını gerçekleştir
        UPDATE [User]
        SET BadgeId = @FirstBadgeId
        WHERE Id = @UserId;

        PRINT 'Badge başarıyla kullanıcıya atandı.';
		END
		ELSE
		BEGIN
			PRINT 'Kullanicida bu rozet zaten var.'
		END
    END
    ELSE
    BEGIN
        PRINT 'Toplam bağış miktarı 10,000 TL\den az.';
    END
END;

-- Bir şirketteki kullanıcıların sahip olduğu badgeleri veren kod
SELECT 
    u.UserName,
    u.UserSurename,
    b.Name AS BadgeName,
    b.Description AS BadgeDescription
FROM 
    [User] u
JOIN 
    Badge b ON u.BadgeId = b.Id
WHERE 
    u.CompanyId = 1;


-- Kullanıcının şirketlere yaptığı bağışları ayrı ayrı veren kod
SELECT 
    u.UserName,
    u.UserSurename,
    b.Name AS BadgeName,
    b.Description AS BadgeDescription
FROM 
    [User] u
JOIN 
    Badge b ON u.BadgeId = b.Id
WHERE 
    u.CompanyId = 1;

-- Bir kullanıcının sahip olduğu badge'leri veren kod
SELECT 
    b.Name AS BadgeName,
    b.Description AS BadgeDescription
FROM 
    [User] u
JOIN 
    Badge b ON u.BadgeId = b.Id
WHERE 
    u.Id = 2;



-- Kullanıcının şirketlere yaptığı toplam bağış miktarını veren kod
SELECT 
    u.UserName,
    u.UserSurename,
    SUM(d.Amount) AS TotalDonationAmount
FROM 
    Donation d
JOIN 
    [User] u ON d.UserId = u.Id
WHERE 
    u.Id = 2
GROUP BY 
    u.UserName, u.UserSurename;


-- Şirketin kampanyalarını ekranda gösteren kod
SELECT 
    c.Name AS CompanyName,
    cmp.Id AS CampaignId,
    cmp.EndDate,
    b.Name AS BadgeName,
    b.Description AS BadgeDescription
FROM 
    Campain cmp
JOIN 
    Badge b ON cmp.BadgeId = b.Id
JOIN 
    Company c ON cmp.CompanyId = c.Id
WHERE 
    cmp.CompanyId = 1;



-- Tetikleyici : Bagıs miktarı toplam 10k olursa prosedure calıstır
CREATE TRIGGER trg_BadgeKontrol
ON Donation
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId INT;
    DECLARE @CompanyId INT;

    -- Yeni eklenen bağışın bilgilerini al
    SELECT @UserId = UserId, @CompanyId = CompanyId
    FROM inserted;

    -- Saklı yordamı çağırarak bağış kontrolü yap ve badge atamasını gerçekleştir
    EXEC ProToplamOnBinBadgeAtama @UserId, @CompanyId;
END;


-- 7. Transaction Yonetimi
BEGIN TRANSACTION;
DECLARE @DonationId int;
DECLARE @UserId int;
BEGIN TRY
	SET @UserId = 2; 
    INSERT INTO Donation (CompanyId, UserId, PaymentTypeId, Amount) VALUES (1, @UserId, 1, 20000);
	Set @DonationId = (SELECT TOP 1 ID FROM Donation ORDER BY 1 DESC); --Yukaridaki bagisin idsini degiskene atiyor
	INSERT INTO FeedBack (DonationId, UserId, Message, Date) VALUES (@DonationId, @UserId, 'Eda kullanicisi bagis yapiyor', GETDATE());
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Islem Sirasinda bir hata olustu';
END CATCH;
