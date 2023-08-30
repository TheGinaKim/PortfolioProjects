/*
CLEANING DATA IN SQL QUERIES
*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- STANDARDIZE DATE FORMAT
-- Utilizing AlterTable and Update, Convert

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing;
-- Alter table and executed query. Updated NashvilleHousing and executed Query. SELECT SaleDateConverted and ran query to confirm the SaleDate has been converted.

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate);

SELECT SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- POPULATE PROPERTY ADDRESS DATA
-- Utilizing Joins, ISNULL, and Update

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;
/* Notice when executing this query... where the ParcelID is exactly the same, the PropertyAddress is also the same (Example rows 44 and 45)
 So.. something we can do is for the ParcelIDs that are missing a Property Address, if there is an exact ParcelID with a PropertyAddress, we can populate the PropertyAddress for the matching ParcelIDs */


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVDUAL COLUMNS (ADDRESS, CITY, STATE)
-- Utilizing substring and character index, Parsname

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing;

/* Delimiter = something that separates different colunns / values. Such as commas in an address */

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress)) AS Address
, CHARINDEX(',' , PropertyAddress) --This line shows us the character count up until the comma
FROM PortfolioProject.dbo.NashvilleHousing;


-- Get rid of the comma at the end of the address...
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) AS Address
--, CHARINDEX(',' , PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress)) AS City  --Shows City after comma 
FROM PortfolioProject.dbo.NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255); --Nvarchar in case it is a large string

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress));

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing;



SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing;


SELECT
PARSENAME(OwnerAddress,1)  --PARSENAME looks for periods, not commas. We can replace the commas with periods.
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1) -- replacing commas with periods
, PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2) 
, PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3) 
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3) 
, PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2) 
, PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1) 
FROM PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3);


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2);


ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1);

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD
-- Utilizing a case statement

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- REMOVE DUPLICATES
-- Utilizing partitions, CTE, and Windows functions to find where there are duplicate values

SELECT * , 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID-- Partition on things that should be unique to each row
				, PropertyAddress
				, SalePrice
				, SaleDate
				, LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID;

-- CTE
WITH RowNumCTE AS(
SELECT * , 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID-- Partition on things that should be unique to each row
				, PropertyAddress
				, SalePrice
				, SaleDate
				, LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 --This while show the duplicates
ORDER BY PropertyAddress;

--Delete duplicates
WITH RowNumCTE AS(
SELECT * , 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID-- Partition on things that should be unique to each row
				, PropertyAddress
				, SalePrice
				, SaleDate
				, LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


--------------------------------------------------------------------------------------------------------------------------------------------------------

-- DELETE UNUSED COLUMNS
-- NOTE TO SELF: do not do this to raw data imported

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate;


