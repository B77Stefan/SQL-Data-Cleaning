/* Cleaning Data in SQL */
Select *
From PortofolioProject.dbo.NashvilleHousing

--Check the data type columns
EXEC sp_help 'NashvilleHousing';

-- Standardise the Date Format
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM PortofolioProject..NashvilleHousing;

--UPDATE PortofolioProject..NashvilleHousing
--SET SaleDate = CONVERT(DATE, SaleDate);

ALTER TABLE PortofolioProject..NashvilleHousing
ALTER COLUMN SaleDate DATE;

--Address Null values in the Property Address Column
SELECT a. [UniqueID ], b.[UniqueID ], a.ParcelID, b.ParcelID, a. PropertyAddress, b. PropertyAddress, 
		ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortofolioProject..NashvilleHousing a
INNER JOIN PortofolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortofolioProject..NashvilleHousing a
INNER JOIN PortofolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID];

--Split the Property Address column into two individual columns for Address and City
SELECT PropertyAddress, LEN(PropertyAddress),  CHARINDEX(',', PropertyAddress, 1)
FROM PortofolioProject..NashvilleHousing;

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1)-1) AS PropertySplitAddress,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS PropertySplitCity,
	RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress, 1) - 1) AS PropertySplitCity_2
FROM PortofolioProject..NashvilleHousing;

ALTER TABLE PortofolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortofolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1)-1);

ALTER TABLE PortofolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortofolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress));

SELECT *
FROM PortofolioProject..NashvilleHousing;

--Replace Null values in Owner Address column with Property Address values
UPDATE PortofolioProject..NashvilleHousing
SET OwnerAddress = ISNULL(OwnerAddress, PropertyAddress)

--Split the Owner Address column into three individual columns for Address, City, and State
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM PortofolioProject..NashvilleHousing
WHERE PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) IS NOT NULL;

ALTER TABLE PortofolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE PortofolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
WHERE PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) IS NOT NULL;

ALTER TABLE PortofolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortofolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
WHERE PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) IS NOT NULL;

ALTER TABLE PortofolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortofolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
WHERE PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) IS NOT NULL;

--Replace NULL values in the OwnerSplitAddress and OwnerSplitCity with values from PropertySplitAddress and PropertySplitCity
UPDATE PortofolioProject..NashvilleHousing
SET OwnerSplitAddress = PropertySplitAddress
WHERE OwnerSplitAddress IS NULL;

UPDATE PortofolioProject..NashvilleHousing
SET OwnerSplitCity = PropertySplitCity
WHERE OwnerSplitCity IS NULL;

--Replace 'Y' and 'N' to 'Yes' and 'No' for SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortofolioProject..NashvilleHousing
GROUP BY SoldAsVacant;

UPDATE PortofolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END;

--Remove duplicates
WITH RowNumDuplicates AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY ParcelID,
										LandUse,
										PropertyAddress,
										SaleDate,
										SalePrice,
										LegalReference
											ORDER BY UniqueID
										) row_num
	FROM PortofolioProject..NashvilleHousing )
DELETE
FROM RowNumDuplicates
WHERE row_num > 1
ORDER BY PropertyAddress;

--Delete unused columns from the table
ALTER TABLE PortofolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress;